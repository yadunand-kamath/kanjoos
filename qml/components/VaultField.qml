import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    id: root
    property string label: ""
    property alias text: field.text
    property color focusColor: "#a29bfe"
    property alias validator: field.validator
    property bool rightAligned: false
    signal edited(string value)

    spacing: 2

    Text {
        text: root.label
        color: "#666"; font.pixelSize: 9; font.letterSpacing: 1
    }

    TextField {
        id: field
        Layout.fillWidth: true
        color: "white"; font.pixelSize: 13
        horizontalAlignment: root.rightAligned ? Text.AlignRight : Text.AlignLeft
        leftPadding: root.rightAligned ? 0 : 2
        rightPadding: 0
        selectByMouse: true
        background: Rectangle { color: "transparent" }

        onTextEdited: {
            let pos      = cursorPosition;
            let stripped = text.replace(/^0+(\d)/, '$1');
            if (stripped !== text) {
                let removed    = text.length - stripped.length;
                text           = stripped;
                cursorPosition = Math.max(0, pos - removed);
            }
        }

        onEditingFinished: root.edited(text)
    }

    Rectangle {
        Layout.fillWidth: true
        height: 1
        color: field.activeFocus ? root.focusColor : "#2A2A2A"
        Behavior on color { ColorAnimation { duration: 150 } }
    }
}
