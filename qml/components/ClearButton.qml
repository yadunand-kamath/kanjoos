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

    onClicked: {
        income1.text = ''; income2.text = ''; income3.text = ''; income4.text = '';
        expense1.text = ''; expense2.text = ''; expense3.text = ''; expense4.text = '';
    }

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
