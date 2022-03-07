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
DIR_WORKING="$DIRNAME/$SCRIPT_ALIAS"

# usage
if [ -z "$1" ] || [ "$1" = "-help" ]; then
    echo "> Usage: $SCRIPT_ALIAS [files]"
    echo ""
	echo "> Optional:"
	echo "crontab -e"
	if is_which "tmux"; then
		echo "* * * * * $(cmd_tmux "$DIR_SCRIPTS/$SCRIPT_ALIAS [files]" "$SCRIPT_ALIAS")"
	else
		echo "* * * * * $DIR_SCRIPTS/$SCRIPT_ALIAS [files] > /dev/null 2>&1"
	fi
    exit 1
# install
elif [ "$1" = "-install" ]; then
	if script_install "$0" "$DIR_SCRIPTS/$SCRIPT_ALIAS" "sudo"; then
		# depends
		if has_arg "$*" "-depends" && [ ! "$(get_system)" = "Darwin" ]; then
			BOOL_FALLBACK=false
			if is_opengl_legacy; then
				if ! maybe_apt_install "cvlc" "vlc"; then
					BOOL_FALLBACK=true
				fi
			else
				if ! maybe_apt_install "omxplayer"; then
					BOOL_FALLBACK=true
				fi
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
		if has_arg "$*" "-depends"; then
			rm -Rf "$DIR_WORKING" > /dev/null 2>&1
		fi
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
	echo "> Process '$STR_PROCESS' is already running. Exiting..."
	exit 0
fi

case "$STR_PROCESS" in
	"vlc")
		CMD_TEST="VLC_VERBOSE=0 cvlc $(get_file_list_video_quotes "$*") --no-osd --fullscreen --align 0 --video-on-top --preferred-resolution -1 --no-interact --loop --no-play-and-exit"
		eval "$CMD_TEST"
		;;

	"omxplayer.bin")
		LIST="$(get_file_list_video_csv "$*")"
		ARR_TEST=()
		IFS_OLD="$IFS"
		IFS="," read -r -a ARR_TEST <<< "$LIST"
		IFS="$IFS_OLD"
		while true; do
			for STR in "${ARR_TEST[@]}"; do
				clear
				CMD_TEST="omxplayer -b -o local --no-osd --timeout 5 $(quote_string_with_spaces "$STR") > /dev/null"
				eval "$CMD_TEST"
			done
		done
		;;

	"ffplay")
		# make a playlist file
		FILE_TEST="$DIR_WORKING/$STR_PROCESS.txt"
		if [ ! -f "$FILE_TEST" ]; then
			if [ ! -d "$DIR_WORKING" ]; then
				mkdir -p "$DIR_WORKING"
				chmod $CHMOD_DIRS "$DIR_WORKING"
			fi
			touch "$FILE_TEST"
			chmod $CHMOD_FILES "$FILE_TEST"
		fi
		echo "ffconcat version 1.0" > "$FILE_TEST"
		# add the list
		LIST="$(get_file_list_video_csv "$*")"
		ARR_TEST=()
		IFS_OLD="$IFS"
		IFS="," read -r -a ARR_TEST <<< "$LIST"
		IFS="$IFS_OLD"
		for STR in "${ARR_TEST[@]}"; do
			file_add_line "$FILE_TEST" "file $(quote_string_with_spaces "$STR")"
		done
		CMD_TEST="ffplay -hide_banner -v quiet -fs -noborder -fast -framedrop -infbuf -fflags discardcorrupt -safe 0 -loop 0 -f concat -i $(quote_string_with_spaces "$FILE_TEST")"
		eval "$CMD_TEST"
		sleep 1
		rm -f "$FILE_TEST" > /dev/null 2>&1
		;;
esac

exit 0
