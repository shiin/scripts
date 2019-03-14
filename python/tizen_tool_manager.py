from bcolors import bcolors
from time import sleep
import subprocess
import os
import re

try:
    from subprocess import DEVNULL
except ImportError:
    import os
    DEVNULL = open(os.devnull, 'wb')

LTHOR = 'lthor'
SDB = 'sdb'
GBS = 'gbs'

class TizenToolManager():
    def __init__(self):
        self._device_info_file_path = '/etc/info.ini'

    def install_lthor_image(self, fpath):
        ret_code = subprocess.call([LTHOR, '-c'], stdout=DEVNULL, stderr=DEVNULL)
        retry = 20
        while ret_code != 0 and retry > 0:
            print(bcolors.RED + 'Unable to connect device, Please connect device propery to continue (retry =%d)' % retry + bcolors.ENDC, end='\r')
            retry -= 1
            ret_code = subprocess.call([LTHOR, '-c'], stdout=DEVNULL, stderr=DEVNULL)
            sleep(1)

        if ret_code != 0:
            return False

        ret_code = subprocess.call([LTHOR, fpath])

        return ret_code is 0

    def root_on(self, serial):
        return subprocess.call([SDB, '-s', serial, 'root', 'on'], stdout=DEVNULL)

    def root_off(self, serial):
        return subprocess.call([SDB, '-s', serial, 'root', 'off'], stdout=DEVNULL)

    def get_connected_device_serial_list(self):
        output = subprocess.check_output([SDB, 'devices']).decode("utf-8")
        """ make list by '\n' and remove 0 indexed row data it's supposed to be header """
        output_list = output.split('\n')[1:]
        device_names = []
        for row in output_list:
            name = row.split('\t')[0]
            name = name.strip()
            device_names.append(name)
        device_names = [x for x in device_names if x]
        return device_names

    def is_device_connected(self, dname):
        cmd = [SDB, '-s', dname, 'get-state']
        output = subprocess.check_output(cmd).decode('utf-8')
        if re.search("device", output) is not None:
            return True
        return False

    def run_sdb_shell(self, dname, argv):
        cmd = [SDB, '-s', dname, 'shell']
        cmd = cmd + argv

        return subprocess.check_output(cmd).decode('utf-8')

    def push(self, dname, spath, dpath='/home/tmp/'):
        success_list = []
        for fpath in spath:
            output = subprocess.check_output([SDB, '-s', dname, 'push', fpath, dpath]).decode('utf-8')
            if re.search('error', output) is None:
                fname = fpath.split('/')[-1]
                success_list.append(os.path.join(dpath, fname))
        return success_list

if __name__ == '__main__':
    sdb = TizenToolManager()
    names = sdb.get_connected_device_serial_list()

    if len(names) > 1:
        for i, name in enumerate(names):
            print('%d. ' % (i) + name)
            index = input('Select number of device you want: ')
            name = names[int(index)]
    else:
        name = names[0]

    print(sdb.is_device_connected(name))
    #sdb.root_on(name)
    #print(sdb.run_sdb_shell(name, ['cat', '/etc/info.ini']))


    '''
    print(sdb.push(name, '/home/prado/bin/scripts/python/test.file'))
    '''
