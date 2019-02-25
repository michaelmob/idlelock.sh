#!/usr/bin/env bash
args=$@
IDLELOCK_DO_NOT_RUN=1 source ./idlelock.sh
test_window_process_name='glxgears'
test_window_title='Gears'
test_audio_url='https://www.youtube.com/watch?v=s-cAcqsFJWY'
test_download_url='http://ipv4.download.thinkbroadband.com/1GB.zip'


test_is_window_fullscreen() {
	#
	# Test is_window_fullscreen does not pass when no window is fullscreen.
	#
	trap 'kill $(jobs -p)' RETURN
	sh -c "exec $test_window_process_name" &
	sleep 0.5
	wmctrl -r $test_window_title -b add,fullscreen
	is_window_fullscreen
}


test_is_window_not_fullscreen() {
	#
	# Test is_window_fullscreen does not pass when no window is fullscreen.
	#
	! is_window_fullscreen
}


test_is_audio_playing() {
	#
	# Test is_audio_playing passes when audio is playing.
	#
	trap 'kill $(jobs -p)' RETURN
	sh -c "exec mpv '$test_audio_url' --no-video" &
	sleep 5
	is_audio_playing
}


test_is_audio_not_playing() {
	#
	# Test is_audio_playing fails when audio is not playing.
	#
	! is_audio_playing
}


test_is_network_busy() {
	#
	# Test is_network_busy passes when downloading a file.
	#
	trap 'kill $(jobs -p); rm -f /tmp/test_file' RETURN
	sh -c "wget --limit-rate=501k '$test_download_url' -O /tmp/test_file" &
	sleep 2
	is_network_busy enp5s0 500
}


test_is_network_not_busy() {
	#
	# Test is_network_busy fails when not downloading.
	#
	! is_network_busy enp5s0 500
}


test_is_cpu_busy() {
	#
	# Test is_cpu_busy passes when there is cpu load.
	#
	trap 'pkill stress' RETURN
	sh -c "stress -c 16" &
	sleep 10
	is_cpu_busy x 3
}


test_is_cpu_not_busy() {
	#
	# Test is_cpu_busy fails when there is no cpu load.
	#
	! is_cpu_busy x 5
}


test_run_command() {
	#
	# Test run_command runs a temporary timer command.
	#
	commands=( [temp]='touch /tmp/test_file' )
	run_command temp
	sleep 0.5
	rm /tmp/test_file
}


test_run_command_with_invalid_timer() {
	#
	# Test run_command fails on invalid timer key.
	#
	! run_command invalid
}


test_run_restore() {
	#
	# Test run_restore runs a restore command.
	#
	restores=( [temp]='touch /tmp/test_file' )
	run_restore temp
	sleep 0.2
	rm /tmp/test_file
}


test_run_restore_with_invalid_timer() {
	#
	# Test run_restore fails when no restores are specified.
	#
	! run_restore invalid
}


validate() {
	#
	# Validate test environment.
	#
	which wmctrl &> /dev/null || { echo 'Missing wmctrl.' && exit 1; }
	which glxgears &> /dev/null || { echo 'Missing glxgears.' && exit 1; }
	which mpv &> /dev/null || { echo 'Missing mpv.' && exit 1; }
	which youtube-dl &> /dev/null || { echo 'Missing youtube-dl.' && exit 1; }
	which stress &> /dev/null || { echo 'Missing stress.' && exit 1; }
}


main() {
	#
	# Run test functions.
	#
	test_functions=${args:-$(declare -F | grep -oP ' test_.*')}
	tests_total=$(echo $test_functions | wc -w)
	tests_completed=0; tests_passed=0; tests_failed=0
	for test_function in $test_functions; do
		((tests_completed++))
		if $test_function; then
			echo "$test_function: Passed ($tests_completed/$tests_total)"
			((tests_passed++))
		else
			echo "$test_function: Failed ($tests_completed/$tests_total)"
			((tests_failed++))
		fi
	done

	echo
	echo 'Tests: ' $tests_completed
	echo 'Passed:' $tests_passed
	echo 'Failed:' $tests_failed
}


validate
main
