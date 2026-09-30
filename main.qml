import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

Window {
    width: 900
    height: 700
    visible: true
    title: qsTr("Adulis Pythonshop")

    FileDialog {
        id: fileDialog
        title: "Carregar Imagem"
        nameFilters: ["Imagens (*.png *.jpg *.jpeg)"]
        onAccepted: {
            backend.loadImage(selectedFile.toString())
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 15

        ScrollView {
            Layout.preferredWidth: 250
            Layout.fillHeight: true

            ColumnLayout {
                width: parent.width
                spacing: 10

                Button {
                    text: "1. Carregar Imagem (JPG/PNG)"
                    Layout.fillWidth: true
                    onClicked: fileDialog.open()
                }

                CheckBox {
                    id: toggleOriginal
                    text: "Aplicar na Imagem Original"
                    onCheckedChanged: backend.setUseOriginal(checked)
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

    Connections {
        target: backend
        function onImageChanged(imgUrl) {
            imageViewer.source = ""
            imageViewer.source = imgUrl
        }
        function onErrorOcurred(msg) {
            console.warn(msg)
        }
    }
}
