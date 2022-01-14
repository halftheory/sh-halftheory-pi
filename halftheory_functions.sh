#!/bin/bash

# functions

function check_remote_host()
{
    # HOST
	if [ -z $1 ]; then
        return 1
	fi
    CMD_TEST=`ping -c1 $1 2>&1 | grep cannot`
    if [ ! "$CMD_TEST" = "" ]; then
        return 1
    fi
    CMD_TEST=`ping -c1 $1 2>&1 | grep sendto`
    if [ ! "$CMD_TEST" = "" ]; then
        return 1
    fi
    return 0
}

function cmd_ssh()
{
    # HOST USER [PASS] [PORT]
	if [ -z $2 ]; then
        return 1
    fi
    MY_HOST=$1
    MY_USER=$2
    MY_PASS=""
	if [ $3 ]; then
		MY_PASS=$3
	fi
    MY_PORT=""
	if [ $4 ]; then
		MY_PORT=$4
	fi
    if [ ! "$MY_PORT" = "" ]; then
        echo "$(maybe_sshpass "$MY_PASS")ssh $MY_USER@$MY_HOST -p $MY_PORT"
        return 0
    else
        echo "$(maybe_sshpass "$MY_PASS")ssh $MY_USER@$MY_HOST"
        return 0
    fi
    return 1
}

function get_file_grp()
{
    # FILE
    if [ -z $1 ]; then
        return 1
    fi
    if [ ! -e "$1" ]; then
        return 1
    fi
    if [ $(get_system) = "Darwin" ]; then
        CMD_TEST=`stat -Lf '%Sg' $1`
    else
        CMD_TEST=`stat -Lc %G $1`
    fi
    if [ ! "$CMD_TEST" = "" ]; then
        echo $CMD_TEST
        return 0
    fi
    return 1
}

function get_file_own()
{
    # FILE
    if [ -z $1 ]; then
        return 1
    fi
    if [ ! -e "$1" ]; then
        return 1
    fi
    if [ $(get_system) = "Darwin" ]; then
        CMD_TEST=`stat -Lf '%Su' $1`
    else
        CMD_TEST=`stat -Lc %U $1`
    fi
    if [ ! "$CMD_TEST" = "" ]; then
        echo $CMD_TEST
        return 0
    fi
    return 1
}

function get_hostname()
{
	STR_TEST="localhost"
	if [ -f "/etc/hostname" ]; then
		read -r STR_TEST < /etc/hostname
	fi
	echo $STR_TEST
	exit 0
}

function get_macos_version()
{
	if is_which "sw_vers"; then
	    CMD_TEST=`sw_vers | grep ProductVersion`
	    if [ ! "$CMD_TEST" = "" ]; then
			echo ${CMD_TEST##*ProductVersion:}
			exit 0
	    fi
    fi
	exit 1
}

function get_os_version()
{
	if [ -f "/etc/debian_version" ]; then
		read -r STR_TEST < /etc/debian_version
		echo $STR_TEST
		exit 0
	fi
	if [ -f "/etc/os-release" ]; then
	    CMD_TEST=`cat /etc/os-release | grep VERSION_ID=`
	    if [ ! "$CMD_TEST" = "" ]; then
			CMD_TEST=${CMD_TEST##*VERSION_ID=\"}
			CMD_TEST=${CMD_TEST%\"}
			echo $CMD_TEST
			exit 0
	    fi
	fi
	if [ $(get_system) = "Darwin" ]; then
		echo "$(get_macos_version)"
		exit 0
	fi
	exit 1
}

function get_os_version_id()
{
	if [ -f "/etc/os-release" ]; then
	    CMD_TEST=`cat /etc/os-release | grep VERSION_ID=`
	    if [ ! "$CMD_TEST" = "" ]; then
			CMD_TEST=${CMD_TEST##*VERSION_ID=\"}
			CMD_TEST=${CMD_TEST%\"}
			echo $CMD_TEST
			exit 0
	    fi
	fi
	if [ -f "/etc/debian_version" ]; then
		read -r STR_TEST < /etc/debian_version
		echo ${STR_TEST%%.*}
		exit 0
	fi
	if [ $(get_system) = "Darwin" ]; then
		STR_TEST="$(get_macos_version)"
		echo ${STR_TEST%%.*}
		exit 0
	fi
	exit 1
}

function get_system()
{
	STR_TEST="Linux"
    CMD_TEST=`uname -s`
    if [ ! "$CMD_TEST" = "" ]; then
		STR_TEST="${CMD_TEST%% *}"
    fi
	echo $STR_TEST
	exit 0
}

function is_int()
{
    # VALUE
    if [ -z $1 ]; then
        return 1
    fi
    if [ "${1//[0-9]/}" = "" ]; then
        return 0
    fi
    return 1
}

function is_sudo()
{
    # [USER]
    if [ $1 ]; then
        MY_USER=$1
    else
    	MY_USER=$(get_file_own $0)
    fi
    if [ "$MY_USER" = "root" ]; then
        return 0
    fi
    return 1
}

function is_which()
{
    # APP
    if [ -z $1 ]; then
        return 1
    fi
    CMD_TEST=`which $1 2>&1 | grep $1`
    if [ ! "$CMD_TEST" = "" ]; then
        return 0
    fi
    return 1
}

function maybe_sshpass()
{
    # PASS
    if [ -z $1 ]; then
        return 1
    fi
    if is_which "sshpass" && [ ! "$1" = "" ]; then
        echo "sshpass -p $1 "
        return 0
    fi
    return 1
}

function maybe_sudo()
{
    # [USER]
    if [ $1 ]; then
        MY_USER=$1
    else
    	MY_USER=$(get_file_own $0)
    fi
    if ! is_sudo "$MY_USER"; then
        echo "sudo "
        return 0
    fi
    return 1
}

function remote_file_exists()
{
    # FILE HOST USER [PASS] [PORT]
    if [ -z $3 ]; then
        return 1
    fi
    MY_FILE=$1
    MY_HOST=$2
    MY_USER=$3
    MY_PASS=""
	if [ $4 ]; then
		MY_PASS=$4
	fi
    MY_PORT=""
	if [ $5 ]; then
		MY_PORT=$5
	fi
    STR_TEST=$(cmd_ssh "$MY_HOST" "$MY_USER" "$MY_PASS" "$MY_PORT")
    if [ ! "$STR_TEST" = "" ]; then
        CMD_TEST=`$STR_TEST "ls $MY_FILE 2>&1 | grep cannot"`
        if [ ! "$CMD_TEST" = "" ]; then
            return 1
        fi
        return 0
    fi
    return 1
}
