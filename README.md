# idlelock.sh 0.2.2


## Installation

### Install
```sh
# For Debian-based systems
sudo apt install libx11 libxss

# For Arch-based systems
sudo pacman -S libx11 libxss

# Clone and install
git clone https://github.com/thetarkus/idlelock.sh && cd idlelock.sh
make && sudo make install
```
After installation, minimal configuration is required.

### Dependencies
To compile `xidleseconds`, there are a couple of build dependencies:
* libX11
* libXss

## Configuration
**idlelock.sh** requires a slight amount of configuration through the use of arguments.

Run `idlelock.sh -h` for more information

### Example
```sh
#!/usr/bin/env bash
idlelock.sh \
	--lock-on-sleep \
	--inhibit 'fullscreen' `# Never activate any timer when fullscreen.` \
	--unlock-cmd 'pkill i3lock' \
	\
	`# Restore screen to full brightness on user activity.` \
	--restore-cmd 'xrandr --output $OUTPUT --brightness 1' \
	\
	`# Notify user of inactivity by dimming the screen.` \
	--timer 120 \
		+command 'xrandr --output $OUTPUT --brightness .5' \
	\
	`# Turn the screen off 20 seconds later.` \
	--timer 140 \
		+command 'xset dpms force off' \
	\
	`# Run the screen locker 40 seconds after turning the screen off.` \
	--timer 180 \
		+command 'pgrep -x i3lock || i3lock -n' \
		+inhibit 'audio' `# Do not lock when audio is playing.` \
		+primary `# Primary timer that can be ran with 'loginctl lock-session'` \
	\
	`# Suspend the system after 5 total minutes of inactivity.` \
	--timer 300 \
		+command 'systemctl suspend' \
		+restore 'xset dpms force on' `# Turn screen on after system resume.` \
		+inhibit 'network $DEVICE 2000' `# Inhibit when downloading at 2Mbps.` \
		+repeat `# Retry command every 300 seconds of inactivity.`
```
