#!/bin/bash

# install:
# touch /home/pi/halftheory_config.sh
# pico /home/pi/halftheory_config.sh
# chmod +x /home/pi/halftheory_config.sh
# sudo ln -s /home/pi/halftheory_config.sh /bin/halftheory_config
# check for multiple "exit 0" strings in /etc/rc.local

show_info=0

if [ $1 ]; then
	case $1 in
		"audio")
		echo "> Updating config..."
		sudo sed -i.bak "/audio_pwm_mode=2/d" /boot/config.txt
		case $2 in
			"on")
			sudo sed -i.bak 's/dtparam=audio=off/dtparam=audio=on/g' /boot/config.txt
			echo "audio_pwm_mode=2" | sudo tee -a /boot/config.txt > /dev/null 2>&1
			;;
			"off")
			sudo sed -i.bak 's/dtparam=audio=on/dtparam=audio=off/g' /boot/config.txt
			;;
		esac
		echo "> $1 will be $2 after rebooting."
		;;

		"bluetooth")
		echo "> Updating config..."
		sudo sed -i.bak "/dtoverlay=pi3-disable-bt/d" /boot/config.txt
		case $2 in
			"on")
			echo "> Enabling services..."
			sudo systemctl enable bluetooth
			sudo systemctl enable hciuart
			;;
			"off")
			echo "> Disabling services..."
			sudo systemctl disable bluetooth
			sudo systemctl disable hciuart
			echo "dtoverlay=pi3-disable-bt" | sudo tee -a /boot/config.txt > /dev/null 2>&1
			;;
		esac
		echo "> $1 will be $2 after rebooting."
		;;

		"hdmi")
		sudo sed -i.bak "/\/usr\/bin\/tvservice -o/d" /etc/rc.local
		sudo sed -i.bak "/vcgencmd display_power 0/d" /etc/rc.local
		case $2 in
			"on")
			sudo sed -i.bak 's/[#]*hdmi_force_hotplug=1/hdmi_force_hotplug=1/g' /boot/config.txt
			sudo sed -i.bak 's/[#]*sdtv_mode=[0-9]*/#sdtv_mode=18/g' /boot/config.txt
			vcgencmd display_power 1
			/usr/bin/tvservice -p
			;;
			"off")
			sudo sed -i.bak 's/[#]*hdmi_force_hotplug=1/#hdmi_force_hotplug=1/g' /boot/config.txt
			sudo sed -i.bak 's/[#]*sdtv_mode=[0-9]*/#sdtv_mode=18/g' /boot/config.txt
			/usr/bin/tvservice -o
			vcgencmd display_power 0
			sudo sed -i.bak 's/exit 0/\/usr\/bin\/tvservice -o\nexit 0/g' /etc/rc.local
			sudo sed -i.bak 's/exit 0/vcgencmd display_power 0\nexit 0/g' /etc/rc.local
			;;
		esac
		echo "> $1 is now $2. This will persist after rebooting."
		;;

		"pal")
		sudo sed -i.bak "/\/usr\/bin\/tvservice -o/d" /etc/rc.local
		sudo sed -i.bak "/vcgencmd display_power 0/d" /etc/rc.local
		case $2 in
			"on")
			sudo sed -i.bak 's/[#]*sdtv_mode=[0-9]*/sdtv_mode=18/g' /boot/config.txt
			sudo sed -i.bak 's/[#]*hdmi_force_hotplug=1/#hdmi_force_hotplug=1/g' /boot/config.txt
			vcgencmd display_power 0
			/usr/bin/tvservice -p
			sudo sed -i.bak 's/exit 0/vcgencmd display_power 0\nexit 0/g' /etc/rc.local
			;;
			"off")
			sudo sed -i.bak 's/[#]*sdtv_mode=[0-9]*/#sdtv_mode=18/g' /boot/config.txt
			sudo sed -i.bak 's/[#]*hdmi_force_hotplug=1/hdmi_force_hotplug=1/g' /boot/config.txt
			vcgencmd display_power 1
			/usr/bin/tvservice -p
			;;
		esac
		echo "> $1 is now $2. This will persist after rebooting."
		;;

		"network")
		echo "> Updating config..."
		sudo sed -i.bak "/dtoverlay=pi3-disable-wifi/d" /boot/config.txt
		case $2 in
			"on")
			echo "> Enabling services..."
			sudo systemctl enable networking
			sudo systemctl enable ssh
			sudo systemctl enable smbd
			sudo systemctl enable nmbd
			;;
			"off")
			echo "> Disabling services..."
			sudo systemctl disable nmbd
			sudo systemctl disable smbd
			sudo systemctl disable ssh
			sudo systemctl disable networking
			echo "dtoverlay=pi3-disable-wifi" | sudo tee -a /boot/config.txt > /dev/null 2>&1
			;;
		esac
		echo "> $1 is now $2. This will persist after rebooting."
		;;

		"firewall")
		echo "> Reset firewall..."
		sudo ufw logging off
		sudo ufw --force reset
		case $2 in
			"on")
			echo "> Enabling firewall..."
			sudo ufw allow ssh
			sudo ufw default allow incoming
			sudo ufw default allow outgoing
			sudo ufw deny ftp
			sudo ufw deny http
			sudo ufw deny https
			sudo ufw deny imap
			sudo ufw deny pop3
			sudo ufw deny smtp
			sudo ufw --force enable
			;;
			"off")
			echo "> Disabling firewall..."
			sudo ufw --force disable
			;;
		esac
		echo "> $1 is now $2. This will persist after rebooting."
		;;

		*)
		show_info=1
		;;
	esac
else
	show_info=1
fi

if [ $show_info = 1 ]; then
	echo "Usage:"
	echo "sudo $0 audio on|off"
	echo "sudo $0 bluetooth on|off"
	echo "sudo $0 hdmi on|off"
	echo "sudo $0 pal on|off"
	echo "sudo $0 network on|off"
	echo "sudo $0 firewall on|off"
fi
