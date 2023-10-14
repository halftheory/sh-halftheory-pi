#!/bin/bash

# install:
# chmod 644 halftheory_env.sh
# chmod 644 halftheory_functions.sh

# import functions
CMD_TEST="$(readlink "$0")"
if [ ! "$CMD_TEST" = "" ]; then
	DIRNAME="$(dirname "$CMD_TEST")"
else
	DIRNAME="$(dirname "$0")"
fi
if [ -f "$DIRNAME/halftheory_functions.sh" ]; then
	. $DIRNAME/halftheory_functions.sh
else
	echo "Error in $0 on line $LINENO. Exiting..."
	exit 1
fi

# import environment
DIRNAME="$(get_realpath "$DIRNAME")"
CHMOD_DIR="755"
CHMOD_FILE="644"
CHMOD_0="700"
CHMOD_X="755"
CHMOD_RWX="777"
OWN_LOCAL="$(whoami)"
GRP_LOCAL="$(get_file_grp "$0")"
DIR_HOME="$(get_user_dir "$OWN_LOCAL")"
FILE_ENV="$DIRNAME/.env"
if [ -f "$FILE_ENV" ]; then
	. $FILE_ENV
fi

function file_add_line_env()
{
	# KEY VALUE
	if [ -z $2 ]; then
		return 1
	fi
	if [ ! -f "$FILE_ENV" ]; then
		touch $FILE_ENV
		chmod $CHMOD_FILE "$FILE_ENV"
		echo "> Created file '$FILE_ENV' > Edit this file to change environment variables." >&2
	fi
	local STR_KEY="$1"
	local STR_VALUE="$2"
	if is_int "$STR_VALUE"; then
		local STR_TEST="$STR_KEY=$STR_VALUE"
	else
		local STR_TEST="$STR_KEY=\"$STR_VALUE\""
	fi
	if file_contains_line "$FILE_ENV" "$STR_TEST"; then
		echo "$STR_VALUE"
		return 0
	else
		file_delete_line "$FILE_ENV" "^$STR_KEY=(.*)"
	fi
	if file_add_line "$FILE_ENV" "$STR_TEST"; then
		echo "> Added the following line to $(basename "$FILE_ENV") > $STR_TEST" >&2
		echo "$STR_VALUE"
		return 0
	fi
	return 1
}

function file_add_line_env_prompt()
{
	# KEY [VALUES(csv)] [TYPE=str|dir|file|user|group]
	if [ -z $1 ]; then
		return 1
	fi
	local STR_KEY="$1"
	local STR_VALUE=""
	local STR_TYPE="str"
	if [ $3 ]; then
		STR_TYPE="$3"
	fi
	if [ $2 ]; then
		# convert csv to array
		local ARR_TEST=()
		local IFS_OLD="$IFS"
		IFS="," read -r -a ARR_TEST <<< "$2"
		IFS="$IFS_OLD"
		if [ ! "$ARR_TEST" = "" ]; then
			STR_VALUE="${ARR_TEST[0]}"
			# find the best candidate for the value
			local STR=""
			for STR in "${ARR_TEST[@]}"; do
				case "$STR_TYPE" in
					str)
						break
						;;
					dir)
						if [ -d "$STR" ]; then
							STR_VALUE="$STR"
							break
						fi
						;;
					file)
						if [ -f "$STR" ]; then
							STR_VALUE="$STR"
							break
						fi
						;;
					user)
						if user_exists "$STR"; then
							STR_VALUE="$STR"
							break
						fi
						;;
					group)
						if group_exists "$STR"; then
							STR_VALUE="$STR"
							break
						fi
						;;
					*)
						break
						;;
				esac
			done
		fi
	fi
	# allow user input
	local PROMPT_TEST=""
	read -p "> $STR_KEY=$STR_VALUE [?]: " PROMPT_TEST
	STR_VALUE="${PROMPT_TEST:-$STR_VALUE}"
	if [ "$STR_VALUE" = "" ]; then
		echo "Error in $0 on line $LINENO. Empty values are not allowed. Exiting..." >&2
		exit 1
	fi
	STR_VALUE="$(file_add_line_env "$STR_KEY" "$STR_VALUE")"
	if [ "$STR_VALUE" = "" ]; then
		echo "Error in $0 on line $LINENO. Exiting..." >&2
		exit 1
	fi
	# maybe create the value
	case "$STR_TYPE" in
		str)
			;;
		dir)
			if [ ! -d "$STR_VALUE" ]; then
				read -p "> Create directory? $STR_VALUE [y]: " PROMPT_TEST
				PROMPT_TEST="${PROMPT_TEST:-y}"
				if [ "$PROMPT_TEST" = "y" ]; then
					mkdir -p "$STR_VALUE"
					chmod $CHMOD_DIR "$STR_VALUE"
				fi
			fi
			;;
		file)
			if [ ! -f "$STR_VALUE" ]; then
				read -p "> Create file? $STR_VALUE [y]: " PROMPT_TEST
				PROMPT_TEST="${PROMPT_TEST:-y}"
				if [ "$PROMPT_TEST" = "y" ]; then
					touch "$STR_VALUE"
					chmod $CHMOD_FILE "$STR_VALUE"
				fi
			fi
			;;
		user)
			;;
		group)
			;;
		*)
			;;
	esac
	echo "$STR_VALUE"
	return 0
}

# persistent vars
if [ ! -n "$HOSTNAME" ]; then
	HOSTNAME="$(file_add_line_env_prompt "HOSTNAME" "$(get_hostname)")"
fi
if [ ! -n "$DIR_SCRIPTS" ]; then
	DIR_SCRIPTS="$(file_add_line_env_prompt "DIR_SCRIPTS" "$DIR_HOME/bin,$DIR_HOME/.local/bin,/usr/local/bin,/usr/bin" "dir")"
fi
