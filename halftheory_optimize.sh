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
	echo "> Usage: $SCRIPT_ALIAS [all|force]"
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

if prompt "Set all passwords to 'pi'"; then
	echo -ne "pi\npi\n" | ${MAYBE_SUDO}passwd root
	echo -ne "pi\npi\n" | ${MAYBE_SUDO}passwd $OWN_LOCAL
fi

if prompt "Set locale to en_US.UTF-8"; then
	STR_TEST="en_US.UTF-8"
	if [ ! "$(locale 2>&1 | grep -v $STR_TEST)" = "" ]; then
		export LANG=$STR_TEST
		export LANGUAGE=$STR_TEST
		${MAYBE_SUDO}dpkg-reconfigure locales
		${MAYBE_SUDO}locale-gen --purge $STR_TEST
		${MAYBE_SUDO}update-locale LANG=$STR_TEST LANGUAGE=$STR_TEST LC_CTYPE=$STR_TEST LC_ALL=$STR_TEST
	fi
fi

if prompt "Perform apt-get upgrades"; then
	if check_remote_host "archive.raspberrypi.org"; then
		${MAYBE_SUDO}apt-get -y clean
		${MAYBE_SUDO}apt-get -y update
		${MAYBE_SUDO}apt-get -y upgrade
		${MAYBE_SUDO}apt-get -y dist-upgrade
	fi
fi

if prompt "Remove triggerhappy"; then
	if [ -e "/etc/init.d/triggerhappy" ] || [ -e "/etc/default/triggerhappy" ]; then
		${MAYBE_SUDO}systemctl disable triggerhappy
		${MAYBE_SUDO}apt-get -y remove triggerhappy
		${MAYBE_SUDO}apt-get -y autoremove
		${MAYBE_SUDO}rm -f /etc/init.d/triggerhappy > /dev/null 2>&1
		${MAYBE_SUDO}rm -f /etc/default/triggerhappy > /dev/null 2>&1
	fi
fi

if prompt "Reduce bash/tmux buffer"; then
	FILE_TEST="$DIR_LOCAL/.bashrc"
	ARR_TEST=(
		"HISTSIZE=500"
		"HISTFILESIZE=1000"
	)
	if ! file_contains_line "$FILE_TEST" "${ARR_TEST[0]}"; then
		if [ ! -f "$FILE_TEST" ]; then
			touch "$FILE_TEST"
			chmod $CHMOD_FILES "$FILE_TEST"
		else
			if [ "$(get_system)" = "Darwin" ]; then
				sed -i '' -E "s/HISTSIZE=[0-9]*/${ARR_TEST[0]}/g" $FILE_TEST
				sed -i '' -E "s/HISTFILESIZE=[0-9]*/${ARR_TEST[1]}/g" $FILE_TEST
			else
				sed -i -E "s/HISTSIZE=[0-9]*/${ARR_TEST[0]}/g" $FILE_TEST
				sed -i -E "s/HISTFILESIZE=[0-9]*/${ARR_TEST[1]}/g" $FILE_TEST
			fi
		fi
		for STR_TEST in "${ARR_TEST[@]}"; do
			file_add_line "$FILE_TEST" "$STR_TEST"
		done
		echo "> Updated $(basename "$FILE_TEST")..."
	fi
	if is_which "tmux"; then
		FILE_TEST="$DIR_LOCAL/.tmux.conf"
		ARR_TEST=(
			"set-option -g history-limit 1000"
			"set -g mouse off"
		)
		if ! file_contains_line "$FILE_TEST" "${ARR_TEST[0]}"; then
			if [ ! -f "$FILE_TEST" ]; then
				touch "$FILE_TEST"
				chmod $CHMOD_FILES "$FILE_TEST"
			fi
			for STR_TEST in "${ARR_TEST[@]}"; do
				file_add_line "$FILE_TEST" "$STR_TEST"
			done
			echo "> Updated $(basename "$FILE_TEST")..."
		fi
	fi
fi

