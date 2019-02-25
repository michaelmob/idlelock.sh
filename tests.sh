#!/usr/bin/env bash
args=$@
IDLELOCK_DO_NOT_RUN=1 source ./idlelock.sh
test_window_process_name='glxgears'
test_window_title='Gears'
test_audio_url='https://www.youtube.com/watch?v=s-cAcqsFJWY'


test_window_is_not_fullscreen() {
	#
	# Test is_window_fullscreen does not pass when no window is fullscreen.
	#
	is_window_fullscreen && return 1
	return 0
}


test_window_is_fullscreen() {
	#
	# Test is_window_fullscreen does not pass when no window is fullscreen.
	#
	result=1
	sh -c "exec $test_window_process_name" &
	sleep 0.5
	wmctrl -r $test_window_title -b add,fullscreen
	is_window_fullscreen && result=0
	kill $(jobs -p)
	return $result
}


test_audio_is_playing() {
	#
	# Test is_audio_playing passes when audio is playing.
	#
	result=1
	sh -c "exec mpv '$test_audio_url' --no-video" &
	sleep 5
	is_audio_playing && result=0
	kill $(jobs -p)
	return $result
}


test_audio_is_not_playing() {
	#
	# Test is_audio_playing fails when audio is not playing.
	#
	is_audio_playing && return 1
	return 0


test_is_network_busy() {
	#
	# Test is_network_busy passes when downloading a file.
	#
	trap 'kill $(jobs -p); rm -f /tmp/test_file' RETURN
	sh -c "wget --limit-rate=501k '$test_download_url' -O /tmp/test_file" &
	sleep 2
	is_network_busy x enp5s0 500
}


test_is_network_not_busy() {
	#
	# Test is_network_busy fails when not downloading.
	#
	! is_network_busy x enp5s0 500
}
}


validate() {
	#
	# Validate test environment.
	#
	which wmctrl &> /dev/null || { echo 'Missing wmctrl.' && exit 1; }
	which glxgears &> /dev/null || { echo 'Missing glxgears.' && exit 1; }
	which mpv &> /dev/null || { echo 'Missing mpv.' && exit 1; }
	which youtube-dl &> /dev/null || { echo 'Missing youtube-dl.' && exit 1; }
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
