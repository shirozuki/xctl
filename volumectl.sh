#!/bin/sh

invalidopt() {
	printf 'usage: %s up|down|toggle\n' "$0" >&2
	exit 2
}

modbar_notify() {
	[ -n "$MODBAR_PIPE_PATH" ] || return 0
	[ -p "$MODBAR_PIPE_PATH" ] || return 0

	timeout 0.1 sh -c 'printf "mb-volume\n" > "$1"' _ \
		"$MODBAR_PIPE_PATH" 2>/dev/null

	return 0
}

case $1 in
	up)
		pactl set-sink-volume @DEFAULT_SINK@ +1%
		modbar_notify
		;;
	down)
		pactl set-sink-volume @DEFAULT_SINK@ -1%
		modbar_notify
		;;

	toggle)
		pactl set-sink-mute @DEFAULT_SINK@ toggle
		modbar_notify
		;;
	*)
		invalidopt
		;;
esac

