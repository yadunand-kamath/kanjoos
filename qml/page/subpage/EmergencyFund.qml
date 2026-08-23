import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "../../components"

Item {
    id: emergencyFundRoot
    Layout.fillWidth: true
    Layout.fillHeight: true

    // ── PROPERTIES ────────────────────────────────────────────────────────────
    property real linkedPortfolioValue: 0
    readonly property real currentSavings: linkedPortfolioValue
    property int  multiplierIndex: 0
    property string lastUpdated: ""

    // Sum current value of any portfolio assets linked to the "Emergency Fund" goal
    function syncPortfolio() {
        linkedPortfolioValue = portfolioModel.getFundedAmountForGoal("Emergency Fund")
    }
    Component.onCompleted: syncPortfolio()
    Connections {
        target: portfolioModel
        function onPortfolioUpdated() { emergencyFundRoot.syncPortfolio() }
    }

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

            Rectangle {
                id: savingsBox
                Layout.preferredWidth: 275; Layout.preferredHeight: 50
                Layout.alignment: Qt.AlignHCenter
                color: "transparent"; border.color: "#222"; border.width: 1; radius: 12

                Text {
                    anchors.centerIn: parent
                    visible: emergencyFundRoot.linkedPortfolioValue > 0
                    text: root.currencySymbol + " " + emergencyFundRoot.currentSavings.toLocaleString(Qt.locale(), 'f', 0)
                    color: "white"; font.pixelSize: 30; font.bold: true
                }

                Text {
                    anchors.centerIn: parent
                    anchors.margins: 8
                    width: parent.width - 16
                    visible: emergencyFundRoot.linkedPortfolioValue === 0
                    text: "Link an asset in Portfolio"
                    color: "#555"; font.pixelSize: 14; font.italic: true
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.WhatsThisCursor
                    ToolTip.visible: containsMouse
                    ToolTip.delay: 400
                    ToolTip.text: "This amount is linked from Portfolio assets assigned to the \"Emergency Fund\" goal"
                }
            }
        }

        // ── HERO PERCENTAGE ───────────────────────────────────────────────────
        // Fills with color based on progress; shows raw ratio so overfunding is visible
        Column {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: -20
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
            Layout.topMargin: 12
            Layout.bottomMargin: 6
            spacing: 8

            // Context label so the buttons are self-explanatory
            Text {
                text: "MONTHS OF BASE INCOME TO SAVE AS BUFFER"
                color: "#555"; font.pixelSize: 10; font.letterSpacing: 1
                Layout.alignment: Qt.AlignHCenter
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 20

                // Multiplier pill buttons
                Row {
                    spacing: 5
                    Repeater {
                        id: multiplierRepeater
                        model: ["x6 months", "x12 months", "Custom"]
                        readonly property var tips: [
                            "Protect yourself for 6 months",
                            "Protect yourself for 12 months",
                            ""
                        ]
                        Button {
                            text: modelData
                            flat: true
                            implicitWidth: 85
                            palette.buttonText: multiplierIndex === index ? "#ECEFF1" : "#555"
                            font.bold: multiplierIndex === index
                            onClicked: multiplierIndex = index

                            hoverEnabled: true
                            ToolTip.visible: hovered && multiplierRepeater.tips[index] !== ""
                            ToolTip.delay: 400
                            ToolTip.text: multiplierRepeater.tips[index]

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
                        Layout.preferredWidth: 100; font.pixelSize: 13
                        horizontalAlignment: Text.AlignLeft
                        leftPadding: 10; rightPadding: 26
                        placeholderText: ""
                        validator: DoubleValidator { bottom: 1; top: 60; notation: DoubleValidator.StandardNotation }
                        onTextEdited: {
                            let pos      = cursorPosition;
                            let stripped = text.replace(/^0+(\d)/, '$1');
                            if (stripped !== text) {
                                let removed    = text.length - stripped.length;
                                text           = stripped;
                                cursorPosition = Math.max(0, pos - removed);
                            }
                        }

                        background: Rectangle {
                            color: "#111"; radius: 4; implicitHeight: 36
                            border.color: customInput.activeFocus ? "#FFFFFF" : "#333"; border.width: 1
                            Text {
                                text: "months x"; color: "#666"
                                anchors.right: parent.right; anchors.rightMargin: 8
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                    }

                    // Custom monthly income override
                    TextField {
                        id: salaryInput; text: globalMonthlyIncome === 0 ? "" : root.globalMonthlyIncome.toString()
                        Layout.preferredWidth: 140; leftPadding: 26
                        color: "white"; font.pixelSize: 13
                        horizontalAlignment: Text.AlignLeft
                        placeholderText: "Monthly income"
                        validator: DoubleValidator { bottom: 0; notation: DoubleValidator.StandardNotation }
                        onTextEdited: {
                            let pos      = cursorPosition;
                            let stripped = text.replace(/^0+(\d)/, '$1');
                            if (stripped !== text) {
                                let removed    = text.length - stripped.length;
                                text           = stripped;
                                cursorPosition = Math.max(0, pos - removed);
                            }
                        }

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
            Layout.topMargin: 12
            spacing: 14

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
                        color: targetAmount > 0 ? "#43e97b" : "#555"
                        font.pixelSize: 18; font.bold: true
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
                        text: runwayMonths > 0 ? runwayMonths.toFixed(1) + " months"
                                : root.globalMonthlyExpense <= 0
                                ? "Enter Expenses in CashFlow"
                                : "Enter Saved Amount or Link in Portfolio"
                        color: runwayMonths > 0 ? "#2196F3" : "#555"
                        font.pixelSize: 18; font.bold: true
                        Layout.alignment: Qt.AlignRight
                    }
                }
            }

            // ── FOOTER DIVIDER ───────────────────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                Layout.topMargin: -8
                height: 1; color: "#555"
            }

            // ── BUTTONS + LAST UPDATED ────────────────────────────────────────
            // Buttons centered; timestamp anchored to bottom-left
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 34
                Layout.topMargin: -8

                // Timestamp — bottom-left
                Text {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: lastUpdated !== "" ? "Last saved: " + lastUpdated : ""
                    color: "#444"; font.pixelSize: 10; font.italic: true
                }

                // Save centered
                Row {
                    anchors.centerIn: parent
                    spacing: 12

                    SaveButton {
                        id: saveButton
                        onClicked: {
                            lastUpdated = Qt.formatDateTime(new Date(), "dd MMM yyyy, hh:mm")
                        }
                    }
                }
            }
        }
    }
}