if prompt "Disable logging"; then
	FILE_TEST="/etc/rsyslog.conf"
	if [ -e "$FILE_TEST" ]; then
		if ! file_contains_line "$FILE_TEST" "*.*\t\t~" && [ "$(grep -e "\*\.\*\t\t~" $FILE_TEST)" = "" ] && [ "$(grep -e "\*\.\*\s\s~" $FILE_TEST)" = "" ]; then
			${MAYBE_SUDO}systemctl disable rsyslog
			${MAYBE_SUDO}perl -0777 -pi -e "s/(#### RULES ####\n###############\n)/\1*.*\t\t~\n/sg" $FILE_TEST
			echo "> Updated $(basename "$FILE_TEST")..."
		fi
	fi
fi

if prompt "Disable man indexing"; then
	FILE_TEST="/etc/cron.daily/man-db"
	if [ -e "$FILE_TEST" ]; then
		if [ "$(grep -Pzo "\#\!\/bin\/sh\nexit 0" $FILE_TEST | xargs --null)" = "" ]; then
			if file_replace_line_first "$FILE_TEST" "(#!/bin/sh)" "\1\nexit 0" "sudo"; then
				echo "> Updated $(basename "$FILE_TEST")..."
			fi
		fi
	fi
	FILE_TEST="/etc/cron.weekly/man-db"
	if [ -e "$FILE_TEST" ]; then
		if [ "$(grep -Pzo "\#\!\/bin\/sh\nexit 0" $FILE_TEST | xargs --null)" = "" ]; then
			if file_replace_line_first "$FILE_TEST" "(#!/bin/sh)" "\1\nexit 0" "sudo"; then
				echo "> Updated $(basename "$FILE_TEST")..."
			fi
		fi
	fi
fi

if prompt "tmpfs - Write to RAM instead of the local disk"; then
	FILE_TEST="/etc/fstab"
	if [ -e "$FILE_TEST" ]; then
		ARR_TEST=(
			"tmpfs    /tmp    tmpfs    defaults,noatime,nosuid,size=100m    0 0"
			"tmpfs    /var/tmp    tmpfs    defaults,noatime,nosuid,size=30m    0 0"
			"tmpfs    /var/log    tmpfs    defaults,noatime,nosuid,size=100m    0 0"
		)
		if ! file_contains_line "$FILE_TEST" "${ARR_TEST[0]}"; then
			for STR_TEST in "${ARR_TEST[@]}"; do
				file_add_line "$FILE_TEST" "$STR_TEST" "sudo"
			done
			mount | grep tmpfs
			echo "> Updated $(basename "$FILE_TEST")..."
		fi
	fi
fi

if prompt "Use all 4 CPUs for compiling"; then
	STR_TEST="MAKEFLAGS=-j4"
	export $STR_TEST
	FILE_TEST="$DIR_LOCAL/.profile"
	if ! file_contains_line "$FILE_TEST" "$STR_TEST"; then
		if [ ! -f "$FILE_TEST" ]; then
			touch "$FILE_TEST"
			chmod $CHMOD_FILES "$FILE_TEST"
		fi
		if file_add_line "$FILE_TEST" "$STR_TEST"; then
			echo "> Updated $(basename "$FILE_TEST")..."
		fi
	fi
	if file_add_line "/etc/environment" "$STR_TEST" "sudo"; then
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

if prompt "Delete mac system files"; then
	ARR_TEST=(
		"/boot"
		"/home"
	)
	for STR_TEST in "${ARR_TEST[@]}"; do
		delete_macos_system_files "$STR_TEST" "sudo"
	done
fi

if prompt "Disable video"; then
	if is_which "tvservice" && is_opengl_legacy; then
		if file_add_line_rclocal_before_exit "tvservice -o"; then
			echo "> Updated $(basename "$FILE_RCLOCAL")..."
		fi
		tvservice -o
	elif is_which "xset"; then
		if file_add_line_rclocal_before_exit "xset dpms force off"; then
			echo "> Updated $(basename "$FILE_RCLOCAL")..."
		fi
		xset dpms force off
	fi
	if is_vcgencmd_working; then
		if file_add_line_rclocal_before_exit "vcgencmd display_power 0"; then
			echo "> Updated $(basename "$FILE_RCLOCAL")..."
		fi
		vcgencmd display_power 0
	fi
fi

if prompt "Run raspi-config"; then
	${MAYBE_SUDO}raspi-config
fi

echo "> Done."
exit 0
