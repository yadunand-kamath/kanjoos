import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    id: root
    property string label: ""
    property alias text: field.text
    property color focusColor: "#a29bfe"
    property alias validator: field.validator
    signal edited(string value)

    spacing: 4

    Text {
        text: root.label
        color: "#757575"; font.pixelSize: 10; font.letterSpacing: 1.2
    }

    TextField {
        id: field
        Layout.fillWidth: true
        color: "white"; font.pixelSize: 16; font.weight: Font.DemiBold
        selectByMouse: true
        background: Rectangle { color: "transparent" }
        leftPadding: 0

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
