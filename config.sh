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

SCRIPT_ALIAS="config"

# usage
if [ -z "$1" ] || [ "$1" = "-help" ]; then
	echo "> Usage: $SCRIPT_ALIAS [audio|bluetooth|firewall|hdmi|led|network|overclock|video|wifi] [on|off]"
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

case "$2" in
	on | off)
		;;
	*)
		echo "> Usage: $SCRIPT_ALIAS [audio|bluetooth|firewall|hdmi|led|network|overclock|video|wifi] [on|off]"
		exit 1
		;;
esac

case "$1" in
	audio)
		FILESIZE="$(get_file_size "$PI_FILE_CONFIG")"
		ARR_TEST=(
			"alsa-restore"
			"alsa-state"
			"alsa-utils"
		)
		case "$2" in
			on)
				if ! file_contains_line "$PI_FILE_CONFIG" "dtparam=audio=on"; then
					if ! file_replace_line "$PI_FILE_CONFIG" "dtparam=audio=off" "dtparam=audio=on" "sudo"; then
						file_add_line_config_after_all "dtparam=audio=on"
					fi
				fi
				file_add_line_config_after_all "audio_pwm_mode=2"
				for STR in "${ARR_TEST[@]}"; do
					${MAYBE_SUDO}systemctl enable ${STR}.service
					${MAYBE_SUDO}systemctl start ${STR}.service
				done
				;;
			off)
				if ! file_contains_line "$PI_FILE_CONFIG" "dtparam=audio=off"; then
					if ! file_replace_line "$PI_FILE_CONFIG" "dtparam=audio=on" "dtparam=audio=off" "sudo"; then
						file_add_line_config_after_all "dtparam=audio=off"
					fi
				fi
				file_comment_line "$PI_FILE_CONFIG" "audio_pwm_mode=2" "sudo"
				for STR in "${ARR_TEST[@]}"; do
					${MAYBE_SUDO}systemctl stop ${STR}.service
					${MAYBE_SUDO}systemctl disable ${STR}.service
				done
				;;
		esac
		sleep 1
		if [ ! "$FILESIZE" = "$(get_file_size "$PI_FILE_CONFIG")" ]; then
			echo "> Updated '$(basename "$PI_FILE_CONFIG")'."
		fi
		echo "> $1 will be $2 after rebooting."
		;;

	bluetooth)
		FILESIZE="$(get_file_size "$PI_FILE_CONFIG")"
		ARR_TEST=(
			"bluetooth"
			"hciuart"
		)
		case "$2" in
			on)
				echo "> Enabling services..."
				file_comment_line "$PI_FILE_CONFIG" "dtoverlay=disable-bt" "sudo"
				for STR in "${ARR_TEST[@]}"; do
					${MAYBE_SUDO}systemctl enable ${STR}.service
					${MAYBE_SUDO}systemctl start ${STR}.service
				done
				;;
			off)
				echo "> Disabling services..."
				file_add_line_config_after_all "dtoverlay=disable-bt"
				for STR in "${ARR_TEST[@]}"; do
					${MAYBE_SUDO}systemctl stop ${STR}.service
					${MAYBE_SUDO}systemctl disable ${STR}.service
				done
				;;
		esac
		sleep 1
		if [ ! "$FILESIZE" = "$(get_file_size "$PI_FILE_CONFIG")" ]; then
			echo "> Updated '$(basename "$PI_FILE_CONFIG")'."
		fi
		echo "> $1 will be $2 after rebooting."
		;;

	firewall)
		case "$2" in
			on)
				if maybe_install "ufw"; then
					echo "> Enabling firewall..."
					${MAYBE_SUDO}systemctl enable ufw.service
					${MAYBE_SUDO}systemctl start ufw.service
					${MAYBE_SUDO}ufw --force reset
					${MAYBE_SUDO}ufw logging off
					${MAYBE_SUDO}ufw default allow incoming
					${MAYBE_SUDO}ufw default allow outgoing
					${MAYBE_SUDO}ufw deny ftp
					${MAYBE_SUDO}ufw deny http
					${MAYBE_SUDO}ufw deny https
					${MAYBE_SUDO}ufw deny imap
					${MAYBE_SUDO}ufw deny pop3
					${MAYBE_SUDO}ufw deny smtp
					${MAYBE_SUDO}ufw allow ssh
					ARR_TEST=(
						"avahi-daemon"
						"samba"
						"wsdd"
					)
					for STR in "${ARR_TEST[@]}"; do
						if is_which "$STR"; then
							${MAYBE_SUDO}ufw allow $STR
						fi
					done
					${MAYBE_SUDO}ufw --force enable
				fi
				;;
			off)
				if is_which "ufw"; then
					echo "> Disabling firewall..."
					${MAYBE_SUDO}ufw --force disable
					${MAYBE_SUDO}systemctl stop ufw.service
					${MAYBE_SUDO}systemctl disable ufw.service
				fi
				;;
		esac
		echo "> $1 is now $2. This will persist after rebooting."
		;;

	hdmi)
		FILESIZE_CONFIG="$(get_file_size "$PI_FILE_CONFIG")"
		FILESIZE_RCLOCAL="$(get_file_size "$PI_FILE_RCLOCAL")"
		case "$2" in
			on)
				# hdmi_force_hotplug=1
				file_add_line_config_after_all "hdmi_force_hotplug=1"
				# comment sdtv_mode
				file_replace_line "$PI_FILE_CONFIG" "(sdtv_mode=[0-9]*)" "#\1" "sudo"
				# disable_overscan
				file_comment_line "$PI_FILE_CONFIG" "disable_overscan=1" "sudo"
				# rc.local
				if is_which "tvservice"; then
					file_comment_line "$PI_FILE_RCLOCAL" "tvservice -o" "sudo"
				fi
				if is_vcgencmd_working; then
					file_comment_line "$PI_FILE_RCLOCAL" "vcgencmd display_power 0" "sudo"
					vcgencmd display_power 1
				fi
				;;
			off)
				# comment hdmi_force_hotplug=1
				file_comment_line "$PI_FILE_CONFIG" "hdmi_force_hotplug=1" "sudo"
				# rc.local
				if is_which "tvservice"; then
					file_add_line_rclocal_before_exit "tvservice -o"
				fi
				if is_vcgencmd_working; then
					file_add_line_rclocal_before_exit "vcgencmd display_power 0"
					vcgencmd display_power 0
				fi
				;;
		esac
		sleep 1
		if [ ! "$FILESIZE_CONFIG" = "$(get_file_size "$PI_FILE_CONFIG")" ]; then
			echo "> Updated '$(basename "$PI_FILE_CONFIG")'."
		fi
		if [ ! "$FILESIZE_RCLOCAL" = "$(get_file_size "$PI_FILE_RCLOCAL")" ]; then
			echo "> Updated '$(basename "$PI_FILE_RCLOCAL")'."
		fi
		echo "> $1 is now $2. This will persist after rebooting."
		;;

	led)
		FILESIZE_CONFIG="$(get_file_size "$PI_FILE_CONFIG")"
		FILESIZE_RCLOCAL="$(get_file_size "$PI_FILE_RCLOCAL")"
		ARR_CONFIG=(
			"dtparam=pwr_led_trigger=none"
			"dtparam=pwr_led_activelow=off"
			"dtparam=act_led_trigger=none"
			"dtparam=act_led_activelow=off"
		)
		STR_TEST="$(get_rpi_model_id)"
		if is_int "$STR_TEST" && (($STR_TEST > 3)); then
			ARR_CONFIG+=("dtparam=eth_led0=4")
			ARR_CONFIG+=("dtparam=eth_led1=4")
		else
			ARR_CONFIG+=("dtparam=eth_led0=14")
			ARR_CONFIG+=("dtparam=eth_led1=14")
		fi
		ARR_RCLOCAL=()
		DIR_TEST="/sys/class/leds"
		if [ -d "$DIR_TEST" ]; then
			IFS_OLD="$IFS"
			IFS=$'\n'
			ARR_TEST=( $(find $DIR_TEST -maxdepth 1) )
			IFS="$IFS_OLD"
			if [ ! "$ARR_TEST" = "" ]; then
				for STR in "${ARR_TEST[@]}"; do
					if [ "$STR" = "$DIR_TEST" ]; then
						continue
					fi
					if [ -e "$STR/trigger" ]; then
						ARR_RCLOCAL+=("echo none > $STR/trigger")
					fi
					if [ -e "$STR/brightness" ]; then
						ARR_RCLOCAL+=("echo 0 > $STR/brightness")
					fi
				done
			fi
		fi
		case "$2" in
			on)
				for STR in "${ARR_CONFIG[@]}"; do
					file_comment_line "$PI_FILE_CONFIG" "$STR" "sudo"
				done
				for STR in "${ARR_RCLOCAL[@]}"; do
					file_comment_line "$PI_FILE_RCLOCAL" "$STR" "sudo"
				done
				;;
			off)
				for STR in "${ARR_CONFIG[@]}"; do
					file_add_line_config_after_all "$STR"
				done
				for STR in "${ARR_RCLOCAL[@]}"; do
					file_add_line_rclocal_before_exit "$STR"
				done
				;;
		esac
		sleep 1
		if [ ! "$FILESIZE_CONFIG" = "$(get_file_size "$PI_FILE_CONFIG")" ]; then
			echo "> Updated '$(basename "$PI_FILE_CONFIG")'."
		fi
		if [ ! "$FILESIZE_RCLOCAL" = "$(get_file_size "$PI_FILE_RCLOCAL")" ]; then
			echo "> Updated '$(basename "$PI_FILE_RCLOCAL")'."
		fi
		echo "> $1 will be $2 after rebooting."
		;;

	network)
		ARR_TEST=(
			"networking"
			"ssh"
		)
		if [ -e "/etc/NetworkManager" ]; then
			ARR_TEST+=("NetworkManager")
		fi
		ARR_APPS=(
			"avahi-daemon"
			"nmbd"
			"samba"
			"smbd"
			"wsdd"
		)
		for STR in "${ARR_APPS[@]}"; do
			if is_which "$STR"; then
				ARR_TEST+=("$STR")
			fi
		done
		case "$2" in
			on)
				echo "> Enabling services..."
				for STR in "${ARR_TEST[@]}"; do
					${MAYBE_SUDO}systemctl enable ${STR}.service
					${MAYBE_SUDO}systemctl start ${STR}.service
				done
				;;
			off)
				echo "> Disabling services..."
				for STR in "${ARR_TEST[@]}"; do
					${MAYBE_SUDO}systemctl stop ${STR}.service
					${MAYBE_SUDO}systemctl disable ${STR}.service
				done
				;;
		esac
		sleep 1
		echo "> $1 is now $2. This will persist after rebooting."
		;;

	overclock)
		FILESIZE="$(get_file_size "$PI_FILE_CONFIG")"
		ARR_TEST=(
			"arm_boost=1"
			"gpu_freq=600"
			"over_voltage=5"
		)
		case "$2" in
			on)
				for STR in "${ARR_TEST[@]}"; do
					file_add_line_config_after_all "$STR"
				done
				;;
			off)
				for STR in "${ARR_TEST[@]}"; do
					file_comment_line "$PI_FILE_CONFIG" "$STR" "sudo"
				done
				;;
		esac
		sleep 1
		if [ ! "$FILESIZE" = "$(get_file_size "$PI_FILE_CONFIG")" ]; then
			echo "> Updated '$(basename "$PI_FILE_CONFIG")'."
		fi
		echo "> $1 will be $2 after rebooting."
		;;

	video)
		FILESIZE_CONFIG="$(get_file_size "$PI_FILE_CONFIG")"
		FILESIZE_RCLOCAL="$(get_file_size "$PI_FILE_RCLOCAL")"
		case "$2" in
			on)
				# sdtv_mode=18
				if ! file_contains_line "$PI_FILE_CONFIG" "sdtv_mode=18"; then
					if [ "$(get_system)" = "Darwin" ]; then
						${MAYBE_SUDO}sed -i '' -E "s/sdtv_mode=[0-9]*/sdtv_mode=18/g" "$PI_FILE_CONFIG"
					else
						${MAYBE_SUDO}sed -i -E "s/sdtv_mode=[0-9]*/sdtv_mode=18/g" "$PI_FILE_CONFIG"
					fi
					file_add_line_config_after_all "sdtv_mode=18"
				fi
				# rc.local
				if is_which "tvservice"; then
					file_comment_line "$PI_FILE_RCLOCAL" "tvservice -o" "sudo"
					if is_opengl_legacy; then
						tvservice -p
					fi
				elif is_which "xset"; then
					file_comment_line "$PI_FILE_RCLOCAL" "xset dpms force off" "sudo"
					xset dpms force on
				fi
				if is_vcgencmd_working; then
					file_comment_line "$PI_FILE_RCLOCAL" "vcgencmd display_power 0" "sudo"
					vcgencmd display_power 1
				fi
				;;
			off)
				# comment sdtv_mode
				file_replace_line "$PI_FILE_CONFIG" "(sdtv_mode=[0-9]*)" "#\1" "sudo"
				# rc.local
				if is_which "tvservice"; then
					file_add_line_rclocal_before_exit "tvservice -o"
					if is_opengl_legacy; then
						tvservice -o
					fi
				elif is_which "xset"; then
					file_add_line_rclocal_before_exit "xset dpms force off"
					xset dpms force off
				fi
				if is_vcgencmd_working; then
					file_add_line_rclocal_before_exit "vcgencmd display_power 0"
					vcgencmd display_power 0
				fi
				;;
		esac
		sleep 1
		if [ ! "$FILESIZE_CONFIG" = "$(get_file_size "$PI_FILE_CONFIG")" ]; then
			echo "> Updated '$(basename "$PI_FILE_CONFIG")'."
		fi
		if [ ! "$FILESIZE_RCLOCAL" = "$(get_file_size "$PI_FILE_RCLOCAL")" ]; then
			echo "> Updated '$(basename "$PI_FILE_RCLOCAL")'."
		fi
		echo "> $1 is now $2. This will persist after rebooting."
		;;

	wifi)
		case "$2" in
			on)
				file_comment_line "$PI_FILE_CONFIG" "dtoverlay=disable-wifi" "sudo"
				;;
			off)
				STR_TEST="$(ifconfig | grep wlan)"
				if [ ! "$STR_TEST" = "" ]; then
					file_add_line_config_after_all "dtoverlay=disable-wifi"
				fi
				;;
		esac
		echo "> $1 will be $2 after rebooting."
		;;

	*)
		echo "Error in $0 on line $LINENO. Exiting..."
		exit 1
		;;
esac

exit 0
