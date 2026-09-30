# This Python file uses the following encoding: utf-8
import sys
import cv2
import numpy as np
import time
from pathlib import Path

from PySide6.QtCore import QObject, Slot, Signal, QUrl
from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine

class AdulisBackend(QObject):
    imageChanged = Signal(str)
    errorOcurred = Signal(str)

    def __init__(self):
        super().__init__()
        self.original_image = None
        self.current_image = None
        self.temp_path = Path(__file__).resolve().parent / "temp_output.png"
        self.use_original = False

    @Slot(bool)
    def setUseOriginal(self, use_orig):
        self.use_original = use_orig

    @Slot(str)
    def loadImage(self, file_url):
        # Converte a URL do QML para um caminho de ficheiro válido no sistema local
        path = QUrl(file_url).toLocalFile()
        if not path:
            path = file_url.replace("file:///", "").replace("file://", "")

        img = cv2.imread(path)
        if img is None:
            self.errorOcurred.emit("Falha ao carregar a imagem. Verifique o caminho ou formato.")
            return

        self.original_image = img.copy()
        self.current_image = img.copy()
        self._updateImage()

    def _getSourceImage(self):
        if self.original_image is None:
            return None
        if self.use_original:
            return self.original_image.copy()
        return self.current_image.copy()

    def _updateImage(self):
        if self.current_image is None:
            return
        cv2.imwrite(str(self.temp_path), self.current_image)
        # Gera uma URL do tipo file:/// com carimbo de data/hora para forçar o recarregamento no QML
        file_url = QUrl.fromLocalFile(str(self.temp_path)).toString()
        self.imageChanged.emit(f"{file_url}?t={int(time.time() * 1000)}")

    @Slot()
    def applyGrayscale(self):
        img = self._getSourceImage()
        if img is None: return
        if len(img.shape) == 3:
            img = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
        self.current_image = img
        self._updateImage()

    @Slot(int)
    def applyBrightness(self, value):
        img = self._getSourceImage()
        if img is None: return
        img_int = np.int16(img) + value
        img_int = np.clip(img_int, 0, 255)
        self.current_image = np.uint8(img_int)
        self._updateImage()

    @Slot()
    def applyNegative(self):
        img = self._getSourceImage()
        if img is None: return
        self.current_image = 255 - img
        self._updateImage()

    @Slot(float)
    def applyRotation(self, angle):
        img = self._getSourceImage()
        if img is None: return
        h, w = img.shape[:2]
        center = (w // 2, h // 2)
        M = cv2.getRotationMatrix2D(center, angle, 1.0)
        self.current_image = cv2.warpAffine(img, M, (w, h), borderMode=cv2.BORDER_REPLICATE)
        self._updateImage()

    @Slot(int, int)
    def applyTranslation(self, dx, dy):
        img = self._getSourceImage()
        if img is None: return
        h, w = img.shape[:2]
        M = np.float32([[1, 0, dx], [0, 1, dy]])
        self.current_image = cv2.warpAffine(img, M, (w, h), borderMode=cv2.BORDER_REPLICATE)
        self._updateImage()

    @Slot(int)
    def applyMirror(self, flipCode):
        img = self._getSourceImage()
        if img is None: return
        self.current_image = cv2.flip(img, flipCode)
        self._updateImage()

    @Slot(int)
    def applyMeanFilter(self, kernel_size):
        img = self._getSourceImage()
        if img is None: return
        self.current_image = cv2.blur(img, (kernel_size, kernel_size), borderType=cv2.BORDER_REPLICATE)
        self._updateImage()

    @Slot(int, float)
    def applyGaussianFilter(self, kernel_size, sigma):
        img = self._getSourceImage()
        if img is None: return
        self.current_image = cv2.GaussianBlur(img, (kernel_size, kernel_size), sigma, borderType=cv2.BORDER_REPLICATE)
        self._updateImage()

    @Slot()
    def addNoise(self):
        img = self._getSourceImage()
        if img is None: return
        noise = np.random.normal(0, 25, img.shape).astype(np.int16)
        noisy_img = np.int16(img) + noise
        noisy_img = np.clip(noisy_img, 0, 255)
        self.current_image = np.uint8(noisy_img)
        self._updateImage()

if __name__ == "__main__":
    app = QGuiApplication(sys.argv)
    engine = QQmlApplicationEngine()

    backend = AdulisBackend()
    engine.rootContext().setContextProperty("backend", backend)

    qml_file = Path(__file__).resolve().parent / "main.qml"
    engine.load(qml_file)
    if not engine.rootObjects():
        sys.exit(-1)
    sys.exit(app.exec())
