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

# prompt
if ! has_arg "$*" "-force"; then
	if ! prompt "Continue update"; then
		exit 0
	fi
fi

# functions

function scripts_install()
{
	if script_install "$DIRNAME/install.sh"; then
		$DIRNAME/install.sh -install -force
		return 0
	fi
	return 1
}

function scripts_uninstall()
{
	if script_install "$DIRNAME/install.sh"; then
		$DIRNAME/install.sh -uninstall -force
		return 0
	fi
	return 1
}

# git
if [ -d "$DIRNAME/.git" ]; then
	if maybe_install "git"; then
		scripts_uninstall
		(cd "$DIRNAME" && git fetch && git reset --hard HEAD && git pull)
		if scripts_install; then
			echo "> Updated."
			exit 0
		fi
	fi
fi

# wget from github.com
STR_REPO="$(basename "$DIRNAME")"
if [ -n "$GITHUB_HANDLE" ] && [ ! "$STR_REPO" = "" ]; then
	if maybe_install "wget"; then
		wget -q https://github.com/$GITHUB_HANDLE/$STR_REPO/archive/refs/heads/main.zip
		if [ $? -eq 0 ] && [ -f "main.zip" ]; then
			if is_which "unzip"; then
				unzip -oq main.zip -d "$DIRNAME"
			else
				tar vxfz main.zip -C "$DIRNAME"
			fi
			if [ -d "$DIRNAME/${STR_REPO}-main" ]; then
				chmod $CHMOD_DIR "$DIRNAME/${STR_REPO}-main"
				scripts_uninstall
				cp -Rf "$DIRNAME/${STR_REPO}-main/*" "$DIRNAME/"
				rm -Rf "$DIRNAME/${STR_REPO}-main" > /dev/null 2>&1
				if scripts_install; then
					rm -f main.zip > /dev/null 2>&1
					echo "> Updated."
					exit 0
				fi
			fi
			rm -f main.zip > /dev/null 2>&1
		fi
	fi
fi

echo "> Update failed."
exit 1
