import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Button {
    id: saveBtn
    text: "Save"
    flat: true
    Layout.alignment: Qt.AlignHCenter
    palette.buttonText: "white"
    hoverEnabled: true

    onClicked: {}

    background: Rectangle {
        implicitWidth: 90; implicitHeight: 32
        radius: 6
        color: saveBtn.hovered ? "#0a2e14" : "#222"
        border.width: 1
        border.color: saveBtn.hovered ? "#1a7a3a" : "transparent"
        Behavior on color       { ColorAnimation { duration: 150 } }
        Behavior on border.color { ColorAnimation { duration: 150 } }
    }
}
