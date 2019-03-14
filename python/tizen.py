import os
import re
from time import sleep
from bcolors import bcolors
from pathlib import Path
from subprocess import call, check_output, DEVNULL
from urllib.parse import urljoin

from remote_manager import RemoteManager
from tizen_tool_manager import TizenToolManager

class TizenManager(TizenToolManager):
    def __init__(self):
        self._tmp_path = os.path.join(str(Path.home()), 'temp', 'tizen')
        self._repo_url = 'http://cdn.download.tizen.org/snapshots/tizen/unified'
        self._image_sub_url = 'images/standard/mobile-wayland-armv7l-tm1'
        self._debug_sub_url = 'repos/standard/debug/'
        self._device_info_file_path = '/etc/info.ini'
        self._device_tmp_path = '/home/tmp/'
        self._remote = RemoteManager()
        if not os.path.exists(self._tmp_path):
            os.mkdir(self._tmp_path)

        super().__init__()

    def download_image(self, version='latest'):
        url = os.path.join(self._repo_url, version, self._image_sub_url)
        links = self._remote.get_link_list(url)
        found = None
        for link in links:
            if re.search('tar\.gz$', link) is not None:
                found = link
        if found is None:
            return None

        url = os.path.join(url, found)
        return self._remote.download(url, self._tmp_path)

    def get_release_image_list(self):
        self._releases = self._remote.get_link_list(self._repo_url)
        self._releases = [x.strip('/') for x in self._releases]
        return self._releases

    def download_image_to_device(self, version='latest'):
        f = self.download_image(version)
        return super().install_lthor_image(f)

    def get_device_installed_image_version(self, dname):
        cmd = ['cat', self._device_info_file_path]
        output = super().run_sdb_shell(dname, cmd)
        output = output.split('\r\n')
        version = None
        for row in output:
            if re.search('Build=', row):
                version = row.split('=')
                version = version[1].strip(';')
        return version

    def setup_device_debug_pkgs(self, dname, keywords, version=None):
        if keywords is None:
            return None

        # Get version of installed image in given device, 
        # the version's going to be used to make download url
        if version is None:
            version = self.get_device_installed_image_version(dname)
        if version is None:
            version = 'latest'

        # Get platform name to use downloading rpms
        cmd = ['rpm', '-qa', '|', 'grep', 'enlightenment']
        platform = (super().run_sdb_shell(dname, cmd)).strip('\r\n').split('.')[-1]

        url = os.path.join(self._repo_url, version, self._debug_sub_url)
        links = self._remote.get_link_list(url)
        download_list = []
        for link in links:
            for keyword in keywords:
                if re.search('^' + keyword + '.*-debug.*' + platform + '.rpm$', link):
                    download_list.append(link)

        downloaded_list = []
        for link in download_list:
            download_url = os.path.join(url, link)
            downloaded_list.append(self._remote.download(download_url, self._tmp_path))

        super().root_on(dname)        
        install_list = self.push(dname, downloaded_list, self._device_tmp_path)

        cmd = ['mount', '-o', 'remount,rw', '/']
        self.run_sdb_shell(dname, cmd)

        for pkg in install_list:
            cmd = ['rpm', '--force', '--nodeps', '-ivh']
            cmd.append(pkg)
            print(self.run_sdb_shell(dname, cmd))

if __name__ == '__main__':
    tzman = TizenManager()
    # Download Binary

    tmp = 0
    if tmp == 1:
        release_list = tzman.get_release_image_list()
        for i, ver in enumerate(release_list):
            print('%d.' % (i) + ver)
        id = int(input('Select number of device you want: '))

        tzman.download_image_to_device(release_list[id])
    else:
        keywords = ['wayland', 'efl', 'eo', 'ecore', 'evas', 'ecore-evas', 'elementary', 'enlightenment']
        devices = tzman.get_connected_device_serial_list()
        for i, device in enumerate(devices):
            print('%d.' % (i) + device)
        id = int(input('Select number of device you want: '))
        tzman.setup_device_debug_pkgs(devices[id], keywords)
        # TODO there remains issue that couldn't install rpm package due to the space of disk.