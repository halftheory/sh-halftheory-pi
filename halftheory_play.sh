#!/bin/bash

# import vars
DIRNAME=`dirname "$0"`
CMD_TEST=`readlink "$0"`
if [ ! "$CMD_TEST" = "" ]; then
    DIRNAME=`dirname "$CMD_TEST"`
fi
if [ -f "$DIRNAME/halftheory_vars.sh" ]; then
    . $DIRNAME/halftheory_vars.sh
else
	echo "Error in $0 on line $LINENO. Exiting..."
    exit 1
fi

SCRIPT_ALIAS="play"

# usage
if [ -z $1 ]; then
    echo "> Usage: $SCRIPT_ALIAS [file]"
    exit 1
# install
elif [ "$1" = "-install" ]; then
	FILE_SCRIPT=$0
	CMD_TEST=`readlink "$0"`
	if [ ! "$CMD_TEST" = "" ]; then
	    FILE_SCRIPT=$CMD_TEST
	fi
	chmod $CHMOD_FILES $FILE_SCRIPT
	chmod +x $FILE_SCRIPT
	${MAYBE_SUDO}rm $DIR_SCRIPTS/$SCRIPT_ALIAS > /dev/null 2>&1
	${MAYBE_SUDO}ln -s $FILE_SCRIPT $DIR_SCRIPTS/$SCRIPT_ALIAS
	echo "> Installed."
	exit 0
# uninstall
elif [ "$1" = "-uninstall" ]; then
	${MAYBE_SUDO}rm $DIR_SCRIPTS/$SCRIPT_ALIAS > /dev/null 2>&1
	echo "> Uninstalled."
	exit 0
fi

if [ ! -e "$1" ]; then
	echo "Error in $0 on line $LINENO. Exiting..."
    exit 1
fi

BOOL_FALLBACK=true

if is_which "cvlc" && is_opengl_legacy; then
	VLC_VERBOSE=0 cvlc $1 vlc://quit --no-osd --fullscreen --align 0 --video-on-top --preferred-resolution -1 --play-and-exit
	sleep 1
	CMD_TEST=`pidof vlc`
	if [ ! "$CMD_TEST" = "" ]; then
		BOOL_FALLBACK=false
	fi
elif is_which "omxplayer"; then
	CMD_TEST=`omxplayer -b -o local --no-osd --timeout 5 $1 | grep -oP "unknown|unable|ERROR|unrecognized|omx_err"`
	if [ "$CMD_TEST" = "" ]; then
		BOOL_FALLBACK=false
	fi
fi

if [ $BOOL_FALLBACK = true ] && is_which "ffplay"; then
	ffplay -hide_banner -v quiet -fs -fast -framedrop -infbuf -autoexit -exitonkeydown -fflags discardcorrupt $1
fi

exit 0
