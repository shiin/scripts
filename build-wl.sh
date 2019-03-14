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
   export EXTRA_LIBDIR=$LIBDIR/x86_64-linux-gnu
   export SHAREDIR=$WLD/share
   export LD_LIBRARY_PATH="$LIBDIR:$EXTRA_LIBDIR:$LD_LIBRARY_PATH"
   export PKG_CONFIG_PATH="$LIBDIR/pkgconfig:$SHAREDIR/pkgconfig:$EXTRA_LIBDIR/pkgconfig:$PKG_CONFIG_PATH"
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
   local meson=false
   echo "Build $mod ..."

   _pushd $repo_path/$mod

   if [[ -e meson.build ]]; then
      meson=true
   fi


   PREFIX="--prefix=$WLD"

   case $mod in
      wayland )
         mod_config_options="--disable-documentation"
         ;;
      mesa )
         mod_config_options="-Dgles2=true \
            -Dplatforms=x11,wayland,drm -Dgbm=true -Dshared-glapi=true \
            -Dgallium-drivers=r600,swrast,nouveau"
         ;;
      cairo )
         mod_config_options="--enable-xcb"
         ;;
      libxkbcommon )
         mod_config_options="--with-xkb-config-root=/usr/share/X11/xkb"
         ;;
      libinput )
         mod_config_options="-Dtests=false -Ddebug-gui=false"
         ;;
      xserver )
         mod_config_options="--disable-docs --disable-devel-docs \
            --enable-xwayland --disable-xorg --disable-xvfb --disable-xnest \
            --disable-xquartz --disable-xwin"
         ;;
      efl )
         mod_config_options="--with-systemdunitdir=$WLD/etc/efl --enable-drm --enable-wayland --enable-systemd --enable-egl --with-opengl=es"
         ;;
      enlightenment )
         mod_config_options="--with-systemdunitdir=$WLD/etc/enlightenment --enable-wayland --enable-wayland-egl --enable-wayland-only --enable-wl-drm --enable-wl-text-input --enable-wl-weekeyboard --enable-wl-x11 --enable-wl-desktop-shell --disable-shot --disable-xkbswitch --disable-conf-randr"
         ;;
   esac

   if [[ "$meson" == true ]]; then
      meson . build $PREFIX $mod_config_options >> build.log 2>&1 || die "meson: error running build"
      ninja -C build >> build.log 2>&1 || die "ninja: error running build"
      sudo ninja -C build install 2>&1 || die "ninja: error running install"
   else
      [ ! -f Makefile ] && E_NO_CONFIGURE=""
      if [ -z "$NO_CONFIGURE" ] && [ -x ./autogen.sh ]; then
         rm -f m4/libtool.m4
         autoreconf -i > /dev/null 2>&1
         NOCONFIGURE=1 ./autogen.sh >> build.log 2>&1 || die "$mod: error running autogen.sh"
         ./configure $PREFIX $mod_config_options >> build.log 2>&1 || die "$mod: error running configure"
      fi
      $MAKE >> build.log 2>&1 || die "$mod: error building"
      $MAKE -j 1 install >> build.log 2>&1 || die "$mod: error installing"
   fi

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
   libunwind \
   weston \
"

# 2018-03-23 for wayland
sudo apt install libffi-dev

# 2018-03-23 for drm
sudo apt install libpciaccess-dev

# 2018-03-23 for mesa
sudo apt install libvdpau-dev libxvmc-dev libva-dev python-mako libelf-dev llvm-5.0-dev bison flex

# 2018-03-23 for libinput
sudo apt install libmtdev-dev libwacom-dev doxygen-gui xdot

# X Server:

# xserver: configure.ac:38: error: must install xorg-macros 1.14 or later before running autoconf/autogen
# xserver: configure: error: Package requirements (glproto >= 1.4.17 gl >= 9.2.0) were not met:
sudo apt install xutils-dev libgl1-mesa-dev

# checking for SHA1 implementation... configure: error: No suitable SHA1 implementation found
# checking for SHA1Init in -lmd... no
sudo apt install libmd-dev # no .pc file?

