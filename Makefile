ifndef PREFIX
	PREFIX=$(HOME)/.local/bin
	EXTRAS_PREFIX=$(HOME)/.local/share/idlelock.sh
	ifeq ($(USER),root)
		PREFIX=/usr/local/bin
		EXTRAS_PREFIX=/usr/share/idlelock.sh
	endif
endif

.PHONY: all build install clean

all: build

build:
	gcc ./xidleseconds.c -o xidleseconds -lX11 -lXss

install: all
	mkdir -p $(PREFIX) $(EXTRAS_PREFIX)
	cp idlelock.sh $(PREFIX)/idlelock.sh
	mv xidleseconds $(PREFIX)/xidleseconds
	cp extras/* $(EXTRAS_PREFIX)

uninstall:
	rm $(PREFIX)/idlelock.sh
	rm $(PREFIX)/xidleseconds
	rm -rf $(EXTRAS_PREFIX)

clean:
	rm xidleseconds
