#!/bin/bash

# NOTE: Only on Ubuntu 16.04
sudo sh -c 'echo "# For Tizen" >> /etc/apt/sources.list'
sudo sh -c 'echo "deb [trusted=yes] http://download.tizen.org/tools/latest-release/Ubuntu_16.04/ /" >> /etc/apt/sources.list'

sudo apt update && sudo apt install gbs mic lthor sdb

# For Tizen-IDE
# wget https://developer.tizen.org/development/tizen-studio/download
sudo apt install default-jdk libwebkitgtk-1.0-0
sudo apt install bridge-utils openvpn

# Bring Tizen major source
ENLIGHTENMENT_PATH=$HOME/repos/tizen/enlightenment

mkdir -p $ENLIGHTENMENT_PATH

pushd $ENLIGHTENMENT_PATH
git clone ssh://shiin@review.tizen.org:29418/platform/upstream/enlightenment
git clone ssh://shiin@review.tizen.org:29418/platform/core/uifw/e-mod-tizen-wm-policy
git clone ssh://shiin@review.tizen.org:29418/platform/core/uifw/e-mod-tizen-wl-textinput
popd
