# idlelock.sh 0.2


## Installation

### Install
```sh
# For Debian-based systems
sudo apt install libx11 libxss

# For Arch-based systems
sudo pacman -S libx11 libxss

# Clone and install
git clone https://github.com/thetarkus/idlelock.sh && cd idlelock.sh && make && sudo make install
```
After installation, minimal configuration is required.

### Dependencies
To compile `xidleseconds`, there are a couple of build dependencies:
* libX11
* libXss

## Configuration
**idlelock.sh** requires a slight amount of configuration through the use of arguments.

Run `idlelock.sh -h` for more information about configuring **idlelock.sh**.

### Example
```sh
#!/usr/bin/env bash
idlelock.sh \
	--lock-on-sleep \
	--inhibit 'fullscreen' \
	--unlock 'pkill i3lock' \
	\
	`# Restore screen to full brightness on user activity.` \
	--restore 'xrandr --output $OUTPUT --brightness 1' \
	\
	`# Notify user of inactivity by dimming the screen.` \
	-120 'notify' \
		+command 'xrandr --output $OUTPUT --brightness .5' \
	\
	`# Turn the screen off 20 seconds later.` \
	-140 'screen off' \
		+command 'xset dpms force off' \
	\
	`# Run the screen locker 40 seconds after turning the screen off.` \
	-180 'lock' \
		+command 'pgrep -x i3lock || i3lock -n' \
		+inhibit 'audio' `# Do not lock when audio is playing.` \
	\
	`# Suspend the system after 5 total minutes of inactivity.` \
	-300 'sleep' \
		+command 'systemctl suspend' \
		+restore 'xset dpms force on' `# Turn screen on after resuming from sleep.`
```
