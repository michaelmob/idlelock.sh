#!/usr/bin/env bash
args=$@
IDLELOCK_DO_NOT_RUN=1 source ./idlelock.sh
test_window_process_name='gears'
test_window_title='Gears'


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


validate() {
	#
	# Validate test environment.
	#
	which wmctrl &> /dev/null || { echo 'Missing wmctrl.' && exit 1; }
	which glxgears &> /dev/null || { echo 'Missing glxgears.' && exit 1; }
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
