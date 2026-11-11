#!/bin/bash
# Assemble a FakeR36S-OS base image from CI artifacts without Docker or guestfish
# (same layout as image/Dockerfile). Works on macOS and Linux.
# Needs: python3, mke2fs from e2fsprogs >= 1.47.1 (tarball support in -d), mkfs.fat (dosfstools), mtools.
# Usage: tools/assemble-base.sh android_boot_a23_panel2.img rootfs.tar home.tar goodluck_base_a23_panel2.img
set -euo pipefail
BOOT=$1; ROOTFS=$2; HOME_TAR=$3; OUT=$4
MKE2FS=${MKE2FS:-mke2fs}; MKFAT=${MKFAT:-mkfs.fat}
SECT=512
P1_START=262144;  P1_END=3145728     # 128 MiB .. 1536 MiB  (system, ext4 "linux")
P2_START=3145728; TOTAL=4194304      # 1536 MiB .. 2 GiB    (HOME, FAT32, grown on first boot)
P1_LEN=$((P1_END - P1_START)); P2_LEN=$((TOTAL - P2_START))
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT

rm -f "$OUT"; truncate -s $((TOTAL * SECT)) "$OUT"

# MBR: p1 Linux (0x83), p2 FAT32 LBA (0x0c), like parted's msdos label
python3 - "$OUT" $P1_START $P1_LEN $P2_START $P2_LEN <<'EOF'
import struct, sys, os
out, p1s, p1l, p2s, p2l = sys.argv[1], *map(int, sys.argv[2:])
mbr = bytearray(512)
mbr[440:444] = os.urandom(4)                     # disk signature
def entry(ptype, start, length):
    return struct.pack("<B3sB3sII", 0, b"\xfe\xff\xff", ptype, b"\xfe\xff\xff", start, length)
mbr[446:462] = entry(0x83, p1s, p1l)
mbr[462:478] = entry(0x0C, p2s, p2l)
mbr[510:512] = b"\x55\xaa"
with open(out, "r+b") as f: f.write(mbr)
EOF

# kernel (Android boot image) at sector 172032, inside the stock boot region
dd if="$BOOT" of="$OUT" bs=$SECT seek=172032 conv=notrunc status=none

# system partition: ext4 straight from the rootfs tarball (keeps owners, modes, device nodes)
"$MKE2FS" -q -t ext4 -L linux -d "$ROOTFS" "$TMP/p1.img" $((P1_LEN * SECT / 1024))k
dd if="$TMP/p1.img" of="$OUT" bs=1m seek=$((P1_START * SECT / 1048576)) conv=notrunc status=none

# HOME: FAT32 with the home overlay
truncate -s $((P2_LEN * SECT)) "$TMP/p2.img"
"$MKFAT" -F 32 -n HOME "$TMP/p2.img" >/dev/null
mkdir -p "$TMP/home" && tar -xf "$HOME_TAR" -C "$TMP/home"
export MTOOLS_SKIP_CHECK=1
mcopy -s -i "$TMP/p2.img" "$TMP/home/." ::/
dd if="$TMP/p2.img" of="$OUT" bs=1m seek=$((P2_START * SECT / 1048576)) conv=notrunc status=none

ls -la "$OUT"
