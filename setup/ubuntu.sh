#!/bin/bash

# Required version 16.04 or later.
function ask_yes_no ()
{
    local yn=

    while [ "$yn" = "" ]; do
        echo -en "$1"
        read yn
        case $yn in
            y|Y)    yn=0 ;;
            n|N)    yn=1 ;;
            *)      yn=
                    echo "Invalid response - please answer y or n"
                    ;;
        esac
    done
    return $yn
}

# Build essential
sudo apt update

if ask_yes_no "Do you want to execute command 'apt upgrade'? [y/n]"; then
    sudo apt upgrade
fi

sudo apt install autoconf autopoint ctags cscope gitk vim

# useful tools
sudo apt install trash-cli lynx
sudo apt install openssh-server # For using PuTTY in Windows

# Aliases
ALIAS_SYM="# Prado's Aliases"
grep "${ALIAS_SYM}" $HOME/.bashrc
if [ $? -ne 0 ]; then
    echo "" >> $HOME/.bashrc
    echo ${ALIAS_SYM} >> $HOME/.bashrc
    echo "alias vi='vim'" >> $HOME/.bashrc
fi

# meson - Updated on Ubuntu 16.04
sudo apt install python3-pip
pip3 install meson

GIT_PROMPT_SYM="# For GIT Prompt"
grep "${GIT_PROMPT_SYM}" $HOME/.bashrc
if [ $? -ne 0 ]; then
    # install bash-git-prompt
    if [ ! -d $HOME/.bash-git-prompt ]; then
        git clone https://github.com/magicmonty/bash-git-prompt.git ~/.bash-git-prompt
    fi

    echo "" >> $HOME/.bashrc
    echo "${GIT_PROMPT_SYM}" >> $HOME/.bashrc
    echo "GIT_PROMPT_ONLY_IN_REPO=1" >> ~/.bashrc
    echo "source ~/.bash-git-prompt/gitprompt.sh" >> ~/.bashrc
fi

# install awesome_vimrc
if [ ! -d $HOME/.vim_runtime ]; then
    git clone --depth=1 https://github.com/amix/vimrc.git ~/.vim_runtime
    sh ~/.vim_runtime/install_awesome_vimrc.sh
fi

# Reactive bashrc
source ~/.bashrc
