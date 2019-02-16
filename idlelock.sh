#!/usr/bin/env bash

#
# idlelock.sh -- run programs on inactivity
# github.com/thetarkus/idlelock.sh
#


__version=0.2.1
declare -A timers commands inhibitors restores


is_audio_playing() {
	#
	# Test for audio playing.
	#
	grep -c RUNNING /proc/asound/card*/pcm*/sub*/status > /dev/null
}


is_window_fullscreen() {
	#
	# Test for active fullscreen window.
	#
	window=$(xdotool getactivewindow); [[ "$window" ]] || return 1
	xwininfo -id $window -wm | grep -cP '\s{8}Fullscreen' > /dev/null
}


is_network_busy() {
	#
	# Test if network is busy.
	# $0 = ignored
	# $1 = network card name (ip link)
	# $2 = kbps to inhibit at
	#
	local IFS=' '; args=($@)
	net_stats_path="/sys/class/net/${args[1]}/statistics"
	tx_file="$net_stats_path/tx_bytes"
	rx_file="$net_stats_path/rx_bytes"
	prev_tx=$(<$tx_file)
	prev_rx=$(<$rx_file)
	sleep 1
	(( ($(<$tx_file) - prev_tx + $(<$rx_file) - prev_rx) / 1000 > ${args[2]} ))
}


is_cpu_busy() {
	#
	# Test if network is busy.
	# $0 = ignored
	# $1 = cpu load to inhibit at
	#
	local IFS=' '; args=($@)
	return $(echo "$(grep -oP '^.*? ' /proc/loadavg) < ${args[1]}" | bc)
}


is_inhibited() {
	#
	# Test for successful inhibitors.
	# $1 = timer seconds
	# returns 0 when inhibited
	#
	local temp_inhibitors=

	# global inhibitors
	[[ $global_inhibitors ]] && \
		temp_inhibitors+=$global_inhibitors

	# timer inhibitors
	[[ $1 ]] && [[ ${inhibitors[$1]} ]] && \
		temp_inhibitors+=";${inhibitors[$1]}"

	# loop through inhibitors, return
	local IFS=';'
	for value in $temp_inhibitors; do
		case $value in
			# audio inhibitor
			audio) is_audio_playing && return 0 ;;

			# fullscreen inhibitor
			fullscreen) is_window_fullscreen && return 0 ;;

			# network inhibitor
			network*) is_network_busy $value && return 0 ;;

			# cpu load inhibitor
			cpu*) is_cpu_busy $value && return 0 ;;

			# external inhibitor
			*) [[ $value ]] && sh -c "$value" && return 0 ;;
		esac
	done

	return 1
}


run_command() {
	#
	# Run timers command.
	# $1 = timer seconds
	#
	[[ $1 ]] || return
	[[ ${commands[$1]} ]] || return
	sh -c "${commands[$1]}" &
}


run_restore() {
	#
	# Run global and timers restore commands.
	# $1 = timer seconds
	#
	[[ $global_restore ]] && sh -c "$global_restore" &
	[[ $1 ]] || return
	[[ ${restores[$1]} ]] || return
	sh -c "${restores[$1]}" &
}


idle_monitor() {
	#
	# Monitor session idle time using an external process.
	#
	local args=
	for timer in ${!timers[@]}; do
		[[ " ${repeating_timers[@]} " =~ " ${timers[$timer]} " ]] \
			&& args+="-r $timer " \
			|| args+="-s $timer "
	done

	xidleseconds $args | while read -r line; do
		[[ $line ]] || continue

		timer=${timers[$line]}
		[[ $timer ]] || continue

		# on restore, run restore for the last ran timer
		if [[ $timer = 'restore' ]]; then
			run_restore $last_timer

		# do not check inhibition when restoring
		else
			is_inhibited $timer && continue
		fi

		run_command $timer
		last_timer=$timer
	done
}


dbus_monitor() {
	#
	# Monitor dbus for events like lock, unlock, and sleep.
	#
	dbus-monitor --system \
		'type=signal,member=Lock' \
		'type=signal,member=Unlock' \
		'type=signal,member=PrepareForSleep' 2> /dev/null | \
	while read -r line; do
		# get next line when necessary
		[[ $next_line ]] && unset next_line && \
			dbus_receive $member $line && continue

		# ignore non-signals
		[[ $line != signal* ]] && continue

		line=${line##*interface=}
		line=(${line/; member=/ })

		case "${line[@]}" in
			# lock/unlock
			org.freedesktop.login*.Session\ *)
				dbus_receive ${line[1]}
				;;

			# sleep
			org.freedesktop.login*.Manager\ PrepareForSleep)
				member=${line[1]}
				next_line=1  # next iteration will pass to dbus_receive
				;;
		esac
	done &
}


dbus_receive() {
	#
	# Process dbus events.
	#
	case "$1" in
		# run lock
		Lock)
			[[ $primary_timer ]] && run_command $primary_timer
			;;

		# run unlock
		Unlock)
			sh -c "$unlock_command" &
			;;

		# run lock before sleeping
		PrepareForSleep)
			[[ $lock_on_sleep ]] || return
			[[ $primary_timer ]] && run_command $primary_timer
			;;
	esac
}


