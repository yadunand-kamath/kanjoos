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
        implicitWidth: 90
        implicitHeight: 32
        radius: 6
        color: clearBtn.hovered ? "#333" : "#222"

        // Smoothly transition the color change
        Behavior on color { ColorAnimation { duration: 150 } }

        border.width: 1
        border.color: clearBtn.hovered ? "white" : "transparent"
    }
}
