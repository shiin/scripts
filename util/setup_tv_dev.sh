#!/bin/bash

sdb root on
sdb shell 'mv /lib/modules/3.10.30/kernel/smart_deadlock.ko /lib/modules/3.10.30/kernel/smart_deadlock_bk.ko'
sdb shell 'rm -fv /var/lib/rpm/__db.001'
sdb push $HOME/bin/data/gdb/* /home/gdb/
sdb shell 'rpm --force --nodeps -ivh /home/gdb/*.rpm'
sdb shell 'sync'
