#!/bin/bash

sudo apt install vim git gitk

read -p "Enter your name: " NAME
read -p "Enter your email: " EMAIL

# Add user
git config --global user.name $NAME
git config --global user.email $EMAIL

git config --global core.editor vim

echo "== GIT Alias list =="
echo "status -> st"
echo "checkout -> co"
echo "clone -> cl"
echo "branch -> br"
echo "commit -> cm"
echo "commit --amend -> ca"

# alias
git config --global alias.st status
git config --global alias.co checkout
git config --global alias.cl clone
git config --global alias.br branch
git config --global alias.cm commit
git config --global alias.ca "commit --amend"
