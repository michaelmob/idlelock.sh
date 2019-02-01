ifndef PREFIX
	PREFIX=$(HOME)/.local/bin
	ifeq ($(USER),root)
		PREFIX=/usr/local/bin
	endif
endif

.PHONY: all build install clean

all: build

build:
	gcc ./xidleseconds.c -o xidleseconds -lX11 -lXss

install: all
	mkdir -p $(PREFIX)
	cp idlelock.sh $(PREFIX)/idlelock.sh
	mv xidleseconds $(PREFIX)/xidleseconds

uninstall:
	rm $(PREFIX)/idlelock.sh
	rm $(PREFIX)/xidleseconds

clean:
	rm xidleseconds
