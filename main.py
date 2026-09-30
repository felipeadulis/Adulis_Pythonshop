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
    requestSaveAs = Signal()
    dimensionsChanged = Signal(int, int)

    def __init__(self):
        super().__init__()
        self.original_image = None
        self.current_image = None
        self.current_file_path = None
        self.temp_path = Path(__file__).resolve().parent / "temp_output.png"

    @Slot(str)
    def loadImage(self, file_url):
        path = QUrl(file_url).toLocalFile()
        if not path:
            path = file_url.replace("file:///", "").replace("file://", "")

        img = cv2.imread(path)
        if img is None:
            self.errorOcurred.emit("Falha ao carregar a imagem. Verifique o caminho ou formato.")
            return

        self.current_file_path = Path(path)
        self.original_image = img.copy()
        self.current_image = img.copy()
        self._updateImage(self.current_image)

    @Slot(str)
    def saveImage(self, file_url):
        if self.current_image is None:
            self.errorOcurred.emit("Nenhuma imagem para salvar.")
            return

        path = QUrl(file_url).toLocalFile()
        if not path:
            path = file_url.replace("file:///", "").replace("file://", "")

        cv2.imwrite(path, self.current_image)
        self.current_file_path = Path(path)

    @Slot()
    def saveDefault(self):
        if self.current_image is None:
            self.errorOcurred.emit("Nenhuma imagem ativa para salvar.")
            return

        if self.current_file_path is None:
            self.requestSaveAs.emit()
            return

        directory = self.current_file_path.parent
        stem = self.current_file_path.stem
        suffix = self.current_file_path.suffix
        save_path = directory / f"{stem}_edited{suffix}"

        if not save_path.exists():
            self.requestSaveAs.emit()
            return

        cv2.imwrite(str(save_path), self.current_image)

    @Slot()
    def resetImage(self):
        if self.original_image is not None:
            self.current_image = self.original_image.copy()
            self._updateImage(self.current_image)

    def _updateImage(self, img_to_show):
        if img_to_show is None:
            return
        h, w = img_to_show.shape[:2]
        self.dimensionsChanged.emit(w, h)

        cv2.imwrite(str(self.temp_path), img_to_show)
        file_url = QUrl.fromLocalFile(str(self.temp_path)).toString()
        self.imageChanged.emit(f"{file_url}?t={int(time.time() * 1000)}")

    def _get_border_value(self, img):
        return (255, 255, 255) if len(img.shape) == 3 else 255

    # ==========================================
    # LÓGICA DE PREVIEW E APLICAÇÃO
    # ==========================================

    @Slot(int, bool)
    def processBrightness(self, value, apply):
        if self.current_image is None: return
        img_int = np.int16(self.current_image) + value
        img_int = np.clip(img_int, 0, 255)
        res = np.uint8(img_int)

        if apply:
            self.current_image = res
        self._updateImage(res)

    @Slot(float, bool)
    def processContrast(self, factor, apply):
        """Aplica o fator de contraste centralizado em 127.5"""
        if self.current_image is None: return
        img_float = self.current_image.astype(np.float32)

        res = (img_float - 127.5) * factor + 127.5
        res = np.clip(res, 0, 255).astype(np.uint8)

        if apply:
            self.current_image = res
        self._updateImage(res)

    @Slot(float, bool)
    def processRotation(self, angle, apply):
        if self.current_image is None: return
        img = self.current_image
        h, w = img.shape[:2]
        center = (w / 2, h / 2)
        M = cv2.getRotationMatrix2D(center, angle, 1.0)

        cos = np.abs(M[0, 0])
        sin = np.abs(M[0, 1])
        new_w = int((h * sin) + (w * cos))
        new_h = int((h * cos) + (w * sin))
        M[0, 2] += (new_w / 2) - center[0]
        M[1, 2] += (new_h / 2) - center[1]

        border_val = self._get_border_value(img)
        res = cv2.warpAffine(img, M, (new_w, new_h), borderMode=cv2.BORDER_CONSTANT, borderValue=border_val)

        if apply:
            self.current_image = res
        self._updateImage(res)

    @Slot(int, int, bool)
    def processTranslation(self, dx, dy, apply):
        if self.current_image is None: return
        img = self.current_image
        h, w = img.shape[:2]
        M = np.float32([[1, 0, dx], [0, 1, dy]])
        border_val = self._get_border_value(img)

        res = cv2.warpAffine(img, M, (w, h), borderMode=cv2.BORDER_CONSTANT, borderValue=border_val)

        if apply:
            self.current_image = res
        self._updateImage(res)

    # ==========================================
    # DEMAIS TRANSFORMAÇÕES
    # ==========================================

    @Slot()
    def applyGrayscale(self):
        if self.current_image is None: return
        img = self.current_image.copy()
        if len(img.shape) == 3:
            img = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
        self.current_image = img
        self._updateImage(self.current_image)

    @Slot()
    def applyNegative(self):
        if self.current_image is None: return
        self.current_image = 255 - self.current_image
        self._updateImage(self.current_image)

    @Slot(int)
    def applyMirror(self, flipCode):
        if self.current_image is None: return
        self.current_image = cv2.flip(self.current_image, flipCode)
        self._updateImage(self.current_image)

    @Slot(int)
    def applyMeanFilter(self, kernel_size):
        if self.current_image is None: return
        self.current_image = cv2.blur(self.current_image, (kernel_size, kernel_size), borderType=cv2.BORDER_REPLICATE)
        self._updateImage(self.current_image)

    @Slot(int, float)
    def applyGaussianFilter(self, kernel_size, sigma):
        if self.current_image is None: return
        self.current_image = cv2.GaussianBlur(self.current_image, (kernel_size, kernel_size), sigma, borderType=cv2.BORDER_REPLICATE)
        self._updateImage(self.current_image)

    @Slot()
    def addNoise(self):
        if self.current_image is None: return
        img = self.current_image
        noise = np.random.normal(0, 25, img.shape).astype(np.int16)
        noisy_img = np.int16(img) + noise
        noisy_img = np.clip(noisy_img, 0, 255)
        self.current_image = np.uint8(noisy_img)
        self._updateImage(self.current_image)

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
