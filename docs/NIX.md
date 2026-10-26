# /nix on its own APFS volume

Manual for now: there is no `dots:setup:nix` task yet. Run the steps by hand (sudo).

## Why

The Nix store path is baked into every store path hash, so `/nix` must be the
mount point of its own volume. `dots:check:nix` (nix profile only:
`mise -E home,nix bootstrap`) refuses anything else.

## External or internal disk

The steps are the same, only the APFS container changes. Use the container where
the machine's other dedicated volumes already live (see "Machine layout:
Runtimes and Spaces" in `AGENTS.md`).

- Desktop Mac: the external disk's container. Find it with
  `diskutil list external` (here `disk7`, 2 TB, already holds OrbStack HD, Spaces,
  Runtimes, IA):

  ```sh
  sudo diskutil apfs addVolume disk7 APFS "Nix Store" -nomount
  ```

  With the disk unplugged, `/nix` is not mounted and `dots:check:nix` fails
  `mise bootstrap`, same as `dots:check:volumes` for Runtimes/Spaces (intended).
- Laptop: the internal container. Find it with `diskutil list internal` (here
  `disk3`, 245 GB):

  ```sh
  sudo diskutil apfs addVolume disk3 APFS "Nix Store" -nomount
  ```

  The volume shares the container's free space (here Data uses ~175 GB of 245 GB).

## Steps

1. Make `/nix` exist at the read-only root:

   ```sh
   echo nix | sudo tee -a /etc/synthetic.conf
   sudo /System/Library/Filesystems/apfs.fs/Contents/Resources/apfs.util -t   # or reboot
   ```

2. Create the volume in the container from the section above
   (adapt name and container). External example:

   ```sh
   sudo diskutil apfs addVolume disk7 APFS "Nix Store" -nomount
   ```

3. Mount it on `/nix` through `/etc/fstab` (`sudo vifs` is safer than `tee`):

   ```sh
   uuid=$(diskutil info "Nix Store" | awk '/Volume UUID/ {print $3}')
   echo "UUID=$uuid /nix apfs rw,noauto,nobrowse,suid,owners" | sudo tee -a /etc/fstab
   sudo diskutil mount "Nix Store"
   ```

4. Check:

   ```sh
   mise -E home,nix run dots:check:nix
   ```

## Notes

- `nobrowse` already keeps Spotlight away. Do not run `sudo mdutil -i off /nix`:
  it is useless and fails with `Error: unknown indexing state (-400)` on such a volume.
- Optional quota: append `-quota 300g` (any size) to the `addVolume` command to cap the
  volume; it can only be set at creation. A quota is a cap, not a reservation, so on the
  nearly full internal container (~60 GB free) it changes nothing.
- Optional encryption: `diskutil apfs encryptVolume`.
