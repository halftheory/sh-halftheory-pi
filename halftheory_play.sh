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
if [ -z "$1" ] || [ "$1" = "-help" ]; then
	echo "> Usage: $SCRIPT_ALIAS [file]"
	exit 1
# install
elif [ "$1" = "-install" ]; then
	if script_install "$0" "$DIR_SCRIPTS/$SCRIPT_ALIAS" "sudo"; then
		# depends
		if has_arg "$*" "-depends" && [ ! "$(get_system)" = "Darwin" ]; then
			BOOL_FALLBACK=false
			if ! maybe_apt_install "cvlc" "vlc"; then
				BOOL_FALLBACK=true
			elif ! maybe_apt_install "omxplayer"; then
				BOOL_FALLBACK=true
			fi
			if [ $BOOL_FALLBACK = true ]; then
				maybe_apt_install "ffplay" "ffmpeg"
			fi
		fi
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

# check if able to run
if is_which "cvlc"; then
	STR_PROCESS="vlc"
elif is_which "omxplayer"; then
	STR_PROCESS="omxplayer.bin"
elif is_which "ffplay"; then
	STR_PROCESS="ffplay"
else
	echo "Error in $0 on line $LINENO. Exiting..."
	exit 1
fi

CMD_TEST=""
if [ "$STR_PROCESS" = "vlc" ]; then
	CMD_TEST="VLC_VERBOSE=0 cvlc $(quote_string_with_spaces "$*") vlc://quit --no-osd --fullscreen --align 0 --video-on-top --preferred-resolution -1 --play-and-exit"
elif [ "$STR_PROCESS" = "omxplayer.bin" ]; then
	CMD_TEST="omxplayer -b -o local --no-osd --timeout 5 $(quote_string_with_spaces "$*")"
fi
BOOL_FALLBACK=false
if [ ! "$CMD_TEST" = "" ]; then
	eval "$CMD_TEST &"
	sleep 1
	if ! is_process_running "$STR_PROCESS"; then
		BOOL_FALLBACK=true
	fi
fi

if [ $BOOL_FALLBACK = true ] || [ "$STR_PROCESS" = "ffplay" ]; then
	CMD_TEST="ffplay -hide_banner -v quiet -fs -noborder -fast -framedrop -infbuf -fflags discardcorrupt -autoexit $(quote_string_with_spaces "$*")"
	eval "$CMD_TEST"
fi

exit 0
