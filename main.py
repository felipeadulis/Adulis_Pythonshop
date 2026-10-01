# This Python file uses the following encoding: utf-8
import sys
import cv2
import numpy as np
import time
from pathlib import Path
from PySide6.QtCore import QObject, Slot, Signal, QUrl
from PySide6.QtGui import QGuiApplication, QImage
from PySide6.QtQml import QQmlApplicationEngine
from PySide6.QtQuick import QQuickImageProvider

# ==========================================
# 1. O PROVEDOR DE IMAGENS NA RAM
# ==========================================
class AdulisImageProvider(QQuickImageProvider):
    def __init__(self):
        super().__init__(QQuickImageProvider.Image)
        self.images = {}

    def requestImage(self, id_str, size, requestedSize):
        clean_id = id_str.split('?')[0]
        if clean_id in self.images:
            img = self.images[clean_id]
            if size:
                size.setWidth(img.width())
                size.setHeight(img.height())
            return img
        return QImage()

    def update_image(self, id_str, cv_img):
        if cv_img is None: return
        if len(cv_img.shape) == 2:
            h, w = cv_img.shape
            bytes_per_line = w
            qimg = QImage(cv_img.data, w, h, bytes_per_line, QImage.Format_Grayscale8)
            self.images[id_str] = qimg.copy()
        else:
            h, w, ch = cv_img.shape
            bytes_per_line = ch * w
            rgb_img = cv2.cvtColor(cv_img, cv2.COLOR_BGR2RGB)
            qimg = QImage(rgb_img.data, w, h, bytes_per_line, QImage.Format_RGB888)
            self.images[id_str] = qimg.copy()


