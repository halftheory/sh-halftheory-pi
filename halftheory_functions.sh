#!/bin/bash

# hostname
HOSTNAME="localhost"
if [ -f "/etc/hostname" ]; then
	read -r HOSTNAME < /etc/hostname
fi

# functions
function get_file_own()
{
    # FILE
    if [ -z $1 ]; then
        return 1
    fi
    if [ ! -e "$1" ]; then
        return 1
    fi
    # TODO: check Linux/Darwin.
    if [ "$HOSTNAME" = "localhost" ]; then
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

function get_file_grp()
{
    # FILE
    if [ -z $1 ]; then
        return 1
    fi
    if [ ! -e "$1" ]; then
        return 1
    fi
    # TODO: check Linux/Darwin.
    if [ "$HOSTNAME" = "localhost" ]; then
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

function set_local_owngrp()
{
    if [ -z $0 ]; then
        return 1
    fi
    STR_TEST=$(get_file_own $0)
    if [ ! "$STR_TEST" = "" ]; then
        set_var "$HOSTNAME" "OWN_LOCAL" "$STR_TEST"
    fi
    STR_TEST=$(get_file_grp $0)
    if [ ! "$STR_TEST" = "" ]; then
        set_var "$HOSTNAME" "GRP_LOCAL" "$STR_TEST"
    fi
    return 0
}

function is_sudo()
{
    # [USER]
    MY_USER=$(get_file_own $0)
    if [ $1 ]; then
        MY_USER=$1
    fi
    if [ "$MY_USER" = "root" ]; then
        return 0
    fi
    return 1
}

function maybe_sudo()
{
    # [USER]
    MY_USER=$(get_file_own $0)
    if [ $1 ]; then
        MY_USER=$1
    fi
    if ! is_sudo "$MY_USER"; then
        echo "sudo "
        return 0
    fi
    return 1
}

function maybe_sshpass()
{
    # [PASS]
    MY_PASS=$(get_var "SSH_PASS" "halftheory")
    if [ $1 ]; then
        MY_PASS=$1
    fi
    CMD_TEST=`which sshpass 2>&1 | grep sshpass`
    if [ ! "$CMD_TEST" = "" ] && [ ! "$MY_PASS" = "" ]; then
        echo "sshpass -p $MY_PASS "
        return 0
    fi
    return 1
}

function cmd_ssh()
{
    # [HOSTNAME]
    MY_HOSTNAME="halftheory"
    if [ $1 ]; then
        MY_HOSTNAME=$1
    fi
    MY_HOST=$(get_var "SSH_HOST" "$MY_HOSTNAME")
    MY_PORT=$(get_var "SSH_PORT" "$MY_HOSTNAME")
    MY_USER=$(get_var "SSH_USER" "$MY_HOSTNAME")
    MY_PASS=$(get_var "SSH_PASS" "$MY_HOSTNAME")
    if [ ! "$MY_USER" = "" ] && [ ! "$MY_HOST" = "" ] && [ ! "$MY_PORT" = "" ]; then
        echo "$(maybe_sshpass "$MY_PASS")ssh $MY_USER@$MY_HOST -p $MY_PORT"
        return 0
    elif [ ! "$MY_USER" = "" ] && [ ! "$MY_HOST" = "" ]; then
        echo "$(maybe_sshpass "$MY_PASS")ssh $MY_USER@$MY_HOST"
        return 0
    fi
    return 1
}

function remote_file_exists()
{
    # FILE [HOSTNAME]
    if [ -z $1 ]; then
        return 1
    fi
    MY_HOSTNAME="halftheory"
    if [ $2 ]; then
        MY_HOSTNAME=$2
    fi
    STR_TEST=$(cmd_ssh "$MY_HOSTNAME")
    if [ ! "$STR_TEST" = "" ]; then
        CMD_TEST=`$STR_TEST "ls $1 2>&1 | grep cannot"`
        if [ ! "$CMD_TEST" = "" ]; then
            return 1
        fi
        return 0
    fi
    return 1
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

function which()
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
