# sh-halftheory-pi
Helper scripts to run on the raspberrypi.

Command | Function
:--- | :---
config | Turn off/on common features - audio, bluetooth, hdmi, etc.
optimize | Common optimizations - set easy passwords, apt updates, stop logging, etc.
play | Play a video.
playlist | Play a collection of videos in an endless loop.
renicer | Give top priority to a process.

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
