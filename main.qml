import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

Window {
    width: 980
    height: 750
    visible: true
    title: qsTr("Adulis Photoshop")

    FileDialog {
        id: openDialog
        title: "Abrir Imagem"
        nameFilters: ["Imagens (*.png *.jpg *.jpeg)"]
        onAccepted: {
            backend.loadImage(selectedFile.toString())
        }
    }

    FileDialog {
        id: saveAsDialog
        title: "Salvar Imagem Como"
        fileMode: FileDialog.SaveFile
        nameFilters: ["Imagens (*.png *.jpg *.jpeg)"]
        onAccepted: {
            backend.saveImage(selectedFile.toString())
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        MenuBar {
            Layout.fillWidth: true
            Menu {
                title: qsTr("Arquivo")
                MenuItem {
                    text: qsTr("Abrir...")
                    onTriggered: openDialog.open()
                }
                MenuItem {
                    text: qsTr("Salvar")
                    onTriggered: backend.saveDefault()
                }
                MenuItem {
                    text: qsTr("Salvar Como...")
                    onTriggered: saveAsDialog.open()
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.margins: 10
            spacing: 15

            ScrollView {
                Layout.preferredWidth: 310
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
                            }
                            Button {
                                text: "Aplicar"
                                onClicked: {
                                    backend.applyBrightness(Math.round(brightnessSlider.value))
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
                            }
                            Button {
                                text: "Aplicar"
                                onClicked: {
                                    backend.applyRotation(rotationSlider.value)
                                    rotationSlider.value = 0
                                }
                            }
                        }
                    }

                    // --- TRANSLAÇÃO (JOYSTICK) ---
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4

                        Text {
                            text: "Translação (Joystick)"
                            font.pixelSize: 12
                        }

                        GridLayout {
                            columns: 3
                            rows: 3
                            Layout.alignment: Qt.AlignHCenter

                            Item { width: 40; height: 35 } // Espaço vazio topo-esquerdo

                            Button {
                                text: "▲"
                                implicitWidth: 40
                                implicitHeight: 35
                                onClicked: backend.applyTranslation(0, -20)
                            }

                            Item { width: 40; height: 35 } // Espaço vazio topo-direito

                            Button {
                                text: "◄"
                                implicitWidth: 40
                                implicitHeight: 35
                                onClicked: backend.applyTranslation(-20, 0)
                            }

                            Button {
                                text: "●"
                                implicitWidth: 40
                                implicitHeight: 35
                                onClicked: backend.applyTranslation(0, 0)
                            }

                            Button {
                                text: "►"
                                implicitWidth: 40
                                implicitHeight: 35
                                onClicked: backend.applyTranslation(20, 0)
                            }

                            Item { width: 40; height: 35 } // Espaço vazio baixo-esquerdo

                            Button {
                                text: "▼"
                                implicitWidth: 40
                                implicitHeight: 35
                                onClicked: backend.applyTranslation(0, 20)
                            }

                            Item { width: 40; height: 35 } // Espaço vazio baixo-direito
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
        function onErrorOcurred(msg) {
            console.warn(msg)
        }
        function onRequestSaveAs() {
            saveAsDialog.open()
        }
    }
}
