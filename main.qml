import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

Window {
    width: 950
    height: 700
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

        // Barra de Menu Superior
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

        // Layout Principal (Painel Lateral + Visualizador)
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.margins: 10
            spacing: 15

            ScrollView {
                Layout.preferredWidth: 260
                Layout.fillHeight: true

                ColumnLayout {
                    width: parent.width
                    spacing: 10

                    Button {
                        text: "Resetar"
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
                    Button {
                        text: "Ajuste de Brilho (+30)"
                        Layout.fillWidth: true
                        onClicked: backend.applyBrightness(30)
                    }
                    Button {
                        text: "Negativo da Imagem"
                        Layout.fillWidth: true
                        onClicked: backend.applyNegative()
                    }

                    Rectangle { height: 1; Layout.fillWidth: true; color: "gray" }
                    Text { text: "<b>Transformações Geométricas</b>" }

                    Button {
                        text: "Rotação (45º)"
                        Layout.fillWidth: true
                        onClicked: backend.applyRotation(45)
                    }
                    Button {
                        text: "Translação (X:50, Y:50)"
                        Layout.fillWidth: true
                        onClicked: backend.applyTranslation(50, 50)
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
