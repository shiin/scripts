#!/bin/bash

# Make sure only root can run our script
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

sudo ifconfig enx000acd2945b8 down
sudo ifconfig enx000acd2945b8 192.168.250.1 up
/home/prado/tizen-studio/tools/sdb connect 192.168.250.250
