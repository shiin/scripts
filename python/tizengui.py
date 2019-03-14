import sys
from PyQt5.QtWidgets import *
from PyQt5 import uic

from tizen import TizenManager

form_class = uic.loadUiType("tizenmanager.ui")[0]

class TizenGui(QMainWindow, form_class):
    def __init__(self):
        super().__init__()
        self.setupUi(self)
        self.setWindowTitle("Tizen Tools")

    def set_devices(self, devices):
        self.devicesCombo.addItems(devices)

    def set_release_list(self, release_list):
        self.releaseCombo.addItems(release_list)

if __name__ == "__main__":
    app = QApplication(sys.argv)
    tzman = TizenManager()
    window = TizenGui()
    devices = tzman.get_device_list()
    release_list = tzman.get_release_image_list()
    window.set_devices(devices)
    window.set_release_list(release_list)
    window.show()
    app.exec_()