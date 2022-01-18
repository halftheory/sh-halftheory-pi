#!/bin/bash

# import functions
DIRNAME=`dirname "$0"`
CMD_TEST=`readlink "$0"`
if [ ! "$CMD_TEST" = "" ]; then
	DIRNAME=`dirname "$CMD_TEST"`
fi
if [ -f "$DIRNAME/halftheory_functions.sh" ]; then
	. $DIRNAME/halftheory_functions.sh
else
	echo "Error in $0 on line $LINENO. Exiting..."
	exit 1
fi

# vars
MAYBE_SUDO=$(maybe_sudo)
OWN_LOCAL=$(whoami)
GRP_LOCAL=$(get_file_grp $0)
DIR_LOCAL=$(get_user_dir "$OWN_LOCAL")
CHMOD_DIRS="755"
CHMOD_FILES="644"
CHMOD_UPLOADS="777"
DIR_SCRIPTS="/usr/local/bin"
FILE_CONFIG="/boot/config.txt"
FILE_RCLOCAL="/etc/rc.local"

# functions

function is_opengl_legacy()
{
	if file_contains_line "$FILE_CONFIG" "dtoverlay=vc4-kms-v3d"; then
		return 1
	fi
	return 0
}
