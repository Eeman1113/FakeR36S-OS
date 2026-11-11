#!/bin/bash
# Build the FakeR36S-OS rootfs natively on a Google Colab VM (no Docker), same layout as rootfs/Dockerfile.
# Usage in a Colab cell:  !curl -fsSL https://raw.githubusercontent.com/Eeman1113/FakeR36S-OS/main/tools/colab-build.sh | bash
# Runs in the background; check progress with:  !bash /content/fr/tools/colab-status.sh
set -e
apt-get -qq update >/dev/null && apt-get -qq install -y build-essential libncurses-dev file wget cpio unzip rsync bc git python3 >/dev/null
cd /content && rm -rf fr && git clone -q --depth 1 https://github.com/Eeman1113/FakeR36S-OS.git fr
mkdir -p /src && cd /src
[ -d buildroot ] || git clone -q --depth 1 -b 2026.08-rc2 https://gitlab.com/buildroot.org/buildroot.git buildroot
for d in scripts board configs package; do rm -rf "/src/$d"; cp -r "/content/fr/rootfs/$d" "/src/$d"; done
printf 'name: GOODLUCKOS\ndesc: An enthusiast OS for the GA36-MB\n' > /src/external.desc
echo 'include $(sort $(wildcard $(BR2_EXTERNAL_GOODLUCKOS_PATH)/package/*/*.mk))' > /src/external.mk
echo 'source "/src/package/Config.in"' > /src/Config.in
mkdir -p /src/out /src/dl /src/ccache
export FORCE_UNSAFE_CONFIGURE=1
nohup bash -c 'bash /src/scripts/configure.sh && bash /src/scripts/build.sh -j$(nproc); echo "BUILD EXIT CODE: $?"' > /content/br.log 2>&1 &
echo "Started on $(nproc) threads. Log: /content/br.log"
