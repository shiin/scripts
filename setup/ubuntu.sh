#!/bin/bash

# Required version 16.04 or later.

# Build essential
sudo apt install autoconf autopoint ctags cscope gitk vim

echo ""
echo "alias vi='vim' >> $HOME/.bashrc"

# useful tools
sudo apt install trash-cli lynx
sudo apt install openssh-server # For using PuTTY in Windows

# meson - Updated on Ubuntu 16.04
sudo apt install python3-pip
pip3 install meson

# install bash-git-prompt
git clone https://github.com/magicmonty/bash-git-prompt.git ~/.bash-git-prompt
echo "GIT_PROMPT_ONLY_IN_REPO=1" >> ~/.bashrc
echo "source ~/.bash-git-prompt/gitprompt.sh" >> ~/.bashrc

# install awesome_vimrc
git clone --depth=1 https://github.com/amix/vimrc.git ~/.vim_runtime
sh ~/.vim_runtime/install_awesome_vimrc.sh

# Reactive bashrc
source ~/.bashrc
