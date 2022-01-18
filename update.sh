#!/bin/bash

# import vars
DIRNAME=`dirname "$0"`
CMD_TEST=`readlink "$0"`
if [ ! "$CMD_TEST" = "" ]; then
    DIRNAME=`dirname "$CMD_TEST"`
fi
if [ -f "$DIRNAME/halftheory_vars.sh" ]; then
    . $DIRNAME/halftheory_vars.sh
else
	echo "Error in $0 on line $LINENO. Exiting..."
    exit 1
fi

# prompt to continue
read -p "> Continue update? [y]: " PROMPT_TEST
PROMPT_TEST=${PROMPT_TEST:-y}
if [ ! "$PROMPT_TEST" = "y" ]; then
	exit 0
fi

# functions
function halftheory_uninstall()
{
	if [ -f "$DIRNAME/install.sh" ]; then
		chmod $CHMOD_FILES $DIRNAME/install.sh
		chmod +x $DIRNAME/install.sh
		$DIRNAME/install.sh -uninstall
		return 0
	fi
	return 1
}
function halftheory_install()
{
	if [ -f "$DIRNAME/install.sh" ]; then
		chmod $CHMOD_FILES $DIRNAME/install.sh
		chmod +x $DIRNAME/install.sh
		$DIRNAME/install.sh
		return 0
	fi
	return 1
}

# git
if [ -d "$DIRNAME/.git" ]; then
	if maybe_install "git"; then
		halftheory_uninstall
		git fetch
		git pull
		if halftheory_install; then
			echo "> Updated."
			exit 0
		fi
	fi
fi

# wget
if maybe_install "wget"; then
	wget -q https://github.com/halftheory/sh-halftheory-pi/archive/refs/heads/main.zip
	sleep 1
	if [ -f "main.zip" ]; then
		if is_which "unzip"; then
			unzip -oq main.zip -d $DIRNAME
		else
			tar vxfz main.zip -C $DIRNAME
		fi
		if [ -d "$DIRNAME/sh-halftheory-pi-main" ]; then
			halftheory_uninstall
			cp -Rf $DIRNAME/sh-halftheory-pi-main/ $DIRNAME/
			rm -Rf $DIRNAME/sh-halftheory-pi-main
			if halftheory_install; then
				echo "> Updated."
			fi
		fi
		rm -f main.zip
		exit 0
	fi
fi

exit 0
