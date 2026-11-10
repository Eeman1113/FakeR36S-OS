#!/bin/sh
# audio-output.sh toggle|speaker|headphones|get|apply
# The GA36-MB can't detect the headphone jack and the speaker amp is fed from the
# headphone output, so "headphones" just turns the speaker off (Speaker Switch).
# FakeR36S-OS: each output remembers its own volume, and switching fades the volume
# in from silence, so plugging in headphones never blasts the speaker-level volume.

CARD=0
CONTROL=Headphone
STATE_DIR=/home/player/.config/audio
DEFAULT_SPEAKER=70
DEFAULT_HEADPHONES=35
mkdir -p "$STATE_DIR" 2>/dev/null

cur=$(amixer -c "$CARD" cget name='Speaker Switch' 2>/dev/null | grep -o ': values=[a-z]*' | cut -d= -f2)
[ -n "$cur" ] || exit 1
[ "$cur" = on ] && cur=speaker || cur=headphones

vol_now() { amixer -c "$CARD" sget "$CONTROL" | grep -m1 -oE '[0-9]+%' | tr -d '%'; }
saved() {   # saved <output>
    v=$(cat "$STATE_DIR/$1.vol" 2>/dev/null)
    [ -n "$v" ] || { [ "$1" = headphones ] && v=$DEFAULT_HEADPHONES || v=$DEFAULT_SPEAKER; }
    echo "$v"
}
fade_to() { # fade_to <percent>: ramp up from silence in small steps
    target=$1
    amixer -q -c "$CARD" sset "$CONTROL" 0% 2>/dev/null
    [ "$target" -le 0 ] && { amixer -q -c "$CARD" sset "$CONTROL" 0% mute; return; }
    amixer -q -c "$CARD" sset "$CONTROL" unmute
    v=0
    while [ "$v" -lt "$target" ]; do
        v=$((v + 5)); [ "$v" -gt "$target" ] && v=$target
        amixer -q -c "$CARD" sset "$CONTROL" "${v}%"
        sleep 0.02 2>/dev/null
    done
}

case "$1" in
    get)    echo "$cur"; exit 0 ;;
    apply)  fade_to "$(saved "$cur")"; exit 0 ;;
    toggle) [ "$cur" = speaker ] && new=headphones || new=speaker ;;
    speaker|headphones) new=$1 ;;
    *)      echo "usage: $0 toggle|speaker|headphones|get|apply" >&2; exit 2 ;;
esac

vol_now > "$STATE_DIR/$cur.vol"                       # remember the old output's level
amixer -q -c "$CARD" sset "$CONTROL" 0% 2>/dev/null   # silence before switching paths
[ "$new" = headphones ] && sw=off || sw=on
amixer -q -c "$CARD" cset name='Speaker Switch' "$sw"
fade_to "$(saved "$new")"
[ "$(id -u)" = 0 ] && chown -R player:player /home/player/.config/audio 2>/dev/null
exit 0
