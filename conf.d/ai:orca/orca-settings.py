#!/usr/bin/env python3
"""Export, compare and import Orca settings against conf.d/ai:orca/orca-settings.json.

    orca-settings.py export   DB -> JSON (portable keys only, see portable())
    orca-settings.py check    print the JSON keys whose value differs in the DB (exit 1 if any)
    orca-settings.py import   JSON -> DB (Orca must be closed; DB backed up first)

Exit codes: 0 ok / in sync, 1 differs (check), 2 missing DB or JSON, 3 Orca is running (import).
Stdout: one key per line (changed or exported keys); errors on stderr. The tasks dots:orca:export,
dots:orca:import and dots:sync render that output.

Orca keeps its settings as one JSON document (domain "settings") in the SQLite store
~/Library/Application Support/orca/profiles/<profile>/profile-state.db (table profile_state_documents).
Format observed on Orca's schemaVersion 1, not documented: payload is compact JSON, content_hash is
sha256(payload), revision is the store-wide counter of profile_state_meta at the last write. An import
bumps both. Other domains (repos, worktrees, sessions...) are never touched.
"""

import hashlib
import json
import os
import re
import shutil
import sqlite3
import subprocess
import sys
import time
from pathlib import Path

HERE = Path(__file__).resolve().parent
JSON_PATH = HERE / "orca-settings.json"
PROFILE = os.environ.get("ORCA_PROFILE", "local-default")
DB_PATH = Path(os.environ.get("ORCA_DB", Path.home() / "Library/Application Support/orca/profiles" / PROFILE / "profile-state.db"))
BACKUP_DIR = Path(os.environ.get("XDG_STATE_HOME", Path.home() / ".local/state")) / "dots-orca"
SCHEMA_VERSION = "1"

# Portable = look and behaviour. Left out: accounts and secrets, machine paths, telemetry ids,
# Orca's internal migration/default flags, caches tied to installed plugins, Windows/WSL options.
INCLUDE = re.compile(
    r"^(theme|app(FontFamily|Icon)|editor|terminal|diff|markdown|notifications|compactWorktreeCards"
    r"|leftSidebar|window|reduceVisualEffects|show|uiLanguage$|branchPrefix|sourceControl|nativeChat"
    r"|openLinksInApp|tabAutoGenerateTitle|confirmClosePinnedTab|ctrlTabOrderMode|rightSidebarOpenByDefault"
    r"|floatingTerminal|keepComputerAwakeWhileAgentsRun|minimizeToTrayOnClose|prAutoRefresh"
    r"|plugin(AppTheme|IconTheme)|defaultTuiAgent|agentDefaultSurface|agentPermissionDefault"
    r"|experimental|skip)"
)
EXCLUDE = re.compile(
    r"Migrated|Defaulted|Seed|Windows|Wsl|Authority|Prompted|TrustedCwds|terminalHidden|ViewParking"
    r"|terminalPluginPalettes|nativeChat(ShellEnvironmentVariables|SessionOptions)"
)


def portable(key):
    return bool(INCLUDE.match(key)) and not EXCLUDE.search(key)


def die(msg, code=2):
    print(msg, file=sys.stderr)
    sys.exit(code)


def connect(readonly):
    if not DB_PATH.exists():
        die(f"no Orca store at {DB_PATH} (Orca never started on this profile?)")
    uri = f"file:{DB_PATH}" + ("?mode=ro" if readonly else "")
    db = sqlite3.connect(uri, uri=True)
    row = db.execute("select payload from profile_state_documents where domain='schemaVersion'").fetchone()
    if not row or row[0] != SCHEMA_VERSION:
        die(f"Orca store schema is {row and row[0]}, this script knows {SCHEMA_VERSION}: check the format first")
    return db


def db_settings(db):
    row = db.execute("select payload, domain_version from profile_state_documents where domain='settings'").fetchone()
    if not row or row[1] != 1:
        die("unexpected settings document in the Orca store (missing or domain_version != 1)")
    return json.loads(row[0])


def repo_settings():
    if not JSON_PATH.exists():
        die(f"no {JSON_PATH.name} yet: run dots:orca:export first")
    return json.loads(JSON_PATH.read_text())


def diff(db_values, wanted):
    return [k for k, v in wanted.items() if db_values.get(k, object()) != v]


def orca_running():
    if subprocess.run(["pgrep", "-x", "Orca"], capture_output=True).returncode == 0:
        return True
    # anything else holding the store open (a headless orca serve, a helper)
    return bool(subprocess.run(["lsof", "-t", str(DB_PATH)], capture_output=True, text=True).stdout.strip())


def export():
    values = db_settings(connect(readonly=True))
    out = {k: values[k] for k in sorted(values) if portable(k)}
    JSON_PATH.write_text(json.dumps(out, indent=2, ensure_ascii=False) + "\n")
    print("\n".join(out))


def check():
    changed = diff(db_settings(connect(readonly=True)), repo_settings())
    print("\n".join(changed))
    sys.exit(1 if changed else 0)


def do_import():
    wanted = repo_settings()
    if orca_running():
        die("Orca is running: quit it (and any orca serve) first, it would overwrite the import", 3)
    db = connect(readonly=False)
    values = db_settings(db)
    changed = diff(values, wanted)
    if not changed:
        return
    BACKUP_DIR.mkdir(parents=True, exist_ok=True)
    backup = BACKUP_DIR / f"profile-state-{PROFILE}-{time.strftime('%Y%m%d-%H%M%S')}.db"
    with sqlite3.connect(backup) as dst:
        db.backup(dst)
    values.update(wanted)
    payload = json.dumps(values, separators=(",", ":"), ensure_ascii=False)
    with db:  # one transaction: document + store revision move together
        rev = int(db.execute("select value from profile_state_meta where key='revision'").fetchone()[0]) + 1
        db.execute(
            "update profile_state_documents set payload=?, content_hash=?, revision=?, updated_at=? where domain='settings'",
            (payload, hashlib.sha256(payload.encode()).hexdigest(), rev, int(time.time() * 1000)),
        )
        db.execute("update profile_state_meta set value=? where key='revision'", (str(rev),))
    db.execute("pragma wal_checkpoint(truncate)")
    db.close()
    print("\n".join(changed))
    print(f"backup: {backup}", file=sys.stderr)


if __name__ == "__main__":
    cmd = sys.argv[1] if len(sys.argv) > 1 else ""
    {"export": export, "check": check, "import": do_import}.get(cmd, lambda: die(__doc__))()
