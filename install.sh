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

STR_ARG="-install"
if [ $1 ]; then
	if [ "$1" = "-uninstall" ]; then
		STR_ARG="-uninstall"
	fi
fi

# loop through *.sh
LIST=$(get_file_list_csv $DIRNAME/*.sh)
IFS_OLD=$IFS
IFS=","
for FILE in $LIST; do
	chmod $CHMOD_FILES $FILE
	# skip
	if [[ $FILE = *halftheory_functions* ]] || [[ $FILE = *halftheory_vars* ]]; then
		continue
	fi
	chmod +x $FILE
	if [[ $FILE = *install* ]] || [[ $FILE = *update* ]]; then
		continue
	fi
	echo "> $(basename "$FILE")"
	$FILE $STR_ARG
done
IFS=$IFS_OLD

exit 0
