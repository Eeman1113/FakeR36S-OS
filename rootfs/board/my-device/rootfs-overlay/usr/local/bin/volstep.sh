#!/bin/sh
CARD=0
CONTROL=Headphone
STEP=5

cur=$(amixer -c "$CARD" sget "$CONTROL" | grep -m1 -oE '[0-9]+%' | tr -d '%')

case "$1" in
    up)   new=$((cur + STEP)); [ "$new" -gt 100 ] && new=100 ;;
    down) new=$((cur - STEP)); [ "$new" -lt 0 ] && new=0 ;;
esac

if [ "$new" -eq 0 ]; then
    amixer -q -c "$CARD" sset "$CONTROL" 0% mute
else
    amixer -q -c "$CARD" sset "$CONTROL" "${new}%" unmute
fi

# FakeR36S-OS: remember this level for the current output (speaker / headphones)
out=$(/usr/local/bin/audio-output.sh get 2>/dev/null)
[ -n "$out" ] && { mkdir -p /home/player/.config/audio; echo "$new" > "/home/player/.config/audio/$out.vol"; }
[ "$(id -u)" = 0 ] && chown -R player:player /home/player/.config/audio 2>/dev/null
exit 0