# ==========================================
# 2. O BACKEND PRINCIPAL
# ==========================================
class AdulisBackend(QObject):
    imageChanged = Signal(str)
    histogramChanged = Signal(str)
    errorOcurred = Signal(str)
    requestSaveAs = Signal(str)
    dimensionsChanged = Signal(int, int)

    def __init__(self, image_provider):
        super().__init__()
        self.provider = image_provider
        self.original_image = None
        self.current_image = None

        self.original_file_path = None
        self.current_save_path = None

    @Slot(str)
    def loadImage(self, file_url):
        path = QUrl(file_url).toLocalFile()
        if not path:
            path = file_url.replace("file:///", "").replace("file://", "")

        try:
            stream = open(path, "rb")
            bytes_array = bytearray(stream.read())
            numpy_array = np.asarray(bytes_array, dtype=np.uint8)
            img = cv2.imdecode(numpy_array, cv2.IMREAD_UNCHANGED)
        except Exception:
            img = None

        if img is None:
            self.errorOcurred.emit("Falha ao carregar a imagem. Verifique o caminho ou formato.")
            return

        if len(img.shape) == 3 and img.shape[2] == 4:
            img = cv2.cvtColor(img, cv2.COLOR_BGRA2BGR)

        self.original_file_path = Path(path)
        self.current_save_path = None

        self.original_image = img.copy()
        self.current_image = img.copy()
        self._updateImage(self.current_image)

    @Slot()
    def requestSaveAsDialog(self):
        if self.current_image is None:
            self.errorOcurred.emit("Abra uma imagem antes de salvar.")
            return

        suggested_url = ""
        if self.original_file_path:
            stem = self.original_file_path.stem
            suffix = self.original_file_path.suffix
            directory = self.original_file_path.parent
            suggested_path = directory / f"{stem}_edited{suffix}"
            suggested_url = QUrl.fromLocalFile(str(suggested_path)).toString()

        self.requestSaveAs.emit(suggested_url)

    @Slot(str)
    def saveImage(self, file_url):
        if self.current_image is None:
            self.errorOcurred.emit("Abra uma imagem antes de salvar.")
            return

        path = QUrl(file_url).toLocalFile()
        if not path:
            path = file_url.replace("file:///", "").replace("file://", "")

        path_obj = Path(path)
        ext = path_obj.suffix if path_obj.suffix else '.png'

        success, encoded = cv2.imencode(ext, self.current_image)
        if success:
            encoded.tofile(str(path_obj))
            self.current_save_path = path_obj

    @Slot()
    def saveDefault(self):
        if self.current_image is None:
            self.errorOcurred.emit("Abra uma imagem antes de salvar.")
            return

        if self.current_save_path is None:
            self.requestSaveAsDialog()
        else:
            ext = self.current_save_path.suffix if self.current_save_path.suffix else '.png'
            success, encoded = cv2.imencode(ext, self.current_image)
            if success:
                encoded.tofile(str(self.current_save_path))

    @Slot()
    def resetImage(self):
        if self.original_image is not None:
            self.current_image = self.original_image.copy()
            self._updateImage(self.current_image)

    def _updateImage(self, img_to_show):
        if img_to_show is None: return
        h, w = img_to_show.shape[:2]
        self.dimensionsChanged.emit(w, h)

        self.provider.update_image("main", img_to_show)
        self.imageChanged.emit(f"image://adulis/main?t={int(time.time() * 1000)}")
        self._updateHistogram(img_to_show)

    def _updateHistogram(self, img):
        h_hist, w_hist = 300, 400
        hist_img = np.full((h_hist, w_hist, 3), 245, dtype=np.uint8)

        if len(img.shape) == 2:
            hist = cv2.calcHist([img], [0], None, [256], [0, 256])
            cv2.normalize(hist, hist, 0, h_hist - 20, cv2.NORM_MINMAX)
            for x in range(255):
                cv2.line(hist_img, (int(x * w_hist / 256), h_hist - 10),
                         (int(x * w_hist / 256), h_hist - 10 - int(hist[x])), (50, 50, 50), 2)
        else:
            colors = [(255, 0, 0), (0, 255, 0), (0, 0, 255)]
            for i, col in enumerate(colors):
                hist = cv2.calcHist([img], [i], None, [256], [0, 256])
                cv2.normalize(hist, hist, 0, h_hist - 20, cv2.NORM_MINMAX)
                for x in range(255):
                    y1 = h_hist - 10 - int(hist[x])
                    y2 = h_hist - 10 - int(hist[x+1])
                    x1 = int(x * w_hist / 256)
                    x2 = int((x+1) * w_hist / 256)
                    cv2.line(hist_img, (x1, y1), (x2, y2), col, 2)

        self.provider.update_image("hist", hist_img)
        self.histogramChanged.emit(f"image://adulis/hist?t={int(time.time() * 1000)}")

    def _get_border_value(self, img):
        return (255, 255, 255) if len(img.shape) == 3 else 255

    # ==========================================
    # TRANSFORMAÇÕES PONTUAIS & GEOMÉTRICAS
    # ==========================================
    @Slot(int, bool)
    def processBrightness(self, value, apply):
        if self.current_image is None: return
        img_int = np.int16(self.current_image) + value
        img_int = np.clip(img_int, 0, 255)
        res = np.uint8(img_int)
        if apply: self.current_image = res
        self._updateImage(res)

    @Slot(float, bool)
    def processContrast(self, factor, apply):
        if self.current_image is None: return
        img_float = self.current_image.astype(np.float32)
        res = (img_float - 127.5) * factor + 127.5
        res = np.clip(res, 0, 255).astype(np.uint8)
        if apply: self.current_image = res
        self._updateImage(res)

    @Slot(float, bool)
    def processRotation(self, angle, apply):
        if self.current_image is None: return
        img = self.current_image
        h, w = img.shape[:2]
        center = (w / 2, h / 2)
        M = cv2.getRotationMatrix2D(center, angle, 1.0)

        cos, sin = np.abs(M[0, 0]), np.abs(M[0, 1])
        new_w = int((h * sin) + (w * cos))
        new_h = int((h * cos) + (w * sin))
        M[0, 2] += (new_w / 2) - center[0]
        M[1, 2] += (new_h / 2) - center[1]

        border_val = self._get_border_value(img)
        res = cv2.warpAffine(img, M, (new_w, new_h), borderMode=cv2.BORDER_CONSTANT, borderValue=border_val)
        if apply: self.current_image = res
        self._updateImage(res)

    @Slot(int, int, bool)
    def processTranslation(self, dx, dy, apply):
        if self.current_image is None: return
        img = self.current_image
        h, w = img.shape[:2]
        M = np.float32([[1, 0, dx], [0, 1, dy]])
        border_val = self._get_border_value(img)
        res = cv2.warpAffine(img, M, (w, h), borderMode=cv2.BORDER_CONSTANT, borderValue=border_val)
        if apply: self.current_image = res
        self._updateImage(res)

    @Slot()
    def applyContrastStretching(self):
        if self.current_image is None: return
        img = self.current_image
        if len(img.shape) == 2:
            f_min, f_max = img.min(), img.max()
            if f_max > f_min:
                self.current_image = np.uint8(((img.astype(np.float32) - f_min) / (f_max - f_min)) * 255.0)
        else:
            stretched = np.zeros_like(img)
            for i in range(3):
                f_min, f_max = img[:, :, i].min(), img[:, :, i].max()
                if f_max > f_min:
                    stretched[:, :, i] = ((img[:, :, i].astype(np.float32) - f_min) / (f_max - f_min)) * 255.0
                else:
                    stretched[:, :, i] = img[:, :, i]
            self.current_image = np.uint8(stretched)
        self._updateImage(self.current_image)

    @Slot(bool)
    def applyHistogramEqualization(self, use_clahe):
        if self.current_image is None: return
        img = self.current_image

        if use_clahe:
            clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8, 8))
            if len(img.shape) == 2:
                self.current_image = clahe.apply(img)
            else:
                ycrcb = cv2.cvtColor(img, cv2.COLOR_BGR2YCrCb)
                ycrcb[:, :, 0] = clahe.apply(ycrcb[:, :, 0])
                self.current_image = cv2.cvtColor(ycrcb, cv2.COLOR_YCrCb2BGR)
        else:
            if len(img.shape) == 2:
                self.current_image = cv2.equalizeHist(img)
            else:
                ycrcb = cv2.cvtColor(img, cv2.COLOR_BGR2YCrCb)
                ycrcb[:, :, 0] = cv2.equalizeHist(ycrcb[:, :, 0])
                self.current_image = cv2.cvtColor(ycrcb, cv2.COLOR_YCrCb2BGR)

        self._updateImage(self.current_image)

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

    # ==========================================
    # TRANSFORMAÇÕES POR VIZINHANÇA
    # ==========================================
    @Slot(int, bool)
    def processMeanFilter(self, kernel_size, apply):
        if self.current_image is None: return

        if kernel_size < 3:
            res = self.current_image.copy()
        else:
            res = cv2.blur(self.current_image, (kernel_size, kernel_size), borderType=cv2.BORDER_REPLICATE)

        if apply: self.current_image = res
        self._updateImage(res)

    @Slot(int, float, bool)
    def processGaussianFilter(self, kernel_size, sigma, apply):
        if self.current_image is None: return

        if kernel_size < 3:
            res = self.current_image.copy()
        else:
            res = cv2.GaussianBlur(self.current_image, (kernel_size, kernel_size), sigma, borderType=cv2.BORDER_REPLICATE)

        if apply: self.current_image = res
        self._updateImage(res)

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

    image_provider = AdulisImageProvider()
    engine.addImageProvider("adulis", image_provider)

    backend = AdulisBackend(image_provider)
    engine.rootContext().setContextProperty("backend", backend)

    qml_file = Path(__file__).resolve().parent / "main.qml"
    engine.load(qml_file)
    if not engine.rootObjects():
        sys.exit(-1)
    sys.exit(app.exec())
