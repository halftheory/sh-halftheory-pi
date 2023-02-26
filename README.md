# sh-halftheory-pi
Helper scripts to run on the raspberrypi.

Command | Function
:--- | :---
config | Turn off/on common features - audio, bluetooth, hdmi, etc.
ejecter | Safely unmount and power off all attached USB drives.
optimize | Common optimizations - set easy passwords, apt updates, stop logging, etc.
play | Play a video.
playlist | Play a collection of videos in an endless loop.
renicer | Wrapper for `renice`. Give top priority to a process.
wpa_supplicant | Generator for `wpa_supplicant.conf`.

## Install
```
cd ~
sudo apt-get -y install git tmux
git clone https://github.com/halftheory/sh-halftheory-pi
cd sh-halftheory-pi
chmod +x install.sh
./install.sh
```

## Operation
Type `[command]` without arguments or `[command] -help` to see usage options.

## Update
```
./update.sh
```

## Uninstall
```
./install.sh -uninstall
```
