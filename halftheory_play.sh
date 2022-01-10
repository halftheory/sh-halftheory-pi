#!/bin/bash

# install:
# touch /home/pi/halftheory_play.sh
# pico /home/pi/halftheory_play.sh
# chmod +x /home/pi/halftheory_play.sh
# sudo ln -s /home/pi/halftheory_play.sh /bin/play

# usage
if [ -z $1 ]; then
    BASENAME=`basename $0`
    echo "> Usage: $BASENAME [file]"
    exit 1
fi

if [ $1 ]; then
	CMD_OMXPLAYER=`omxplayer -b -o local --no-osd --timeout 5 $1 | grep -oP "unknown|unable|omx_err|ERROR|unrecognized"`
	if [ ! "$CMD_OMXPLAYER" = "" ]; then
		ffplay -hide_banner -v quiet -fs -fast -framedrop -infbuf -autoexit -exitonkeydown -fflags discardcorrupt $1
	fi
fi

exit 0
