#!/bin/bash

# NOTE: Only on Ubuntu 16.04

sudo apt install -y minicom

grep "# For Tizen" /etc/apt/sources.list > /dev/null 2>&1
if [ $? -ne 0 ]; then
    sudo sh -c 'echo "# For Tizen" >> /etc/apt/sources.list'
    sudo sh -c 'echo "deb [trusted=yes] http://download.tizen.org/tools/latest-release/Ubuntu_16.04/ /" >> /etc/apt/sources.list'
fi

# For Tizen-Studio
grep "# For Tizen-Studio" /etc/apt/sources.list > /dev/null 2>&1
if [ $? -ne 0 ]; then
    sudo sh -c 'echo "# For Tizen-Studio" >> /etc/apt/sources.list'
    sudo sh -c 'echo "deb http://security.ubuntu.com/ubuntu xenial-security main'
fi

sudo apt update && sudo apt install -y gbs mic lthor

# For Tizen-Studio
sudo apt install -y libpng12-0

# For Tizen-IDE
# wget https://developer.tizen.org/development/tizen-studio/download
sudo apt install -y default-jdk libwebkitgtk-1.0-0
sudo apt install -y bridge-utils openvpn

# Register Tizen source repository to PATH environment
TIZEN_PATH=$HOME/repos/tizen
UIFW_PATH=$TIZEN_PATH/uifw
DM_PATH=$UIFW_PATH/display-manager
DS_PATH=$UIFW_PATH/display-server

echo "" >> $HOME/.bashrc
echo "# For Tizen repository" >> $HOME/.bashrc
echo "TIZEN_PATH=${TIZEN_PATH}" >> $HOME/.bashrc
echo "UIFW_PATH=${UIFW_PATH}" >> $HOME/.bashrc
echo "DM_PATH=${DM_PATH}" >> $HOME/.bashrc
echo "DS_PATH=${DS_PATH}" >> $HOME/.bashrc

source ~/.bashrc

mkdir -p ${TIZEN_PATH}
mkdir -p ${UIFW_PATH}
mkdir -p ${DM_PATH}
mkdir -p ${DS_PATH}

CLONE="git clone"

pushd $DM_PATH
if [ ! -d libtbm ]; then
    $CLONE ssh://shiin@review.tizen.org:29418/platform/core/uifw/libtbm
fi

if [ ! -d libtdm ]; then
    $CLONE ssh://shiin@review.tizen.org:29418/platform/core/uifw/libtdm
fi
ctags -R
find ./ -name *.[chx] -print > cscope.files
popd

pushd $DS_PATH
if [ ! -d enlightenment ]; then
    $CLONE ssh://shiin@review.tizen.org:29418/platform/upstream/enlightenment
fi

if [ ! -d e-mod-tizen-wm-policy ]; then
    $CLONE ssh://shiin@review.tizen.org:29418/platform/core/uifw/e-mod-tizen-wm-policy
fi

if [ ! -d e-mod-tizen-wl-textinput ]; then
    $CLONE ssh://shiin@review.tizen.org:29418/platform/core/uifw/e-mod-tizen-wl-textinput
fi

if [ ! -d pepper ]; then
    $CLONE ssh://shiin@review.tizen.org:29418/platform/core/uifw/pepper
fi

if [ ! -d libpepper-efl ]; then
    $CLONE ssh://shiin@review.tizen.org:29418/platform/core/uifw/libpepper-efl
fi
ctags -R
find ./ -name *.[chx] -print > cscope.files
popd

pushd $UIFW_PATH
if [ ! -d wayland ]; then
    $CLONE ssh://shiin@review.tizen.org:29418/platform/upstream/wayland
fi

if [ ! -d wayland-extension ]; then
    $CLONE ssh://shiin@review.tizen.org:29418/platform/core/uifw/wayland-extension
fi

if [ ! -d wayland-tbm ]; then
    $CLONE ssh://shiin@review.tizen.org:29418/platform/core/uifw/wayland-tbm
fi

if [ ! -d libtpl-egl ]; then
    $CLONE ssh://shiin@review.tizen.org:29418/platform/core/uifw/libtpl-egl
fi

if [ ! -d efl ]; then
    $CLONE ssh://shiin@review.tizen.org:29418/platform/upstream/efl
fi
ctags -R
find ./ -name *.[chx] -print > cscope.files
popd
