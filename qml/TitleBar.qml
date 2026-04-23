import QtQuick 2.15
import QtQuick.Controls

Rectangle {
    id: titleBar
    height: 50
    color: "black"

    FontLoader {
        id: titleFont
        source: "../assets/fonts/BJCree-Bold.ttf"
    }

    // App Title
    Text {
        id: titleId
        text: "kanjoos"
        color: "white"
        anchors.centerIn: parent

        font.family: titleFont.name
        font.pixelSize: 22
        font.weight: Font.Bold
        font.letterSpacing: 1.5

        renderType: Text.NativeRendering
    }
}
