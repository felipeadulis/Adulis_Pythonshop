import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

Window {
    width: 1200
    height: 800
    visible: true
    title: qsTr("Adulis Pythonshop")

    property int imgWidth: 800
    property int imgHeight: 600
    property bool showHistogram: true
    property bool hasImage: false

    // Global keyboard shortcuts
    Shortcut {
        sequence: "Ctrl+O"
        onActivated: openDialog.open()
    }
    Shortcut {
        sequence: "Ctrl+S"
        onActivated: backend.saveDefault()
    }
    Shortcut {
        sequence: "Ctrl+Shift+S"
        onActivated: backend.requestSaveAsDialog()
    }

    // Resets inactive controls to default values
    function resetOthers(activeControl) {
        if (!hasImage) return
        if (activeControl !== "brightness" && brightnessSlider.value !== 0) {
            brightnessSlider.value = 0
            backend.processBrightness(0, false)
        }
        if (activeControl !== "contrast" && contrastSlider.value !== 1.0) {
            contrastSlider.value = 1.0
            backend.processContrast(1.0, false)
        }
        if (activeControl !== "rotation" && rotationSlider.value !== 0) {
            rotationSlider.value = 0
            backend.processRotation(0, false)
        }
        if (activeControl !== "joystick" && (Math.round(joystickHandle.dx) !== 0 || Math.round(joystickHandle.dy) !== 0)) {
            centerJoystick()
            backend.processTranslation(0, 0, false)
        }
        if (activeControl !== "mean" && meanSlider.value !== 1) {
            meanSlider.value = 1
            backend.processMeanFilter(1, false)
        }
        if (activeControl !== "gauss" && gaussKernelSlider.value !== 1) {
            gaussKernelSlider.value = 1
            backend.processGaussianFilter(1, 0, false)
        }
    }

    function centerJoystick() {
        joystickHandle.x = (joystickPad.width - joystickHandle.width) / 2
        joystickHandle.y = (joystickPad.height - joystickHandle.height) / 2
    }

    FileDialog {
        id: openDialog
        title: "Abrir Imagem"
        nameFilters: ["Imagens (*.png *.jpg *.jpeg)"]
        onAccepted: backend.loadImage(selectedFile.toString())
    }

    FileDialog {
        id: saveAsDialog
        title: "Salvar Imagem Como"
        fileMode: FileDialog.SaveFile
        nameFilters: ["Imagens (*.png *.jpg *.jpeg)"]
        onAccepted: backend.saveImage(selectedFile.toString())
    }

    Dialog {
        id: warningDialog
        title: "Aviso"
        modal: true
        standardButtons: Dialog.Ok
        anchors.centerIn: parent
        property alias text: warningText.text

        Text {
            id: warningText
            text: ""
            font.pixelSize: 13
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        MenuBar {
            Layout.fillWidth: true
            Menu {
                title: qsTr("Arquivo")
                MenuItem { text: qsTr("Abrir... (Ctrl+O)"); onTriggered: openDialog.open() }
                MenuItem { text: qsTr("Salvar (Ctrl+S)"); onTriggered: backend.saveDefault() }
                MenuItem { text: qsTr("Salvar Como... (Ctrl+Shift+S)"); onTriggered: backend.requestSaveAsDialog() }
            }
            Menu {
                title: qsTr("Exibir")
                MenuItem {
                    text: qsTr("Histograma")
                    checkable: true
                    checked: showHistogram
                    onTriggered: showHistogram = checked
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.margins: 10
            spacing: 15

            ScrollView {
                Layout.preferredWidth: 350
                Layout.fillHeight: true

                ColumnLayout {
                    width: parent.width - 15
                    spacing: 10

                    // Shortcut actions panel
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 5

                        Button {
                            text: "Salvar"
                            Layout.fillWidth: true
                            enabled: hasImage
                            onClicked: backend.saveDefault()
                        }

                        Button {
                            text: "Resetar Imagem"
                            Layout.fillWidth: true
                            enabled: hasImage
                            onClicked: {
                                resetOthers("all")
                                backend.resetImage()
                            }
                        }
                    }

                    Rectangle { height: 1; Layout.fillWidth: true; color: "gray" }
                    Text { text: "<b>Transformações Pontuais</b>" }

                    Button {
                        text: "Escala de Cinza"
                        Layout.fillWidth: true
                        enabled: hasImage
                        onClicked: { resetOthers("grayscale"); backend.applyGrayscale() }
                    }

                    // Brightness control
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        property bool isChanged: brightnessSlider.value !== 0

                        Text {
                            text: "Ajuste de Brilho: " + Math.round(brightnessSlider.value)
                            font.pixelSize: 12; color: hasImage ? "#333" : "#888"
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Slider {
                                id: brightnessSlider
                                Layout.fillWidth: true
                                enabled: hasImage
                                from: -255; to: 255; value: 0; stepSize: 1
                                property real lastUpdate: 0
                                property real clickTime: 0
                                property bool resetPending: false

                                Timer {
                                    id: brightResetTimer
                                    interval: 50
                                    onTriggered: {
                                        brightnessSlider.value = 0
                                        backend.processBrightness(0, false)
                                        brightnessSlider.resetPending = false
                                    }
                                }

                                onPressedChanged: {
                                    if (pressed) {
                                        let now = Date.now()
                                        if (now - clickTime < 300) {
                                            resetPending = true
                                        } else {
                                            resetOthers("brightness")
                                        }
                                        clickTime = now
                                    } else {
                                        if (resetPending) {
                                            brightResetTimer.start()
                                        } else {
                                            if (Math.abs(value) < 12) value = 0
                                            backend.processBrightness(Math.round(value), false)
                                        }
                                    }
                                }
                                onValueChanged: {
                                    if (pressed && !resetPending) {
                                        if (Math.abs(value) < 5 && value !== 0) value = 0
                                        let now = Date.now()
                                        if (now - lastUpdate > 60) {
                                            backend.processBrightness(Math.round(value), false)
                                            lastUpdate = now
                                        }
                                    }
                                }
                            }

                            Button {
                                text: "Reset"
                                enabled: hasImage && parent.parent.isChanged
                                onClicked: { brightnessSlider.value = 0; backend.processBrightness(0, false) }
                            }

                            Button {
                                text: "Aplicar"
                                enabled: hasImage && parent.parent.isChanged
                                onClicked: { backend.processBrightness(Math.round(brightnessSlider.value), true); brightnessSlider.value = 0 }
                            }
                        }
                    }

                    // Contrast control
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        property bool isChanged: contrastSlider.value !== 1.0

                        Text {
                            text: "Fator de Contraste: " + contrastSlider.value.toFixed(1) + "x"
                            font.pixelSize: 12; color: hasImage ? "#333" : "#888"
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Slider {
                                id: contrastSlider
                                Layout.fillWidth: true
                                enabled: hasImage
                                from: 0.0; to: 3.0; value: 1.0; stepSize: 0.1
                                property real lastUpdate: 0
                                property real clickTime: 0
                                property bool resetPending: false

                                Timer {
                                    id: contResetTimer
                                    interval: 50
                                    onTriggered: {
                                        contrastSlider.value = 1.0
                                        backend.processContrast(1.0, false)
                                        contrastSlider.resetPending = false
                                    }
                                }

                                onPressedChanged: {
                                    if (pressed) {
                                        let now = Date.now()
                                        if (now - clickTime < 300) {
                                            resetPending = true
                                        } else {
                                            resetOthers("contrast")
                                        }
                                        clickTime = now
                                    } else {
                                        if (resetPending) {
                                            contResetTimer.start()
                                        } else {
                                            if (Math.abs(value - 1.0) < 0.12) value = 1.0
                                            backend.processContrast(value, false)
                                        }
                                    }
                                }
                                onValueChanged: {
                                    if (pressed && !resetPending) {
                                        if (Math.abs(value - 1.0) < 0.05 && value !== 1.0) value = 1.0
                                        let now = Date.now()
                                        if (now - lastUpdate > 60) {
                                            backend.processContrast(value, false)
                                            lastUpdate = now
                                        }
                                    }
                                }
                            }

                            Button {
                                text: "Reset"
                                enabled: hasImage && parent.parent.isChanged
                                onClicked: { contrastSlider.value = 1.0; backend.processContrast(1.0, false) }
                            }

                            Button {
                                text: "Aplicar"
                                enabled: hasImage && parent.parent.isChanged
                                onClicked: { backend.processContrast(contrastSlider.value, true); contrastSlider.value = 1.0 }
                            }
                        }
                    }

                    Button {
                        text: "Negativo da Imagem"
                        Layout.fillWidth: true
                        enabled: hasImage
                        onClicked: { resetOthers("negative"); backend.applyNegative() }
                    }

                    Button {
                        text: "Alongamento de Contraste"
                        Layout.fillWidth: true
                        enabled: hasImage
                        onClicked: { resetOthers("stretching"); backend.applyContrastStretching() }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 5
                        Button {
                            text: "Equalização de Histograma"
                            Layout.fillWidth: true
                            enabled: hasImage
                            onClicked: { resetOthers("equalization"); backend.applyHistogramEqualization(claheCheckbox.checked) }
                        }
                        CheckBox { id: claheCheckbox; text: "CLAHE"; checked: true; font.pixelSize: 11; enabled: hasImage }
                    }

                    Rectangle { height: 1; Layout.fillWidth: true; color: "gray" }
                    Text { text: "<b>Transformações Geométricas</b>" }

                    // Rotation control
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        property bool isChanged: rotationSlider.value !== 0

                        Text {
                            text: "Rotação: " + Math.round(rotationSlider.value) + "°"
                            font.pixelSize: 12; color: hasImage ? "#333" : "#888"
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Slider {
                                id: rotationSlider
                                Layout.fillWidth: true
                                enabled: hasImage
                                from: -180; to: 180; value: 0; stepSize: 1
                                property real lastUpdate: 0
                                property real clickTime: 0
                                property bool resetPending: false

                                Timer {
                                    id: rotResetTimer
                                    interval: 50
                                    onTriggered: {
                                        rotationSlider.value = 0
                                        backend.processRotation(0, false)
                                        rotationSlider.resetPending = false
                                    }
                                }

                                onPressedChanged: {
                                    if (pressed) {
                                        let now = Date.now()
                                        if (now - clickTime < 300) {
                                            resetPending = true
                                        } else {
                                            resetOthers("rotation")
                                        }
                                        clickTime = now
                                    } else {
                                        if (resetPending) {
                                            rotResetTimer.start()
                                        } else {
                                            if (Math.abs(value) < 8) value = 0
                                            backend.processRotation(value, false)
                                        }
                                    }
                                }
                                onValueChanged: {
                                    if (pressed && !resetPending) {
                                        if (Math.abs(value) < 4 && value !== 0) value = 0
                                        let now = Date.now()
                                        if (now - lastUpdate > 60) {
                                            backend.processRotation(value, false)
                                            lastUpdate = now
                                        }
                                    }
                                }
                            }

                            Button {
                                text: "Reset"
                                enabled: hasImage && parent.parent.isChanged
                                onClicked: { rotationSlider.value = 0; backend.processRotation(0, false) }
                            }

                            Button {
                                text: "Aplicar"
                                enabled: hasImage && parent.parent.isChanged
                                onClicked: { backend.processRotation(rotationSlider.value, true); rotationSlider.value = 0 }
                            }
                        }
                    }

                    // Translation joystick control
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4
                        property bool isChanged: Math.round(joystickHandle.dx) !== 0 || Math.round(joystickHandle.dy) !== 0

                        Text {
                            text: "Translação X: " + Math.round(joystickHandle.dx) + "px | Y: " + Math.round(joystickHandle.dy) + "px"
                            font.pixelSize: 12; color: hasImage ? "#333" : "#888"
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10

                            Rectangle {
                                id: joystickPad
                                width: 140; height: 140; color: "#f0f0f0"; border.color: "#888888"; border.width: 1
                                enabled: hasImage

                                property real globalClickTime: 0

                                Rectangle { width: parent.width; height: 1; color: "#dddddd"; anchors.centerIn: parent }
                                Rectangle { width: 1; height: parent.height; color: "#dddddd"; anchors.centerIn: parent }

                                Timer {
                                    id: joyGlobalResetTimer
                                    interval: 10
                                    onTriggered: {
                                        centerJoystick()
                                        backend.processTranslation(0, 0, false)
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    enabled: hasImage
                                    property bool resetPending: false

                                    onPressed: (mouse) => {
                                        if (!hasImage) return
                                        let now = Date.now()
                                        if (now - joystickPad.globalClickTime < 300) {
                                            resetPending = true
                                            joystickPad.globalClickTime = 0
                                        } else {
                                            joystickPad.globalClickTime = now
                                            resetOthers("joystick")
                                            let maxTravel = joystickPad.width - joystickHandle.width
                                            let nx = mouse.x - joystickHandle.width / 2
                                            let ny = mouse.y - joystickHandle.height / 2

                                            joystickHandle.x = Math.max(0, Math.min(nx, maxTravel))
                                            joystickHandle.y = Math.max(0, Math.min(ny, maxTravel))
                                            backend.processTranslation(Math.round(joystickHandle.dx), Math.round(joystickHandle.dy), false)
                                        }
                                    }
                                    onReleased: {
                                        if (resetPending) {
                                            joyGlobalResetTimer.start()
                                            resetPending = false
                                        }
                                    }
                                }

                                Rectangle {
                                    id: joystickHandle
                                    width: 20; height: 20; radius: 10; color: hasImage ? "#007acc" : "#aaaaaa"; x: 60; y: 60
                                    property real dx: ((x / 120) * 2 - 1) * imgWidth
                                    property real dy: ((y / 120) * 2 - 1) * imgHeight
                                    property real lastUpdate: 0

                                    TapHandler {
                                        enabled: hasImage
                                        property bool resetPending: false
                                        onPressedChanged: {
                                            if (pressed) {
                                                let now = Date.now()
                                                if (now - joystickPad.globalClickTime < 300) {
                                                    resetPending = true
                                                    joystickPad.globalClickTime = 0
                                                } else {
                                                    joystickPad.globalClickTime = now
                                                    resetOthers("joystick")
                                                }
                                            } else {
                                                if (resetPending) {
                                                    joyGlobalResetTimer.start()
                                                    resetPending = false
                                                }
                                            }
                                        }
                                    }

                                    DragHandler {
                                        id: dragHandler; target: joystickHandle
                                        enabled: hasImage
                                        xAxis.minimum: 0; xAxis.maximum: joystickPad.width - joystickHandle.width
                                        yAxis.minimum: 0; yAxis.maximum: joystickPad.height - joystickHandle.height
                                        onActiveChanged: {
                                            if (active) resetOthers("joystick")
                                            else backend.processTranslation(Math.round(joystickHandle.dx), Math.round(joystickHandle.dy), false)
                                        }
                                    }

                                    onXChanged: throttleUpdate()
                                    onYChanged: throttleUpdate()

                                    function throttleUpdate() {
                                        if (dragHandler.active) {
                                            if (Math.abs(x - 60) < 5 && Math.abs(y - 60) < 5 && (x !== 60 || y !== 60)) {
                                                x = 60
                                                y = 60
                                            }
                                            let now = Date.now()
                                            if (now - lastUpdate > 60) {
                                                backend.processTranslation(Math.round(dx), Math.round(dy), false)
                                                lastUpdate = now
                                            }
                                        }
                                    }
                                }
                            }

                            ColumnLayout {
                                Button {
                                    text: "Reset"
                                    enabled: hasImage && parent.parent.parent.isChanged
                                    onClicked: { centerJoystick(); backend.processTranslation(0, 0, false) }
                                }
                                Button {
                                    text: "Aplicar"
                                    enabled: hasImage && parent.parent.parent.isChanged
                                    onClicked: {
                                        backend.processTranslation(Math.round(joystickHandle.dx), Math.round(joystickHandle.dy), true)
                                        centerJoystick()
                                    }
                                }
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 5
                        Button { text: "Espelhar Horiz."; Layout.fillWidth: true; enabled: hasImage; onClicked: { resetOthers("mirrorH"); backend.applyMirror(1) } }
                        Button { text: "Espelhar Vert."; Layout.fillWidth: true; enabled: hasImage; onClicked: { resetOthers("mirrorV"); backend.applyMirror(0) } }
                    }

                    Rectangle { height: 1; Layout.fillWidth: true; color: "gray" }
                    Text { text: "<b>Transformações por Vizinhança</b>" }

                    // Mean filter control
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        property bool isChanged: meanSlider.value >= 3

                        Text {
                            text: parent.isChanged ? "Filtro da Média (Kernel: " + Math.round(meanSlider.value) + "x" + Math.round(meanSlider.value) + ")" : "Filtro da Média (Desativado)"
                            font.pixelSize: 12; color: (hasImage && parent.isChanged) ? "#333" : "#888"
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10

                            Slider {
                                id: meanSlider
                                Layout.fillWidth: true
                                enabled: hasImage
                                from: 1; to: 9; value: 1; stepSize: 2
                                snapMode: Slider.SnapAlways

                                property real lastUpdate: 0
                                property real clickTime: 0
                                property bool resetPending: false

                                Timer {
                                    id: meanResetTimer
                                    interval: 50
                                    onTriggered: {
                                        meanSlider.value = 1
                                        backend.processMeanFilter(1, false)
                                        meanSlider.resetPending = false
                                    }
                                }

                                onPressedChanged: {
                                    if (pressed) {
                                        let now = Date.now()
                                        if (now - clickTime < 300) {
                                            resetPending = true
                                        } else {
                                            resetOthers("mean")
                                        }
                                        clickTime = now
                                    } else {
                                        if (resetPending) {
                                            meanResetTimer.start()
                                        } else {
                                            backend.processMeanFilter(Math.round(value), false)
                                        }
                                    }
                                }
                                onValueChanged: {
                                    if (pressed && !resetPending) {
                                        let now = Date.now()
                                        if (now - lastUpdate > 60) {
                                            backend.processMeanFilter(Math.round(value), false)
                                            lastUpdate = now
                                        }
                                    }
                                }
                            }

                            Button {
                                text: "Reset"
                                enabled: hasImage && parent.parent.isChanged
                                onClicked: { meanSlider.value = 1; backend.processMeanFilter(1, false) }
                            }

                            Button {
                                text: "Aplicar"
                                enabled: hasImage && parent.parent.isChanged
                                onClicked: { backend.processMeanFilter(Math.round(meanSlider.value), true); meanSlider.value = 1 }
                            }
                        }
                    }

                    // Gaussian filter control
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        property bool isChanged: gaussKernelSlider.value >= 3

                        Text {
                            text: parent.isChanged ? "Filtro Gaussiano (Kernel: " + Math.round(gaussKernelSlider.value) + "x" + Math.round(gaussKernelSlider.value) + " | σ: " + (gaussSigmaSpin.value / 10.0).toFixed(1) + ")" : "Filtro Gaussiano (Desativado)"
                            font.pixelSize: 12; color: (hasImage && parent.isChanged) ? "#333" : "#888"
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10

                            Slider {
                                id: gaussKernelSlider
                                Layout.fillWidth: true
                                enabled: hasImage
                                from: 1; to: 9; value: 1; stepSize: 2
                                snapMode: Slider.SnapAlways

                                property real lastUpdate: 0
                                property real clickTime: 0
                                property bool resetPending: false

                                Timer {
                                    id: gaussResetTimer
                                    interval: 50
                                    onTriggered: {
                                        gaussKernelSlider.value = 1
                                        gaussSigmaSpin.value = 15
                                        backend.processGaussianFilter(1, 0, false)
                                        gaussKernelSlider.resetPending = false
                                    }
                                }

                                onPressedChanged: {
                                    if (pressed) {
                                        let now = Date.now()
                                        if (now - clickTime < 300) {
                                            resetPending = true
                                        } else {
                                            resetOthers("gauss")
                                        }
                                        clickTime = now
                                    } else {
                                        if (resetPending) {
                                            gaussResetTimer.start()
                                        } else {
                                            backend.processGaussianFilter(Math.round(value), gaussSigmaSpin.realValue, false)
                                        }
                                    }
                                }
                                onValueChanged: {
                                    if (pressed && !resetPending) {
                                        let now = Date.now()
                                        if (now - lastUpdate > 60) {
                                            backend.processGaussianFilter(Math.round(value), gaussSigmaSpin.realValue, false)
                                            lastUpdate = now
                                        }
                                    }
                                }
                            }

                            SpinBox {
                                id: gaussSigmaSpin
                                enabled: hasImage && parent.parent.isChanged
                                from: 0; to: 100; value: 15; stepSize: 5
                                Layout.preferredWidth: 80

                                property real realValue: value / 10.0
                                textFromValue: function(value, locale) { return Number(value / 10.0).toLocaleString(locale, 'f', 1) }
                                valueFromText: function(text, locale) { return Number.fromLocaleString(locale, text) * 10 }

                                onValueChanged: {
                                    if (parent.parent.isChanged && !gaussKernelSlider.pressed) {
                                        backend.processGaussianFilter(Math.round(gaussKernelSlider.value), realValue, false)
                                    }
                                }
                            }

                            Button {
                                text: "Reset"
                                enabled: hasImage && parent.parent.isChanged
                                onClicked: { gaussKernelSlider.value = 1; gaussSigmaSpin.value = 15; backend.processGaussianFilter(1, 0, false) }
                            }

                            Button {
                                text: "Aplicar"
                                enabled: hasImage && parent.parent.isChanged
                                onClicked: {
                                    backend.processGaussianFilter(Math.round(gaussKernelSlider.value), gaussSigmaSpin.realValue, true)
                                    gaussKernelSlider.value = 1
                                    gaussSigmaSpin.value = 15
                                }
                            }
                        }
                    }

                    Button {
                        text: "Adicionar Ruído"
                        Layout.fillWidth: true
                        enabled: hasImage
                        onClicked: { resetOthers("noise"); backend.addNoise() }
                    }
                }
            }

            // Central viewport section
            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 10

                // Main image viewport
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: "#e0e0e0"
                    border.color: "#999999"

                    Button {
                        text: "Abrir Imagem"
                        visible: !hasImage
                        anchors.centerIn: parent
                        font.pixelSize: 15
                        font.bold: true
                        palette.buttonText: "#333333"
                        onClicked: openDialog.open()
                    }

                    Image {
                        id: imageViewer
                        anchors.fill: parent
                        anchors.margins: 5
                        fillMode: Image.PreserveAspectFit
                        cache: false
                        visible: hasImage
                    }
                }

                // Histogram viewport (fixed 420px width)
                Rectangle {
                    visible: showHistogram && hasImage
                    Layout.preferredWidth: 420
                    Layout.fillHeight: true
                    color: "#f5f5f5"
                    border.color: "#999999"

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 5

                        Text {
                            text: "<b>Histograma de Intensidades</b>"
                            Layout.alignment: Qt.AlignHCenter
                            font.pixelSize: 13
                        }

                        Image {
                            id: histogramViewer
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            fillMode: Image.PreserveAspectFit
                            cache: false
                            visible: hasImage
                        }
                    }
                }
            }
        }
    }

    Connections {
        target: backend
        function onImageChanged(imgUrl) {
            hasImage = true
            imageViewer.source = ""
            imageViewer.source = imgUrl
        }
        function onHistogramChanged(histUrl) {
            histogramViewer.source = ""
            histogramViewer.source = histUrl
        }
        function onDimensionsChanged(w, h) {
            imgWidth = w
            imgHeight = h
        }
        function onErrorOcurred(msg) {
            warningDialog.text = msg
            warningDialog.open()
        }
        function onRequestSaveAs(suggestedUrl) {
            saveAsDialog.currentFile = suggestedUrl
            saveAsDialog.open()
        }
    }
}
