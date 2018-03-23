#!/bin/bash

# Required version 16.04 or later.

# Build essential
sudo apt install autoconf autopoint ctags cscope gitk

# useful tools
sudo apt install trash-cli

# meson - Updated on Ubuntu 16.04
sudo apt install python3-pip
pip3 install meson

# Required building EFL library.
sudo apt install ccache libtool check libssl-dev libsystemd-dev libjpeg-dev libglib2.0-dev libgstreamer1.0-dev libluajit-5.1-dev libfreetype6-dev libfontconfig1-dev libfribidi-dev

sudo apt install libx11-dev libxcursor-dev libxrender-dev libxrandr-dev libxfixes-dev libxdamage-dev libxcomposite-dev libxss-dev libxpresent-dev libxext-dev libxinerama-dev libxkbfile-dev libxtst-dev libxcb1-dev libxcb-shape0-dev libxcb-keysyms1-dev libglu1-mesa-dev freeglut3-dev mesa-common-dev libgif-dev libtiff5-dev libpoppler-cpp-dev libspectre-dev libraw-dev librsvg2-dev libcairo2-dev libudev-dev libblkid-dev libmount-dev libdbus-1-dev libpulse-dev libsndfile1-dev libbullet-dev libgstreamer-plugins-base1.0-dev

# install bash-git-prompt
git clone https://github.com/magicmonty/bash-git-prompt.git ~/.bash-git-prompt
echo "GIT_PROMPT_ONLY_IN_REPO=1" >> ~/.bashrc
echo "source ~/.bash-git-prompt/gitprompt.sh" >> ~/.bashrc

# install awesome_vimrc
git clone --depth=1 https://github.com/amix/vimrc.git ~/.vim_runtime
sh ~/.vim_runtime/install_awesome_vimrc.sh

# Reactive bashrc
source ~/.bashrc
