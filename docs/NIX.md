# /nix on its own APFS volume

`dots:setup:nix` installs Nix with the Determinate Systems installer, which creates the `/nix`
APFS volume itself (it cannot reuse an existing one). Nothing to prepare by hand.

## Why

The Nix store path is baked into every store path hash, so `/nix` must be the
mount point of its own volume. `dots:check:nix` refuses anything else.

## Which disk

Pick the APFS container where the machine's other dedicated volumes live (see "Machine
layout: Runtimes and Spaces" in `AGENTS.md`): the external disk on a desktop Mac, the
internal container on a laptop. The volume shares the container's free space.

With the external disk unplugged, `/nix` is not mounted and `dots:check:nix` fails
`mise bootstrap`, same as `dots:check:volumes` for Runtimes/Spaces (intended).

## Run

nix profile only. First pre-packages hook, before `dots:check:nix`:

```sh
mise -E home,nix bootstrap
mise run dots:setup:nix        # by hand
```

Needs a terminal and sudo. Interactive:

1. pick the APFS container (internal or external) with gum
2. the installer prints its plan (`--explain`, `--case-sensitive`, no diagnostics)
3. confirm in the installer's prompt (decline and nothing is touched)
4. it installs
5. the downloaded installer script is deleted

Untested: whether `--root-disk` takes the container (`diskutil apfs list`) or the physical
disk. Read the plan before confirming.

No-op when Nix is already installed. Open a new shell afterwards.

## What it changes

The `/nix` volume ("Nix Store", case sensitive), `nix` in `/etc/synthetic.conf`, a line in
`/etc/fstab`, the nix daemon, and `/nix/nix-installer`. Remove Nix with
`/nix/nix-installer uninstall`.

## Notes

- The installer edits the shell startup files under `/etc` (zsh/bash). Fish needs
  `nix-daemon.fish` sourced; not wired.
- `sudo mdutil -i off /nix` is useless on a `nobrowse` volume and fails with
  `Error: unknown indexing state (-400)`.
- Leftover from a manual setup (a "Nix Store" volume, an `/etc/fstab` line, a `nix` line in
  `/etc/synthetic.conf`) must be removed first, or the installer fails:

  ```sh
  sudo diskutil unmount /nix
  sudo diskutil apfs deleteVolume <volume>
  ```

  Then delete the `/nix` line of `/etc/fstab` and the `nix` line of `/etc/synthetic.conf`,
  and reboot. `sudo vifs` fails when `EDITOR` has arguments (`zed --wait`): use
  `sudo EDITOR=nano vifs`, or `sed`.
