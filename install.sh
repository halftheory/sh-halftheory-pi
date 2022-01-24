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

STR_ARG="-install"
if [ $1 ] && [ "$1" = "-uninstall" ]; then
	STR_ARG="-uninstall"
fi

# loop through *.sh
DIRNAME="$(get_realpath "$DIRNAME")"
LIST="$(get_file_list_csv $DIRNAME/*.sh)"
ARR_TEST=()
IFS_OLD="$IFS"
IFS="," read -r -a ARR_TEST <<< "$LIST"
IFS="$IFS_OLD"
for FILE in "${ARR_TEST[@]}"; do
	chmod $CHMOD_FILES $FILE
	# skip
	if [[ "$FILE" = *halftheory_functions* ]] || [[ "$FILE" = *halftheory_vars* ]]; then
		continue
	fi
	chmod +x $FILE
	if [[ "$FILE" = *install* ]] || [[ "$FILE" = *update* ]]; then
		continue
	fi
	echo "> $(basename "$FILE")"
	CMD_TEST="$FILE $STR_ARG"
	eval "$CMD_TEST"
done

exit 0
