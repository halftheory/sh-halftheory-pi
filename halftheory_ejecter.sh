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
ARR_VOLUMES=()
ARR_DISKS=()
IFS_OLD="$IFS"
IFS=$'\n'
if dir_not_empty "/media"; then
	ARR_MEDIA=( $(find /media -maxdepth 1 -name 'usb*') )
fi
ARR_VOLUMES=( $(${MAYBE_SUDO}fdisk -l | awk '{print $1}' | grep /dev/s) )
ARR_DISKS=( $(${MAYBE_SUDO}fdisk -l | awk '{print $2}' | grep /dev/s | sed 's/:$//') )
IFS="$IFS_OLD"

if is_which "eject"; then
	for STR in "${ARR_MEDIA[@]}"; do
		${MAYBE_SUDO}eject $STR > /dev/null 2>&1
	done
	for STR in "${ARR_VOLUMES[@]}"; do
		${MAYBE_SUDO}eject $STR > /dev/null 2>&1
	done
elif is_which "umount"; then
	for STR in "${ARR_MEDIA[@]}"; do
		${MAYBE_SUDO}umount -a -q $STR > /dev/null 2>&1
	done
	for STR in "${ARR_VOLUMES[@]}"; do
		${MAYBE_SUDO}umount -a -q $STR > /dev/null 2>&1
	done
fi

if is_which "udisksctl"; then
	for STR in "${ARR_DISKS[@]}"; do
		${MAYBE_SUDO}udisksctl power-off -b $STR > /dev/null 2>&1
	done
fi

echo "> Done."
exit 0
