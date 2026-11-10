#!/bin/bash
# Turn a CI base image into a flashable image for YOUR GA36 card.
#   1. copies sectors 1..172031 of your own stock card dump (vendor boot0 / U-Boot / script.bin / boot-resource)
#   2. writes the custom boot logo into the stock boot-resource FAT (bootlogo.bmp)
#   3. refuses to run unless the stock dump is the A23 "Esisla" variant this build targets
#
# Usage: tools/make-flashable.sh <goodluck_base_a23_panelN.img[.xz]> <stock_dump.img> <out.img>
# The stock dump can be the full card image or just its first 128 MB.
set -euo pipefail
BASE=$1; STOCK=$2; OUT=$3
HERE=$(cd "$(dirname "$0")/.." && pwd)
LOGO=${LOGO:-$HERE/image/res/eeman_bootlogo.bmp}
STOCK_END_SECTOR=172032
SCRIPT_BIN_OFFSET=20340736
BOOTRES_OFFSET=37748736          # stock FAT16 boot-resource partition (sector 73728)
ESISLA=ad0b836c8b3cc6dd2b3b0d8c1817e2fdfe9ed48998a3bed758a73603f05f96e1

# --- variant check: hash script.bin exactly like the goodluckOS Firmware Builder ---
HASH=$(python3 - "$STOCK" <<'EOF'
import struct, hashlib, sys
f = open(sys.argv[1], "rb"); f.seek(20340736); d = f.read(131072)
n = struct.unpack_from("<I", d, 0)[0]; m = 16 + n * 40
for i in range(n):
    cnt, off = struct.unpack_from("<ii", d, 16 + i * 40 + 32); off *= 4
    m = max(m, off + cnt * 40)
    for j in range(cnt):
        do, pat = struct.unpack_from("<iI", d, off + j * 40 + 32)
        m = max(m, do * 4 + (pat & 0xffff) * 4)
print(hashlib.sha256(d[:m]).hexdigest())
EOF
)
if [ "$HASH" != "$ESISLA" ]; then
  echo "Refusing: stock dump script.bin is $HASH, not the A23 Esisla variant this build is made for." >&2
  exit 1
fi
echo "[ok] stock dump is GA36-MB A23 Esisla"

# --- base image ---
case "$BASE" in
  *.xz) xz -dc "$BASE" > "$OUT" ;;
  *)    cp "$BASE" "$OUT" ;;
esac

# --- splice stock boot region (sector 0 = MBR stays from the base image) ---
dd if="$STOCK" of="$OUT" bs=512 skip=1 seek=1 count=$((STOCK_END_SECTOR - 1)) conv=notrunc status=none
echo "[ok] spliced stock sectors 1..$((STOCK_END_SECTOR - 1))"

# --- custom boot logo ---
if [ -f "$LOGO" ]; then
  export MTOOLS_SKIP_CHECK=1
  mcopy -o -i "$OUT@@$BOOTRES_OFFSET" "$LOGO" ::/bootlogo.bmp
  echo "[ok] boot logo -> bootlogo.bmp"
fi

ls -la "$OUT"
echo "Flash with: sudo dd if=$OUT of=/dev/rdiskN bs=4m   (check N with 'diskutil list' first!)"
