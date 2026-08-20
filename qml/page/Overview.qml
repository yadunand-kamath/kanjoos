import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "../components"

Rectangle {
    id: overviewRoot
    color: "#000000"

    // ── PROPERTIES / BINDINGS ─────────────────────────────────────────────────
    // getTotalValue is a Q_INVOKABLE — no auto-notify. Store results explicitly
    // and refresh them all in onPortfolioUpdated so the whole page stays in sync.
    property real portfolioTotal:    portfolioModel.getTotalValue("Total")
    property real barEquity:         portfolioModel.getTotalValue("Equity")
    property real barDebt:           portfolioModel.getTotalValue("Debt")
    property real barRealEstate:     portfolioModel.getTotalValue("Real Estate")
    property real barCommodity:      portfolioModel.getTotalValue("Commodity")
    property real barCrypto:         portfolioModel.getTotalValue("Crypto")
    property real actualNetWorth:    portfolioTotal - totalLiabilities

    // Static sub-type lists for liquidity — set once in Component.onCompleted
    property var liquidSubTypes:   ["Stock", "Mutual Fund", "ETF",
                                    "FD/RD", "Bond", "Fund", "Cash & Savings",
                                    "REITs", "Digital", "ETF/Fund", "Crypto"]
    property var illiquidSubTypes: ["ESOPs", "Private", "Govt. Scheme",
                                    "Residential", "Commercial", "Physical"]

    property real liquidValue:   portfolioModel.getLiquidValue(liquidSubTypes)
    property real illiquidValue: portfolioModel.getIlliquidValue(illiquidSubTypes)
    property real totalAssets:   liquidValue + illiquidValue
    property real totalLiabilities: 0

    // getGoalFundedRatio — funded ÷ target corpus (0–1+); NOT coverageRatio (SIP ÷ required SIP)
    property real emergencyCoverage: 0.0
    property real retirementCoverage: 0.0

    // Last-updated timestamp (set whenever data changes; persisted later)
    property string lastUpdated: ""

    // ── refreshGoalCoverage ───────────────────────────────────────────────────
    function refreshGoalCoverage() {
        emergencyCoverage  = goalModel.getGoalFundedRatio("Emergency Fund");
        retirementCoverage = goalModel.getGoalFundedRatio("Retirement");
    }

    // ── CONNECTIONS ───────────────────────────────────────────────────────────
    Connections {
        target: goalModel
        function onTotalsChanged() { overviewRoot.refreshGoalCoverage() }
    }

    Connections {
        target: portfolioModel
        function onPortfolioUpdated() {
            // Re-read all invokable return values — bindings on Q_INVOKABLE calls
            // break after beginResetModel (used by clearAll), so we refresh manually.
            overviewRoot.portfolioTotal  = portfolioModel.getTotalValue("Total")
            overviewRoot.barEquity       = portfolioModel.getTotalValue("Equity")
            overviewRoot.barDebt         = portfolioModel.getTotalValue("Debt")
            overviewRoot.barRealEstate   = portfolioModel.getTotalValue("Real Estate")
            overviewRoot.barCommodity    = portfolioModel.getTotalValue("Commodity")
            overviewRoot.barCrypto       = portfolioModel.getTotalValue("Crypto")
            overviewRoot.liquidValue     = portfolioModel.getLiquidValue(overviewRoot.liquidSubTypes)
            overviewRoot.illiquidValue   = portfolioModel.getIlliquidValue(overviewRoot.illiquidSubTypes)
            overviewRoot.refreshGoalCoverage()
        }
    }

    // ── systemStatus ──────────────────────────────────────────────────────────
    // coverageRatio is actual-SIP ÷ required-SIP (%), not corpus funded ratio.
    property string systemStatus: {
        let cov = goalModel.coverageRatio;
        let req = goalModel.totalRequiredSIP;
        let act = goalModel.coverageRatio > 0 ? req * (cov / 100) : 0;
        let shortfall = req - act;

        if (cov <= 0 && req <= 0)
            return "> [ -- ] Enter goal data to see system status."
        if (cov < 50)
            return "> [ CRITICAL ] SIP coverage " + cov.toFixed(0) + "% — ₹" +
                   shortfall.toLocaleString(Qt.locale(), 'f', 0) + "/mo shortfall. Immediate action needed."
        if (cov < 100)
            return "> [ WARN ] SIP coverage " + cov.toFixed(0) + "% — ₹" +
                   shortfall.toLocaleString(Qt.locale(), 'f', 0) + "/mo below target."
        return "> [ OK ] All goals fully funded. Surplus SIP capacity: ₹" +
               (act - req).toLocaleString(Qt.locale(), 'f', 0) + "/mo."
    }

    // ── Component.onCompleted ─────────────────────────────────────────────────
    Component.onCompleted: {
        refreshGoalCoverage();
    }

    // ── MAIN LAYOUT ───────────────────────────────────────────────────────────
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 40
        anchors.topMargin: 10
        spacing: 30

        // ── NET WORTH HEADLINE ────────────────────────────────────────────────
        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            spacing: 4

            Text {
                text: "NET WORTH"
                color: "#666"
                font.pixelSize: 12; font.bold: true; font.letterSpacing: 3
                Layout.alignment: Qt.AlignHCenter
            }

            Text {
                id: netWorthText
                text: root.currencySymbol + " " + Math.floor(overviewRoot.actualNetWorth).toLocaleString(Qt.locale(), 'f', 0)
                color: overviewRoot.actualNetWorth >= 0 ? "#FFFFFF" : "#F44336"
                font.pixelSize: 60; font.bold: true
                Layout.alignment: Qt.AlignHCenter
            }

            // Last updated label — placeholder until persistence
            Text {
                text: overviewRoot.lastUpdated !== "" ? "Last updated: " + overviewRoot.lastUpdated : "Last updated: —"
                color: "#444"
                font.pixelSize: 10; font.italic: true
                Layout.alignment: Qt.AlignHCenter
            }

            // ── DIVERSIFICATION BAR ───────────────────────────────────────────
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 12
                spacing: 12

                // Left label: hovered asset name
                Text {
                    id: barLeftLabel
                    text: "DIVERSIFICATION"
                    color: "#555"
                    font.pixelSize: 11; font.bold: true; font.letterSpacing: 1
                    Layout.preferredWidth: 140
                    horizontalAlignment: Text.AlignRight
                }

                // Bar
                Rectangle {
                    id: barContainer
                    width: Math.max(netWorthText.implicitWidth, 320)
                    height: 10
                    color: "#1A1A1A"
                    radius: 2

                    Row {
                        id: divBar
                        anchors.fill: parent
                        clip: true

                        property string hoverType: ""
                        property real   hoverVal:  0

                        BarSegment { segType: "Equity";      segVal: overviewRoot.barEquity;     segColor: "#00d2ff" }
                        BarSegment { segType: "Debt";        segVal: overviewRoot.barDebt;       segColor: "#a29bfe" }
                        BarSegment { segType: "Real Estate"; segVal: overviewRoot.barRealEstate; segColor: "#ff7675" }
                        BarSegment { segType: "Commodity";   segVal: overviewRoot.barCommodity;  segColor: "#f1c40f" }
                        BarSegment { segType: "Crypto";      segVal: overviewRoot.barCrypto;     segColor: "#6c5ce7" }
                    }
                }

                // Right label: hovered value
                Text {
                    id: barRightLabel
                    text: divBar.hoverType !== "" ? root.currencySymbol + " " + divBar.hoverVal.toLocaleString(Qt.locale(), 'f', 0) : ""
                    color: "#CCCCCC"
                    font.pixelSize: 11; font.bold: true; font.family: "Monospace"
                    Layout.preferredWidth: 140
                    horizontalAlignment: Text.AlignLeft
                }
            }
        }

        // ── METRICS ROW ───────────────────────────────────────────────────────
        // Item + Row: children use width: parent.width/3, avoiding Layout circular bindings.
        Item {
            Layout.fillWidth: true
            Layout.leftMargin: 40
            Layout.rightMargin: 40
            implicitHeight: 56

            Row {
                anchors.fill: parent

                // LIQUID ASSETS
                MetricCell {
                    width: parent.width / 3; height: parent.height
                    label: "LIQUID ASSETS"
                    percentage: totalAssets > 0 ? (liquidValue / totalAssets * 100) : 0
                    absoluteValue: liquidValue
                    accent: "#43e97b"
                }

                // Divider
                Rectangle { width: 1; height: parent.height; color: "#222" }

                // ILLIQUID ASSETS — dark orange, distinct from Real Estate red
                MetricCell {
                    width: parent.width / 3 - 1; height: parent.height
                    label: "ILLIQUID ASSETS"
                    percentage: totalAssets > 0 ? (illiquidValue / totalAssets * 100) : 0
                    absoluteValue: illiquidValue
                    accent: "#e67e22"
                }

                // Divider
                Rectangle { width: 1; height: parent.height; color: "#222" }

                // LIABILITIES — label above, value + TRACK button on same row
                Item {
                    width: parent.width / 3 - 1; height: parent.height

                    Column {
                        anchors.centerIn: parent
                        spacing: 6

                        Text {
                            text: "TOTAL LIABILITIES"
                            color: "#555"; font.pixelSize: 9; font.bold: true; font.letterSpacing: 1
                            anchors.horizontalCenter: parent.horizontalCenter
                        }

                        Row {
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: 10

                            Text {
                                text: root.currencySymbol + " " + totalLiabilities.toLocaleString(Qt.locale(), 'f', 0)
                                color: totalLiabilities > 0 ? "#F44336" : "#444"
                                font.pixelSize: 22; font.bold: true; font.family: "Monospace"
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            // TRACK button
                            Rectangle {
                                width: 52; height: 20; radius: 4
                                anchors.verticalCenter: parent.verticalCenter
                                color: trackArea.containsMouse ? "#2a0a0a" : "transparent"
                                border.color: trackArea.containsMouse ? "#F44336" : "#3a1a1a"
                                border.width: 1
                                Behavior on color        { ColorAnimation { duration: 150 } }
                                Behavior on border.color { ColorAnimation { duration: 150 } }

                                Text {
                                    anchors.centerIn: parent
                                    text: "TRACK"
                                    color: trackArea.containsMouse ? "#F44336" : "#555"
                                    font.pixelSize: 9; font.bold: true; font.letterSpacing: 1
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                }

                                MouseArea {
                                    id: trackArea
                                    anchors.fill: parent; hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: liabilityModal.open()
                                }
                            }
                        }
                    }
                }
            }
        }

        // ── SYSTEM STATUS RECTANGLE ───────────────────────────────────────────
        Rectangle {
            Layout.preferredWidth: 640
            Layout.preferredHeight: 36
            Layout.alignment: Qt.AlignHCenter
            color: "#0D0D0D"
            border.color: "#1E1E1E"
            radius: 2

            Text {
                anchors.centerIn: parent
                text: overviewRoot.systemStatus
                color: {
                    if (overviewRoot.systemStatus.indexOf("CRITICAL") !== -1) return "#F44336"
                    if (overviewRoot.systemStatus.indexOf("WARN")     !== -1) return "#FF9100"
                    if (overviewRoot.systemStatus.indexOf("OK")       !== -1) return "#43e97b"
                    return "#555"
                }
                font.family: "Monospace"; font.pixelSize: 11; font.bold: true
            }
        }

        // ── PROGRESS BARS ─────────────────────────────────────────────────────
        VelocityTrack {
            title: "EMERGENCY FUND"
            subtitle: "Funded vs. Target"
            percent: overviewRoot.emergencyCoverage
            fillColor: "#43e97b"
            Layout.preferredWidth: 640
            Layout.alignment: Qt.AlignHCenter
        }

        VelocityTrack {
            title: "RETIREMENT"
            subtitle: "Funded vs. Target"
            percent: overviewRoot.retirementCoverage
            fillColor: "#00d2ff"
            Layout.preferredWidth: 640
            Layout.alignment: Qt.AlignHCenter
        }

        Item { Layout.fillHeight: true }
    }

    // ── FOOTER ────────────────────────────────────────────────────────────────
    Rectangle {
        anchors.bottom: parent.bottom
        width: parent.width
        height: 80
        color: "#0D0D0D"
        border.color: "#1E1E1E"

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 40; anchors.rightMargin: 40
            spacing: 0

            FooterCol {
                label: "TOTAL SIP / MO"
                value: root.currencySymbol + " " + goalModel.totalRequiredSIP.toLocaleString(Qt.locale(), 'f', 0)
                Layout.fillWidth: true
            }

            Rectangle { width: 1; height: 40; color: "#1E1E1E" }

            FooterCol {
                label: "GOALS COVERAGE"
                value: goalModel.coverageRatio.toFixed(1) + "%"
                valueColor: goalModel.coverageRatio >= 100 ? "#43e97b" : (goalModel.coverageRatio >= 50 ? "#FF9100" : "#F44336")
                Layout.fillWidth: true
            }

            Rectangle { width: 1; height: 40; color: "#1E1E1E" }

            FooterCol {
                label: "TOTAL PORTFOLIO"
                value: root.currencySymbol + " " + overviewRoot.portfolioTotal.toLocaleString(Qt.locale(), 'f', 0)
                Layout.fillWidth: true
            }
        }
    }

    // ── LIABILITY MODAL ───────────────────────────────────────────────────────
    Popup {
        id: liabilityModal
        anchors.centerIn: parent
        modal: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        padding: 0
        width: 320

        background: Rectangle {
            color: "#141414"
            border.color: "#2A2A2A"
            border.width: 1
            radius: 8
        }

        ColumnLayout {
            width: parent.width
            spacing: 0

            // Header: Save (left) · LIABILITIES (center) · × (right)
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 48

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12; anchors.rightMargin: 12
                    spacing: 8

                    // Save — stamps timestamp and closes
                    SaveButton {
                        text: "Save"
                        Layout.alignment: Qt.AlignVCenter
                        onClicked: {
                            overviewRoot.lastUpdated = Qt.formatDateTime(new Date(), "dd MMM yyyy, hh:mm")
                            liabilityModal.close()
                        }
                    }

                    // Centered title
                    Text {
                        text: "LIABILITIES"
                        color: "#F44336"; font.bold: true; font.pixelSize: 13; font.letterSpacing: 2
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    // Close ×
                    Rectangle {
                        width: 28; height: 28; radius: 14
                        color: closeArea.containsMouse ? "#2a0a0a" : "transparent"
                        border.color: closeArea.containsMouse ? "#555" : "transparent"
                        Behavior on color { ColorAnimation { duration: 120 } }
                        Text { text: "×"; color: "#888"; font.pixelSize: 20; anchors.centerIn: parent }
                        MouseArea {
                            id: closeArea; anchors.fill: parent; hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: liabilityModal.close()
                        }
                    }
                }

                Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: "#2A2A2A" }
            }

            // Rows — one per liability category
            Repeater {
                model: liabilityModel
                delegate: ColumnLayout {
                    spacing: 0
                    Layout.fillWidth: true

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.leftMargin: 16; Layout.rightMargin: 16
                        Layout.topMargin: 10; Layout.bottomMargin: 10
                        spacing: 10

                        // Label — fixed width so inputs align
                        Text {
                            text: model.label
                            color: "#888"; font.pixelSize: 12
                            Layout.preferredWidth: 110
                        }

                        // ₹ prefix chip + text field
                        RowLayout {
                            spacing: 0
                            Layout.fillWidth: true

                            Rectangle {
                                width: 24; height: 30; color: "#1A1A1A"; radius: 4
                                Text {
                                    text: root.currencySymbol
                                    color: "#555"; font.pixelSize: 12; anchors.centerIn: parent
                                }
                            }

                            TextField {
                                id: liabField
                                text: model.amount > 0 ? model.amount.toFixed(0) : ""
                                placeholderText: "0"
                                color: "white"; font.pixelSize: 13
                                Layout.fillWidth: true
                                leftPadding: 8
                                selectByMouse: true
                                validator: DoubleValidator { bottom: 0; notation: DoubleValidator.StandardNotation }
                                inputMethodHints: Qt.ImhFormattedNumbersOnly
                                onTextEdited: {
                                    let v = parseFloat(text) || 0;
                                    liabilityModel.setProperty(index, "amount", v);
                                    overviewRoot.totalLiabilities = overviewRoot.sumLiabilities();
                                }
                                background: Rectangle {
                                    color: "#1A1A1A"; radius: 4; implicitHeight: 30
                                    border.color: liabField.activeFocus ? "#F44336" : "transparent"; border.width: 1
                                }
                            }
                        }
                    }

                    Rectangle { Layout.fillWidth: true; height: 1; color: "#1E1E1E" }
                }
            }

            // Total row
            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 16; Layout.rightMargin: 16
                Layout.topMargin: 12; Layout.bottomMargin: 14

                Text { text: "TOTAL"; color: "#888"; font.pixelSize: 10; font.bold: true; font.letterSpacing: 1 }
                Item { Layout.fillWidth: true }
                Text {
                    text: root.currencySymbol + " " + overviewRoot.totalLiabilities.toLocaleString(Qt.locale(), 'f', 0)
                    color: overviewRoot.totalLiabilities > 0 ? "#F44336" : "#444"
                    font.pixelSize: 18; font.bold: true; font.family: "Monospace"
                }
            }
        }
    }

    // ── liabilityModel + sumLiabilities ──────────────────────────────────────
    ListModel {
        id: liabilityModel
        ListElement { label: "Home Loan";   amount: 0 }
        ListElement { label: "Car Loan";    amount: 0 }
        ListElement { label: "Personal Loan"; amount: 0 }
        ListElement { label: "Credit Cards"; amount: 0 }
        ListElement { label: "Other";       amount: 0 }
    }

    // Called on every keystroke in the modal so totalLiabilities (and thus actualNetWorth) updates live.
    function sumLiabilities() {
        let t = 0;
        for (let i = 0; i < liabilityModel.count; i++) t += liabilityModel.get(i).amount;
        return t;
    }

    // ── INTERNAL COMPONENTS ───────────────────────────────────────────────────

    // ── MetricCell ────────────────────────────────────────────────────────────
    // Hover toggles between percentage and absolute value on the same Text node.
    // MetricCell is a plain Item (not ColumnLayout) to avoid recursive-rearrange
    // when nested inside the parent RowLayout with Layout.fillWidth on both sides.
    component MetricCell : Item {
        property string label: ""
        property real   percentage: 0
        property real   absoluteValue: 0
        property color  accent: "white"
        implicitHeight: 56

        Text {
            id: cellLabel
            anchors.top: parent.top; anchors.horizontalCenter: parent.horizontalCenter
            text: label
            color: "#555"; font.pixelSize: 9; font.bold: true; font.letterSpacing: 1
        }

        // Hover: show absolute value; idle: show percentage
        MouseArea {
            id: metricMA
            anchors { top: cellLabel.bottom; topMargin: 4; left: parent.left; right: parent.right; bottom: parent.bottom }
            hoverEnabled: true

            Text {
                anchors.centerIn: parent
                text: metricMA.containsMouse
                      ? root.currencySymbol + " " + absoluteValue.toLocaleString(Qt.locale(), 'f', 0)
                      : percentage.toFixed(1) + "%"
                color: metricMA.containsMouse ? "white" : accent
                font.pixelSize: 22; font.bold: true; font.family: "Monospace"
                Behavior on color { ColorAnimation { duration: 150 } }
            }
        }
    }

    // ── BarSegment ────────────────────────────────────────────────────────────
    // Uses portfolioTotal (not liquidValue+illiquidValue) so all asset types including
    // Crypto (subType "-") are proportioned correctly and always visible.
    component BarSegment : Rectangle {
        property string segType:  ""
        property real   segVal:   0
        property color  segColor: "white"

        color:   segColor
        width:   overviewRoot.portfolioTotal > 0 ? (barContainer.width * (segVal / overviewRoot.portfolioTotal)) : 0
        height:  parent.height
        visible: width > 0.5

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onEntered: { divBar.hoverType = segType; divBar.hoverVal = segVal; barLeftLabel.text = segType.toUpperCase(); }
            onExited:  { divBar.hoverType = ""; divBar.hoverVal = 0; barLeftLabel.text = "DIVERSIFICATION"; }
        }
    }

    // ── VelocityTrack ─────────────────────────────────────────────────────────
    // percent is a 0–1+ ratio from getGoalFundedRatio; clamped to 1.0 for the bar width.
    component VelocityTrack : ColumnLayout {
        property string title: ""
        property string subtitle: ""
        property real   percent: 0.0
        property color  fillColor: "white"
        spacing: 6

        RowLayout {
            Layout.fillWidth: true

            ColumnLayout {
                spacing: 1
                Text { text: title;    color: "white"; font.pixelSize: 11; font.bold: true; font.letterSpacing: 1 }
                Text { text: subtitle; color: "#444";  font.pixelSize: 9 }
            }

            Item { Layout.fillWidth: true }

            Text {
                text: (percent * 100).toFixed(0) + "%"
                color: "#888"; font.pixelSize: 11; font.family: "Monospace"
            }
        }

        Rectangle {
            Layout.fillWidth: true; height: 6; color: "#1A1A1A"; radius: 3
            Rectangle {
                width: parent.width * Math.min(1.0, percent)
                height: parent.height; color: fillColor; radius: 3
                Behavior on width { NumberAnimation { duration: 1000; easing.type: Easing.OutCubic } }
            }
        }
    }

    // ── FooterCol ─────────────────────────────────────────────────────────────
    component FooterCol : ColumnLayout {
        property string label: ""
        property string value: ""
        property color  valueColor: "white"
        spacing: 3

        // Center children horizontally within the column
        Layout.alignment: Qt.AlignHCenter

        Text {
            text: label
            color: "#555"; font.pixelSize: 9; font.bold: true; font.letterSpacing: 1
            horizontalAlignment: Text.AlignHCenter
            Layout.alignment: Qt.AlignHCenter
        }
        Text {
            text: value
            color: valueColor; font.pixelSize: 20; font.bold: true; font.family: "Monospace"
            horizontalAlignment: Text.AlignHCenter
            Layout.alignment: Qt.AlignHCenter
        }
    }
}
