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

SCRIPT_ALIAS="wpa_supplicant"

# usage
if [ "$1" = "-help" ]; then
	echo "> Usage: $SCRIPT_ALIAS [directory]"
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

STR_SSID=""
read -p "> SSID: " STR_SSID
if [ "$STR_SSID" = "" ]; then
	exit 1
fi
STR_PASS=""
read -p "> Pass: " STR_PASS

DIR_TEST="."
if [ "$1" ] && [ -d "$1" ]; then
	DIR_TEST="$1"
fi
DIR_TEST="$(get_realpath "$DIR_TEST")"
if [ "$DIR_TEST" = "" ]; then
	echo "Error in $0 on line $LINENO. Exiting..."
	exit 1
fi

FILE_TEST="$DIR_TEST/wpa_supplicant.conf"
if [ -f "$FILE_TEST" ]; then
	${MAYBE_SUDO}rm -f "$FILE_TEST" > /dev/null 2>&1
fi
${MAYBE_SUDO}touch "$FILE_TEST"
if [ -e "$FILE_TEST" ]; then
	${MAYBE_SUDO}chmod $CHMOD_FILES "$FILE_TEST"
	file_add_line "$FILE_TEST" "ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev" "sudo"
	file_add_line "$FILE_TEST" "update_config=1" "sudo"
	file_add_line "$FILE_TEST" "country=US" "sudo"
	file_add_line "$FILE_TEST" "network={" "sudo"
	file_add_line "$FILE_TEST" "scan_ssid=1" "sudo"
	file_add_line "$FILE_TEST" "ssid=\"$STR_SSID\"" "sudo"
	if [ "$STR_PASS" = "" ]; then
		file_add_line "$FILE_TEST" "key_mgmt=NONE" "sudo"
	else
		file_add_line "$FILE_TEST" "psk=\"$STR_PASS\"" "sudo"
	fi
	file_add_line "$FILE_TEST" "}" "sudo"
else
	echo "Error in $0 on line $LINENO. Exiting..."
	exit 1
fi

echo "> Done."
exit 0
