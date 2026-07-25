import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Basic

ComboBox {
    id: control
    font.pixelSize: 12

    // Custom Chevron Indicator
    indicator: Text {
        x: control.width - width - control.rightPadding
        y: control.topPadding + (control.availableHeight - height) / 2
        text: "▼"
        font.pixelSize: 8
        color: control.hovered || control.opened ? "white" : "#444"
        Behavior on color { ColorAnimation { duration: 150 } }
    }

    // Text Display
    contentItem: Text {
        leftPadding: 0
        text: control.displayText
        font: control.font
        color: control.hovered || control.opened ? "white" : "#888888"
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }

    // Popup Styling
    delegate: ItemDelegate {
        width: control.width
        contentItem: Text {
            text: control.textRole ? (model[control.textRole] || "") : (typeof modelData !== "undefined" ? modelData : "")
            color: highlighted ? "white" : "#888888"
            font: control.font
            verticalAlignment: Text.AlignVCenter
        }
        background: Rectangle {
            color: highlighted ? "#121212" : "#1A1A1A"
        }
    }

    background: Rectangle {
        color: "transparent" // Brutalist: No border or box around dropdown
    }
}