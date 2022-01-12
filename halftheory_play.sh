#!/bin/bash

# install:
# touch /home/pi/halftheory_play.sh
# pico /home/pi/halftheory_play.sh
# chmod +x /home/pi/halftheory_play.sh
# sudo ln -s /home/pi/halftheory_play.sh /bin/play

# import vars
DIRNAME=`dirname $0`
CMD_TEST=`readlink $0`
if [ ! "$CMD_TEST" = "" ]; then
    DIRNAME=`dirname $CMD_TEST`
fi
if [ -f "$DIRNAME/halftheory_functions.sh" ]; then
	. $DIRNAME/halftheory_functions.sh
else
    BASENAME=`basename $0`
	echo "Error in $BASENAME on line $LINENO. Exiting..."
	exit 1
fi

# usage
if [ -z $1 ]; then
    BASENAME=`basename $0`
    echo "> Usage: $BASENAME [file]"
    exit 1
fi

CMD_FFPLAY="ffplay -hide_banner -v quiet -fs -fast -framedrop -infbuf -autoexit -exitonkeydown -fflags discardcorrupt $1"

if which "cvlc"; then
	CMD_TEST=`cvlc -b -o local --no-osd --timeout 5 $1 | grep -oP "unknown|unable|omx_err|ERROR|unrecognized"`
	if [ ! "$CMD_TEST" = "" ] && which "ffplay"; then
		$CMD_FFPLAY
	fi
else if which "omxplayer"; then
	CMD_TEST=`omxplayer -b -o local --no-osd --timeout 5 $1 | grep -oP "unknown|unable|omx_err|ERROR|unrecognized"`
	if [ ! "$CMD_TEST" = "" ] && which "ffplay"; then
		$CMD_FFPLAY
	fi
else if which "ffplay"; then
	$CMD_FFPLAY
else
    BASENAME=`basename $0`
	echo "Error in $BASENAME on line $LINENO. Exiting..."
	exit 1
fi

exit 0
