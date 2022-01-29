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

SCRIPT_ALIAS="optimize"

# usage
if [ -z $1 ]; then
	echo "> Usage: $MAYBE_SUDO$SCRIPT_ALIAS [all|force]"
	echo "> Warning: This script is not designed to undo these changes."
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

# vars

VAR_FORCE=false
if [ $1 ] && [ "$1" = "force" ]; then
	VAR_FORCE=true
fi

# functions

function prompt()
{
	if [ -z "$1" ]; then
		return 0
	fi
	if [ $VAR_FORCE = true ]; then
		return 0
	fi
	read -p "> $1? [y]: " PROMPT_TEST
	PROMPT_TEST="${PROMPT_TEST:-y}"
	if [ ! "$PROMPT_TEST" = "y" ]; then
		return 1
	fi
	return 0
}

if prompt "Remove triggerhappy"; then
	if [ -e "/etc/init.d/triggerhappy" ]; then
		${MAYBE_SUDO}systemctl disable triggerhappy
		${MAYBE_SUDO}apt-get remove triggerhappy
		${MAYBE_SUDO}apt-get autoremove
		${MAYBE_SUDO}rm /etc/init.d/triggerhappy > /dev/null 2>&1
	fi
fi

if prompt "Reduce bash/tmux buffer"; then
	FILE_TEST="$DIR_LOCAL/.bashrc"
	if ! file_contains_line "$FILE_TEST" "HISTSIZE=500"; then
		if [ ! -f "$FILE_TEST" ]; then
			touch $FILE_TEST
			chmod $CHMOD_FILES $FILE_TEST
		fi
		if [ "$(get_system)" = "Darwin" ]; then
			sed -i '' -E 's/HISTSIZE=[0-9]*/HISTSIZE=500/g' $FILE_TEST
			sed -i '' -E 's/HISTFILESIZE=[0-9]*/HISTFILESIZE=1000/g' $FILE_TEST
		else
			sed -i -E 's/HISTSIZE=[0-9]*/HISTSIZE=500/g' $FILE_TEST
			sed -i -E 's/HISTFILESIZE=[0-9]*/HISTFILESIZE=1000/g' $FILE_TEST
		fi
		file_add_line "$FILE_TEST" "HISTSIZE=500"
		if file_add_line "$FILE_TEST" "HISTFILESIZE=1000"; then
			echo "> Updated $(basename "$FILE_TEST")..."
		fi
	fi
	if is_which "tmux"; then
		FILE_TEST="$DIR_LOCAL/.tmux.conf"
		if ! file_contains_line "$FILE_TEST" "set-option -g history-limit 1000"; then
			if [ ! -f "$FILE_TEST" ]; then
				touch $FILE_TEST
				chmod $CHMOD_FILES $FILE_TEST
			fi
			file_add_line "$FILE_TEST" "set-option -g history-limit 1000"
			if file_add_line "$FILE_TEST" "set -g mouse off"; then
				echo "> Updated $(basename "$FILE_TEST")..."
			fi
		fi
	fi
fi

if prompt "Disable logging"; then
	if ! file_contains_line "/etc/rsyslog.conf" "*.*\t\t~" && [ "$(grep -e "\*\.\*\t\t~" /etc/rsyslog.conf)" = "" ]; then
		${MAYBE_SUDO}systemctl disable rsyslog
		perl -0777 -pi -e "s/(#### RULES ####\n###############\n)/\1*.*\t\t~\n/sg" /etc/rsyslog.conf
		echo "> Updated /etc/rsyslog.conf..."
	fi
fi

if prompt "Disable man indexing"; then
	if [ "$(grep -Pzo "\#\!\/bin\/sh\nexit 0" /etc/cron.daily/man-db)" = "" ]; then
		if file_replace_line_first "/etc/cron.daily/man-db" "(#!/bin/sh)" "\1\nexit 0" "sudo"; then
			echo "> Updated /etc/cron.daily/man-db..."
		fi
		if file_replace_line_first "/etc/cron.weekly/man-db" "(#!/bin/sh)" "\1\nexit 0" "sudo"; then
			echo "> Updated /etc/cron.weekly/man-db..."
		fi
	fi
fi

if prompt "tmpfs - Write to RAM instead of the local disk"; then
	ARR_TEST=(
		"tmpfs    /tmp    tmpfs    defaults,noatime,nosuid,size=100m    0 0"
		"tmpfs    /var/tmp    tmpfs    defaults,noatime,nosuid,size=30m    0 0"
		"tmpfs    /var/log    tmpfs    defaults,noatime,nosuid,size=100m    0 0"
	)
	if ! file_contains_line "/etc/fstab" "${ARR_TEST[0]}"; then
		for STR_TEST in "${ARR_TEST[@]}"; do
			file_add_line "/etc/fstab" "$STR_TEST" "sudo"
		done
		echo "> Updated /etc/fstab..."
		mount | grep tmpfs
	fi
fi

if prompt "Use all 4 CPUs for compiling"; then
	export MAKEFLAGS=-j4
	FILE_TEST="$DIR_LOCAL/.profile"
	if [ ! -f "$FILE_TEST" ]; then
		touch $FILE_TEST
		chmod $CHMOD_FILES $FILE_TEST
	fi
	if file_add_line "$FILE_TEST" "MAKEFLAGS=-j4"; then
		echo "> Updated $(basename "$FILE_TEST")..."
	fi
	if file_add_line "/etc/environment" "MAKEFLAGS=-j4" "sudo"; then
		echo "> Updated /etc/environment..."
	fi
fi

if prompt "Enable overclocking"; then
	ARR_TEST=(
		"arm_boost=1"
		"gpu_freq=600"
		"over_voltage=5"
	)
	for STR_TEST in "${ARR_TEST[@]}"; do
		file_add_line_config_after_all "$STR_TEST"
	done
	echo "> Updated $(basename "$FILE_CONFIG")..."
fi

if prompt "Improve Wi-Fi performance - Disable WLAN adaptor power management"; then
	if file_add_line_rclocal_before_exit "iwconfig wlan0 power off"; then
		echo "> Updated $(basename "$FILE_RCLOCAL")..."
	fi
fi

if prompt "Turn off blinking cursor"; then
	if file_add_line_rclocal_before_exit "echo 0 > /sys/class/graphics/fbcon/cursor_blink"; then
		echo "> Updated $(basename "$FILE_RCLOCAL")..."
	fi
fi

if prompt "Disable video"; then
	if is_which "tvservice" && is_opengl_legacy; then
		tvservice -o
		if file_add_line_rclocal_before_exit "tvservice -o"; then
			echo "> Updated $(basename "$FILE_RCLOCAL")..."
		fi
	fi
	if is_which "vcgencmd"; then
		vcgencmd display_power 0
		if file_add_line_rclocal_before_exit "vcgencmd display_power 0"; then
			echo "> Updated $(basename "$FILE_RCLOCAL")..."
		fi
	fi
fi

echo "> Done."
exit 0
