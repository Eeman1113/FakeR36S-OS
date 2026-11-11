#!/bin/bash
# Update FakeR36S-OS on a card that already has it, keeping everything on HOME (games, saves,
# save states, settings, art, BIOS, ports). Writes only the boot region and the system partition
# (sectors 1 .. 3145727) from a new flashable image; the partition table and HOME are untouched.
#
#   macOS:  sudo tools/update-os.sh fakers36s.img disk4
#   Linux:  sudo tools/update-os.sh fakers36s.img /dev/sdb
#
# The image must be a flashable FakeR36S-OS image (from the web installer or make-flashable.sh).
# Prefer the on-device update (web installer, "Update instead") if you can: it needs no root.
set -euo pipefail
IMG=${1:?usage: $0 <fakers36s.img> <disk: diskN on macOS, /dev/sdX on Linux>}
DEV=${2:?name the card's disk explicitly (macOS: diskutil list, Linux: lsblk)}
P1_START=262144                 # system partition (128 MiB)
P2_START=3145728                # HOME (1536 MiB)

[ -f "$IMG" ] || { echo "No such image: $IMG" >&2; exit 1; }
case $(uname) in
    Darwin)
        DEV=${DEV#/dev/}; RAW=/dev/r$DEV
        diskutil info "$DEV" | grep -q "Removable Media:.*Removable" || { echo "Refusing: $DEV is not removable media." >&2; exit 1; }
        unmount() { diskutil unmountDisk "/dev/$DEV" >/dev/null; }
        done_msg() { diskutil eject "/dev/$DEV" >/dev/null 2>&1 || true; } ;;
    Linux)
        RAW=$DEV
        [ "$(cat /sys/block/$(basename "$DEV")/removable 2>/dev/null)" = 1 ] || { echo "Refusing: $DEV is not removable." >&2; exit 1; }
        unmount() { for p in "$DEV"?*; do umount "$p" 2>/dev/null || true; done; }
        done_msg() { true; } ;;
    *) echo "macOS or Linux only; elsewhere use the on-device update." >&2; exit 1 ;;
esac

starts() { dd if="$1" bs=512 count=1 2>/dev/null | python3 -c 'import sys, struct
m = sys.stdin.buffer.read()
print(*(struct.unpack_from("<I", m, 446 + 16 * i + 8)[0] for i in range(2)))'; }
unmount
[ "$(starts "$RAW")" = "$P1_START $P2_START" ] || { echo "Refusing: the card doesn't have FakeR36S-OS's partition layout." >&2; exit 1; }
[ "$(starts "$IMG")" = "$P1_START $P2_START" ] || { echo "Refusing: the image doesn't have FakeR36S-OS's layout." >&2; exit 1; }

read -r -p "Update FakeR36S-OS on $DEV? Your HOME partition is kept. [y/N] " ok
[ "$ok" = y ] || [ "$ok" = Y ] || exit 1
dd if="$IMG" of="$RAW" bs=512 skip=1 seek=1 count=2047 2>/dev/null
dd if="$IMG" of="$RAW" bs=1048576 skip=1 seek=1 count=1535
sync
[ "$(starts "$RAW")" = "$P1_START $P2_START" ] || echo "WARNING: the partition table looks different now." >&2
done_msg
echo "Done. Put the card in the console: games, saves and settings are all still there."
