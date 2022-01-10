#!/bin/bash

# install:
# touch /home/pi/halftheory_renice.sh
# pico /home/pi/halftheory_renice.sh
# chmod +x /home/pi/halftheory_renice.sh
# sudo ln -s /home/pi/halftheory_renice.sh /bin/halftheory_renice
# sudo crontab -e
# @reboot halftheory_renice [process] > /dev/null 2>&1

if [ $1 ]; then
	LAST_PID=0
	echo "> Listening for $1..."
	while [ 1 ]; do
		PROCESS_PID=`pidof $1`
		if [ "$PROCESS_PID" = "" ]; then
			LAST_PID=0
		else
			if [ ! "$PROCESS_PID" = $LAST_PID ]; then
				sudo renice -n -20 -p $PROCESS_PID > /dev/null 2>&1
				LAST_PID=$PROCESS_PID
				echo "> $1 is now top priority..."
			fi
		fi
		#echo $LAST_PID
		sleep 60
	done;
else
	echo "> Usage: sudo $0 [process]"
fi