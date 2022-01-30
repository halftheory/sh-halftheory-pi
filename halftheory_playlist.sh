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

SCRIPT_ALIAS="playlist"

# usage
if [ -z "$1" ]; then
    echo "> Usage: $SCRIPT_ALIAS [files]"
    exit 1
# install
elif [ "$1" = "-install" ]; then
	if script_install "$0" "$DIR_SCRIPTS/$SCRIPT_ALIAS" "sudo"; then
		if [ ! "$(get_system)" = "Darwin" ]; then
			BOOL_FALLBACK=false
			if is_opengl_legacy; then
				if ! maybe_install "cvlc" "vlc"; then
					BOOL_FALLBACK=true
				fi
			else
				if ! maybe_install "omxplayer"; then
					BOOL_FALLBACK=true
				fi
			fi
			if [ $BOOL_FALLBACK = true ]; then
				maybe_install "ffplay" "ffmpeg"
			fi
		fi
		echo "> Installed."
		echo "> Optional:"
		echo "crontab -e"
		if is_which "tmux"; then
			echo "* * * * * tmux new -d -s $SCRIPT_ALIAS '$SCRIPT_ALIAS [files]' > /dev/null 2>&1"
		else
			echo "* * * * * $SCRIPT_ALIAS [files] > /dev/null 2>&1"
		fi
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

# check if able to run
if is_which "cvlc" && is_opengl_legacy; then
	STR_PROCESS="vlc"
elif is_which "omxplayer"; then
	STR_PROCESS="omxplayer.bin"
elif is_which "ffplay"; then
	STR_PROCESS="ffplay"
else
	echo "Error in $0 on line $LINENO. Exiting..."
    exit 1
fi
# check if already running
if is_process_running "$STR_PROCESS"; then
	exit 0
fi

case "$STR_PROCESS" in
	"vlc")
		CMD_TEST="VLC_VERBOSE=0 cvlc $(get_file_list_quotes "$*") --no-osd --fullscreen --align 0 --video-on-top --preferred-resolution -1 --no-interact --loop --no-play-and-exit"
		eval "$CMD_TEST"
		;;

	"omxplayer.bin")
		LIST="$(get_file_list_csv "$*")"
		ARR_TEST=()
		IFS_OLD="$IFS"
		IFS="," read -r -a ARR_TEST <<< "$LIST"
		IFS="$IFS_OLD"
		for STR in "${ARR_TEST[@]}"; do
			clear
			CMD_TEST="omxplayer -b -o local --no-osd --timeout 5 $(quote_string_with_spaces "$STR") > /dev/null"
			eval "$CMD_TEST"
		done
		;;

	"ffplay")
		# make a playlist file
		FILE_TEST="$(get_realpath "$DIRNAME")/$SCRIPT_ALIAS/$STR_PROCESS.txt"
		if [ ! -d "$(dirname "$FILE_TEST")" ]; then
			mkdir -p $(dirname "$FILE_TEST")
		else
			rm $FILE_TEST > /dev/null 2>&1
		fi
		touch $FILE_TEST
		chmod $CHMOD_FILES $FILE_TEST
		file_add_line $FILE_TEST "ffconcat version 1.0"
		# add the list
		LIST="$(get_file_list_csv "$*")"
		ARR_TEST=()
		IFS_OLD="$IFS"
		IFS="," read -r -a ARR_TEST <<< "$LIST"
		IFS="$IFS_OLD"
		for STR in "${ARR_TEST[@]}"; do
			file_add_line $FILE_TEST "file $(quote_string_with_spaces "$STR")"
		done
		CMD_TEST="ffplay -hide_banner -v quiet -fs -fast -framedrop -infbuf -fflags discardcorrupt -safe 0 -loop 0 -f concat -i $(quote_string_with_spaces "$FILE_TEST")"
		eval "$CMD_TEST"
		sleep 1
		rm $FILE_TEST > /dev/null 2>&1
		;;
esac

exit 0
