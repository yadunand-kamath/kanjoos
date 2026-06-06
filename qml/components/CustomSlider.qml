import QtQuick

Item {
    id: root
    property real value: 0
    property real from: 0
    property real to: 100
    property color accentColor: "#FFFFFF"
    signal moved(real val)

    implicitWidth: 180
    implicitHeight: 30

    // Background Track
    Rectangle {
        id: track
        width: parent.width
        height: 8
        anchors.verticalCenter: parent.verticalCenter
        color: "#2A2A2A"
        radius: 4

        // Fill Progress
        Rectangle {
            width: (root.value - root.from) / (root.to - root.from) * parent.width
            height: parent.height
            color: root.accentColor
            radius: 4
            Behavior on width { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
        }
    }

    // Interactive Thumb
    Rectangle {
        id: thumb
        width: 10
        height: 24
        radius: 5
        color: "#FFFFFF"
        anchors.verticalCenter: parent.verticalCenter
        x: (root.value - root.from) / (root.to - root.from) * (root.width - width)

        // Visual shadow/glow for premium feel
        border.color: "#000"
        border.width: 1
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onPositionChanged: (mouse) => {
            if (pressed) {
                let pos = Math.max(0, Math.min(mouse.x, width));
                let newVal = root.from + (pos / width) * (root.to - root.from);
                root.moved(Math.round(newVal));
            }
        }
        onPressed: (mouse) => {
            let pos = Math.max(0, Math.min(mouse.x, width));
            let newVal = root.from + (pos / width) * (root.to - root.from);
            root.moved(Math.round(newVal));
        }
    }
}