import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "../../components"

Item {
    id: emergencyFundRoot
    Layout.fillWidth: true
    Layout.fillHeight: true

    // ── PROPERTIES ────────────────────────────────────────────────────────────
    property real currentSavings: parseFloat(savingsInput.text) || 0
    property int  multiplierIndex: 0
    property string lastUpdated: ""

    // Use CashFlow income when not in Custom mode; custom salary field otherwise
    readonly property real activeSalary:     multiplierIndex === 2
                                                 ? (parseFloat(salaryInput.text) || 0)
                                                 : root.globalMonthlyIncome

    // Target is based on whichever is higher: income or expenses
    readonly property real baseAmount:       Math.max(activeSalary, root.globalMonthlyExpense)
    readonly property real activeMultiplier: multiplierIndex === 0 ? 6
                                           : multiplierIndex === 1 ? 12
                                           : (parseFloat(customInput.text) || 0)
    readonly property real targetAmount:     baseAmount * activeMultiplier

    // Raw ratio — NOT clamped, so overfunded shows > 100%
    readonly property real rawRatio:     targetAmount > 0 ? currentSavings / targetAmount : 0

    // Bar clamps at 1.0; hero text shows the real (possibly > 100%) value
    readonly property real progress:     Math.min(rawRatio, 1.0)
    readonly property real runwayMonths: root.globalMonthlyExpense > 0
                                             ? currentSavings / root.globalMonthlyExpense : 0

    // ── COLOR CODING ─────────────────────────────────────────────────────────
    // Matches Goals progress bar ramp; 0% uses a darker red so it reads as "nothing yet"
    readonly property color progressColor: {
        var p = rawRatio * 100
        if (p <= 0)   return "#5a0a0a"    // very dark red — empty state
        if (p < 25)   return "#c0392b"    // dark red — critical
        if (p < 50)   return "#e67e22"    // orange
        if (p < 75)   return "#f1c40f"    // yellow
        if (p < 100)  return "#43e97b"    // green
        // 100%+ — horizon accent (long-term goal)
        return "#a29bfe"                  // purple: fully funded
    }

    // ── MAIN LAYOUT ───────────────────────────────────────────────────────────
    ColumnLayout {
        anchors.centerIn: parent
        width: Math.min(parent.width * 0.85, 700)  // caps on wide screens
        spacing: 5

        // ── SAVINGS INPUT ─────────────────────────────────────────────────────
        ColumnLayout {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 15
            spacing: 10

            Text {
                text: "HOW MUCH DO YOU HAVE SAVED TODAY?"
                color: "#888"; font.pixelSize: 11; font.letterSpacing: 1
                Layout.alignment: Qt.AlignHCenter
            }

            TextField {
                id: savingsInput
                placeholderText: "0"
                color: "white"
                font.pixelSize: 30; font.bold: true
                horizontalAlignment: Text.AlignHCenter
                Layout.preferredWidth: 275
                leftPadding: 40

                validator: DoubleValidator { bottom: 0 }
                // Strip leading zeros but allow "0." for decimals
                onTextEdited: if (text.length > 1 && text.startsWith("0") && !text.startsWith("0."))
                                  text = text.replace(/^0+/, '')

                background: Rectangle {
                    color: "transparent"
                    border.color: savingsInput.activeFocus ? "#FFFFFF" : "#222"
                    border.width: 1; radius: 12; implicitHeight: 50

                    Text {
                        text: root.currencySymbol; color: "#333"; font.pixelSize: 30
                        anchors.left: parent.left; anchors.leftMargin: 20
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }
        }

        // ── HERO PERCENTAGE ───────────────────────────────────────────────────
        // Fills with color based on progress; shows raw ratio so overfunding is visible
        Column {
            Layout.alignment: Qt.AlignHCenter
            spacing: 0

            Item {
                id: heroContainer
                width: dummyText.width
                height: dummyText.height
                anchors.horizontalCenter: parent.horizontalCenter

                // Invisible reference for sizing and font metrics
                Text {
                    id: dummyText
                    text: (rawRatio * 100).toFixed(1) + "%"
                    font.pixelSize: 95; font.bold: true
                    visible: false
                }

                // Correct the fill to actual ink bounds (not the font line-height box)
                FontMetrics { id: heroFontMetrics; font: dummyText.font }
                readonly property rect inkRect:        heroFontMetrics.tightBoundingRect(dummyText.text)
                readonly property real inkBottomMargin: dummyText.height - (heroFontMetrics.ascent + inkRect.y + inkRect.height)
                readonly property real fillHeight:      Math.max(0, Math.min(dummyText.height,
                                                            inkBottomMargin + progress * inkRect.height))

                // Base layer — dim color representing the "empty" portion
                Text {
                    text: dummyText.text; font: dummyText.font
                    // At exactly 0 use the darkest red; once filling starts use a mid-grey
                    color: rawRatio <= 0 ? "#5a0a0a" : "#3a3a3a"
                    Behavior on color { ColorAnimation { duration: 400 } }
                }

                // Fill layer — clips from bottom upward at progress height
                Item {
                    width: parent.width
                    height: heroContainer.fillHeight
                    anchors.bottom: parent.bottom
                    clip: true
                    Behavior on height { NumberAnimation { duration: 1000; easing.type: Easing.OutExpo } }

                    Text {
                        text: dummyText.text; font: dummyText.font
                        color: emergencyFundRoot.progressColor
                        anchors.bottom: parent.bottom
                        Behavior on color { ColorAnimation { duration: 400 } }
                    }
                }
            }

            Text {
                text: "OF YOUR FUND SECURED"
                font.pixelSize: 14; font.weight: Font.DemiBold; font.letterSpacing: 4
                color: "#888"
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }

        // ── MULTIPLIER SETTINGS ───────────────────────────────────────────────
        ColumnLayout {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 20
            Layout.bottomMargin: 10
            spacing: 8

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 20

                // Multiplier pill buttons
                Row {
                    spacing: 5
                    Repeater {
                        model: ["x 6 months", "x 12 months", "Custom"]
                        Button {
                            text: modelData
                            flat: true
                            implicitWidth: 85
                            palette.buttonText: multiplierIndex === index ? "#ECEFF1" : "#555"
                            font.bold: multiplierIndex === index
                            onClicked: multiplierIndex = index

                            background: Rectangle {
                                color: multiplierIndex === index ? "#252525" : "transparent"
                                border.color: multiplierIndex === index ? "#ECEFF1" : "#2A2A2A"
                                radius: 6; border.width: 1
                            }
                        }
                    }
                }

                // Custom inputs — only visible when Custom is selected
                RowLayout {
                    visible: multiplierIndex === 2
                    spacing: 8

                    // Custom multiplier (months)
                    TextField {
                        id: customInput; text: "15"
                        Layout.preferredWidth: 70; font.pixelSize: 13
                        horizontalAlignment: Text.AlignLeft
                        leftPadding: 10; rightPadding: 26
                        placeholderText: "months"
                        validator: DoubleValidator { bottom: 1 }
                        onTextEdited: text = text.replace(/^0+/, '')

                        background: Rectangle {
                            color: "#111"; radius: 4; implicitHeight: 36
                            border.color: customInput.activeFocus ? "#FFFFFF" : "#333"; border.width: 1
                            Text {
                                text: "x"; color: "#666"
                                anchors.right: parent.right; anchors.rightMargin: 8
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                    }

                    // Custom monthly income override
                    TextField {
                        id: salaryInput; text: root.globalMonthlyIncome.toString()
                        Layout.preferredWidth: 120; leftPadding: 26
                        color: "white"; font.pixelSize: 13
                        horizontalAlignment: Text.AlignLeft
                        placeholderText: "Monthly income"
                        validator: DoubleValidator { bottom: 0 }
                        onTextEdited: text = text.replace(/^0+/, '')

                        background: Rectangle {
                            color: "#111"; radius: 4; implicitHeight: 36
                            border.color: salaryInput.activeFocus ? "#FFFFFF" : "#333"; border.width: 1
                            Text {
                                text: root.currencySymbol; color: "#666"
                                anchors.left: parent.left; anchors.leftMargin: 8
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                    }
                }
            }
        }

        // ── PROGRESS BAR & STATS ──────────────────────────────────────────────
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
                        height: 8; radius: 4
                        color: emergencyFundRoot.progressColor
                        Behavior on width { NumberAnimation { duration: 1000; easing.type: Easing.OutExpo } }
                        Behavior on color { ColorAnimation { duration: 400 } }
                    }
                }
            }

            // Stats row
            RowLayout {
                Layout.fillWidth: true

                // Goal target — left aligned
                ColumnLayout {
                    spacing: 3

                    Text {
                        text: "GOAL TARGET"
                        color: "#AAA"; font.pixelSize: 10; font.letterSpacing: 1; font.bold: true
                    }
                    Text {
                        text: "Based on higher of: Income or Expenses"
                        color: "#555"; font.pixelSize: 9
                    }
                    Text {
                        text: targetAmount > 0
                              ? root.currencySymbol + " " + targetAmount.toLocaleString(Qt.locale(), 'f', 0)
                              : "Enter Income in CashFlow or use Custom"
                        color: targetAmount > 0 ? "#4CAF50" : "#555"
                        font.pixelSize: 18; font.bold: true
                        Behavior on color { ColorAnimation { duration: 400 } }
                    }
                }

                Item { Layout.fillWidth: true }

                // Runway — right aligned
                ColumnLayout {
                    spacing: 3
                    Layout.alignment: Qt.AlignRight

                    Text {
                        text: "RUNWAY LEFT"
                        color: "#AAA"; font.pixelSize: 10; font.letterSpacing: 1; font.bold: true
                        Layout.alignment: Qt.AlignRight
                    }
                    Text {
                        text: "Based on your monthly Expenses"
                        color: "#555"; font.pixelSize: 9
                        Layout.alignment: Qt.AlignRight
                    }
                    Text {
                        text: runwayMonths > 0
                              ? runwayMonths.toFixed(1) + " months"
                              : "Enter Expenses in CashFlow"
                        color: runwayMonths > 0 ? "#2196F3" : "#555"
                        font.pixelSize: 18; font.bold: true
                        Layout.alignment: Qt.AlignRight
                    }
                }
            }

            // ── BUTTONS + LAST UPDATED ────────────────────────────────────────
            // Buttons centered; timestamp anchored to bottom-left
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 40

                // Timestamp at bottom-left
                Text {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: lastUpdated !== "" ? "Last saved: " + lastUpdated : ""
                    color: "#444"; font.pixelSize: 10; font.italic: true
                }

                // Save + Clear centered
                Row {
                    anchors.centerIn: parent
                    spacing: 12

                    SaveButton {
                        id: saveButton
                        onClicked: {
                            lastUpdated = Qt.formatDateTime(new Date(), "dd MMM yyyy, hh:mm")
                        }
                    }

                    ClearButton {
                        id: clearButton
                        text: "Clear"
                        onClicked: {
                            savingsInput.text = ""
                            multiplierIndex = 0
                        }
                    }
                }
            }
        }
    }
}