usage() {
	#
	# Display usage information.
	#
	echo -e "\e[1midlelock.sh $__version\e[0m"
	echo "usage: idlelock.sh [option] ... [-{seconds} +command {command}] ..."
	echo
	echo '-v, --version       : display version'
	echo '-h, --help          : display help'
	echo '-i, --inhibit {cmd} : inhibitors to check against for every timer'
	echo '-r, --restore {cmd} : command to run on restore from every timer'
	echo '-u, --unlock {cmd}  : command to kill or cancel the screen lock'
	echo '-l, --lock-on-sleep : launch lock timer before system sleep'
	echo
	echo -e '\e[1mtimers\e[0m'
	echo "-t {seconds}        : timer to be used with timer options"
	echo '    +command {cmd}  : command to run after {seconds} of inactivity'
	echo '    +restore {cmd}  : command to run on activity after timer is activated'
	echo '    +inhibit {val}  : inhibitors to check against before running command'
	echo '    +primary        : mark timer as primary '
	echo '    +repeat         : run every {seconds} after inactivity'
	echo
	echo 'each timer may different options. options are prefixed with a plus and'
	echo 'only apply to the current timer. multiple options can be combined in'
	echo 'a single timer, either by a semi-colon delimeter or by adding the same'
	echo 'option but with a different value (example in inhibitors section)'
	echo
	echo 'timers must all have different {seconds} values'
	echo
	echo -e '\e[1minhibitors\e[0m'
	echo 'multiple inhibitors can be used by separating them with a semi-colon'
	echo "for example: +inhibit 'fullscreen;audio'"
	echo "         or: +inhibit 'fullscreen' +inhibit 'audio'"
	echo
	echo 'external scripts can also be used as inhibitors. scripts that return an'
	echo "exit code of 0 will inhibit the timer. for example: +inhibit 'audio;exit 0'"
	echo "will check for audio playing and then always be inhibited because of 'exit 0'"
	echo
	echo 'list of built-in inhibitors:'
	echo '    audio'
	echo '    fullscreen'
	echo '    network {device} {kbps}'
	echo '    cpu {load}'
	echo
	echo -e '\e[1mexample\e[0m'
	echo 'idlelock.sh \'
	echo "    --lock-on-sleep \\"
	echo "    --unlock 'pkill i3lock' \\"
	echo "    --inhibit 'fullscreen' \\"
	echo "    --restore 'xrandr --output \$OUTPUT --brightness 1' \\"
	echo '    \'
	echo "    -t 30 \\"
	echo "        +command 'xrandr --output \$OUTPUT --brightness .5' \\"
	echo '    \'
	echo "    -t 60 \\"
	echo "        +command 'pgrep -x i3lock || i3lock -n' \\"
	echo "        +inhibit 'audio' \\"
	echo '    \'
	echo "    -t 65 \\"
	echo "        +command 'xset dpms force off' \\"
	echo '    \'
	echo "    -t 120 \\"
	echo "        +command 'systemctl suspend' \\"
	echo "        +restore 'xset dpms force on'"
	echo
	echo -e '\e[1mexternal commands\e[0m'
	echo 'loginctl lock-session   : launch the screen locker'
	echo 'loginctl unlock-session : kill/cancel the screen locker'
}


main() {
	#
	# Run idlelock.sh.
	#
	echo -e "\e[1midlelock.sh $__version\e[0m"

	# setup
	timers[0]='restore'

	# trap
	trap 'kill $(jobs -p)' EXIT

	# run monitors
	dbus_monitor
	idle_monitor
}


# parse arguments
while :; do
	[[ $1 ]] || break

	case "$1" in
		# version
		-v | --version) echo $__version && exit 0 ;;

		# help
		-h | --help) usage && exit 0 ;;

		# inhibitors
		-i | --inhibit) global_inhibitors+="$2;" ;;

		# restore
		-r | --restore) global_restore+="$2;" ;;

		# lock on sleep
		-l | --lock-on-sleep) lock_on_sleep=1 ;;

		# unlock
		-u | --unlock) unlock_command+="$2;" ;;

		--source) source_only=1 ;;

		# timers
		-t | --timer)
			# check for duplicate timers
			[[ " ${!timers[@]} " =~ " $2 " ]] && {
				echo -e "Duplicate timers: $2\nRun $0 -h for help."
				exit 1; }

			seconds=$2
			timers[$2]=$2

			# parse timer arguments
			while :; do
				case "$1" in
					+c | +command) commands[$seconds]+="$2;" ;;
					+r | +restore) restores[$seconds]+="$2;" ;;
					+i | +inhibit) inhibitors[$seconds]+="$2;" ;;
					+repeat) repeating_timers+=($seconds) ;;
					+primary) primary_timer=$seconds ;;
				esac

				if [[ -z $2 ]] || [[ ${2:0:1} = '-' ]]; then
					break
				fi
				shift 1
			done
			;;
	esac
	shift 1
done


[[ $source_only ]] || main
