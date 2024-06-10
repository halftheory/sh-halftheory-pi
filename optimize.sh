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

SCRIPT_ALIAS="optimize"

# usage
if [ "$1" = "-help" ]; then
	echo "> Usage: $SCRIPT_ALIAS [force]"
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
BOOL_FORCE=false
if [ $1 ] && [ "$1" = "force" ]; then
	BOOL_FORCE=true
fi

# functions
function prompt()
{
	if [ -z "$1" ]; then
		return 1
	fi
	if [ $BOOL_FORCE = true ]; then
		echo "> $1? YES"
		return 0
	fi
	local PROMPT_TEST=""
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

if prompt "Enable SSH login over USB"; then
	if file_add_line_config_after_all "dtoverlay=dwc2"; then
		echo "> Updated '$(basename "$PI_FILE_CONFIG")'."
	fi
	if file_add_string_cmdline "modules-load=dwc2,g_ether"; then
		echo "> Updated '$(basename "$PI_FILE_CMDLINE")'."
	fi
fi

STR_TEST="en_US.UTF-8"
if prompt "Set locale to $STR_TEST"; then
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

if prompt "Disable/remove unneeded built-in services"; then
	if [ -e "/etc/init.d/triggerhappy" ] || [ -e "/etc/default/triggerhappy" ]; then
		${MAYBE_SUDO}systemctl stop triggerhappy
		${MAYBE_SUDO}systemctl disable triggerhappy
		${MAYBE_SUDO}apt-get -y remove triggerhappy
		${MAYBE_SUDO}apt-get -y autoremove
		${MAYBE_SUDO}rm -f /etc/init.d/triggerhappy > /dev/null 2>&1
		${MAYBE_SUDO}rm -f /etc/default/triggerhappy > /dev/null 2>&1
		echo "> Removed 'triggerhappy'."
	fi
	if [ -e "/etc/NetworkManager" ]; then
		${MAYBE_SUDO}systemctl stop NetworkManager-wait-online.service
		${MAYBE_SUDO}systemctl disable NetworkManager-wait-online.service
		echo "> Disabled 'NetworkManager-wait-online'."
	fi
	if [ -e "/etc/ModemManager" ]; then
		${MAYBE_SUDO}systemctl stop ModemManager.service
		${MAYBE_SUDO}systemctl disable ModemManager.service
		echo "> Disabled 'ModemManager'."
	fi
	${MAYBE_SUDO}systemctl stop rpi-display-backlight.service
	${MAYBE_SUDO}systemctl disable rpi-display-backlight.service
	echo "> Disabled 'rpi-display-backlight'."
fi

if prompt "Reduce bash/tmux buffer"; then
	FILE_TEST="$(get_shell_env_file)"
	ARR_TEST=(
		"HISTSIZE=500"
		"HISTFILESIZE=1000"
	)
	if ! file_contains_line "$FILE_TEST" "${ARR_TEST[0]}"; then
		if [ ! -f "$FILE_TEST" ]; then
			touch "$FILE_TEST"
			chmod $CHMOD_0 "$FILE_TEST"
		else
			if [ "$(get_system)" = "Darwin" ]; then
				sed -i '' -E "s/HISTSIZE=[0-9]*/${ARR_TEST[0]}/g" "$FILE_TEST"
				sed -i '' -E "s/HISTFILESIZE=[0-9]*/${ARR_TEST[1]}/g" "$FILE_TEST"
			else
				sed -i -E "s/HISTSIZE=[0-9]*/${ARR_TEST[0]}/g" "$FILE_TEST"
				sed -i -E "s/HISTFILESIZE=[0-9]*/${ARR_TEST[1]}/g" "$FILE_TEST"
			fi
		fi
		for STR in "${ARR_TEST[@]}"; do
			file_add_line "$FILE_TEST" "$STR"
		done
		echo "> Updated '$(basename "$FILE_TEST")'."
	fi
	if is_which "tmux"; then
		FILE_TEST="$DIR_HOME/.tmux.conf"
		ARR_TEST=(
			"set-option -g history-limit 1000"
			"set -g mouse off"
		)
		if ! file_contains_line "$FILE_TEST" "${ARR_TEST[0]}"; then
			if [ ! -f "$FILE_TEST" ]; then
				touch "$FILE_TEST"
				chmod $CHMOD_FILE "$FILE_TEST"
			fi
			for STR in "${ARR_TEST[@]}"; do
				file_add_line "$FILE_TEST" "$STR"
			done
			echo "> Updated '$(basename "$FILE_TEST")'."
		fi
	fi
fi

if prompt "Disable logging"; then
	FILE_TEST="/etc/rsyslog.conf"
	if [ -e "$FILE_TEST" ]; then
		if ! file_contains_line "$FILE_TEST" "*.*\t\t~" && [ "$(grep -e "\*\.\*\t\t~" "$FILE_TEST")" = "" ] && [ "$(grep -e "\*\.\*\s\s~" "$FILE_TEST")" = "" ]; then
			${MAYBE_SUDO}systemctl stop rsyslog
			${MAYBE_SUDO}systemctl disable rsyslog
			${MAYBE_SUDO}perl -0777 -pi -e "s/(#### RULES ####\n###############\n)/\1*.*\t\t~\n/sg" "$FILE_TEST"
			echo "> Updated '$(basename "$FILE_TEST")'."
		fi
	fi
	FILE_TEST="/etc/systemd/journald.conf"
	if [ -e "$FILE_TEST" ]; then
		file_add_line "$FILE_TEST" "ReadKMsg=no" "sudo"
		${MAYBE_SUDO}systemctl restart systemd-journald.service
		echo "> Updated '$(basename "$FILE_TEST")'."
	fi
	FILE_TEST="/etc/NetworkManager/conf.d"
	if [ -e "$FILE_TEST" ]; then
		FILE_TEST="/etc/NetworkManager/conf.d/90_nolog.conf"
		if [ ! -f "$FILE_TEST" ]; then
			${MAYBE_SUDO}touch "$FILE_TEST"
			ARR_TEST=(
				"[logging]"
				"domains=ALL:OFF"
				"level=OFF"
			)
			for STR in "${ARR_TEST[@]}"; do
				file_add_line "$FILE_TEST" "$STR"
			done
			echo "> Updated '$(basename "$FILE_TEST")'."
		fi
	fi
fi

if prompt "Disable man indexing"; then
	FILE_TEST="/etc/cron.daily/man-db"
	if [ -e "$FILE_TEST" ]; then
		if [ "$(grep -Pzo "\#\!\/bin\/sh\nexit 0" "$FILE_TEST" | xargs --null)" = "" ]; then
			if file_replace_line_first "$FILE_TEST" "(#!/bin/sh)" "\1\nexit 0" "sudo"; then
				echo "> Updated '$(basename "$FILE_TEST")'."
			fi
		fi
	fi
	FILE_TEST="/etc/cron.weekly/man-db"
	if [ -e "$FILE_TEST" ]; then
		if [ "$(grep -Pzo "\#\!\/bin\/sh\nexit 0" "$FILE_TEST" | xargs --null)" = "" ]; then
			if file_replace_line_first "$FILE_TEST" "(#!/bin/sh)" "\1\nexit 0" "sudo"; then
				echo "> Updated '$(basename "$FILE_TEST")'."
			fi
		fi
	fi
fi

if prompt "tmpfs - Write to RAM instead of the local disk"; then
	FILE_TEST="/etc/fstab"
	if [ -e "$FILE_TEST" ]; then
		ARR_TEST=(
			"tmpfs    /tmp    tmpfs    defaults,noatime,nosuid,size=100m    0 0"
			"tmpfs    /var/tmp    tmpfs    defaults,noatime,nosuid,size=100m    0 0"
			"tmpfs    /var/log    tmpfs    defaults,noatime,nosuid,size=100m    0 0"
		)
		if ! file_contains_line "$FILE_TEST" "${ARR_TEST[0]}"; then
			for STR in "${ARR_TEST[@]}"; do
				file_add_line "$FILE_TEST" "$STR" "sudo"
			done
			mount | grep tmpfs
			echo "> Updated '$(basename "$FILE_TEST")'."
		fi
	fi
fi

if prompt "Use all 4 CPUs for compiling"; then
	STR_TEST="MAKEFLAGS=-j4"
	export $STR_TEST
	FILE_TEST="$(get_shell_env_file)"
	if ! file_contains_line "$FILE_TEST" "$STR_TEST"; then
		if [ ! -f "$FILE_TEST" ]; then
			touch "$FILE_TEST"
			chmod $CHMOD_0 "$FILE_TEST"
		fi
		if file_add_line "$FILE_TEST" "$STR_TEST"; then
			echo "> Updated '$(basename "$FILE_TEST")'."
		fi
	fi
	if file_add_line "/etc/environment" "$STR_TEST" "sudo"; then
		echo "> Updated '/etc/environment'."
	fi
fi

if prompt "Turn off temperature warning"; then
	if file_add_line_config_after_all "avoid_warnings=1"; then
		echo "> Updated '$(basename "$PI_FILE_CONFIG")'."
	fi
fi

if prompt "Turn off top raspberries"; then
	if file_add_string_cmdline "logo.nologo"; then
		echo "> Updated '$(basename "$PI_FILE_CMDLINE")'."
	fi
fi

if prompt "Improve Wi-Fi performance - Disable WLAN adaptor power management"; then
	if is_which "iwconfig"; then
		STR_TEST="$(ifconfig | grep wlan | awk '{print $1}')"
		if [ ! "$STR_TEST" = "" ]; then
			STR_TEST="${STR_TEST%:}"
			if file_add_line_rclocal_before_exit "iwconfig $STR_TEST power off"; then
				echo "> Updated '$(basename "$PI_FILE_RCLOCAL")'."
			fi
		fi
	fi
fi

if prompt "Turn off blinking cursor"; then
	if [ -e "/sys/class/graphics/fbcon" ]; then
		if file_add_line_rclocal_before_exit "echo 0 > /sys/class/graphics/fbcon/cursor_blink"; then
			echo "> Updated '$(basename "$PI_FILE_RCLOCAL")'."
		fi
	fi
fi

if prompt "Delete system files"; then
	ARR_TEST=(
		"/boot"
		"/home"
	)
	for STR in "${ARR_TEST[@]}"; do
		delete_macos_system_files "$STR" "sudo"
		delete_windows_system_files "$STR" "sudo"
	done
fi

if prompt "Install samba"; then
	BOOL_TEST=false
	CMD_TEST="${MAYBE_SUDO}apt list --installed 2>&1 | grep \"samba/\""
	CMD_TEST="$(eval "$CMD_TEST")"
	if [ "$CMD_TEST" = "" ] && check_remote_host "archive.raspberrypi.org"; then
		${MAYBE_SUDO}apt-get -y install samba samba-common-bin
		sleep 1
		if is_which "smbpasswd"; then
			echo -ne "pi\npi\n" | ${MAYBE_SUDO}smbpasswd -s -a $OWN_LOCAL
			BOOL_TEST=true
		fi
		# smb.conf
		FILE_TEST="/etc/samba/smb.conf"
		if [ -e "$FILE_TEST" ]; then
			# existing values
			file_replace_line_first "$FILE_TEST" "browseable = no" "browseable = yes" "sudo"
			file_replace_line_first "$FILE_TEST" "read only = yes" "read only = no" "sudo"
			file_replace_line_first "$FILE_TEST" "create mask = [0-9]*" "create mask = 0775" "sudo"
			file_replace_line_first "$FILE_TEST" "directory mask = [0-9]*" "directory mask = 0775" "sudo"
			# new values
			ARR_TEST=(
				"available = yes"
				"public = yes"
				"writeable = yes"
			)
			for STR in "${ARR_TEST[@]}"; do
				file_replace_line_first "$FILE_TEST" "(\[homes\])" "\1\n${STR}" "sudo"
			done
		fi
		# services
		${MAYBE_SUDO}systemctl restart nmbd samba smbd
	fi
	if [ $BOOL_TEST = true ]; then
		echo "> Installed. You must reboot."
	else
		echo "> Not installed."
	fi
fi

if prompt "Install usbmount"; then
	BOOL_TEST=false
	CMD_TEST="${MAYBE_SUDO}apt list --installed 2>&1 | grep \"usbmount/\""
	CMD_TEST="$(eval "$CMD_TEST")"
	if [ "$CMD_TEST" = "" ] && check_remote_host "archive.raspberrypi.org"; then
		${MAYBE_SUDO}apt-get -y install git debhelper build-essential eject ntfs-3g exfat-fuse exfat-utils
		sleep 1
		if [ -d "$DIR_HOME" ]; then
			(cd "$DIR_HOME" && git clone https://github.com/nicokaiser/usbmount/)
		else
			git clone https://github.com/nicokaiser/usbmount/
		fi
		if [ $? -eq 0 ] && [ -d "${DIR_HOME}usbmount" ]; then
			(cd "${DIR_HOME}usbmount" && ${MAYBE_SUDO}dpkg-buildpackage -us -uc -b)
			sleep 1
			if [ -f "${DIR_HOME}usbmount_0.0.24_all.deb" ]; then
				${MAYBE_SUDO}dpkg -i ${DIR_HOME}usbmount_0.0.24_all.deb
				${MAYBE_SUDO}apt-get -y install -f
				sleep 1
				BOOL_TEST=true
			fi
			if [ ! -f "/etc/usbmount/usbmount.conf" ] && [ -f "${DIR_HOME}usbmount/usbmount.conf" ]; then
				${MAYBE_SUDO}cp -f "${DIR_HOME}usbmount/usbmount.conf" "/etc/usbmount/usbmount.conf" > /dev/null 2>&1
			fi
			${MAYBE_SUDO}rm -Rf "${DIR_HOME}usbmount" > /dev/null 2>&1
		fi
		# usbmount.conf
		FILE_TEST="/etc/usbmount/usbmount.conf"
		if [ -e "$FILE_TEST" ]; then
			if file_replace_line_first "$FILE_TEST" "FILESYSTEMS=\"vfat ext2 ext3 ext4 hfsplus\"" "FILESYSTEMS=\"vfat ext2 ext3 ext4 hfsplus fuseblk ntfs-3g exfat\"" "sudo"; then
				echo "> Updated '$(basename "$FILE_TEST")'."
			fi
		fi
		# systemd-udevd.service
		FILE_TEST="/lib/systemd/system/systemd-udevd.service"
		if [ -e "$FILE_TEST" ]; then
			if file_replace_line_first "$FILE_TEST" "PrivateMounts=yes" "PrivateMounts=no" "sudo"; then
				echo "> Updated '$(basename "$FILE_TEST")'."
			elif ! file_contains_line "$FILE_TEST" "PrivateMounts=no"; then
				file_add_line "$FILE_TEST" "PrivateMounts=no" "sudo"
				echo "> Updated '$(basename "$FILE_TEST")'."
			fi
		fi
	fi
	if [ $BOOL_TEST = true ]; then
		echo "> Installed. You must reboot."
	else
		echo "> Not installed."
	fi
fi

if prompt "Run raspi-config"; then
	${MAYBE_SUDO}raspi-config
fi

echo "> Done."
exit 0
