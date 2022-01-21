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

SCRIPT_ALIAS="renicer"

# usage
if [ -z $1 ]; then
    echo "> Usage: $MAYBE_SUDO$SCRIPT_ALIAS [process] [persistent]"
    exit 1
# install
elif [ "$1" = "-install" ]; then
	if script_install "$0" "$DIR_SCRIPTS/$SCRIPT_ALIAS" "sudo"; then
		echo "> Installed."
		echo "> Optional:"
		echo "${MAYBE_SUDO}crontab -e"
		echo "@reboot $SCRIPT_ALIAS [process] [persistent] > /dev/null 2>&1"
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

LAST_PID=0
echo "> Listening for $1..."
while [ 1 ]; do
	PROCESS_PID="$(get_pidof "$1")"
	if [ "$PROCESS_PID" = "" ]; then
		LAST_PID=0
	elif [ ! "$PROCESS_PID" = "$LAST_PID" ]; then
		${MAYBE_SUDO}renice -n -20 -p $PROCESS_PID > /dev/null 2>&1
		LAST_PID="$PROCESS_PID"
		echo "> $1 is now top priority..."
		# not persistent
		if [ -z $2 ]; then
			exit 0
		fi
	fi
	sleep 60
done;

exit 0
