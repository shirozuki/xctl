#!/bin/sh

STEP=1
VOLUME_MAX=150

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

command -v pactl >/dev/null 2>&1 || {
	printf '%s: pactl not found\n' "$0" >&2
	exit 127
}

case $1 in
	up)
		vol=$(LC_ALL=C pactl get-sink-volume @DEFAULT_SINK@ | \
			head -n 1 | \
			awk '{ print $5 }' | \
			tr -d '%')

		[ -n "$vol" ] || exit 1

		if [ $((vol + STEP)) -gt "$VOLUME_MAX" ]; then
			pactl set-sink-volume @DEFAULT_SINK@ "${VOLUME_MAX}%" || exit $?
		else
			pactl set-sink-volume @DEFAULT_SINK@ "+${STEP}%" || exit $?
		fi
		modbar_notify
		;;
	down)
		pactl set-sink-volume @DEFAULT_SINK@ "-${STEP}%" || exit $?
		modbar_notify
		;;

	toggle)
		pactl set-sink-mute @DEFAULT_SINK@ toggle || exit $?
		modbar_notify
		;;
	*)
		invalidopt
		;;
esac
