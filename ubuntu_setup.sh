#!/bin/bash

DATA="$HOME/usr/data"
BASH="$HOME/.bashrc"
VIMRC="$HOME/.vimrc"
SSL_CERT1="/etc/ssl/certs/ca-certificates.crt"
SSL_CERT2="/home/prado/.local/lib/python3.5/site-packages/pip/_vendor/certifi/cacert.pem"

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

sudo apt install -y autoconf autopoint ctags cscope gitk vim

# useful tools
sudo apt install -y trash-cli curl lynx
sudo apt install -y openssh-server # For using PuTTY & WinSCP in Windows

# Useful Applications
sudo apt install -y chromium-browser gnome-tweak-tool unity-tweak-tool

# For ssl certification
sed -e "s/\r//g" $DATA/SRnD_Web_Proxy.crt >> $SSL_CERT1
echo "" >> $SSL_CERT1
sed -e "s/\r//g" $DATA/SRnD_Web_Proxy.crt >> $SSL_CERT2
echo "" >> $SSL_CERT2

# meson - Updated on Ubuntu 16.04
sudo apt install -y python-pip python3-pip
pip3 install meson

# PATH
PATH_SYM="# Prado's PATH"
grep "${PATH_SYM}" $BASH > /dev/null 2>&1
if [ $? -ne 0  ]; then
    echo "" >> $BASH
    echo "${PATH_SYM}" >> $BASH
    echo "PATH=\$PATH:\$HOME/usr/bin" >> $BASH
fi

# Aliases
ALIAS_SYM="# Prado's Aliases"
grep "${ALIAS_SYM}" $BASH > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "" >> $BASH
    echo "${ALIAS_SYM}" >> $BASH
    echo "alias vi='vim'" >> $BASH
fi

# GIT PROMPT
GIT_PROMPT_SYM="# For GIT Prompt"
grep "${GIT_PROMPT_SYM}" $BASH > /dev/null 2>&1
if [ $? -ne 0 ]; then
    # install bash-git-prompt
    if [ ! -d $HOME/.bash-git-prompt ]; then
        git clone https://github.com/magicmonty/bash-git-prompt.git ~/.bash-git-prompt
    fi

    echo "" >> $BASH
    echo "${GIT_PROMPT_SYM}" >> $BASH
    echo "GIT_PROMPT_ONLY_IN_REPO=1" >> ~/.bashrc
    echo "source ~/.bash-git-prompt/gitprompt.sh" >> ~/.bashrc
fi

# Disabled : 2019-03-05
# install awesome_vimrc
# if [ ! -d $HOME/.vim_runtime ]; then
#     git clone --depth=1 https://github.com/amix/vimrc.git ~/.vim_runtime
#     sh ~/.vim_runtime/install_awesome_vimrc.sh
# fi

# Update .vimrc
curl 'http://vim-bootstrap.com/generate.vim' --data 'langs=c&langs=python&langs=javascript&langs=html&editor=vim' > $VIMRC

MY_CONFIGURATION_SYM="\" My configuration"
grep "${MY_CONFIGURATION_SYM}" $VIMRC > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "" >> $VIMRC
    echo $MY_CONFIGURATION_SYM >> $VIMRC
    echo "set updatetime=500" >> $VIMRC
    echo "nnoremap <silent> <F5> :set ts=8 sw=3 sts=3 expandtab cino=>5n-3f0^-2{2(0W1st0)}<CR>" >> $VIMRC
    echo "nnoremap <silent> <F6> :set autoindent noexpandtab tabstop=4 shiftwidth=4<CR>" >> $VIMRC
fi

# For cscope shorcut 'cscope_macros.vim'
# Make sure there is plugin directory for vim and download 'cscope_macros.vim'
if [ ! -d $HOME/.vim/plugin ]; then
    mkdir -p $HOME/.vim/plugin
fi

curl 'https://www.vim.org/scripts/download_script.php?src_id=171' > ~/.vim/plugin/cscope_macros.vim

# Reactive bashrc
source ~/.bashrc

# For hangul
# http://hochulshin.com/ubuntu-1604-hangul/

# Add for Ubuntu 18.04

# For adding shotcut for workspace
sudo apt install -y xdotool

sudo apt install -y net-tools
