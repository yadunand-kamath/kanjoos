import QtQuick
import QtQuick.Controls

Row {
    id: root
    property bool isAnnual: false
    property color accent: "#a29bfe"
    signal changed(bool annual)

    spacing: 4

    Rectangle {
        width: 44; height: 22; radius: 6
        color: !root.isAnnual ? root.accent : "transparent"
        border.color: !root.isAnnual ? root.accent : "#333"
        Text {
            anchors.centerIn: parent
            text: "M"; font.pixelSize: 10; font.bold: true
            color: !root.isAnnual ? "#0d0d0d" : "#888"
        }
        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.changed(false) }
    }
    Rectangle {
        width: 44; height: 22; radius: 6
        color: root.isAnnual ? root.accent : "transparent"
        border.color: root.isAnnual ? root.accent : "#333"
        Text {
            anchors.centerIn: parent
            text: "A"; font.pixelSize: 10; font.bold: true
            color: root.isAnnual ? "#0d0d0d" : "#888"
        }
        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.changed(true) }
    }
}
