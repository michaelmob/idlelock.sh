#!/usr/bin/env bash
pause_file=${PAUSE_FILE:-$HOME/.cache/idlelock.sh/pause}
value=(${1//:/ })
count=${1//[^:]}

# Parse seconds from first argument
case "${#count}" in
	0) seconds=$(( value[0] * 60 )) ;;  # m
	1) seconds=$(( value[0] * 3600 + value[1] * 60 )) ;;  # h:m
	*) seconds=$(( value[0] * 3600 + value[1] * 60 + value[2] )) ;;  # h:m:s
esac

# Pause
if (( seconds > 0 )); then
	h=$(($seconds/3600)); m=$(($seconds%3600/60)); s=$(($seconds%60))
	pause_until=$(( $(printf '%(%s)T') + seconds ))
	mkdir -p $(dirname $pause_file)
	echo $pause_until > $pause_file
	printf 'paused for:   %d hours, %d minutes, %d seconds\n' $h $m $s
	echo 'paused until:' $(date -d @$pause_until)
	notify-send -t 3000 "Screensaver is paused for ${h}h ${m}m ${s}s."

# Unpause
else
	rm -f $pause_file > /dev/null 2>&1
	notify-send -t 3000 "Screensaver is no longer paused."
	echo unpaused
fi

exit 0
