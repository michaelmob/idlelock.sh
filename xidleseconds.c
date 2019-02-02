/*
 * xidleseconds 0.2
 */
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <X11/extensions/scrnsaver.h>


char *version = "0.2";
Display *display = NULL;
XScreenSaverInfo *info = NULL;
unsigned long window;



void usage() {
	/*
	 * Display help and usage instructions.
	 */
	printf("\e[1mxidleseconds %s\e[0m\n", version);
	printf("usage: xidleseconds [-s {seconds}] ... [-r {seconds}] ...\n\n");
	printf("-h           : display help\n");
	printf("-s {seconds} : output every separate user activity\n");
	printf("-r {seconds} : output when idle seconds are divisible by value\n");
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


void selective_counter(int selective_len, unsigned long *selective_values,
		int repeating_len, unsigned long *repeating_values) {
	/*
	 * Only show idle time that belongs to the array.
	 * Show zero when idle time is reset.
	 */
	unsigned long seconds;
	int i;
	int flag = 0;
	while (1) {
		XScreenSaverQueryInfo(display, window, info);
		seconds = info->idle / 1000;

		// Show zero for reset and set flag to false.
		if (flag && (seconds == 0)) {
			printf("0\n");
			flag = 0;
			continue;
		}

		// Selective Values
		for (i = selective_len - 1; i > -1; --i) {
			if (seconds != selective_values[i])
				continue;

			printf("%lu\n", seconds);
			flag = 1;
		}

		// Repeating Values
		for (i = repeating_len - 1; i > -1; --i) {
			if (seconds < repeating_values[i])
				continue;

			if (seconds % repeating_values[i] != 0)
				continue;

			printf("%lu\n", repeating_values[i]);
			flag = 1;
		}
		
		sleep(1);
	}
}


void append_long(int *len, unsigned long *values, unsigned long value) {
	/*
	 * Dynamically append unsigned long value to array.
	 */
	if (value == 0)
		return;
	int *temp = realloc(values, ++*len * sizeof(unsigned long));
	if (!temp) {
		fprintf(stderr, "Could not allocate memory.\n");
		exit(EXIT_FAILURE);
	}
	values[*len - 1] = value;
}


int main(int argc, char *argv[]) {
	/*
	 * Manipulate arguments and run counter.
	 */
	// Set buffer to stdout.
	setbuf(stdout, NULL);

	int selective_len = 0;
	int repeating_len = 0;

	unsigned long *selective_values = malloc(sizeof(unsigned long));
	if (!selective_values) {
		fprintf(stderr, "Could not allocate memory.\n");
		return EXIT_FAILURE;
	}

	unsigned long *repeating_values = malloc(sizeof(unsigned long));
	if (!repeating_values) {
		fprintf(stderr, "Could not allocate memory.\n");
		return EXIT_FAILURE;
	}

	int opt;
	while((opt = getopt(argc, argv, "vhs:r:")) != -1) {
		switch(opt) {
			case 'v':
				printf("%s", version);
				return EXIT_SUCCESS;

			case 'h':
				usage();
				return EXIT_SUCCESS;

			case 's':
				append_long(&selective_len, selective_values, atol(optarg));
				break;

			case 'r':
				append_long(&repeating_len, repeating_values, atol(optarg));
				break;

			case '?':
				break;
		}
	}

	// Get X Display.
	display = XOpenDisplay(NULL);
	if (!display) {
		fprintf(stderr, "Unable to open X display.\n");
		return EXIT_FAILURE;
	}

	window = DefaultRootWindow(display);
	info = XScreenSaverAllocInfo();
	if (!info) {
		fprintf(stderr, "Unable to allocate info from XScreenSaver.\n");
		return EXIT_FAILURE;
	}

	// Only show idle seconds specified in arguments.
	if (argc > 1)
		selective_counter(selective_len, selective_values,
				repeating_len, repeating_values);

	// Show idle seconds every second.
	else
		continous_counter();

	free(selective_values);
	free(repeating_values);
	free(display);
	free(info);
	return EXIT_SUCCESS;
}
