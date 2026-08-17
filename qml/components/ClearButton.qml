import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Button {
    id: clearBtn
    text: "Clear All"
    flat: true
    Layout.alignment: Qt.AlignHCenter
    palette.buttonText: "white"
    hoverEnabled: true

    background: Rectangle {
        implicitWidth: 90; implicitHeight: 32
        radius: 6
        color: clearBtn.hovered ? "#2e0a0a" : "#222"
        border.width: 1
        border.color: clearBtn.hovered ? "#8b0000" : "transparent"
        Behavior on color       { ColorAnimation { duration: 150 } }
        Behavior on border.color { ColorAnimation { duration: 150 } }
    }
}
