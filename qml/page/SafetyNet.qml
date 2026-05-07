import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: safetyNetRoot
    color: "#121212"

    property real currentSavings: Number(savingsInput.text)
    property int multiplierIndex: 0
    readonly property real activeSalary: multiplierIndex === 2 ? Number(salaryInput.text) : root.globalMonthlyIncome
    readonly property real activeMultiplier: multiplierIndex === 0 ? 6 : (multiplierIndex === 1 ? 12 : Number(customInput.text) || 0)
    readonly property real targetAmount: activeSalary * activeMultiplier
    readonly property real progress: targetAmount > 0 ? Math.min(currentSavings / targetAmount, 1.0) : 0
    readonly property real runwayMonths: root.globalMonthlyExpense > 0 ? (currentSavings / root.globalMonthlyExpense) : 0

    ColumnLayout {
        anchors.fill: parent
        anchors.topMargin: 10
        anchors.leftMargin: 40
        anchors.rightMargin: 40
        anchors.bottomMargin: 40
        spacing: 30

        // --- NAVIGATION & INFO BAR ---
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 50

            // Sub-Navigation Tabs (Center)
            Row {
                anchors.centerIn: parent
                spacing: 30
                Repeater {
                    model: ["Emergency Fund", "Insurance", "Retirement"]
                    Button {
                        text: modelData
                        flat: true
                        font.pixelSize: 15
                        font.bold: safetyStack.currentIndex === index
                        palette.buttonText: safetyStack.currentIndex === index ? "white" : "#555"
                        onClicked: safetyStack.currentIndex = index

                        // Small underline for active tab
                        Rectangle {
                            anchors.bottom: parent.bottom
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: parent.width * 0.6
                            height: 2
                            color: "#666"
                            visible: safetyStack.currentIndex === index
                        }
                    }
                }
            }

            Item { Layout.fillWidth: true }

            // INFO BUTTON (Top Right)
            Button {
                id: infoBtn
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: "ⓘ"
                flat: true
                font.pixelSize: 20
                palette.buttonText: helpOverlay.visible ? "#4CAF50" : "#888"
                onClicked: helpOverlay.visible = !helpOverlay.visible
            }
        }

        // --- PAGE LAYOUT ---
        StackLayout {
            id: safetyStack
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: 0

            // --- PAGE 1: EMERGENCY FUND ---
            Item {
                id: emergencyFundPage

                ColumnLayout {
                    anchors.centerIn: parent
                    width: parent.width * 0.8
                    spacing: 20 // whitespace between sections

                    // SAVINGS INPUT
                    ColumnLayout {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.topMargin: 5
                        spacing: 12

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
                                border.color: savingsInput.activeFocus ? "#0772c8" : "#222"
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

                    // THE HERO NUMBER
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
                                text: (progress * 100).toFixed(1) + "%"
                                font.pixelSize: 95
                                font.bold: true
                                visible: false
                            }
                            // Base Layer: Dull Gray (Empty State)
                            Text {
                                text: dummyText.text
                                font: dummyText.font
                                color: (progress * 100 < 0.1) ? "#990000" : "#7D7D7D" // Dull gray for the "empty" part
                            }
                            // Fill Layer: Green (Controlled by progress)
                            Item {
                                width: parent.width
                                height: parent.height * progress // Height grows based on %
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
                            font.letterSpacing: 4
                            color: "#666"
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                    }

                    // SETTINGS DRAWER
                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
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
                                    palette.buttonText: multiplierIndex === index ? "#4CAF50" : "#555"
                                    font.bold: multiplierIndex === index
                                    onClicked: multiplierIndex = index

                                    background: Rectangle {
                                        color: multiplierIndex === index ? "#1a2e1a" : "transparent"
                                        border.color: multiplierIndex === index ? "#4CAF50" : "transparent"
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
                                    border.color: "#333"; border.width: 1

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
                                    border.color: "#333"; border.width: 1
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
                                Text { text: "GOAL TARGET (based on your income)"; color: "#555"; font.pixelSize: 10; font.letterSpacing: 1 }
                                Text { text: root.currencySymbol + targetAmount.toLocaleString(Qt.locale(), 'f', 0); color: "white"; font.pixelSize: 18; font.bold: true }
                            }
                            Item { Layout.fillWidth: true }
                            // Runway Stat
                            Column {
                                Layout.alignment: Qt.AlignRight
                                Text { text: "RUNWAY LEFT (Based on your Expenses)"; color: "#555"; font.pixelSize: 10; font.letterSpacing: 1; Layout.alignment: Qt.AlignRight }
                                Text { text: runwayMonths.toFixed(1) + " Months"; color: "#2196F3"; font.pixelSize: 18; font.bold: true; Layout.alignment: Qt.AlignRight }
                            }
                        }
                    }
                }
            }

            // PAGE 2 & 3 PLACEHOLDERS
            Rectangle { color: "transparent"; Text { text: "Insurance Details Go Here"; color: "#333"; anchors.centerIn: parent } }
            Rectangle { color: "transparent"; Text { text: "Retirement Calculator Goes Here"; color: "#333"; anchors.centerIn: parent } }
        }
    }

    // --- 3. HELP OVERLAY (10% Delight) ---
    Rectangle {
        id: helpOverlay
        anchors.fill: parent
        color: "#f2121212" // Semi-transparent dark
        visible: false
        z: 100 // Ensure it's on top

        MouseArea { anchors.fill: parent } // Prevent clicks through to page

        ColumnLayout {
            anchors.centerIn: parent
            width: parent.width * 0.6
            spacing: 25

            Text {
                text: "The Emergency Fund"
                color: "#4CAF50"; font.pixelSize: 32; font.bold: true
                Layout.alignment: Qt.AlignHCenter
            }

            Text {
                text: "An emergency fund is a stash of money set aside to cover the financial surprises life throws your way.\n\n" +
                      "• 3-6 Months: Recommended for salaried individuals.\n" +
                      "• 6-12 Months: Recommended for freelancers or business owners.\n\n" +
                      "This fund should be kept in a liquid savings account, separate from your daily spending."
                color: "white"; font.pixelSize: 16; lineHeight: 1.3; wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter; Layout.fillWidth: true
            }

            Button {
                text: "Got it"
                Layout.alignment: Qt.AlignHCenter
                onClicked: helpOverlay.visible = false
                background: Rectangle { color: "#222"; radius: 8; implicitWidth: 120; implicitHeight: 45; border.color: "#4CAF50" }
            }
        }
    }
}