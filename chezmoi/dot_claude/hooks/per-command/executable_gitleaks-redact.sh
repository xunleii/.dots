#!/bin/bash

# Scans PreToolUse tool_input / PostToolUse tool_output for secrets with
# gitleaks and strips them out before the content reaches the model's
# context. Registered for both events in private_settings.json.tmpl.
#
# ponytail: default gitleaks ruleset, no custom allowlist yet — add one in
# ~/.gitleaks.toml (passed via --config) if real secrets trigger false
# positives often enough to be annoying.

set -uo pipefail

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# Redacts secrets found in $1 in place. No-op if gitleaks finds nothing.
redact() {
    local file="$1" report="$tmpdir/report.json"
    gitleaks detect --no-git --source "$file" -f json -r "$report" --exit-code 0 >/dev/null 2>&1
    [ -s "$report" ] || return 0
    jq -r '.[]?.Secret // empty' "$report" 2>/dev/null | sort -u | while IFS= read -r secret; do
        [ -n "$secret" ] || continue
        SECRET="$secret" perl -i -pe 's/\Q$ENV{SECRET}\E/[REDACTED-SECRET]/g' "$file"
    done
}

if [ "${1:-}" = "--self-test" ]; then
    f="$tmpdir/selftest"
    printf 'aws_key = "AKIAIOSFODNN7EXAMPLE"' >"$f"
    redact "$f"
    if grep -q AKIAIOSFODNN7EXAMPLE "$f"; then
        echo "FAIL: secret survived redaction" >&2
        exit 1
    fi
    echo "PASS"
    exit 0
fi

input=$(cat)
event=$(jq -r '.hook_event_name // empty' <<<"$input")

case "$event" in
PreToolUse)
    blob="$tmpdir/input.json"
    jq -c '.tool_input' <<<"$input" >"$blob"
    before=$(cat "$blob")
    redact "$blob"
    [ "$before" = "$(cat "$blob")" ] && exit 0
    jq -n --argjson ui "$(cat "$blob")" \
        '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "allow", updatedInput: $ui}}'
    ;;
PostToolUse)
    blob="$tmpdir/output.txt"
    jq -r '.tool_output // empty' <<<"$input" >"$blob"
    before=$(cat "$blob")
    redact "$blob"
    [ "$before" = "$(cat "$blob")" ] && exit 0
    jq -n --rawfile out "$blob" \
        '{hookSpecificOutput: {hookEventName: "PostToolUse", updatedToolOutput: $out}}'
    ;;
esac
