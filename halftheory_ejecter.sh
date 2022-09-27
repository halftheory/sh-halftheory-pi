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

SCRIPT_ALIAS="ejecter"

# usage
if [ "$1" = "-help" ]; then
    echo "> Usage: $SCRIPT_ALIAS"
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

ARR_MEDIA=()
if dir_not_empty "/media"; then
	ARR_MEDIA=( $(find /media -maxdepth 1 -name 'usb*') )
fi
ARR_VOLUMES=( $(fdisk -l | awk '{print $1}' | grep /dev/s) )

if is_which "eject"; then
	if [ ! "$ARR_MEDIA" = "" ]; then
		for STR in "${ARR_MEDIA[@]}"; do
			${MAYBE_SUDO}eject $STR > /dev/null 2>&1
		done
	fi
	if [ ! "$ARR_VOLUMES" = "" ]; then
		for STR in "${ARR_VOLUMES[@]}"; do
			${MAYBE_SUDO}eject $STR > /dev/null 2>&1
		done
	fi
elif is_which "umount"; then
	if [ ! "$ARR_MEDIA" = "" ]; then
		for STR in "${ARR_MEDIA[@]}"; do
			${MAYBE_SUDO}umount -a -q $STR > /dev/null 2>&1
		done
	fi
	if [ ! "$ARR_VOLUMES" = "" ]; then
		for STR in "${ARR_VOLUMES[@]}"; do
			${MAYBE_SUDO}umount -a -q $STR > /dev/null 2>&1
		done
	fi
fi

if is_which "udisksctl"; then
	ARR_TEST=( $(fdisk -l | awk '{print $2}' | grep /dev/s | sed 's/:$//') )
	if [ ! "$ARR_TEST" = "" ]; then
		for STR in "${ARR_TEST[@]}"; do
			${MAYBE_SUDO}udisksctl power-off -b $STR > /dev/null 2>&1
		done
	fi
fi

echo "> Done."
exit 0
