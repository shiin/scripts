#!/bin/bash

source ../helper.sh

SDB_SHELL="sdb -d shell"
DINFO_FILE="/etc/tizen-build.conf"

function query_pkg()
{
   #####
   #     Function to check if given package is existed.
   #     Arguments:
   #           1        The name of package to check
   #####
   local res=
   res=`${SDB_SHELL} rpm -qa ${1}`
   [[ -z ${res} ]] && return 1 || return 0
}

function get_model()
{
   #####
   #     Function to get device model
   #     No Arguments
   #####

   echo `${SDB_SHELL} "cat ${DINFO_FILE}" | grep TZ_BUILD_PROFILE | awk -F '[=]' '{print $2}' | tr -d [:space:]`
}

function get_arch()
{
   #####
   #     Function to get device arch
   #     No Arguments
   #####

   echo `${SDB_SHELL} "cat ${DINFO_FILE}" | grep TZ_BUILD_ARCH | awk -F '[=]' '{print $2}' | tr -d [:space:]`
}

function get_sub_arch()
{
   #####
   #     Function to get device sub arch
   #     No Arguments
   #####

   echo `${SDB_SHELL} "uname -m" | tr -d [:space:]`
}

function get_profile()
{
   #####
   #     Function to get device profile
   #     No Arguments
   #####
   echo `${SDB_SHELL} "cat ${DINFO_FILE}" | grep TZ_BUILD_PROFILE | awk -F '[=]' '{print $2}' | tr -d [:space:]`

}

function get_snapshot_url()
{
   #####
   #     Function to get device profile
   #     No Arguments
   #####
   echo `${SDB_SHELL} "cat ${DINFO_FILE}" | grep TZ_BUILD_SNAPSHOT_URL | awk -F '[=/]' '{ for(i=3;i<NF;i++) printf "%s", $i"/" }'`
}