# configure: error: Package requirements (fixesproto >= 5.0 damageproto >= 1.1 xcmiscproto >= 1.2.0 xtrans >= 1.3.5 bigreqsproto >= 1.1.0 xproto >= 7.0.28 randrproto >= 1.5.0 renderproto >= 0.11 xextproto >= 7.2.99.901 inputproto >= 2.3 kbproto >= 1.0.3 fontsproto >= 2.1.3 pixman-1 >= 0.27.2 videoproto compositeproto >= 0.4 recordproto >= 1.13.99.1 scrnsaverproto >= 1.1 resourceproto >= 1.2.0 xf86driproto >= 2.1.0 glproto >= 1.4.17 dri >= 7.8.0 presentproto >= 1.0 xineramaproto
# xkbfile  pixman-1 >= 0.27.2 xfont >= 1.4.2 xau xshmfence >= 1.1 xdmcp) were not met:
sudo apt install x11proto-xcmisc-dev x11proto-bigreqs-dev x11proto-randr-dev \
   x11proto-fonts-dev x11proto-video-dev x11proto-composite-dev \
   x11proto-record-dev x11proto-scrnsaver-dev x11proto-resource-dev \
   x11proto-xf86dri-dev x11proto-present-dev x11proto-xinerama-dev \
   libxkbfile-dev libxfont-dev libpixman-1-dev x11proto-render-dev

# configure: error: Xwayland build explicitly requested, but required modules not found.
# checking for XWAYLANDMODULES... no
# XWAYLANDMODULES="wayland-client >= 1.3.0 libdrm epoxy"
sudo apt install libepoxy-dev # this error message is uninformative

# For llvm-7 required by mesa - Ubuntu 16.04
APT_FILE=/etc/apt/source.list
LLVM_SYM="# For llvm"

grep ${LLVM_SYM} ${APT_FILE} > /dev/null 2>&1
if [[ $? -ne 0 ]]; then
    wget -O - https://apt.llvm.org/llvm-snapshot.gpg.key|sudo apt-key add

    sudo sh -c 'echo "# For llvm-7" >> $APT_FILE"'
    sudo sh -c 'echo "deb http://apt.llvm.org/xenial/ llvm-toolchain-xenial main" >> $APT_FILE'
    sudo sh -c 'echo "deb-src http://apt.llvm.org/xenial/ llvm-toolchain-xenial main" >> $APT_FILE'
    # 6
    sudo sh -c 'echo "deb http://apt.llvm.org/xenial/ llvm-toolchain-xenial-6.0 main" >> $APT_FILE'
    sudo sh -c 'echo "deb-src http://apt.llvm.org/xenial/ llvm-toolchain-xenial-6.0 main" >> $APT_FILE'
    # 7
    sudo sh -c 'echo "deb http://apt.llvm.org/xenial/ llvm-toolchain-xenial-7 main" >> $APT_FILE'
    sudo sh -c 'echo "deb-src http://apt.llvm.org/xenial/ llvm-toolchain-xenial-7 main" >> $APT_FILE'

    sudo apt install libllvm-7-ocaml-dev libllvm7 llvm-7 llvm-7-dev llvm-7-doc llvm-7-examples llvm-7-runtime
fi


if [ -z "$NO_CLEANUP" ]; then
   run_all cleanup
fi

if [ -z "$NO_UPDATE" ]; then
   run_all update
fi

if [ -z "$NO_BUILD" ]; then
   prepare_build
   # No package 'xfont2' found
   #git clone git://anongit.freedesktop.org/xorg/lib/libXfont $HOME/repos/wayland/libXfont
   #pushd $HOME/repos/wayland/libXfont
   #./autogen.sh --prefix=$WLD
   #make check
   #make && make install
   #popd

   #git clone git://anongit.freedesktop.org/xorg/xserver $HOME/repos/wayland/xserver
   #pushd $HOME/repos/wayland/xserver
   #./autogen.sh --prefix=$WLD --disable-docs --disable-devel-docs \
   #   --enable-xwayland --disable-xorg --disable-xvfb --disable-xnest \
   #   --disable-xquartz --disable-xwin
   #make check
   #make && make install
   #popd

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
