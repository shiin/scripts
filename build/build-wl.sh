#!/bin/bash

[ -z "$MAKEFLAGS" ]  && export MAKEFLAGS="-j 10 -l 10"
[ -z "$MAKE" ]       && export MAKE="chrt --idle 0 make"
[ -z "$REPO_DIR" ]    && export REPO_DIR="$HOME/repos/wayland"

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

   [ -d "$repo_path/$mod" ] || return

   echo "Cleanup $mod ..."

   _pushd $repo_path/$mod
   if [ -f Makefile ]; then
      $MAKE uninstall > /dev/null 2>&1
      $MAKE distclean > /dev/null 2>&1
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

   local REPO=""

   case $mod in
      libunwind )
         REPO="http://git.savannah.gnu.org/r"
         ;;
      libxkbcommon )
         REPO="https://github.com"
         ;;
      efl | elementary | enlightenment )
         REPO="http://git.enlightenment.org"
         ;;
      * )
         REPO="http://anongit.freedesktop.org/git"
         ;;
   esac
  
   [ "$mod_path" == "dummy" ] && GIT_URI="$REPO/$mod.git" || GIT_URI="$REPO/$mod_path/$mod.git"

   git clone $GIT_URI $repo_path/$mod > /dev/null 2>&1 || die "Error cloning $mod from $GIT_URI"
}

function update()
{
   local repo_path=$1
   local mod_path=$2
   local mod=$3

   if [ ! -d "$repo_path/$mod" ]; then
      clone $repo_path $mod_path $mod
      return
   fi

   echo "Update $mod ..."

   _pushd $repo_path/$mod
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
   export WLD=$HOME/install
   export LIBDIR=$WLD/lib
   export SHAREDIR=$WLD/share
   export LD_LIBRARY_PATH="$LIBDIR:$LD_LIBRARY_PATH"
   export PKG_CONFIG_PATH="$LIBDIR/pkgconfig:$SHAREDIR/pkgconfig:$PKG_CONFIG_PATH"
   export PATH="$WLD/bin:$PATH"

   BUILD_FLAGS="-g -O0 -W -Wall -Wextra -march=native -ffast-math -I$WLD/include"
   export CC="ccache gcc"
   export CFLAGS="$BUILD_FLAGS"
   export CXXFLAGS="$BUILD_FLAGS"
   export LDFLAGS="-L$LIBDIR"

   export ACLOCAL_PATH="$WLD/share/aclocal"
   export ACLOCAL="aclocal -I $ACLOCAL_PATH"
   [ -d $ACLOCAL_PATH ] || mkdir -p $ACLOCAL_PATH > /dev/null 2>&1
}

function build()
{
   local repo_path=$1
   local mod_path=$2
   local mod=$3
   local mod_config_options=""
   echo "Build $mod ..."

   case $mod in
      wayland )
         mod_config_options="--prefix=$WLD --disable-documentation"
         ;;
      mesa )
         mod_config_options="--prefix=$WLD --enable-gles2 --disable-gallium-egl     \
            --with-egl-platforms=x11,wayland,drm --enable-gbm --enable-shared-glapi \
            --with-gallium-drivers=r600,swrast,nouveau --disable-llvm-shared-libs"
         ;;
      cairo )
         mod_config_options="--prefix=$WLD --enable-xcb"
         ;;
      libxkbcommon )
         mod_config_options="--prefix=$WLD --with-xkb-config-root=/usr/share/X11/xkb"
         ;;
      libinput )
         mod_config_options="--prefix=$WLD --disable-tests"
         ;;
      xserver )
         mod_config_options="--prefix=$WLD --disable-docs --disable-devel-docs \
            --enable-xwayland --disable-xorg --disable-xvfb --disable-xnest \
            --disable-xquartz --disable-xwin"
         ;;
      weston )
         mod_config_options="--prefix=$WLD --enable-libinput-backend --disable-setuid-install"
         ;;
      efl )
         mod_config_options="--prefix=$WLD --with-systemdunitdir=$WLD/etc/efl --enable-drm --enable-wayland --enable-systemd --enable-egl --with-opengl=es"
         ;;
      enlightenment )
         mod_config_options="--prefix=$WLD --with-systemdunitdir=$WLD/etc/enlightenment --enable-wayland --enable-wayland-egl --enable-wayland-only --enable-wl-drm --enable-wl-text-input --enable-wl-weekeyboard --enable-wl-x11 --enable-wl-desktop-shell --disable-shot --disable-xkbswitch --disable-conf-randr"
         ;;
      * )
         mod_config_options="--prefix=$WLD"
         ;;
   esac

   _pushd $repo_path/$mod

   [ ! -f Makefile ] && E_NO_CONFIGURE=""
   if [ -z "$NO_CONFIGURE" ] && [ -x ./autogen.sh ]; then
      rm -f m4/libtool.m4
      autoreconf -i > /dev/null 2>&1
      NOCONFIGURE=1 ./autogen.sh >> build.log 2>&1 || die "$mod: error running autogen.sh"
      ./configure $mod_config_options >> build.log 2>&1 || die "$mod: error running configure"
   fi

   $MAKE >> build.log 2>&1 || die "$mod: error building"
   $MAKE -j 1 install >> build.log 2>&1 || die "$mod: error installing"
   _popd
}

function run_all()
{
   local function=$1
   local mod_path=""

   for module in $E_MODULES; do
      case $module in
         wayland* | libinput | weston )
            mod_path="wayland"
            ;;
         pthread-stubs )
            mod_path="xcb"
            ;;
         mesa | drm )
            mod_path="mesa"
            ;;
         proto | libxcb )
            mod_path="xcb"
            ;;
         macros )
            mod_path="xorg/util"
            ;;
         *proto )
            mod_path="xorg/proto"
            ;;
         libxshmfence | libxkbfile )
            mod_path="xorg/lib"
            ;;
         libxkbcommon )
            mod_path="xkbcommon"
            ;;
         xserver )
            mod_path="xorg"
            ;;
         efl | elementary | enlightenment )
            mod_path="core"
            ;;
         * )
            mod_path="dummy"
            ;;
      esac
      $function $REPO_DIR $mod_path $module
   done
}

E_MODULES=$@

[ -z "$E_MODULES" ] && E_MODULES=" \
   wayland \
   wayland-protocols \
   pthread-stubs \
   drm \
   proto \
   macros \
   presentproto \
   dri3proto \
   libxshmfence \
   mesa \
   pixman \
   cairo \
   libxkbcommon \
   libevdev \
   libinput \
   libunwind \
   weston \
   libepoxy \
   glproto \
   xproto \
   xcmiscproto \
   libxtrans \
   bigreqsproto \
   xextproto \
   fontsproto \
   videoproto \
   recordproto \
   resourceproto \
   xf86driproto \
   libxkbfile \
   randrproto \
   xserver \
   efl \
   enlightenment \
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

# Links needed so XWayland works:
mkdir -p $WLD/share/X11/xkb/rules
ln -s /usr/share/X11/xkb/rules/evdev $WLD/share/X11/xkb/rules/
ln -s /usr/bin/xkbcomp $WLD/bin/

# Weston configuration:
mkdir -p ~/.config
cp $REPO_DIR/weston/weston.ini ~/.config
vim ~/.config/weston.ini
