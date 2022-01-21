#!/bin/bash

# import vars
CMD_TEST="$(readlink "$0")"
if [ ! "$CMD_TEST" = "" ]; then
	DIRNAME="$(dirname "$CMD_TEST")"
else
	DIRNAME="$(dirname "$0")"
fi
if [ -f "$DIRNAME/halftheory_vars.sh" ]; then
	. $DIRNAME/halftheory_vars.sh
else
	echo "Error in $0 on line $LINENO. Exiting..."
	exit 1
fi

SCRIPT_ALIAS="play"

# usage
if [ -z "$1" ]; then
    echo "> Usage: $SCRIPT_ALIAS [file]"
    exit 1
# install
elif [ "$1" = "-install" ]; then
	if script_install "$0" "$DIR_SCRIPTS/$SCRIPT_ALIAS" "sudo"; then
		echo "> Installed."
		exit 0
	else
		echo "Error in $0 on line $LINENO. Exiting..."
		exit 1
	fi
# uninstall
elif [ "$1" = "-uninstall" ]; then
	if script_uninstall "$0" "$DIR_SCRIPTS/$SCRIPT_ALIAS" "sudo"; then
		echo "> Uninstalled."
		exit 0
	else
		echo "Error in $0 on line $LINENO. Exiting..."
		exit 1
	fi
fi

if [ ! -e "$*" ]; then
	echo "Error in $0 on line $LINENO. Exiting..."
    exit 1
fi

BOOL_FALLBACK=true

if is_which "cvlc" && is_opengl_legacy; then
	CMD_TEST="VLC_VERBOSE=0 cvlc $(quote_string_with_spaces "$*") vlc://quit --no-osd --fullscreen --align 0 --video-on-top --preferred-resolution -1 --play-and-exit"
	eval "$CMD_TEST"
	sleep 1
	if is_process_running "vlc"; then
		BOOL_FALLBACK=false
	fi
elif is_which "omxplayer"; then
	CMD_TEST="omxplayer -b -o local --no-osd --timeout 5 $(quote_string_with_spaces "$*")"
	eval "$CMD_TEST"
	sleep 1
	if is_process_running "omxplayer.bin"; then
		BOOL_FALLBACK=false
	fi
fi

if [ $BOOL_FALLBACK = true ] && is_which "ffplay"; then
	CMD_TEST="ffplay -hide_banner -v quiet -fs -fast -framedrop -infbuf -autoexit -exitonkeydown -fflags discardcorrupt $(quote_string_with_spaces "$*")"
	eval "$CMD_TEST"
fi

exit 0
