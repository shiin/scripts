#!/usr/bin/python3

import os
import re
import zipfile
import urllib3
from shutil import copytree
from bs4 import BeautifulSoup

BASE_URL='http://168.219.244.109/products/tv/archive/2019/MAIN2019/MuseM_ATSC'
SUB_URL='images/T-MSMAKUC'
NAME='updateMM'
ZIP_NAME=NAME + '.zip'
TMP_PATH='/tmp/tizen'
USB_PATH='/media/prado/644D-FF86'

if os.path.exists(TMP_PATH) == False:
    os.mkdir(TMP_PATH)

http = urllib3.PoolManager()
response = http.request('GET', BASE_URL)
soup = BeautifulSoup(response.data, 'html.parser')

# Select Release binary
idx = 0
lname_list = []
for link in soup.findAll('a'):
    lname = link.get('href')
    if re.search('TIZEN|latest', lname) is not None:
        print("%d. " % idx + link.get('href'))
        lname_list.append(lname)
        idx = idx + 1

id = int(input('Select number of release you want: '))
furl = BASE_URL + '/' + lname_list[id] + SUB_URL + '/' + ZIP_NAME
response.release_conn()

# Download binary
print("Downloading binary... '%s' to '%s'" % ZIP_NAME, TMP_PATH)
response = http.request('GET', furl, preload_content=False)
meta = response.info()
fsize = int(meta.getheaders("Content-Length")[0])
print("Downloading: Bytes: %s" % (fsize))

fsize_dl = 0
chunk_size = 8192
file_path = os.path.join(TMP_PATH, ZIP_NAME)
with open(file_path, 'wb') as f:
    while True:
        data = response.read(chunk_size)
        if not data:
            break
        fsize_dl += len(data)
        f.write(data)
        status = r'%10d  [%3.2f%%]' % (fsize_dl, fsize_dl * 100. / fsize)
        status = status + chr(8) * (len(status) + 1)
        print(status, end='\r')
    response.release_conn()
    print('')

# Unzip file
print('Unziping...')
zip_ref = zipfile.ZipFile(file_path, 'r')
zip_ref.extractall(TMP_PATH)
zip_ref.close()

# rename 'dtb_RW.bin' to 'dtb.bin'
print("Rename 'dtb_RW.bin' to 'dtb.bin'...")
fdtb = os.path.join(TMP_PATH, NAME, 'dtb.bin')
fdtbrw = os.path.join(TMP_PATH, NAME, 'dtb_RW.bin')
os.rename(fdtbrw, fdtb)

# copy updateMM directory to usb
print("Copy 'updateMM' directory to USB stick...")
src = os.path.join(TMP_PATH, NAME)
dst = os.path.join(USB_PATH, NAME)
copytree(src, dst)