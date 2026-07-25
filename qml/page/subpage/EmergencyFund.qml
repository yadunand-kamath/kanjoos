import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "../../components"

Item {
    id: emergencyFundRoot
    Layout.fillWidth: true
    Layout.fillHeight: true

    // Emergeny Fund Properties
    property real currentSavings: parseFloat(savingsInput.text) || 0
    property int multiplierIndex: 0

    readonly property real activeSalary: multiplierIndex === 2 ? parseFloat(salaryInput.text) || 0 : root.globalMonthlyIncome
    readonly property real baseAmount: Math.max(activeSalary, root.globalMonthlyExpense)
    readonly property real activeMultiplier: multiplierIndex === 0 ? 6 : (multiplierIndex === 1 ? 12 : parseFloat(customInput.text) || 0)
    readonly property real targetAmount: baseAmount * activeMultiplier
    readonly property real progress: targetAmount > 0 ? Math.min(currentSavings / targetAmount, 1.0) : 0
    readonly property real runwayMonths: root.globalMonthlyExpense > 0 ? (currentSavings / root.globalMonthlyExpense) : 0

    ColumnLayout {
        anchors.centerIn: parent
        width: parent.width * 0.8
        spacing: 5 // whitespace between sections

        // Savings Input
        ColumnLayout {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 15
            spacing: 10

            Text { text: "HOW MUCH DO YOU HAVE SAVED TODAY?"; color: "#888"; font.pixelSize: 11; font.letterSpacing: 1; Layout.alignment: Qt.AlignHCenter }

            TextField {
                id: savingsInput
                placeholderText: "0"
                color: "white"
                font.pixelSize: 30
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                Layout.preferredWidth: 275
                leftPadding: 40

                validator: DoubleValidator { bottom: 0 }
                onTextEdited: if (text.length > 1 && text.startsWith("0") && !text.startsWith("0.")) text = text.replace(/^0+/, '')

                background: Rectangle {
                    color: "transparent"
                    border.color: savingsInput.activeFocus ? "#FFFFFF" : "#222"
                    border.width: 1
                    radius: 12
                    implicitHeight: 50
                    // Currency symbol in background
                    Text {
                        text: root.currencySymbol; color: "#333"; font.pixelSize: 30; anchors.left: parent.left; anchors.leftMargin: 20; anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }
        }

        // Hero Number
        Column {
            Layout.alignment: Qt.AlignHCenter
            spacing: 0

            // Container for the filling effect
            Item {
                id: heroContainer
                width: dummyText.width
                height: dummyText.height
                anchors.horizontalCenter: parent.horizontalCenter

                Text {
                    id: dummyText
                    text: (isNaN(progress) ? "0.0" : (progress * 100).toFixed(1)) + "%"
                    font.pixelSize: 95
                    font.bold: true
                    visible: false
                }

                // Real ink bounds of the glyphs (excludes the empty ascender/descender
                // padding baked into the font's line height). Without this, the fill
                // has to "use up" that empty margin before any ink is revealed at the
                // bottom, and finishes revealing all the ink well before reaching the
                // top of the box - which is why it looked full above ~75% and empty
                // below ~20% instead of matching the real percentage.
                FontMetrics { id: heroFontMetrics; font: dummyText.font }
                readonly property rect inkRect: heroFontMetrics.tightBoundingRect(dummyText.text)
                readonly property real inkBottomMargin: dummyText.height - (heroFontMetrics.ascent + inkRect.y + inkRect.height)
                readonly property real fillHeight: Math.max(0, Math.min(dummyText.height,
                    inkBottomMargin + progress * inkRect.height))

                // Base Layer: Dull Gray (Empty State)
                Text {
                    text: dummyText.text
                    font: dummyText.font
                    color: (progress * 100 < 0.1) ? "#990000" : "#7D7D7D" // Dull gray for the "empty" part
                }
                // Fill Layer: Green (Controlled by progress, mapped to actual glyph ink)
                Item {
                    width: parent.width
                    height: heroContainer.fillHeight
                    anchors.bottom: parent.bottom
                    clip: true // This creates the "fill" look

                    // Delight: Smoothly animate the "filling" height
                    Behavior on height { NumberAnimation { duration: 1000; easing.type: Easing.OutExpo } }

                    Text {
                        text: dummyText.text
                        font: dummyText.font
                        color: "#4CAF50"
                        anchors.bottom: parent.bottom // Keep text aligned to bottom
                    }
                }
            }

            Text {
                text: "OF YOUR FUND SECURED"
                font.pixelSize: 14
                font.weight: Font.DemiBold;
                font.letterSpacing: 4
                color: "#888"
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }

        // SETTINGS DRAWER
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 20
            Layout.bottomMargin: 10
            spacing: 20

            // Multipliers
            Row {
                spacing: 5
                Repeater {
                    model: ["6x", "12x", "Custom"]
                    Button {
                        text: modelData
                        flat: true
                        implicitWidth: 70
                        palette.buttonText: multiplierIndex === index ? "#ECEFF1" : "#555"
                        font.bold: multiplierIndex === index
                        onClicked: multiplierIndex = index

                        background: Rectangle {
                            color: multiplierIndex === index ? "#252525" : "transparent"
                            border.color: multiplierIndex === index ? "#ECEFF1" : "transparent"
                            radius: 6; border.width: 1
                        }
                    }
                }
            }

            // Custom Inputs
            RowLayout {
                visible: multiplierIndex === 2
                spacing: 12

                TextField {
                    id: customInput; text: "15"
                    Layout.preferredWidth: 65; font.pixelSize: 13; horizontalAlignment: Text.AlignLeft
                    leftPadding: 10; rightPadding: 22

                    validator: DoubleValidator { bottom: 1 }
                    onTextEdited: text = text.replace(/^0+/, '')

                    background: Rectangle {
                        color: "#111"; radius: 4; implicitHeight: 36
                        border.color: customInput.activeFocus ? "#FFFFFF" : "#333"; border.width: 1

                        Text {
                            text: "x"; color: "#666";
                            anchors.right: parent.right; anchors.rightMargin: 8; anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }
                TextField {
                    id: salaryInput; text: root.globalMonthlyIncome.toString()
                    Layout.preferredWidth: 110; leftPadding: 25;
                    color: "white"; font.pixelSize: 13; horizontalAlignment: Text.AlignLeft

                    validator: DoubleValidator { bottom: 0 }
                    onTextEdited: text = text.replace(/^0+/, '')

                    background: Rectangle {
                        color: "#111"; radius: 4; implicitHeight: 36
                        border.color: salaryInput.activeFocus ? "#FFFFFF" : "#333"; border.width: 1
                        // Currency symbol in custom income input
                        Text {
                            text: root.currencySymbol; color: "#666"
                            anchors.left: parent.left; anchors.leftMargin: 8;
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }
            }
        }

        // PROGRESS BAR & STATS
        ColumnLayout {
            Layout.fillWidth: true
            Layout.topMargin: 20
            spacing: 20

            ProgressBar {
                id: mainBar
                value: progress
                Layout.fillWidth: true
                Layout.preferredHeight: 8
                background: Rectangle { color: "#222"; radius: 4 }
                contentItem: Item {
                    Rectangle {
                        width: mainBar.visualPosition * parent.width
                        height: 8; radius: 4; color: "#4CAF50"
                        Behavior on width { NumberAnimation { duration: 1000; easing.type: Easing.OutExpo } }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                // Target Stat
                Column {
                    Text { text: "GOAL TARGET (Based on whichever is higher: Income or Expenses)"; color: "#AAA"; font.pixelSize: 10; font.weight: Font.Medium; font.letterSpacing: 1 }
                    Text {
                        text: (targetAmount > 0) ? root.currencySymbol + targetAmount.toLocaleString(Qt.locale(), 'f', 0) : "Enter your Income in CashFlow or Custom"
                        color: (targetAmount > 0) ? "#4CAF50" : "#555"
                        font.pixelSize: 18
                        font.bold: true
                    }
                }
                Item { Layout.fillWidth: true }
                // Runway Stat
                Column {
                    Layout.alignment: Qt.AlignRight
                    Text { text: "RUNWAY LEFT (Based on your Expenses)"; color: "#AAA"; font.pixelSize: 10; font.weight: Font.Medium; font.letterSpacing: 1; Layout.alignment: Qt.AlignRight }
                    Text {
                        text: (runwayMonths > 0) ? runwayMonths.toFixed(1) + " Months" : "Enter your Expenses in CashFlow"
                        color: (runwayMonths > 0) ? "#2196F3" : "#555"
                        font.pixelSize: 18
                        font.bold: true; Layout.alignment: Qt.AlignRight
                    }
                }
            }

            // Button Layout
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                Layout.alignment: Qt.AlignHCenter
                spacing: 30

                SaveButton { id: saveButton }

                ClearButton {
                    id: clearButton
                    text: "Clear"
                    onClicked: savingsInput.text = ''
                }
            }
        }
    }
}
