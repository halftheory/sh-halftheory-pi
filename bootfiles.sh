#!/bin/bash

# import environment
CMD_TEST="$(readlink "$0")"
if [ ! "$CMD_TEST" = "" ]; then
	DIRNAME="$(dirname "$CMD_TEST")"
else
	DIRNAME="$(dirname "$0")"
fi
if [ -f "$DIRNAME/halftheory_env_pi.sh" ]; then
	. $DIRNAME/halftheory_env_pi.sh
else
	echo "Error in $0 on line $LINENO. Exiting..."
	exit 1
fi

SCRIPT_ALIAS="bootfiles"

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

# get directory
DIR_TEST="."
if [ "$1" ] && [ -d "$1" ]; then
	DIR_TEST="$1"
fi
DIR_TEST="$(get_realpath "$DIR_TEST")"
if [ "$DIR_TEST" = "" ]; then
	echo "Error in $0 on line $LINENO. Exiting..."
	exit 1
fi

# ssh
FILE_TEST="$DIR_TEST/ssh"
if prompt "Create file '$FILE_TEST'"; then
	${MAYBE_SUDO}rm -f "$FILE_TEST" > /dev/null 2>&1
	${MAYBE_SUDO}touch "$FILE_TEST"
	${MAYBE_SUDO}chmod $CHMOD_FILE "$FILE_TEST"
fi

# userconf
FILE_TEST="$DIR_TEST/userconf"
if prompt "Create file '$FILE_TEST'"; then
	read -p "> User: " STR_USERCONF_USER
	read -p "> Pass: " STR_USERCONF_PASS
	if [ ! "$STR_USERCONF_USER" = "" ] && [ ! "$STR_USERCONF_PASS" = "" ]; then
		${MAYBE_SUDO}rm -f "$FILE_TEST" > /dev/null 2>&1
		${MAYBE_SUDO}touch "$FILE_TEST"
		${MAYBE_SUDO}chmod $CHMOD_FILE "$FILE_TEST"
		if is_which "openssl"; then
			STR_USERCONF_PASS="$(echo $STR_USERCONF_PASS | openssl passwd -stdin)"
		fi
		file_add_line "$FILE_TEST" "$STR_USERCONF_USER:$STR_USERCONF_PASS" "sudo"
	fi
fi

# wpa_supplicant.conf
FILE_TEST="$DIR_TEST/wpa_supplicant.conf"
if [ -f "/etc/wpa_supplicant/wpa_supplicant.conf" ]; then
	if prompt "Update existing file '/etc/wpa_supplicant/wpa_supplicant.conf'"; then
		FILE_TEST="/etc/wpa_supplicant/wpa_supplicant.conf"
	fi
fi
if prompt "Create file '$FILE_TEST'"; then
	read -p "> SSID: " STR_WPA_SSID
	read -p "> Pass: " STR_WPA_PASS
	if [ ! "$STR_WPA_SSID" = "" ]; then
		${MAYBE_SUDO}rm -f "$FILE_TEST" > /dev/null 2>&1
		${MAYBE_SUDO}touch "$FILE_TEST"
		${MAYBE_SUDO}chmod $CHMOD_FILE "$FILE_TEST"
		file_add_line "$FILE_TEST" "ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev" "sudo"
		file_add_line "$FILE_TEST" "update_config=1" "sudo"
		file_add_line "$FILE_TEST" "country=US" "sudo"
		file_add_line "$FILE_TEST" "network={" "sudo"
		file_add_line "$FILE_TEST" "scan_ssid=1" "sudo"
		file_add_line "$FILE_TEST" "ssid=\"$STR_WPA_SSID\"" "sudo"
		if [ "$STR_WPA_PASS" = "" ]; then
			file_add_line "$FILE_TEST" "key_mgmt=NONE" "sudo"
		else
			# TODO: use wpa_passphrase.
			file_add_line "$FILE_TEST" "psk=\"$STR_WPA_PASS\"" "sudo"
		fi
		file_add_line "$FILE_TEST" "}" "sudo"
	fi
fi

# config.txt, cmdline.txt
if prompt "Enable SSH login over USB"; then
	FILE_TEST="$DIR_TEST/config.txt"
	if [ -f "/boot/firmware/config.txt" ]; then
		if prompt "Update existing file '/boot/firmware/config.txt'"; then
			FILE_TEST="/boot/firmware/config.txt"
		fi
	fi
	if file_add_line_config_after_all "dtoverlay=dwc2" "$FILE_TEST"; then
		echo "> Updated '$(basename "$FILE_TEST")'."
	fi
	FILE_TEST="$DIR_TEST/cmdline.txt"
	if [ -f "/boot/firmware/cmdline.txt" ]; then
		if prompt "Update existing file '/boot/firmware/cmdline.txt'"; then
			FILE_TEST="/boot/firmware/cmdline.txt"
		fi
	fi
	if file_add_string_cmdline "modules-load=dwc2,g_ether" "$FILE_TEST"; then
		echo "> Updated '$(basename "$FILE_TEST")'."
	fi
fi

echo "> Done."
exit 0
