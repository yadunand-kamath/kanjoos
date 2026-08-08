import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: overviewRoot
    color: "#000000"

    property int refreshTick: 0

    // BINDINGS TO C++ MODELS
    property real actualNetWorth: portfolioModel.getTotalValue("Total") - totalLiabilities
    property real displayedNetWorth: 0

    property real minContentWidth: 320
    readonly property real dashboardWidth: 550

    // Liquid: Equity + Debt + Crypto + Commodities
    property real liquidValue: portfolioModel.getTotalValue("Equity") + portfolioModel.getTotalValue("Debt") +
                               portfolioModel.getTotalValue("Crypto") + portfolioModel.getTotalValue("Commodity")

    // Illiquid: Real Estate
    property real illiquidValue: portfolioModel.getTotalValue("Real Estate")

    property real totalAssets: liquidValue + illiquidValue
    property real totalLiabilities: 0 // Updated via the "TRACK" modal

    // Liquid Assets = Sum of Cash, Savings, and Equity (for this example)
    property real liquidNetWorth: portfolioModel.getTotalValue("Equity") + portfolioModel.getTotalValue("Debt")

    // Progress bar tracker
    property real emergencyCoverage: goalModel.getGoalCoverage("Emergency Fund")
    property real retirementCoverage: goalModel.getGoalCoverage("Retirement")

    Connections {
        target: goalModel
        function onTotalsChanged() {
            overviewRoot.emergencyCoverage = goalModel.getGoalCoverage("Emergency Fund")
            overviewRoot.retirementCoverage = goalModel.getGoalCoverage("Retirement")
        }
    }

    // Dynamic System Status
    property string systemStatus: {
        if (goalModel.coverageRatio < 50)
            return "> [ CRITICAL ] Global funding deficit. High risk to Goals."
        if (goalModel.coverageRatio < 100)
            return "> [ WARN ] Moderate SIP shortfall detected."
        return "> [ OK ] Systems nominal. All goals on track."
    }

    Behavior on displayedNetWorth {
        NumberAnimation {
            duration: Math.max(800, Math.min(2000, overviewRoot.actualNetWorth / 10000))
            easing.type: Easing.OutExpo
        }
    }

    onVisibleChanged: {
        if (visible) {
            overviewRoot.displayedNetWorth = 0 // Reset
            Qt.callLater(function() {
                overviewRoot.displayedNetWorth = overviewRoot.actualNetWorth
            })
        }
    }

    onActualNetWorthChanged: {
        if (visible) {
            overviewRoot.displayedNetWorth = overviewRoot.actualNetWorth
        }
    }

    Component.onCompleted: {
        overviewRoot.displayedNetWorth = overviewRoot.actualNetWorth
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 40
        anchors.topMargin: 10
        spacing: 40

        // --- 1. THE HEADLINE (NET WORTH ROLL-UP) ---
        ColumnLayout {
            id: netWorthContainer
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            // Width hugs the net worth number itself, with a floor so the
            // bar/grid below don't collapse when the figure is small.
            Layout.preferredWidth: Math.max(netWorthText.implicitWidth, minContentWidth)
            spacing: 5

            Text {
                text: "NET WORTH"
                color: "#999"
                font.pixelSize: 14; font.bold: true; font.letterSpacing: 2
                Layout.alignment: Qt.AlignHCenter
            }

            // Net Worth Value
            Text {
                id: netWorthText
                text: root.currencySymbol + " " + Math.floor(overviewRoot.displayedNetWorth).toLocaleString(Qt.locale(), 'f', 0)
                color: "#FFFFFF"
                font.pixelSize: 64; font.bold: true
                Layout.alignment: Qt.AlignHCenter
            }

            // DIVERSIFICATION
            RowLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 15
                spacing: 10

                // Hover Label - Asset Name
                Text {
                    text: divBar.hoverLabel
                    color: "#888"
                    font.pixelSize: 12; font.bold: true; font.letterSpacing: 1

                    // This prevents the bar from moving
                    Layout.preferredWidth: 150
                    horizontalAlignment: Text.AlignRight
                }

                // Composition Bar Container
                Rectangle {
                    id: barContainer
                    Layout.preferredWidth: netWorthText.width // width for the visual bar
                    Layout.preferredHeight: 10
                    color: "#1A1A1A"
                    Layout.alignment: Qt.AlignVCenter
                    radius: 0

                    MouseArea {
                        anchors.fill: parent
                        // Make the exit-box even larger so user doesn't have to be precise
                        anchors.margins: -15
                        hoverEnabled: true

                        onPositionChanged: {
                            // Calculate which child segment is under the mouse x coordinate
                            let hit = divBar.childAt(mouseX, height / 2)
                            if (hit && hit.type !== undefined) {
                                divBar.hoverLabel = hit.type.toUpperCase() + ":"
                                divBar.hoverValue = root.currencySymbol + " " + hit.val.toLocaleString(Qt.locale(), 'f', 0)
                            }
                        }

                        onExited: {
                            divBar.hoverLabel = "DIVERSIFICATION:"
                            divBar.hoverValue = ""
                        }
                    }

                    // Composition Bar
                    Row {
                        id: divBar
                        anchors.fill: parent
                        clip: true

                        // Properties updated by BarSegment hover
                        property string hoverLabel: "DIVERSIFICATION:"
                        property string hoverValue: ""

                        BarSegment { type: "Equity"; val: portfolioModel.getTotalValue("Equity"); color: "#00d2ff" }
                        BarSegment { type: "Debt"; val: portfolioModel.getTotalValue("Debt"); color: "#a29bfe" }
                        BarSegment { type: "Real Estate"; val: portfolioModel.getTotalValue("Real Estate"); color: "#ff7675" }
                        BarSegment { type: "Commodity"; val: portfolioModel.getTotalValue("Commodity"); color: "#f1c40f" }
                        BarSegment { type: "Crypto"; val: portfolioModel.getTotalValue("Crypto"); color: "#6c5ce7" }
                    }
                }

                // Hover Label - Asset Value
                Text {
                    text: divBar.hoverValue
                    color: "#888"; font.bold: true
                    font.pixelSize: 12; font.family: "Monospace"

                    // This prevents the bar from moving
                    Layout.preferredWidth: 150
                    horizontalAlignment: Text.AlignLeft
                }

            }
        }

        // --- 2. THE 2x2 METRICS GRID ---
        ColumnLayout {
            Layout.alignment: Qt.AlignHCenter
            // Matches the headline/composition-bar width, but allows
            // growing to fit its own content (e.g. the liabilities row)
            // if that content doesn't fit at the matched width.
            Layout.preferredWidth: overviewRoot.dashboardWidth // Use shared width
            Layout.fillWidth: false
            spacing: 20

            // ROW 1: LIQUID VS ILLIQUID
            RowLayout {
                Layout.preferredWidth: overviewRoot.dashboardWidth
                Layout.alignment: Qt.AlignHCenter
                spacing: 40

                MetricToggleCell {
                    label: "LIQUID ASSETS"
                    percentage: (liquidValue / totalAssets * 100)
                    absoluteValue: liquidValue
                    accent: "#43e97b"
                    Layout.preferredWidth: (overviewRoot.dashboardWidth / 2) - 20
                }

                MetricToggleCell {
                    label: "ILLIQUID ASSETS"
                    percentage: (illiquidValue / totalAssets * 100)
                    absoluteValue: illiquidValue
                    accent: "#F44336"
                    Layout.preferredWidth: (overviewRoot.dashboardWidth / 2) - 20
                }
            }

            // ROW 2: LIABILITIES & TRACK
            Rectangle {
                Layout.fillWidth: true
                height: 50
                color: "#121212"
                border.color: "#2A2A2A"

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 15; anchors.rightMargin: 10

                    Column {
                        Text { text: "TOTAL LIABILITIES"; color: "#888"; font.pixelSize: 9; font.bold: true }
                        Text {
                            text: root.currencySymbol + " " + totalLiabilities.toLocaleString(Qt.locale(), 'f', 0)
                            color: "#FF0000"; font.pixelSize: 18; font.bold: true; font.family: "Monospace"
                        }
                    }

                    Item { Layout.fillWidth: true }

                    Button {
                        text: "TRACK"
                        onClicked: liabilityModal.open()
                        contentItem: Text { text: parent.text; color: "white"; font.bold: true; font.pixelSize: 11 }
                        background: Rectangle {
                            implicitWidth: 80; implicitHeight: 30
                            color: "#2A2A2A"
                            border.color: parent.hovered ? "#FF0000" : "#333"
                        }
                    }
                }
            }
        }

        // --- 3. SYSTEM STATUS TERMINAL ---
        Rectangle {
            Layout.preferredWidth: overviewRoot.dashboardWidth
            Layout.preferredHeight: 40
            Layout.alignment: Qt.AlignHCenter
            color: "#121212"
            border.color: "#2A2A2A"
            radius: 0 // Brutalist sharp edge

            Text {
                anchors.centerIn: parent
                text: overviewRoot.systemStatus
                color: "#FF9100"
                font.family: "Monospace"
                font.pixelSize: 12
                font.bold: true
            }
        }

        // --- 4. CORE PROGRESS BARS (VELOCITY HEALTH) ---
        RowLayout {
            Layout.fillWidth: true
            Layout.maximumWidth: 800
            Layout.alignment: Qt.AlignHCenter
            spacing: 50 // Large horizontal gap

            Connections {
                target: goalModel
                // When the GoalModel signals a total change, increment the tick
                function onTotalsChanged() { overviewRoot.refreshTick++ }
            }

            VelocityTrack {
                title: "EMERGENCY FUND"
                percent: overviewRoot.emergencyCoverage
                fillColor: "#43e97b"
                Layout.fillWidth: true
            }

            VelocityTrack {
                title: "RETIREMENT"
                percent: overviewRoot.retirementCoverage
                fillColor: "#00d2ff"
                Layout.fillWidth: true
            }
        }

        Item { Layout.fillHeight: true } // Spacer to push content up
    }

    // --- 5. THE GLOBAL FOOTER ---
    Rectangle {
        id: globalFooter
        anchors.bottom: parent.bottom
        width: parent.width
        height: 85
        color: "#1A1A1A"
        border.color: "#2A2A2A"

        RowLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 0

            FooterCol {
                label: "TOTAL SIP"
                value: root.currencySymbol + " 45,000"
                Layout.fillWidth: true
            }

            Rectangle { width: 1; Layout.fillHeight: true; color: "#2A2A2A"; Layout.margins: 10 }

            FooterCol {
                label: "GOALS COVERAGE"
                value: "72.4%"
                Layout.fillWidth: true
            }

            Rectangle { width: 1; Layout.fillHeight: true; color: "#2A2A2A"; Layout.margins: 10 }

            FooterCol {
                label: "TOTAL PORTFOLIO"
                value: root.currencySymbol + " 1.24Cr"
                Layout.fillWidth: true
            }
        }
    }

    // --- INTERNAL COMPONENTS ---
    component MetricToggleCell : ColumnLayout {

        property string label: ""
        property real percentage: 0
        property real absoluteValue: 0
        property color accent: "white"

        Text { text: label; color: "#444"; font.pixelSize: 9; font.bold: true }

        MouseArea {
            id: ma
            Layout.fillWidth: true
            height: 30
            hoverEnabled: true
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: ma.containsMouse
                      ? root.currencySymbol + " " + absoluteValue.toLocaleString(Qt.locale(), 'f', 0)
                      : percentage.toFixed(1) + "%"
                color: ma.containsMouse ? "white" : accent
                font.pixelSize: 22; font.bold: true; font.family: "Monospace"
            }
        }
    }

    // Simple Liability Modal
    Dialog {
        id: liabilityModal
        title: "Liability Tracker"
        anchors.centerIn: parent
        modal: true
        standardButtons: Dialog.Ok

        ColumnLayout {
            spacing: 15
            Text { text: "Enter Total Outstanding Liabilities (Loans, Cards, Bills):"; color: "#888" }
            TextField {
                id: liabInput
                placeholderText: "0.00"
                text: totalLiabilities.toString()
                onTextChanged: totalLiabilities = parseFloat(text || 0)
                validator: DoubleValidator { bottom: 0 }
                Layout.fillWidth: true
            }
        }
    }

    component VelocityTrack : ColumnLayout {
        property string title: ""
        property real percent: 0.0
        property color fillColor: "white"
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            Text { text: title; color: "white"; font.pixelSize: 11; font.bold: true; font.letterSpacing: 1 }
            Item { Layout.fillWidth: true }
            Text { text: (percent * 100).toFixed(0) + "%"; color: "#888888"; font.pixelSize: 11; font.family: "Monospace" }
        }

        Rectangle {
            Layout.fillWidth: true; height: 6; color: "#2A2A2A"
            Rectangle {
                width: parent.width * percent; height: parent.height; color: fillColor
                Behavior on width { NumberAnimation { duration: 1000; easing.type: Easing.OutCubic } }
            }
        }
    }

    component BarSegment : Rectangle {
        property string type: ""
        property real val: 0

        // Width is calculated based on the 500px parent container
        width: (overviewRoot.totalAssets > 0) ? (barContainer.width * (val / overviewRoot.totalAssets)) : 0
        height: parent.height
        visible: width > 0.5

        MouseArea {
            anchors.fill: parent; hoverEnabled: true
            width: parent.width; height: 30
            onEntered: {
                divBar.hoverLabel = type.toUpperCase()
                divBar.hoverValue = root.currencySymbol + " " + val.toLocaleString(Qt.locale(), 'f', 0)
            }
        }
    }

    component FooterCol : ColumnLayout {
        property string label: ""
        property string value: ""
        spacing: 2
        Text { text: label; color: "#888888"; font.pixelSize: 10; font.bold: true; Layout.alignment: Qt.AlignHCenter }
        Text { text: value; color: "white"; font.pixelSize: 22; font.bold: true; Layout.alignment: Qt.AlignHCenter }
    }
}