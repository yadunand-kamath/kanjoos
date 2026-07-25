import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: rootItem // Global root

    // Width Ratios for Goal Table
    readonly property real colPriority: 80
    readonly property real colGoal: 230
    readonly property real colYears: 60
    readonly property real colHorizon: 80
    readonly property real colCost: 120
    readonly property real colFunded: 120
    readonly property real colLarge: 130
    readonly property real colActions: 50

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 15
        anchors.topMargin: -10
        spacing: 20

        // TABLE SECTION
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "#121212"
            border.color: "#2A2A2A"
            radius: 4

            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                // ACTION BAR
                RowLayout {
                    Layout.fillWidth: true
                    Layout.margins: 8 // Space between header and table

                    Text {
                        text: "FINANCIAL GOALS"
                        color: "white"
                        font.bold: true
                        font.pixelSize: 14
                        font.letterSpacing: 1
                        Layout.preferredWidth: 150
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    Item { Layout.fillWidth: true } // Spacer pushes button to the right

                    Button {
                        id: settingsBtn
                        text: "⚙ Settings"
                        flat: true
                        onClicked: settingsDialog.open()

                        contentItem: Text {
                            text: settingsBtn.text; color: "#AAA";
                            font.bold: true; font.pixelSize: 13; Layout.preferredWidth: 80
                            horizontalAlignment: Text.AlignRight; verticalAlignment: Text.AlignVCenter
                        }

                        background: Rectangle {
                            color: settingsBtn.hovered ? "#1a1a1a" : "transparent"
                            radius: 15
                        }
                    }

                    Button {
                        id: addGoalBtn
                        text: "+ Add Goal"
                        flat: true
                        onClicked: goalModel.addGoal()
                        Layout.rightMargin: 5

                        contentItem: Text {
                            text: addGoalBtn.text; color: "#AAA"
                            font.bold: true; font.pixelSize: 13; Layout.preferredWidth: 80
                            horizontalAlignment: Text.AlignRight; verticalAlignment: Text.AlignVCenter
                        }

                        background: Rectangle {
                            color: addGoalBtn.hovered ? "#1a1a1a" : "transparent"
                            radius: 15
                        }
                    }
                }

                // --- TABLE HEADER ---
                Rectangle {
                    Layout.fillWidth: true
                    height: 40
                    color: "#181818" // Slightly lighter than background
                    border.color: "#2A2A2A"

                    RowLayout {
                        anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10
                        spacing: 10
                        HeaderLabel { text: "PRIORITY"; Layout.preferredWidth: colPriority }
                        HeaderLabel { text: "GOAL"; Layout.preferredWidth: colGoal; Layout.fillWidth: true }
                        HeaderLabel { text: "YEARS"; Layout.preferredWidth: colYears; horizontalAlignment: Text.AlignHCenter }
                        HeaderLabel { text: "HORIZON"; Layout.preferredWidth: colHorizon; horizontalAlignment: Text.AlignHCenter }
                        HeaderLabel { text: "TODAY'S COST"; Layout.preferredWidth: colCost; horizontalAlignment: Text.AlignRight }
                        HeaderLabel { text: "AVAILABLE TODAY"; Layout.preferredWidth: colFunded; horizontalAlignment: Text.AlignRight }
                        HeaderLabel { text: "FUTURE TARGET"; Layout.preferredWidth: colLarge; horizontalAlignment: Text.AlignRight }
                        HeaderLabel { text: "REQUIRED SIP"; Layout.preferredWidth: colLarge; horizontalAlignment: Text.AlignRight }
                        HeaderLabel { text: "ACTUAL SIP"; Layout.preferredWidth: colLarge; horizontalAlignment: Text.AlignRight }
                        Item { Layout.preferredWidth: colActions }
                    }
                }

                ListView {
                    id: goalList
                    Layout.fillWidth: true; Layout.fillHeight: true
                    model: goalModel
                    clip: true

                    snapMode: ListView.SnapToItem         // Forces the list to stop exactly on a row edge
                    highlightRangeMode: ListView.NoHighlightRange
                    pixelAligned: true                   // Prevents sub-pixel floating

                    // Ensure the list returns to the top when the first row is visible
                    boundsBehavior: Flickable.StopAtBounds

                    // --- ADD THEMED SCROLLBAR ---
                    ScrollBar.vertical: ScrollBar {
                        id: scrollBar
                        active: true // Keep it visible when scrolling
                        policy: ScrollBar.AsNeeded // Show only if content overflows

                        contentItem: Rectangle {
                            implicitWidth: 4
                            implicitHeight: 100
                            radius: 2
                            // Use a subtle grey or your Cyan accent
                            color: scrollBar.pressed ? "silver" : "#333"

                            // Animation for appearance
                            Behavior on color { ColorAnimation { duration: 200 } }
                        }

                        background: Rectangle {
                            implicitWidth: 4
                            color: "transparent" // Keep background clean
                        }
                    }

                    // Automatically scroll to the bottom when the count increases
                    onCountChanged: {
                        // Use a Timer to wait for the item to be created before scrolling
                        Qt.callLater(goalList.positionViewAtEnd)
                    }

                    delegate: Rectangle {
                        id: delegateRoot
                        width: goalList.width; height: 47
                        color: rowMA.containsMouse ? "#1A1A1A" : "transparent"

                        Rectangle { width: parent.width; height: 1; color: "#222"; anchors.bottom: parent.bottom }

                        MouseArea {
                            id: rowMA; anchors.fill: parent; hoverEnabled: true
                            propagateComposedEvents: true; onClicked: (mouse) => mouse.accepted = false
                        }

                        RowLayout {
                            anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10; spacing: 10

                            // Priority
                            GoalInput {
                                text: model.priority
                                Layout.preferredWidth: colPriority
                                horizontalAlignment: Text.AlignHCenter
                                font.bold: true
                                color: model.goalName === "Emergency Fund" ? "#444" : "#888"
                                enabled: model.goalName !== "Emergency Fund"
                                validator: IntValidator { bottom: 2; top: goalModel.rowCount() }
                                onAccepted: model.priority = parseInt(text)
                            }

                            // Goal Name
                            GoalInput {
                                text: model.goalName
                                Layout.preferredWidth: colGoal; Layout.fillWidth: true; Layout.maximumWidth: colGoal
                                clip: true
                                enabled: model.goalName !== "Emergency Fund" && model.goalName !== "Retirement"
                                onAccepted: model.goalName = text
                                color: !enabled ? "#888" : "#FFFFFF"
                            }

                            // Years
                            GoalInput {
                                id: yearsInput
                                text: model.yearsLeft;
                                Layout.preferredWidth: colYears; horizontalAlignment: Text.AlignHCenter
                                validator: IntValidator { bottom: 1; top: 100 }
                                onTextEdited: {
                                    let val = parseInt(text)
                                    model.yearsLeft = isNaN(val) ? 0 : val
                                }
                            }

                            // Horizon
                            Text {
                                text: model.horizon
                                color: text === "Long" ? "#A29BFE" : (text === "Medium" ? "#f1c40f" : "#00d2ff")
                                font.pixelSize: 12; font.bold: true; Layout.preferredWidth: colHorizon; horizontalAlignment: Text.AlignHCenter
                            }

                            // Today's Cost
                            GoalInput {
                                id: costInput
                                // We use a property to track if the field is empty to help the "Clear" logic
                                property bool isEmpty: text === ""
                                text: model.currentCost === 0 ? "" : Number(model.currentCost).toFixed(0)
                                color: "white"
                                Layout.preferredWidth: colCost
                                horizontalAlignment: Text.AlignRight
                                validator: DoubleValidator { bottom: 0 }
                                onTextEdited: {
                                    let val = parseFloat(text)
                                    model.currentCost = isNaN(val) ? 0 : val
                                }
                            }

                            // Available Today
                            GoalInput {
                                id: availableInput
                                text: model.currentFunded === 0 ? "" : Number(model.currentFunded).toFixed(0)
                                color: "white"
                                Layout.preferredWidth: colFunded; horizontalAlignment: Text.AlignRight
                                validator: DoubleValidator { bottom: 0 }
                                onTextEdited: {
                                    let val = parseFloat(text)
                                    model.currentFunded = isNaN(val) ? 0 : val
                                }
                            }

                            // Future Target
                            Text {
                                // If the input is cleared, show a placeholder "-"
                                readonly property bool hasData: yearsInput.text !== "" && costInput.text !== "" && model.yearsLeft > 0
                                text: !hasData ? "-" : root.currencySymbol + Number(model.futureTarget).toLocaleString(Qt.locale(), 'f', 0)
                                color:  !hasData ? "#333" : "#888"
                                Layout.preferredWidth: colLarge
                                horizontalAlignment: Text.AlignRight
                                font.family: "Monospace"
                            }

                            // Required SIP
                            Text {
                                readonly property bool hasData: yearsInput.text !== "" && costInput.text !== "" && model.yearsLeft > 0
                                text: !hasData ? "-" : root.currencySymbol + Number(model.requiredSIP).toLocaleString(Qt.locale(), 'f', 0)
                                color: !hasData ? "#333" : "#2196F3"
                                font.bold: true
                                Layout.preferredWidth: colLarge
                                horizontalAlignment: Text.AlignRight
                            }

                            // Actual SIP
                            Text {
                                text: root.currencySymbol + Number(model.actualSIP).toLocaleString(Qt.locale(), 'f', 0)
                                color: model.actualSIP >= model.requiredSIP ? "#43e97b" : "#FF0000"
                                font.bold: true; Layout.preferredWidth: colLarge; horizontalAlignment: Text.AlignRight
                            }

                            // Remove Row
                            ToolButton {
                                id: removeRowBtn; text: "x"; Layout.preferredWidth: colActions
                                onClicked: goalModel.removeGoal(index)
                                contentItem: Text {
                                    text: "×"
                                    color: (removeRowBtn.hovered && removeRowBtn.isRemovable) ? "white" : "#666"
                                    horizontalAlignment: Text.AlignHCenter
                                }

                                readonly property bool isRemovable: model.goalName !== "Emergency Fund" && model.goalName !== "Retirement"
                                opacity: isRemovable ? 1.0 : 0.0
                                enabled: isRemovable
                                background: Rectangle { color: (removeRowBtn.hovered && removeRowBtn.isRemovable) ? "#1a1a1a" : "transparent" }
                            }
                        }
                    }

                    // Sort animation
                    move: Transition { NumberAnimation { properties: "y"; duration: 400; easing.type: Easing.InOutBack } }
                    displaced: Transition { NumberAnimation { properties: "y"; duration: 400; easing.type: Easing.OutQuad } }
                }
            }
        }

        // PROGRESS BARS AREA
        Rectangle {
            id: velocityContainer
            Layout.fillWidth: true
            Layout.preferredHeight: 150
            color: "#121212"
            border.color: "#2A2A2A"
            radius: 4
            clip: true

            ScrollView {
                id: velocityScroll
                anchors.fill: parent
                anchors.margins: 15
                clip: true

                contentHeight: velocityLayout.implicitHeight
                contentWidth: availableWidth

                ColumnLayout {
                    id: velocityLayout
                    // FIX 3: Use availableWidth minus a small gutter for the scrollbar
                    width: velocityScroll.availableWidth - 12
                    spacing: 15

                    Repeater {
                        model: goalModel
                        delegate: ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 6

                            readonly property real velocityRatio: model.requiredSIP > 0 ? (model.actualSIP / model.requiredSIP) : 0
                            readonly property real percentage: velocityRatio * 100

                            readonly property color barColor: {
                                if (percentage < 25) return "#FF0000"       // 0-25: Red
                                if (percentage < 50) return "#FF8C00"       // 25-50: Orange
                                if (percentage < 75) return "#FFD700"       // 50-75: Yellow/Gold
                                if (percentage < 100) return "#43e97b"      // 75-99: Green

                                // 100+: Use Horizon Accent Colors
                                if (model.yearsLeft < 2) return "#00d2ff"   // Short (Blue)
                                if (model.yearsLeft < 5) return "#f1c40f"   // Medium (Gold)
                                return "#A29BFE"                            // Long (Purple)
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                Text {
                                    text: model.goalName
                                    color: "white"
                                    font.pixelSize: 12; font.bold: true
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                }
                                Text {
                                    text: (velocityRatio * 100).toFixed(0) + "%"
                                    color: barColor
                                    font.pixelSize: 11; font.family: "Monospace"
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                height: 6; color: "#2A2A2A"
                                Rectangle {
                                    anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom
                                    width: Math.min(1.0, velocityRatio) * parent.width
                                    color: barColor
                                    Behavior on width { NumberAnimation { duration: 800; easing.type: Easing.OutCubic } }
                                    Behavior on color { ColorAnimation { duration: 500 } }
                                }
                            }
                        }
                    }
                }
            }
        }

        // FOOTER SUMMARY
        // Rectangle {
        //     Layout.fillWidth: true; Layout.preferredHeight: 80
        //     color: "#ffffff"; radius: 4
        //     RowLayout {
        //         anchors.fill: parent; anchors.margins: 20
        //         Column {
        //             Label { text: "TOTAL SIP"; color: "#888888"; font.pixelSize: 10; font.bold: true }
        //             Label { text: "₹ 0.00"; color: "#000000"; font.pixelSize: 20; font.bold: true }
        //         }
        //         Item { Layout.fillWidth: true }
        //         Column {
        //             Label { text: "COVERAGE RATIO"; color: "#888888"; font.pixelSize: 10; font.bold: true }
        //             Label { text: "0.0%"; color: "#000000"; font.pixelSize: 20; font.bold: true }
        //         }
        //     }
        // }

        // --- FOOTER SUMMARY ---
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 80
            color: "#ffffff"
            radius: 4

            RowLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 0

                // LEFT COLUMN: TOTALS
                ColumnLayout {
                    spacing: 2
                    Label {
                        text: "TOTAL MONTHLY REQUIRED"
                        color: "#888888"
                        font.pixelSize: 10
                        font.bold: true
                    }
                    Label {
                        text: root.currencySymbol + " " + goalModel.totalRequiredSIP.toLocaleString(Qt.locale(), 'f', 0)
                        color: "#000000"
                        font.pixelSize: 22
                        font.bold: true
                    }
                }

                Item { Layout.fillWidth: true } // Spacer pushes next item to the far right

                // RIGHT COLUMN: COVERAGE (Using ColumnLayout for alignment)
                ColumnLayout {
                    spacing: 2
                    Layout.alignment: Qt.AlignRight // Aligns the whole column to the right

                    Label {
                        text: "PLAN VELOCITY / COVERAGE"
                        color: "#888888"
                        font.pixelSize: 10
                        font.bold: true
                        Layout.alignment: Qt.AlignRight // Aligns label within column
                    }
                    Label {
                        text: goalModel.coverageRatio.toFixed(1) + "%"
                        color: goalModel.coverageRatio >= 100 ? "#43e97b" : "#FF0000"
                        font.pixelSize: 22
                        font.bold: true
                        Layout.alignment: Qt.AlignRight // Aligns label within column
                    }
                }
            }
        }
    }

    // --- TIER SETTINGS DIALOG ---
    Dialog {
        id: settingsDialog; title: "Tier Strategy Configuration";
        x: parent.width - width - 20
        y: 80
        modal: true; standardButtons: Dialog.Save | Dialog.Cancel

        ColumnLayout {
            spacing: 15
            GridLayout {
                columns: 3; rowSpacing: 10; columnSpacing: 20
                Item {} Label { text: "Inflation %"; font.bold: true; color: "#888" } Label { text: "Returns %"; font.bold: true; color: "#888" }

                Label { text: "Short Term (<2y)"; color: "#00d2ff" }
                TextField { id: sInf; text: goalModel.shortInf; width: 60 }
                TextField { id: sRet; text: goalModel.shortRet; width: 60 }

                Label { text: "Medium Term (2-5y)"; color: "#f1c40f" }
                TextField { id: mInf; text: goalModel.medInf; width: 60 }
                TextField { id: mRet; text: goalModel.medRet; width: 60 }

                Label { text: "Long Term (>5y)"; color: "#a29bfe" }
                TextField { id: lInf; text: goalModel.longInf; width: 60 }
                TextField { id: lRet; text: goalModel.longRet; width: 60 }
            }
        }
        onAccepted: {
            goalModel.updateSettings(parseFloat(sInf.text), parseFloat(sRet.text),
                                    parseFloat(mInf.text), parseFloat(mRet.text),
                                    parseFloat(lInf.text), parseFloat(lRet.text))
        }
    }

    component HeaderLabel : Text {
        color: "#888"; font.pixelSize: 10; font.bold: true; font.letterSpacing: 1
    }

    component GoalInput : TextInput {
        color: "white"; font.pixelSize: 13; selectByMouse: true
        verticalAlignment: Text.AlignVCenter
        clip: true

        Rectangle {
            anchors.bottom: parent.bottom; width: parent.width; height: 1
            color: parent.activeFocus ? "#00d2ff" : (inputMA.containsMouse ? "#444" : "transparent")
        }

        MouseArea {
            id: inputMA
            anchors.fill: parent; cursorShape: Qt.IBeamCursor; hoverEnabled: true
            onClicked: (mouse) => { parent.forceActiveFocus(); }
        }
    }
}