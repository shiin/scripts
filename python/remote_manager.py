import os
from bcolors import bcolors

import urllib3
from bs4 import BeautifulSoup

class RemoteManager():
    def __init__(self):
        self._http = urllib3.PoolManager()
    
    def download(self, url, path):
        if url is None or path is None:
            return None

        fname = url.split('/')[-1]
        download_full_path = os.path.join(path, fname)

        response = self._http.request('GET', url, preload_content=False)
        meta = response.info()
        file_size = int(meta.getheaders("Content-Length")[0])
        print("Downloading: %s Bytes: %s" % (fname, file_size))

        file_size_dl = 0
        chunk_size = 8192
        if os.path.exists(download_full_path):
            print(bcolors.YELLOW + 'File is already exist: ' + download_full_path + bcolors.ENDC)
            return download_full_path

        with open(download_full_path, 'wb') as out:
            while True:
                data = response.read(chunk_size)
                if not data:
                    break
                file_size_dl += len(data)
                out.write(data)
                status = r'%10d  [%3.2f%%]' % (file_size_dl, file_size_dl * 100. / file_size)
                status = status + chr(8) * (len(status) + 1)
                print(status, end='\r')
        response.release_conn()

        return download_full_path

    def get_link_list(self, url):
        output = []
        if url is None:
            return output

        response = self._http.request('GET', url)
        soup = BeautifulSoup(response.data, 'html.parser')
        links = soup.find_all('a')

        for link in links:
            output.append(link.get('href'))

        return output

if __name__ == '__main__':
    url = 'http://cdn.download.tizen.org/snapshots/tizen/unified'
    rman = RemoteManager()
    print(rman.get_link_list(url))