import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

RowLayout {
    id: root
    property string label: ""
    property bool checked: false
    property color accent: "#a29bfe"
    signal toggled(bool value)

    spacing: 10

    Rectangle {
        id: box
        width: 20; height: 20; radius: 4
        color: root.checked ? root.accent : "transparent"
        border.color: root.checked ? root.accent : "#444"
        border.width: 1.5
        Behavior on color { ColorAnimation { duration: 120 } }

        Text {
            anchors.centerIn: parent
            visible: root.checked
            text: "✓"; color: "#0d0d0d"; font.pixelSize: 12; font.bold: true
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.toggled(!root.checked)
        }
    }

    Text {
        text: root.label
        color: "#cccccc"; font.pixelSize: 13
        Layout.fillWidth: true
        wrapMode: Text.WordWrap

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.toggled(!root.checked)
        }
    }
}
