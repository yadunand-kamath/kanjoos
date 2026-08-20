import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "../../components"

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

                // ── ACTION BAR ────────────────────────────────────────────────
                RowLayout {
                    Layout.fillWidth: true
                    Layout.margins: 8
                    spacing: 8

                    // Left: Save + Clear All
                    SaveButton {
                        text: "Save"
                        onClicked: { /* persistence hook */ }
                    }

                    ClearButton {
                        text: "Clear All"
                        onClicked: goalModel.clearAll()
                    }

                    // Center: title
                    Item { Layout.fillWidth: true }

                    Text {
                        text: "FINANCIAL GOALS"
                        color: "white"; font.bold: true; font.pixelSize: 14; font.letterSpacing: 1
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Item { Layout.fillWidth: true }

                    // Right: Settings + Add Goal
                    Button {
                        id: settingsBtn
                        text: "⚙ Settings"; flat: true
                        onClicked: settingsDialog.open()
                        contentItem: Text {
                            text: settingsBtn.text; color: "#AAA"
                            font.bold: true; font.pixelSize: 13
                            horizontalAlignment: Text.AlignRight; verticalAlignment: Text.AlignVCenter
                        }
                        background: Rectangle { color: settingsBtn.hovered ? "#1a1a1a" : "transparent"; radius: 15 }
                    }

                    Button {
                        id: addGoalBtn
                        text: "+ Add Goal"; flat: true
                        onClicked: goalModel.addGoal()
                        Layout.rightMargin: 5
                        contentItem: Text {
                            text: addGoalBtn.text; color: "#AAA"
                            font.bold: true; font.pixelSize: 13
                            horizontalAlignment: Text.AlignRight; verticalAlignment: Text.AlignVCenter
                        }
                        background: Rectangle { color: addGoalBtn.hovered ? "#1a1a1a" : "transparent"; radius: 15 }
                    }
                }

                // --- TABLE HEADER ---
                Rectangle {
                    Layout.fillWidth: true
                    height: 35
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
                        width: goalList.width; height: 44
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

        // ── PROGRESS BARS ─────────────────────────────────────────────────────
        // Two bars per goal in two columns: left = SIP velocity, right = corpus funded
        Rectangle {
            id: velocityContainer
            Layout.fillWidth: true
            Layout.preferredHeight: 160
            color: "#121212"; border.color: "#2A2A2A"; radius: 4; clip: true

            ScrollView {
                id: velocityScroll
                anchors.fill: parent; anchors.margins: 15
                clip: true
                contentHeight: velocityLayout.implicitHeight
                contentWidth: availableWidth

                GridLayout {
                    id: velocityLayout
                    width: velocityScroll.availableWidth - 12
                    columns: 2
                    columnSpacing: 24
                    rowSpacing: 14

                    Repeater {
                        model: goalModel
                        delegate: Item {
                            // Each delegate fills one grid cell
                            Layout.fillWidth: true
                            implicitHeight: barCol.implicitHeight

                            // ── SIP velocity: actual SIP ÷ required SIP ──────
                            readonly property real sipRatio:    model.requiredSIP > 0
                                                                    ? model.actualSIP / model.requiredSIP : 0
                            // ── Corpus coverage: funded today ÷ today's cost ─
                            readonly property real fundedRatio: model.currentCost > 0
                                                                    ? model.currentFunded / model.currentCost : 0

                            // SIP bar: red→orange→yellow→green→horizon accent
                            readonly property color sipColor: {
                                var p = sipRatio * 100
                                if (p <= 0)  return "#555"      // 0% — neutral grey, not alarming
                                if (p < 25)  return "#FF0000"
                                if (p < 50)  return "#FF8C00"
                                if (p < 75)  return "#FFD700"
                                if (p < 100) return "#43e97b"
                                if (model.yearsLeft < 2) return "#00d2ff"
                                if (model.yearsLeft < 5) return "#f1c40f"
                                return "#A29BFE"
                            }

                            // Corpus funded bar: neutral when empty, teal→green as it fills
                            readonly property color fundedColor: {
                                var p = fundedRatio * 100
                                if (p <= 0)  return "#3d6b85"   // distinct muted blue — visible but calm
                                if (p < 25)  return "#0097a7"
                                if (p < 75)  return "#00b894"
                                return "#43e97b"
                            }

                            ColumnLayout {
                                id: barCol
                                anchors.fill: parent
                                spacing: 4

                                // Goal name + both percentages
                                RowLayout {
                                    Layout.fillWidth: true
                                    Text {
                                        text: model.goalName
                                        color: "white"; font.pixelSize: 11; font.bold: true
                                        Layout.fillWidth: true; elide: Text.ElideRight
                                    }
                                    // SIP coverage %
                                    Text {
                                        text: "SIP " + (sipRatio * 100).toFixed(0) + "%"
                                        color: sipColor; font.pixelSize: 10; font.family: "Monospace"
                                    }
                                    Text { text: "·"; color: "#444"; font.pixelSize: 10 }
                                    // Corpus funded %
                                    Text {
                                        text: "Corpus " + (fundedRatio * 100).toFixed(0) + "%"
                                        color: fundedColor; font.pixelSize: 10; font.family: "Monospace"
                                    }
                                }

                                // SIP velocity bar
                                Rectangle {
                                    Layout.fillWidth: true; height: 5; color: "#2A2A2A"; radius: 2
                                    Rectangle {
                                        anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom
                                        width: Math.min(1.0, sipRatio) * parent.width; radius: 2
                                        color: sipColor
                                        Behavior on width { NumberAnimation { duration: 700; easing.type: Easing.OutCubic } }
                                        Behavior on color { ColorAnimation { duration: 400 } }
                                    }
                                }

                                // Corpus funded bar — slightly brighter track so it reads even when empty
                                Rectangle {
                                    Layout.fillWidth: true; height: 5; color: "#2d3f4a"; radius: 2
                                    Rectangle {
                                        anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom
                                        width: Math.min(1.0, fundedRatio) * parent.width; radius: 2
                                        color: fundedColor
                                        Behavior on width { NumberAnimation { duration: 700; easing.type: Easing.OutCubic } }
                                        Behavior on color { ColorAnimation { duration: 400 } }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

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

                Item {

                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    // CENTER COLUMN: STATUS COUNTS
                    RowLayout {
                        id: statusCounts
                        anchors.centerIn: parent
                        spacing: 18

                        // Hidden tally repeater reuses the same per-row fundedRatio
                        // definition as the velocity grid above, via role properties
                        // (no raw role numbers, matches the existing delegate pattern).
                        property int completedCount: 0
                        property int onTrackCount: 0
                        property int underfundedCount: 0

                        function scheduleRetally() { Qt.callLater(statusCounts.retally) }

                        Repeater {
                            id: tallyRepeater
                            model: goalModel
                            delegate: Item {
                                Layout.preferredWidth: 0
                                Layout.preferredHeight: 0
                                readonly property real fundedRatio: model.currentCost > 0
                                                                        ? model.currentFunded / model.currentCost : 0
                                readonly property real sipRatio: model.requiredSIP > 0 ? model.actualSIP / model.requiredSIP : 0
                                readonly property int status: fundedRatio >= 1.0 ? 2 : (sipRatio >= 1.0 ? 1 : 0)
                            }
                            onItemAdded: statusCounts.scheduleRetally()
                            onItemRemoved: statusCounts.scheduleRetally()
                        }
                        Connections {
                            target: goalModel
                            function onDataChanged() { statusCounts.scheduleRetally() }
                            function onModelReset() { statusCounts.scheduleRetally() }
                        }
                        Component.onCompleted: scheduleRetally()

                        function retally() {
                            var completed = 0, onTrack = 0, underfunded = 0
                            for (var i = 0; i < tallyRepeater.count; i++) {
                                var it = tallyRepeater.itemAt(i)
                                if (!it) continue
                                var s = it.status
                                if (s === 2) completed++
                                else if (s === 1) onTrack++
                                else underfunded++
                            }
                            completedCount = completed
                            onTrackCount = onTrack
                            underfundedCount = underfunded
                        }

                        ColumnLayout {
                            spacing: 2
                            Label { text: "ON TRACK"; color: "#888888"; font.pixelSize: 10; font.bold: true }
                            Label {
                                text: statusCounts.onTrackCount
                                color: "#f1c40f"; font.pixelSize: 20; font.bold: true
                                Layout.alignment: Qt.AlignHCenter
                            }
                        }
                        ColumnLayout {
                            spacing: 2
                            Label { text: "UNDERFUNDED"; color: "#888888"; font.pixelSize: 10; font.bold: true }
                            Label {
                                text: statusCounts.underfundedCount
                                color: "#FF0000"; font.pixelSize: 20; font.bold: true
                                Layout.alignment: Qt.AlignHCenter
                            }
                        }
                        ColumnLayout {
                            spacing: 2
                            Label { text: "COMPLETED"; color: "#888888"; font.pixelSize: 10; font.bold: true }
                            Label {
                                text: statusCounts.completedCount
                                color: "#43e97b"; font.pixelSize: 20; font.bold: true
                                Layout.alignment: Qt.AlignHCenter
                            }
                        }
                    }
                }

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
        id: settingsDialog
        x: parent.width - width - 20
        y: 80
        width: 380
        modal: true
        standardButtons: Dialog.NoButton
        padding: 0

        background: Rectangle {
            color: "#141414"
            border.color: "#2A2A2A"
            radius: 8
        }

        // Custom header
        header: Rectangle {
            width: parent.width
            height: 50
            color: "#1A1A1A"
            radius: 8

            // Bottom edge square so it blends with the body
            Rectangle {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                height: 8
                color: parent.color
            }

            Text {
                text: "TIER SETTINGS"
                color: "white"
                font.bold: true
                font.pixelSize: 14
                font.letterSpacing: 1
                anchors.centerIn: parent
            }

            // Close (X) button
            Rectangle {
                width: 28; height: 28; radius: 14
                anchors.right: parent.right; anchors.rightMargin: 11
                anchors.verticalCenter: parent.verticalCenter
                color: closeArea.containsMouse ? "#2a2a2a" : "transparent"
                Behavior on color { ColorAnimation { duration: 120 } }

                Text { text: "×"; color: "#888"; font.pixelSize: 18; anchors.centerIn: parent }

                MouseArea {
                    id: closeArea; anchors.fill: parent; hoverEnabled: true
                    onClicked: settingsDialog.reject()
                }
            }
        }

        ColumnLayout {
            width: 380
            spacing: 12

            // Column header row
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 4
                Item { Layout.preferredWidth: 130 }
                Text { text: "INFLATION %"; color: "#555"; font.pixelSize: 10; font.bold: true; Layout.preferredWidth: 100; horizontalAlignment: Text.AlignHCenter }
                Text { text: "RETURNS %";   color: "#555"; font.pixelSize: 10; font.bold: true; Layout.preferredWidth: 100; horizontalAlignment: Text.AlignHCenter }
            }

            // SHORT TERM TIER
            Rectangle {
                Layout.fillWidth: true; height: 56
                color: "#1A1A1A"; radius: 6

                // Left accent bar
                Rectangle { width: 3; height: parent.height; radius: 2; color: "#00d2ff"; anchors.left: parent.left }

                RowLayout {
                    anchors.fill: parent; anchors.leftMargin: 16; anchors.rightMargin: 12; spacing: 0

                    Text {
                        text: "Short Term  <2y"
                        color: "#00d2ff"; font.pixelSize: 12; font.bold: true
                        Layout.preferredWidth: 118
                    }

                    TextField {
                        id: sInf; text: goalModel.shortInf
                        width: 70; height: 30
                        horizontalAlignment: Text.AlignHCenter
                        color: "white"
                        validator: DoubleValidator { bottom: 0; top: 100 }
                        Layout.preferredWidth: 70; Layout.preferredHeight: 30
                        background: Rectangle {
                            color: "#222"; radius: 4
                            border.color: sInf.activeFocus ? "#00d2ff" : "#333"; border.width: 1
                        }
                    }

                    Item { Layout.preferredWidth: 28 }

                    TextField {
                        id: sRet; text: goalModel.shortRet
                        width: 70; height: 30
                        horizontalAlignment: Text.AlignHCenter
                        color: "white"
                        validator: DoubleValidator { bottom: 0; top: 100 }
                        Layout.preferredWidth: 70; Layout.preferredHeight: 30
                        background: Rectangle {
                            color: "#222"; radius: 4
                            border.color: sRet.activeFocus ? "#00d2ff" : "#333"; border.width: 1
                        }
                    }
                }
            }

            // MEDIUM TERM TIER
            Rectangle {
                Layout.fillWidth: true; height: 56
                color: "#1A1A1A"; radius: 6

                Rectangle { width: 3; height: parent.height; radius: 2; color: "#f1c40f"; anchors.left: parent.left }

                RowLayout {
                    anchors.fill: parent; anchors.leftMargin: 16; anchors.rightMargin: 12; spacing: 0

                    Text {
                        text: "Medium  2–5y"
                        color: "#f1c40f"; font.pixelSize: 12; font.bold: true
                        Layout.preferredWidth: 118
                    }

                    TextField {
                        id: mInf; text: goalModel.medInf
                        horizontalAlignment: Text.AlignHCenter
                        color: "white"
                        validator: DoubleValidator { bottom: 0; top: 100 }
                        Layout.preferredWidth: 70; Layout.preferredHeight: 30
                        background: Rectangle {
                            color: "#222"; radius: 4
                            border.color: mInf.activeFocus ? "#f1c40f" : "#333"; border.width: 1
                        }
                    }

                    Item { Layout.preferredWidth: 28 }

                    TextField {
                        id: mRet; text: goalModel.medRet
                        horizontalAlignment: Text.AlignHCenter
                        color: "white"
                        validator: DoubleValidator { bottom: 0; top: 100 }
                        Layout.preferredWidth: 70; Layout.preferredHeight: 30
                        background: Rectangle {
                            color: "#222"; radius: 4
                            border.color: mRet.activeFocus ? "#f1c40f" : "#333"; border.width: 1
                        }
                    }
                }
            }

            // LONG TERM TIER
            Rectangle {
                Layout.fillWidth: true; height: 56
                color: "#1A1A1A"; radius: 6

                Rectangle { width: 3; height: parent.height; radius: 2; color: "#a29bfe"; anchors.left: parent.left }

                RowLayout {
                    anchors.fill: parent; anchors.leftMargin: 16; anchors.rightMargin: 12; spacing: 0

                    Text {
                        text: "Long Term  >5y"
                        color: "#a29bfe"; font.pixelSize: 12; font.bold: true
                        Layout.preferredWidth: 118
                    }

                    TextField {
                        id: lInf; text: goalModel.longInf
                        horizontalAlignment: Text.AlignHCenter
                        color: "white"
                        validator: DoubleValidator { bottom: 0; top: 100 }
                        Layout.preferredWidth: 70; Layout.preferredHeight: 30
                        background: Rectangle {
                            color: "#222"; radius: 4
                            border.color: lInf.activeFocus ? "#a29bfe" : "#333"; border.width: 1
                        }
                    }

                    Item { Layout.preferredWidth: 28 }

                    TextField {
                        id: lRet; text: goalModel.longRet
                        horizontalAlignment: Text.AlignHCenter
                        color: "white"
                        validator: DoubleValidator { bottom: 0; top: 100 }
                        Layout.preferredWidth: 70; Layout.preferredHeight: 30
                        background: Rectangle {
                            color: "#222"; radius: 4
                            border.color: lRet.activeFocus ? "#a29bfe" : "#333"; border.width: 1
                        }
                    }
                }
            }

            // Save / Cancel buttons
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 4
                Layout.bottomMargin: 4
                Layout.alignment: Qt.AlignHCenter
                spacing: 16

                Item { Layout.fillWidth: true }

                Rectangle {
                    width: 90; height: 32; radius: 6
                    color: cancelBtnArea.containsMouse ? "#2a2a2a" : "#1e1e1e"
                    border.color: "#444"; border.width: 1
                    Behavior on color { ColorAnimation { duration: 120 } }

                    Text { text: "Cancel"; color: "#888"; font.pixelSize: 13; anchors.centerIn: parent }

                    MouseArea {
                        id: cancelBtnArea; anchors.fill: parent; hoverEnabled: true
                        onClicked: settingsDialog.reject()
                    }
                }

                Rectangle {
                    width: 90; height: 32; radius: 6
                    color: saveBtnArea.containsMouse ? "#005fa3" : "#0078D4"
                    Behavior on color { ColorAnimation { duration: 120 } }

                    Text { text: "Save"; color: "white"; font.pixelSize: 13; font.bold: true; anchors.centerIn: parent }

                    MouseArea {
                        id: saveBtnArea; anchors.fill: parent; hoverEnabled: true
                        onClicked: {
                            goalModel.updateSettings(parseFloat(sInf.text), parseFloat(sRet.text),
                                                     parseFloat(mInf.text), parseFloat(mRet.text),
                                                     parseFloat(lInf.text), parseFloat(lRet.text))
                            settingsDialog.accept()
                        }
                    }
                }

                Item { Layout.fillWidth: true }
            }
        }
    }

    component HeaderLabel : Text {
        color: "#888"; font.pixelSize: 10; font.bold: true; font.letterSpacing: 1
    }

    component GoalInput : TextInput {
        color: "white"; font.pixelSize: 13
        selectByMouse: true          // allows click-drag selection
        mouseSelectionMode: TextInput.SelectCharacters
        cursorVisible: activeFocus
        verticalAlignment: Text.AlignVCenter
        clip: true

        // Underline that highlights on focus/hover
        Rectangle {
            anchors.bottom: parent.bottom; width: parent.width; height: 1
            color: parent.activeFocus ? "#00d2ff" : (underlineMA.containsMouse ? "#444" : "transparent")
        }

        // Thin hover area just to change cursor — does NOT consume mouse so TextInput
        // keeps full selection/click handling
        MouseArea {
            id: underlineMA
            anchors.fill: parent; hoverEnabled: true
            cursorShape: Qt.IBeamCursor
            acceptedButtons: Qt.NoButton  // pass all clicks through to TextInput
        }
    }
}