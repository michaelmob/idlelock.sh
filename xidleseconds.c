/*
 * xidleseconds 0.1
 *
 * Output idle seconds from the X screensaver extension.
 * Use numeric arguments to only output those idle seconds.
 * Use without arguments for continuous output of idle seconds.
 */
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <X11/extensions/scrnsaver.h>


Display *display = NULL;
XScreenSaverInfo *info = NULL;
unsigned long window;


int char_to_int_array(int len, char **input, int *output) {
    /*
     * Create int array to place (int)chars from char array into.
     * Disallow zero from being in array.
     */
    int value;
    int result = 0;
    for (int i = len - 1; i >= 1; --i) {
        value = strtol(input[i], NULL, 0);
        if (value == 0)
            continue;
        output[result++] = value;
    }
    return result;
}


void continous_counter() {
    /*
     * Continously show idle time.
     */
    unsigned long seconds;
    unsigned long previous_seconds = 0;
    while (1) {
        XScreenSaverQueryInfo(display, window, info);
        seconds = info->idle / 1000;

        // Ignore duplicate outputs.
        if (seconds == previous_seconds) {
            sleep(1);
            continue;
        }

        printf("%lu\n", seconds);
        previous_seconds = seconds;
        sleep(1);
    }
}


void selective_counter(int len, int *values) {
    /*
     * Only show idle time that belongs to the array.
     * Show zero when idle time is reset.
     */
    unsigned long seconds;
    unsigned long previous_seconds = 0;
    int flag = 0;
    while (1) {
        XScreenSaverQueryInfo(display, window, info);
        seconds = info->idle / 1000;
        for (int i = len - 1; i > -1; --i) {
            // Show zero for reset and set flag to false.
            if (flag && (seconds == 0)) {
                printf("0\n");
                previous_seconds = 0;
                flag = 0;
                continue;
            }

            // Ignore duplicate outputs.
            if (seconds == previous_seconds)
                continue;

            // Do not display seconds we are not concerned about.
            // Ignore duplicate outputs.
            if (seconds != values[i])
                continue;

            // Display number and set flag to true.
            printf("%lu\n", seconds);
            previous_seconds = seconds;
            flag = 1;
        }
        sleep(1);
    }
}


int main(int argc, char *argv[]) {
    /*
     * Manipulate arguments and run counter.
     */
    // Set buffer to stdout.
    setbuf(stdout, NULL);

    // Create int array of arguments.
    int values[argc];
    int len = char_to_int_array(argc, argv, values);

    // Get X Display.
    display = XOpenDisplay(NULL);
    if (!display)
        return EXIT_FAILURE;

    window = DefaultRootWindow(display);
    info = XScreenSaverAllocInfo();

    // Only show idle seconds specified in arguments.
    if (argc > 1)
        selective_counter(len, values);

    // Show idle seconds every second.
    else
        continous_counter();

    return EXIT_SUCCESS;
}
