#!/bin/bash

# import environment
CMD_TEST="$(readlink "$0")"
if [ ! "$CMD_TEST" = "" ]; then
	DIRNAME="$(dirname "$CMD_TEST")"
else
	DIRNAME="$(dirname "$0")"
fi
if [ -f "$DIRNAME/halftheory_env.sh" ]; then
	. $DIRNAME/halftheory_env.sh
else
	echo "Error in $0 on line $LINENO. Exiting..."
	exit 1
fi

# persistent vars
if [ ! -n "$PI_FILE_CMDLINE" ]; then
	PI_FILE_CMDLINE="$(file_add_line_env_prompt "PI_FILE_CMDLINE" "/boot/cmdline.txt" "file")"
fi
if [ ! -n "$PI_FILE_CONFIG" ]; then
	PI_FILE_CONFIG="$(file_add_line_env_prompt "PI_FILE_CONFIG" "/boot/config.txt" "file")"
fi
if [ ! -n "$PI_FILE_RCLOCAL" ]; then
	PI_FILE_RCLOCAL="$(file_add_line_env_prompt "PI_FILE_RCLOCAL" "/etc/rc.local" "file")"
fi

# vars
MAYBE_SUDO="$(maybe_sudo)"

# functions

function file_add_line_config_after_all()
{
	# STRING [FILE]
	if [ -z "$1" ]; then
		return 1
	fi
	local FILE_TEST="$PI_FILE_CONFIG"
	if [ "$2" ]; then
		FILE_TEST="$2"
	fi
	if ! file_contains_line "$FILE_TEST" "$1"; then
		if file_contains_line "$FILE_TEST" "#$1"; then
			file_add_line "$FILE_TEST" "$1" "sudo"
		elif ! file_replace_line_first "$FILE_TEST" "(\[all\])" "\1\n$1" "sudo"; then
			file_add_line "$FILE_TEST" "$1" "sudo"
		fi
	else
		return 1
	fi
	return 0
}

function file_add_line_rclocal_before_exit()
{
	# STRING
	if [ -z "$1" ]; then
		return 1
	fi
	if ! file_contains_line "$PI_FILE_RCLOCAL" "$*"; then
		if file_contains_line "$PI_FILE_RCLOCAL" "#$*"; then
			file_add_line "$PI_FILE_RCLOCAL" "$*" "sudo"
		elif ! file_replace_line_first "$PI_FILE_RCLOCAL" "(exit 0)" "$*\n\1" "sudo"; then
			file_add_line "$PI_FILE_RCLOCAL" "$*" "sudo"
		fi
	else
		return 1
	fi
	return 0
}

function file_add_string_cmdline()
{
	# STRING [FILE]
	if [ -z "$1" ]; then
		return 1
	fi
	local FILE_TEST="$PI_FILE_CMDLINE"
	if [ "$2" ]; then
		FILE_TEST="$2"
	fi
	if [ -e "$FILE_TEST" ]; then
		if [ "$(grep -e "$1" "$FILE_TEST")" = "" ]; then
			if [ "$(get_system)" = "Darwin" ]; then
				${MAYBE_SUDO}sed -i '' -E "\$s/(\s*)$/ $1\1/g" "$FILE_TEST"
			else
				${MAYBE_SUDO}sed -i -E "\$s/(\s*)$/ $1\1/g" "$FILE_TEST"
			fi
			return 0
		fi
	fi
	return 1
}

function get_rpi_model()
{
	local STR_TEST=""
	if [ -e "/proc/device-tree/model" ]; then
		read -r STR_TEST < /proc/device-tree/model
	fi
	if [ "$STR_TEST" = "" ] && [ -e "/proc/cpuinfo" ]; then
		STR_TEST="$(grep -e "Model" /proc/cpuinfo | awk -F: '{print $2}')"
		if [ "$STR_TEST" = "" ]; then
			STR_TEST="$(grep -e "Hardware" /proc/cpuinfo | awk -F: '{print $2}')"
		fi
	fi
	STR_TEST="$(trim_space "$STR_TEST")"
	if [ "$STR_TEST" = "" ]; then
		return 1
	fi
	echo "$STR_TEST"
	return 0
}

function get_rpi_model_id()
{
	local STR_RES=""
	local STR_MODEL="$(get_rpi_model)"
	if [[ "$STR_MODEL" == "Raspberry Pi "* ]]; then
		local STR="$(echo "$STR_MODEL" | awk '{print $3}')"
		if is_int "$STR"; then
			STR_RES="$STR"
		elif [ "$STR" = "Zero" ]; then
			STR_RES="0"
		elif [ "$STR" = "Model" ]; then
			if [[ "$STR_MODEL" = *" Model B "* ]]; then
				STR_RES="1"
			elif [[ "$STR_MODEL" = *" Model A "* ]]; then
				STR_RES="1"
			fi
		fi
	fi
	if [ "$STR_RES" = "" ]; then
		return 1
	fi
	echo "$STR_RES"
	return 0
}

function is_opengl_legacy()
{
	if file_contains_line "$PI_FILE_CONFIG" "dtoverlay=vc4-kms-v3d" || file_contains_line "$PI_FILE_CONFIG" "dtoverlay=vc4-kms-v3d-pi4"; then
		return 1
	fi
	return 0
}

function is_vcgencmd_working()
{
	local STR_TEST="$(get_os_version_id)"
	if is_which "vcgencmd" && is_int "$STR_TEST" && (($STR_TEST < 11)); then
		return 0
	fi
	return 1
}
