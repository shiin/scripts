#!/bin/sh

#set -ex
# written by shiin.lee@samsung.com

#URL=`sdb -d shell 'cat /etc/zypp/repos.d/slp-release.repo' | grep baseurl | awk -F = '{print $2}' | sed 's/packages\r/debug/'`
#URL=`sdb -d shell 'cat /etc/zypp/repos.d/2.4-mobile-target.repo' | grep baseurl | awk -F = '{print $2}' | sed 's/packages/debug/'`
#URL=`sdb -d shell 'cat /etc/zypp/repos.d/2.3-mobile-target.repo' | grep baseurl | awk -F = '{print $2}' | sed 's/packages/debug/'`
TZ_BUILD_ID=`sdb -d shell 'cat /etc/tizen-build.conf' | grep TZ_BUILD_ID | awk -F = '{print $2}' | tr -d '\r'`
URL=http://download.tizen.org/snapshots/tizen/unified/${TZ_BUILD_ID}/repos/standard/debug/

if [ $# -ne 1 ]; then
PKG_LIST="enlightenment ecore evas eina edje elementary efl"
echo "Downloading DEFAULT debug package:" $PKG_LIST
else
PKG_LIST=$1
echo "Downloading debug_package:" $PKG_LIST
fi

echo $URL
sleep 1

DOWNLOAD_DIR=$HOME/temp/package
DEST_DIR=/home/app/debug/

for x in $PKG_LIST
do
   echo " "
   echo " "
   echo " "
   echo "=============== Downloading "$x" ==============="
   get_pkg $URL $x $DOWNLOAD_DIR
done

echo " "
echo "=============== Pushing the debug packages via sdb ==============="
sdb -d root on
sdb -d shell 'mount -o remount,rw /'
sdb -d push $DOWNLOAD_DIR $DEST_DIR

echo " "
echo " "
echo "=============== Installing rpm pacakages ==============="
sdb -d shell 'rpm --force --nodeps -ivh /home/app/debug/*.rpm'
sdb -d shell 'rm -rf /home/app/debug'
sdb -d shell 'smack_reload.sh'
rm $HOME/temp/package/*
