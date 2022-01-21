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
		echo "> Installed."
		echo "> Optional:"
		echo "crontab -e"
		echo "* * * * * $SCRIPT_ALIAS [files]"
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

# check if able to run or already running
if is_which "cvlc" && is_opengl_legacy; then
	STR_TEST="vlc"
elif is_which "omxplayer"; then
	STR_TEST="omxplayer.bin"
else
	echo "Error in $0 on line $LINENO. Exiting..."
    exit 1
fi
if is_process_running "$STR_TEST"; then
	exit 0
fi

# get file list
LIST=""
LIST_DIRS=()
STR_ARGS="$(get_file_list_csv "$*")"
IFS_OLD="$IFS"
IFS=","
for STR in "$STR_ARGS"; do
	STR_TEST=""
	if [ -d "$STR" ] && dir_has_files "$STR"; then
		STR_TEST="###$STR###"
		LIST_DIRS+=("$STR")
	elif [ -e "$STR" ] && [[ "$(basename "$STR")" = *.* ]]; then
		STR_TEST="$STR"
	fi
	if [ ! "$STR_TEST" = "" ]; then
		if [ "$LIST" = "" ]; then
			LIST="$STR_TEST"
		else
			LIST="$LIST,$STR_TEST"
		fi
	fi
done
IFS="$IFS_OLD"

# replace dirs
for STR in "${LIST_DIRS[@]}"; do
	STR_TEST="$(get_file_list_csv $STR/*.*)"
	if [ ! "$STR_TEST" = "" ]; then
		LIST="${LIST//###$STR###/$STR_TEST}"
	elif [[ $LIST = *###$STR###,* ]]; then
		LIST="${LIST//###$STR###,/}"
	elif [[ $LIST = *,###$STR###* ]]; then
		LIST="${LIST//,###$STR###/}"
	else
		LIST="${LIST//###$STR###/}"
	fi
done

if [ "$LIST" = "" ]; then
	echo "Error in $0 on line $LINENO. Exiting..."
    exit 1
fi

if is_which "cvlc" && is_opengl_legacy; then
	LIST_VLC=""
	IFS_OLD="$IFS"
	IFS=","
	for STR in "$LIST"; do
		STR="$(quote_string_with_spaces "$STR")"
		if [ "$LIST_VLC" = "" ]; then
			LIST_VLC="$STR"
		else
			LIST_VLC="$LIST_VLC $STR"
		fi
	done
	IFS="$IFS_OLD"
	CMD_TEST="VLC_VERBOSE=0 cvlc $LIST_VLC --no-osd --fullscreen --align 0 --video-on-top --preferred-resolution -1 --no-interact --loop --no-play-and-exit"
	eval "$CMD_TEST"
elif is_which "omxplayer"; then
	IFS_OLD="$IFS"
	IFS=","
	for STR in "$LIST"; do
		clear
		CMD_TEST="omxplayer -b -o local --no-osd --timeout 5 $(quote_string_with_spaces "$STR") > /dev/null"
		eval "$CMD_TEST"
	done
	IFS="$IFS_OLD"
fi

exit 0
