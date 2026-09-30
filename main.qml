import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

Window {
    width: 1000
    height: 800
    visible: true
    title: qsTr("Adulis Pythonshop")

    property int imgWidth: 800
    property int imgHeight: 600

    function resetOthers(activeControl) {
        if (activeControl !== "brightness" && brightnessSlider.value !== 0) {
            brightnessSlider.value = 0
        }
        if (activeControl !== "rotation" && rotationSlider.value !== 0) {
            rotationSlider.value = 0
        }
        if (activeControl !== "joystick" && (joystickHandle.x !== 60 || joystickHandle.y !== 60)) {
            centerJoystick()
            backend.processTranslation(0, 0, false)
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

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        MenuBar {
            Layout.fillWidth: true
            Menu {
                title: qsTr("Arquivo")
                MenuItem { text: qsTr("Abrir..."); onTriggered: openDialog.open() }
                MenuItem { text: qsTr("Salvar"); onTriggered: backend.saveDefault() }
                MenuItem { text: qsTr("Salvar Como..."); onTriggered: saveAsDialog.open() }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.margins: 10
            spacing: 15

            ScrollView {
                Layout.preferredWidth: 320
                Layout.fillHeight: true

                ColumnLayout {
                    width: parent.width - 15
                    spacing: 10

                    Button {
                        text: "Resetar Imagem"
                        Layout.fillWidth: true
                        palette.buttonText: "#d9534f"
                        onClicked: backend.resetImage()
                    }

                    Rectangle { height: 1; Layout.fillWidth: true; color: "gray" }
                    Text { text: "<b>Transformações Pontuais</b>" }

                    Button {
                        text: "Escala de Cinza"
                        Layout.fillWidth: true
                        onClicked: backend.applyGrayscale()
                    }

                    // --- AJUSTE DE BRILHO ---
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            text: "Ajuste de Brilho: " + Math.round(brightnessSlider.value)
                            font.pixelSize: 12
                            color: "#333"
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Slider {
                                id: brightnessSlider
                                Layout.fillWidth: true
                                from: -255
                                to: 255
                                value: 0
                                stepSize: 1

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
                                            backend.processBrightness(Math.round(value), false)
                                        }
                                    }
                                }
                                onValueChanged: {
                                    if (pressed && !resetPending) {
                                        let now = Date.now()
                                        if (now - lastUpdate > 60) {
                                            backend.processBrightness(Math.round(value), false)
                                            lastUpdate = now
                                        }
                                    }
                                }
                            }
                            Button {
                                text: "Aplicar"
                                onClicked: {
                                    backend.processBrightness(Math.round(brightnessSlider.value), true)
                                    brightnessSlider.value = 0
                                }
                            }
                        }
                    }

                    Button {
                        text: "Negativo da Imagem"
                        Layout.fillWidth: true
                        onClicked: backend.applyNegative()
                    }

                    Rectangle { height: 1; Layout.fillWidth: true; color: "gray" }
                    Text { text: "<b>Transformações Geométricas</b>" }

                    // --- ROTAÇÃO ---
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            text: "Rotação: " + Math.round(rotationSlider.value) + "°"
                            font.pixelSize: 12
                            color: "#333"
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Slider {
                                id: rotationSlider
                                Layout.fillWidth: true
                                from: -180
                                to: 180
                                value: 0
                                stepSize: 1

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
                                            backend.processRotation(value, false)
                                        }
                                    }
                                }
                                onValueChanged: {
                                    if (pressed && !resetPending) {
                                        let now = Date.now()
                                        if (now - lastUpdate > 60) {
                                            backend.processRotation(value, false)
                                            lastUpdate = now
                                        }
                                    }
                                }
                            }
                            Button {
                                text: "Aplicar"
                                onClicked: {
                                    backend.processRotation(rotationSlider.value, true)
                                    rotationSlider.value = 0
                                }
                            }
                        }
                    }

                    // --- TRANSLAÇÃO ---
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4

                        Text {
                            text: "Translação X: " + Math.round(joystickHandle.dx) + "px | Y: " + Math.round(joystickHandle.dy) + "px"
                            font.pixelSize: 12
                            color: "#333"
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10

                            Rectangle {
                                id: joystickPad
                                width: 140
                                height: 140
                                color: "#f0f0f0"
                                border.color: "#888888"
                                border.width: 1

                                // Memória global do joystick (partilhada entre o fundo e a bolinha)
                                property real globalClickTime: 0

                                Rectangle { width: parent.width; height: 1; color: "#dddddd"; anchors.centerIn: parent }
                                Rectangle { width: 1; height: parent.height; color: "#dddddd"; anchors.centerIn: parent }

                                // Temporizador de reset unificado
                                Timer {
                                    id: joyGlobalResetTimer
                                    interval: 10
                                    onTriggered: {
                                        centerJoystick()
                                        backend.processTranslation(0, 0, false)
                                    }
                                }

                                // Camada do Fundo (MouseArea)
                                MouseArea {
                                    anchors.fill: parent
                                    property bool resetPending: false

                                    onPressed: (mouse) => {
                                        let now = Date.now()
                                        if (now - joystickPad.globalClickTime < 300) {
                                            resetPending = true
                                            joystickPad.globalClickTime = 0 // Evita clique triplo
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

                                // Camada da Bolinha (Handle)
                                Rectangle {
                                    id: joystickHandle
                                    width: 20
                                    height: 20
                                    radius: 10
                                    color: "#007acc"
                                    x: 60
                                    y: 60

                                    property real dx: ((x / 120) * 2 - 1) * imgWidth
                                    property real dy: ((y / 120) * 2 - 1) * imgHeight
                                    property real lastUpdate: 0

                                    // TapHandler focado APENAS na bolinha (impede o roubo do duplo clique)
                                    TapHandler {
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
                                            } else { // onReleased
                                                if (resetPending) {
                                                    joyGlobalResetTimer.start()
                                                    resetPending = false
                                                }
                                            }
                                        }
                                    }

                                    DragHandler {
                                        id: dragHandler
                                        target: joystickHandle
                                        xAxis.minimum: 0
                                        xAxis.maximum: joystickPad.width - joystickHandle.width
                                        yAxis.minimum: 0
                                        yAxis.maximum: joystickPad.height - joystickHandle.height

                                        onActiveChanged: {
                                            if (active) resetOthers("joystick")
                                            else backend.processTranslation(Math.round(joystickHandle.dx), Math.round(joystickHandle.dy), false)
                                        }
                                    }

                                    onXChanged: throttleUpdate()
                                    onYChanged: throttleUpdate()

                                    function throttleUpdate() {
                                        if (dragHandler.active) {
                                            let now = Date.now()
                                            if (now - lastUpdate > 60) {
                                                backend.processTranslation(Math.round(dx), Math.round(dy), false)
                                                lastUpdate = now
                                            }
                                        }
                                    }
                                }
                            }

                            Button {
                                text: "Aplicar"
                                Layout.alignment: Qt.AlignVCenter
                                onClicked: {
                                    backend.processTranslation(Math.round(joystickHandle.dx), Math.round(joystickHandle.dy), true)
                                    centerJoystick()
                                }
                            }
                        }
                    }

                    Button {
                        text: "Espelhamento Horizontal"
                        Layout.fillWidth: true
                        onClicked: backend.applyMirror(1)
                    }

                    Rectangle { height: 1; Layout.fillWidth: true; color: "gray" }
                    Text { text: "<b>Transformações por Vizinhança</b>" }

                    Button {
                        text: "Filtro da Média (Kernel 5x5)"
                        Layout.fillWidth: true
                        onClicked: backend.applyMeanFilter(5)
                    }
                    Button {
                        text: "Filtro Gaussiano (5x5, σ=1.5)"
                        Layout.fillWidth: true
                        onClicked: backend.applyGaussianFilter(5, 1.5)
                    }
                    Button {
                        text: "Adicionar Ruído"
                        Layout.fillWidth: true
                        onClicked: backend.addNoise()
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: "#e0e0e0"
                border.color: "#999999"

                Image {
                    id: imageViewer
                    anchors.fill: parent
                    anchors.margins: 5
                    fillMode: Image.PreserveAspectFit
                    cache: false
                }
            }
        }
    }

    Connections {
        target: backend
        function onImageChanged(imgUrl) {
            imageViewer.source = ""
            imageViewer.source = imgUrl
        }
        function onDimensionsChanged(w, h) {
            imgWidth = w;
            imgHeight = h;
        }
        function onErrorOcurred(msg) {
            console.warn(msg)
        }
        function onRequestSaveAs() {
            saveAsDialog.open()
        }
    }
}
