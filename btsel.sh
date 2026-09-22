#!/bin/sh

DEVICE_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/bluetooth-devices"
ICON="${XDG_CONFIG_HOME:-$HOME/.config}/dunst/critical.png"
ATTEMPTS=3
CONNECT_TIMEOUT=5

die() {
	notify-send -i "$ICON" "Error" "$1"
	exit "${2:-1}"
}

connected() {
	LC_ALL=C bluetoothctl info "$1" 2>/dev/null | \
		grep -q 'Connected: yes'
}

modbar_notify() {
	[ -n "$MODBAR_PIPE_PATH" ] || return 0
	[ -p "$MODBAR_PIPE_PATH" ] || return 0

	timeout 0.1 sh -c 'printf "mb-volume\n" > "$1"' _ \
		"$MODBAR_PIPE_PATH" 2>/dev/null

	return 0
}

for i in dmenu bluetoothctl notify-send; do
	command -v "$i" >/dev/null 2>&1 && continue
	die "Executable \`$i\` not found." 127
done

[ -d "$DEVICE_DIR" ] || die "No devices defined."

devices=$(ls -1 "$DEVICE_DIR")
[ -n "$devices" ] || die "No devices defined."

count=$(printf '%s\n' "$devices" | wc -l)
chosen=$(printf '%s\n' "$devices" | \
	dmenu -i -l "$count" -p "Choose device: ")

[ -z "$chosen" ] && exit 0
[ -f "$DEVICE_DIR/$chosen" ] || die "Unknown device \`$chosen\`."

mac=$(cat "$DEVICE_DIR/$chosen")
[ -n "$mac" ] || die "Empty device file \`$chosen\`."

bluetoothctl show | grep -q "Powered: yes" || \
	bluetoothctl power on >/dev/null 2>&1

try=1
while [ "$try" -le "$ATTEMPTS" ]; do
	bluetoothctl connect "$mac" >/dev/null 2>&1

	waited=0
	while [ "$waited" -lt "$CONNECT_TIMEOUT" ]; do
		connected "$mac" && break 2
		sleep 1
		waited=$((waited + 1))
	done

	try=$((try + 1))
done

connected "$mac" || die "bluetoothctl: Connection attempt failed."

modbar_notify
