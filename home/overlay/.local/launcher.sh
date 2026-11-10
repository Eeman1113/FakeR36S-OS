#!/bin/sh
# FakeR36S-OS: boot straight into EmulationStation (the ArkOS frontend).
# Puppy, goodluckOS's original launcher, is still available under Tools.
. /etc/profile 2>/dev/null
export HOME=/home/player
cd "$HOME"
if [ -x /usr/bin/emulationstation ]; then
    exec /usr/bin/emulationstation
fi
exec /usr/bin/puppy
