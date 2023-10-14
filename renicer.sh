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

SCRIPT_ALIAS="renicer"

# usage
if [ -z "$1" ] || [ "$1" = "-help" ]; then
	echo "> Usage: $SCRIPT_ALIAS [process] [persistent]"
	echo ""
	echo "> Optional:"
	echo "${MAYBE_SUDO}crontab -e"
	if is_which "tmux"; then
		echo "@reboot tmux new -d -s $SCRIPT_ALIAS '$DIR_SCRIPTS/$SCRIPT_ALIAS [process] [persistent]' > /dev/null 2>&1"
	else
		echo "@reboot $DIR_SCRIPTS/$SCRIPT_ALIAS [process] [persistent] > /dev/null 2>&1"
	fi
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

echo "> Listening for '$1'..."
PID_OLD=0
PID_NEW=""
while true; do
	PID_NEW="$(get_pidof "$1")"
	if ! is_int "$PID_NEW"; then
		PID_OLD=0
		echo "> Listening for '$1'..."
	elif (($PID_NEW != $PID_OLD)); then
		${MAYBE_SUDO}renice -n -20 -p $PID_NEW > /dev/null 2>&1
		PID_OLD="$PID_NEW"
		echo "> Process '$1' is now top priority."
		# not persistent
		if [ -z $2 ]; then
			break
		fi
	fi
	sleep 60
done;

exit 0
