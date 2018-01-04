#!/bin/bash

[ -z "$MAKEFLAGS" ]  && export MAKEFLAGS="-j -l 10"
[ -z "$MAKE" ]       && export MAKE="chrt --idle 0 make"
[ -z "$REPO_DIR" ]    && export REPO_DIR="$HOME/repos/efl"

###
### Functions
###

function _pushd()
{
    pushd $1 > /dev/null
}

function _popd()
{
    popd > /dev/null
}

function die()
{
    echo $@
    exit 1
}

function cleanup()
{
    local repo_path=$1
    local mod_path=$2
    local mod=$3

    [ -d "$repo_path/$mod_path/$mod" ] || return

    echo "Cleanup $mod ..."

    _pushd $repo_path/$mod_path/$mod
    if [ -f Makefile ]; then
        sudo $MAKE uninstall > /dev/null 2>&1
        sudo $MAKE distclean > /dev/null 2>&1
    fi
    rm -rf autom4te.cache
    git clean -dfx > /dev/null 2>&1
    _popd
}

function clone()
{
    local repo_path=$1
    local mod_path=$2
    local mod=$3

    echo "Clone $mod ..."

    local REPO="https://git.enlightenment.org"

    [ -z "$mod_path" ] && GIT_URI=$REPO/$mod".git" || GIT_URI=$REPO/$mod_path/$mod".git"

    git clone $GIT_URI $repo_path/$mod_path/$mod > /dev/null 2>&1 || die "Error cloning $mod from $GIT_URI"
}

function update()
{
    local repo_path=$1
    local mod_path=$2
    local mod=$3

    if [ ! -d "$repo_path/$mod_path/$mod" ]; then
        clone $repo_path $mod_path $mod
        return
    fi

    echo "Update $mod ..."

    _pushd $repo_path/$mod_path/$mod
    git pull --rebase > /dev/null 2>&1
    if [ $? = 1 ]; then
        echo "Failed to update $mod, maybe because of unstaged file..."
        echo -n "Do you want to reset git? (y/n)"
        read input
        case $input in
            Y | y | yes | YES )
                git reset --hard
                git pull --rebase > /dev/null 2>&1
                ;;
            * )
                die "Fisish updating $mod"
                ;;
        esac
    fi
    _popd
}

function prepare_build() {
    [ -z "$PREFIX" ]      && PREFIX="/usr/local"

    local arch=`which arch`
    [ $? -eq 0 ]          && ARCH=`$arch`           || ARCH=""
    [ $ARCH == "x86_64" ] && LIBDIR="$PREFIX/lib64" || LIBDIR="$PREFIX/lib"
    [ $PREFIX == "/usr/local" ] && SYSCONFDIR="/etc"      || SYSCONFDIR="$PREFIX/etc"
    [ $PREFIX == "/usr/local" ] && LOCALSTATEDIR="/var"   || LOCALSTATEDIR="$PREFIX/var"

    export PKG_CONFIG_PATH="$LIBDIR/pkgconfig:$PKG_CONFIG_PATH"
    export LD_LIBRARY_PATH="$LIBDIR:$LD_LIBRARY_PATH"
    export PATH="$PREFIX/bin:$PATH"

    CONFIG_OPTIONS="--prefix=$PREFIX --libdir=$LIBDIR --sysconfdir=$SYSCONFDIR --localstatedir=$LOCALSTATEDIR"

    E_BUILD_FLAGS="-g -O0 -W -Wall -Wextra -march=native -ffast-math -I$PREFIX/include"
    export CC="ccache gcc"
    export CFLAGS="$E_BUILD_FLAGS"
    export CXXFLAGS="$E_BUILD_FLAGS"
    export LDFLAGS="-L$LIBDIR"

    ACLOCAL_INCLUDE_DIR="$PREFIX/share/aclocal"
    [ -d $ACLOCAL_INCLUDE_DIR ] || mkdir -p $ACLOCAL_INCLUDE_DIR > /dev/null 2>&1
    export ACLOCAL="aclocal -I$ACLOCAL_INCLUDE_DIR"
}

function build()
{
    local repo_path=$1
    local mod_path=$2
    local mod=$3
    local mod_config_options=""
    echo "Build $mod ..."

    case $mod in
        efl )
            mod_config_options=""
            #         mod_config_options="--enable-ecore-buffer"
            #         mod_config_options="--enable-ecore-buffer --enable-always-build-examples"
            ;;
        *)
            mod_config_options=""
            ;;
    esac

    _pushd $repo_path/$mod_path/$mod

    [ ! -f Makefile ] && E_NO_CONFIGURE=""
    if [ -z "$E_NO_CONFIGURE" ] && [ -x ./autogen.sh ]; then
        rm -f m4/libtool.m4
        NOCONFIGURE=1 ./autogen.sh >> build.log 2>&1 || die "mod: error running autogen.sh"
        ./configure $CONFIG_OPTIONS $mod_config_options $E_CONFIG_OPTIONS >> build.log 2>&1 || die "$mod: error running configure"
    fi

    $MAKE >> build.log 2>&1 || die "$mod: error building"
    sudo $MAKE -j 1 install >> build.log 2>&1 || die "$mod: error installing"
    _popd
    sudo ldconfig
}

function run_all()
{
    local function=$1
    local mod_path="core"

    for module in $E_MODULES; do
        case $module in
            terminology | econnman | emprint | ephoto | rage )
                mod_path="apps"
                ;;
            edi | erigo | enventor | expedite )
                mod_path="tools"
                ;;
        esac
        $function $REPO_DIR $mod_path $module
    done
}

E_MODULES=$@

[ -z "$E_MODULES" ] && E_MODULES=" \
    efl \
    enlightenment \
    terminology \
    rage \
    edi \
    enventor \
    "

if [ -z "$NO_CLEANUP" ]; then
    run_all cleanup
fi

if [ -z "$NO_UPDATE" ]; then
    run_all update
fi

if [ -z "$NO_BUILD" ]; then
    prepare_build
    run_all build
fi
