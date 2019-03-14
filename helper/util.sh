#!/bin/bash

# The list of function
# _pushd -> silence pushd
# _popd -> silence popd

function _pushd()
{
   pushd $1 > /dev/null
}

function _popd()
{
   popd $1 > /dev/null
}

function die()
{
   echo $@
   exit 1
}

function remove_space()
{
   echo `cat ${1} | tr -d [:space:]`
}

function ask_yes_no
{
   #####
   #     Function to ask a yes/no question
   #     Arguments:
   #           1     prompt string (optional)
   #####

   local yn=

   while [ "$yn" = "" ]; do
      echo -en "$1"
      read yn
      case $yn in
         y|Y)  yn=0 ;;
         n|N)  yn=1 ;;
         *)    yn=
               echo "Invalid response - please answer y or n"
               ;;
      esac
   done
   return $yn
}
