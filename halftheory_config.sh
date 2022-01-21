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

SCRIPT_ALIAS="config"

# usage
if [ -z $1 ]; then
	echo "> Usage: $MAYBE_SUDO$SCRIPT_ALIAS [audio|bluetooth|firewall|hdmi|network] [on|off]"
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

if [ ! "$2" = "on" ] && [ ! "$2" = "off" ]; then
	echo "> Usage: $MAYBE_SUDO$SCRIPT_ALIAS [audio|bluetooth|firewall|hdmi|network] [on|off]"
	exit 1
fi

case "$1" in
	audio)
		FILESIZE="$(get_file_size "$FILE_CONFIG")"
		case "$2" in
			on)
				if ! file_replace_line "$FILE_CONFIG" "dtparam=audio=off" "dtparam=audio=on" "sudo"; then
					if file_contains_line "$FILE_CONFIG" "#dtparam=audio=on"; then
						file_add_line "$FILE_CONFIG" "dtparam=audio=on" "sudo"
					elif ! file_replace_line_last "$FILE_CONFIG" "([all])" "\1\ndtparam=audio=on" "sudo"; then
						file_add_line "$FILE_CONFIG" "dtparam=audio=on" "sudo"
					fi
				fi
				if file_contains_line "$FILE_CONFIG" "#audio_pwm_mode=2"; then
					file_add_line "$FILE_CONFIG" "audio_pwm_mode=2" "sudo"
				elif ! file_replace_line_last "$FILE_CONFIG" "([all])" "\1\naudio_pwm_mode=2" "sudo"; then
					file_add_line "$FILE_CONFIG" "audio_pwm_mode=2" "sudo"
				fi
				;;
			off)
				if ! file_replace_line "$FILE_CONFIG" "dtparam=audio=on" "dtparam=audio=off" "sudo"; then
					if file_contains_line "$FILE_CONFIG" "#dtparam=audio=off"; then
						file_add_line "$FILE_CONFIG" "dtparam=audio=off" "sudo"
					elif ! file_replace_line_last "$FILE_CONFIG" "([all])" "\1\ndtparam=audio=off" "sudo"; then
						file_add_line "$FILE_CONFIG" "dtparam=audio=off" "sudo"
					fi
				fi
				file_replace_line "$FILE_CONFIG" "(audio_pwm_mode=2)" "#\1" "sudo"
				;;
		esac
		if [ ! "$FILESIZE" = "$(get_file_size "$FILE_CONFIG")" ]; then
			echo "> Updated $(basename "$FILE_CONFIG")..."
		fi
		echo "> $1 will be $2 after rebooting."
		;;

	bluetooth)
		FILESIZE="$(get_file_size "$FILE_CONFIG")"
		case "$2" in
			on)
				echo "> Enabling services..."
				${MAYBE_SUDO}systemctl enable bluetooth
				${MAYBE_SUDO}systemctl enable hciuart
				file_replace_line "$FILE_CONFIG" "(dtoverlay=disable-bt)" "#\1" "sudo"
				;;
			off)
				echo "> Disabling services..."
				${MAYBE_SUDO}systemctl disable bluetooth
				${MAYBE_SUDO}systemctl disable hciuart
				if file_contains_line "$FILE_CONFIG" "#dtoverlay=disable-bt"; then
					file_add_line "$FILE_CONFIG" "dtoverlay=disable-bt" "sudo"
				elif ! file_replace_line_last "$FILE_CONFIG" "([all])" "\1\ndtoverlay=disable-bt" "sudo"; then
					file_add_line "$FILE_CONFIG" "dtoverlay=disable-bt" "sudo"
				fi
				;;
		esac
		if [ ! "$FILESIZE" = "$(get_file_size "$FILE_CONFIG")" ]; then
			echo "> Updated $(basename "$FILE_CONFIG")..."
		fi
		echo "> $1 will be $2 after rebooting."
		;;

	firewall)
		if is_which "ufw"; then
			echo "> Reseting firewall..."
			${MAYBE_SUDO}ufw logging off
			${MAYBE_SUDO}ufw --force reset
		fi
		case "$2" in
			on)
				if maybe_install "ufw"; then
					echo "> Enabling firewall..."
					${MAYBE_SUDO}ufw allow ssh
					${MAYBE_SUDO}ufw default allow incoming
					${MAYBE_SUDO}ufw default allow outgoing
					${MAYBE_SUDO}ufw deny ftp
					${MAYBE_SUDO}ufw deny http
					${MAYBE_SUDO}ufw deny https
					${MAYBE_SUDO}ufw deny imap
					${MAYBE_SUDO}ufw deny pop3
					${MAYBE_SUDO}ufw deny smtp
					${MAYBE_SUDO}ufw --force enable
				fi
				;;
			off)
				if is_which "ufw"; then
					echo "> Disabling firewall..."
					${MAYBE_SUDO}ufw --force disable
				fi
				;;
		esac
		echo "> $1 is now $2. This will persist after rebooting."
		;;

	hdmi)
		FILESIZE_CONFIG="$(get_file_size "$FILE_CONFIG")"
		FILESIZE_RCLOCAL="$(get_file_size "$FILE_RCLOCAL")"
		case "$2" in
			on)
				# hdmi_force_hotplug=1
				if file_contains_line "$FILE_CONFIG" "#hdmi_force_hotplug=1"; then
					file_add_line "$FILE_CONFIG" "hdmi_force_hotplug=1" "sudo"
				elif ! file_replace_line_last "$FILE_CONFIG" "([all])" "\1\nhdmi_force_hotplug=1" "sudo"; then
					file_add_line "$FILE_CONFIG" "hdmi_force_hotplug=1" "sudo"
				fi
				# comment sdtv_mode
				file_replace_line "$FILE_CONFIG" "(sdtv_mode=[0-9]*)" "#\1" "sudo"
				# rc.local
				if is_which "vcgencmd"; then
					file_replace_line "$FILE_RCLOCAL" "(vcgencmd display_power 0)" "#\1" "sudo"
					vcgencmd display_power 1
				fi
				;;
			off)
				# comment hdmi_force_hotplug=1
				file_replace_line "$FILE_CONFIG" "(hdmi_force_hotplug=1)" "#\1" "sudo"
				# sdtv_mode=18
				if [ "$(get_system)" = "Darwin" ]; then
					${MAYBE_SUDO}sed -i '' -E 's/sdtv_mode=[0-9]*/sdtv_mode=18/g' $FILE_CONFIG
				else
					${MAYBE_SUDO}sed -i -E 's/sdtv_mode=[0-9]*/sdtv_mode=18/g' $FILE_CONFIG
				fi
				if file_contains_line "$FILE_CONFIG" "#sdtv_mode=18"; then
					file_add_line "$FILE_CONFIG" "sdtv_mode=18" "sudo"
				elif ! file_replace_line_last "$FILE_CONFIG" "([all])" "\1\nsdtv_mode=18" "sudo"; then
					file_add_line "$FILE_CONFIG" "sdtv_mode=18" "sudo"
				fi
				# rc.local
				if is_which "vcgencmd"; then
					if ! file_replace_line_last "$FILE_RCLOCAL" "(exit 0)" "vcgencmd display_power 0\n\1" "sudo"; then
						file_add_line "$FILE_RCLOCAL" "vcgencmd display_power 0" "sudo"
					fi
					vcgencmd display_power 0
				fi
				;;
		esac
		# need for both hdmi and pal
		if is_which "tvservice"; then
			file_replace_line "$FILE_RCLOCAL" "(tvservice -o)" "#\1" "sudo"
			if is_opengl_legacy; then
				tvservice -p
			fi
		fi
		if [ ! "$FILESIZE_CONFIG" = "$(get_file_size "$FILE_CONFIG")" ]; then
			echo "> Updated $(basename "$FILE_CONFIG")..."
		fi
		if [ ! "$FILESIZE_RCLOCAL" = "$(get_file_size "$FILE_RCLOCAL")" ]; then
			echo "> Updated $(basename "$FILE_RCLOCAL")..."
		fi
		echo "> $1 is now $2. This will persist after rebooting."
		;;

	network)
		FILESIZE="$(get_file_size "$FILE_CONFIG")"
		case "$2" in
			on)
				echo "> Enabling services..."
				${MAYBE_SUDO}systemctl enable networking
				${MAYBE_SUDO}systemctl enable ssh
				${MAYBE_SUDO}systemctl enable smbd
				${MAYBE_SUDO}systemctl enable nmbd
				file_replace_line "$FILE_CONFIG" "(dtoverlay=disable-wifi)" "#\1" "sudo"
				;;
			off)
				echo "> Disabling services..."
				${MAYBE_SUDO}systemctl disable nmbd
				${MAYBE_SUDO}systemctl disable smbd
				${MAYBE_SUDO}systemctl disable ssh
				${MAYBE_SUDO}systemctl disable networking
				if file_contains_line "$FILE_CONFIG" "#dtoverlay=disable-wifi"; then
					file_add_line "$FILE_CONFIG" "dtoverlay=disable-wifi" "sudo"
				elif ! file_replace_line_last "$FILE_CONFIG" "([all])" "\1\ndtoverlay=disable-wifi" "sudo"; then
					file_add_line "$FILE_CONFIG" "dtoverlay=disable-wifi" "sudo"
				fi
				;;
		esac
		if [ ! "$FILESIZE" = "$(get_file_size "$FILE_CONFIG")" ]; then
			echo "> Updated $(basename "$FILE_CONFIG")..."
		fi
		echo "> $1 is now $2. This will persist after rebooting."
		;;

	*)
		echo "Error in $0 on line $LINENO. Exiting..."
		exit 1
		;;
esac

exit 0
