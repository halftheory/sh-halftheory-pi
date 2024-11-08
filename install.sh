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

STR_ARG="-install"
if has_arg "$*" "-uninstall"; then
	STR_ARG="-uninstall"
fi

# prompt
if ! has_arg "$*" "-force"; then
	if ! prompt "Continue $STR_ARG"; then
		exit 0
	fi
fi

# loop through *.sh
IFS_OLD="$IFS"
IFS="," read -r -a ARR_TEST <<< "$(get_file_list_csv $DIRNAME/*.sh)"
IFS="$IFS_OLD"
for FILE in "${ARR_TEST[@]}"; do
	STR_BASENAME="$(basename "$FILE")"
	if [[ "$STR_BASENAME" = halftheory_* ]]; then
		chmod $CHMOD_FILE "$FILE"
		continue
	fi
	chmod $CHMOD_X "$FILE"
	if [[ "$STR_BASENAME" = install* ]] || [[ "$STR_BASENAME" = update* ]]; then
		continue
	fi
	echo "> $STR_BASENAME"
	eval "$(quote_string_with_spaces "$FILE") $STR_ARG"
done

if [ -f "$FILE_ENV" ]; then
	chmod $CHMOD_FILE "$FILE_ENV"
fi

exit 0
