#!/usr/bin/env bash
set_brightness_xbacklight() {
	#
	# Change the screen brightness using xbacklight (hardware)
	#
	pkill xbacklight
	brightness_file=${BRIGHTNESS_FILE:-$HOME/.cache/idlelock.sh/brightness}
	mkdir -p $(dirname $brightness_file)

	# restore brightness
	if [[ $1 = 'restore' ]]; then
		[[ -f $brightness_file ]] && \
			xbacklight -set $(<$brightness_file) && \
			rm -f $brightness_file

	# set brightness
	else
		echo $(backlight -get) > $brightness_file
		(( $1 > 0 )) && xbacklight -set $1 || xbacklight -dec $1
	fi
}


set_brightness_xrandr() {
	#
	# Change the screen brightness using xrandr (software fallback)
	#
	[[ $1 = 'restore' ]] \
		&& percent=${XRANDR_PERCENT:-1} \
		|| percent=$(echo "$1/100" | bc -l)

	# ignore negative brightness
	[[ ${percent:0:1} = '-' ]] && percent=${percent:1}

	# re-try until successful, sometimes display doesnt show as connected
	for i in {1..5}; do
		while IFS=$'\n' read -r display; do
			[[ -z $display ]] && continue
			xrandr --output $display --brightness $percent && success=0
		done <<< "$(xrandr | grep -oP '.*(?= connected)')"
		sleep 1
		[[ $success = 0 ]] && return
	done
}


xbacklight 2> /dev/null \
	&& set_brightness_xbacklight $@ \
	|| set_brightness_xrandr $@
