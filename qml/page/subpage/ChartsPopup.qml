import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtCharts

Popup {
    id: analyticsPopup
    x: (parent.width - width) / 2
    y: (parent.height - height) / 2
    width: parent.width * 0.85
    height: parent.height * 0.8
    modal: true
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    // Re-pull live data every time the popup opens, and keep it live while open.
    property real currentTypeTotal: sipModel.getTotal(sipPlannerRoot.currentType)

    onOpened: refreshAll()
    Connections {
        target: sipModel
        function onSipUpdated() { if (analyticsPopup.opened) refreshAll() }
    }
    Connections {
        target: sipPlannerRoot
        function onCurrentTypeChanged() { if (analyticsPopup.opened) refreshAll() }
    }
    function refreshAll() {
        currentTypeTotal = sipModel.getTotal(sipPlannerRoot.currentType);
        equityCategoryChart.refresh(); equityInstrumentChart.refresh(); equityMarketChart.refresh();
        debtTypeChart.refresh(); debtHoldingsChart.refresh();
        reTypeChart.refresh(); reHoldingsChart.refresh();
        commodityTypeChart.refresh(); commodityHoldingsChart.refresh();
        cryptoHoldingsChart.refresh();
    }

    Overlay.modal: Rectangle {
        color: "#CC000000" // Deep dim effect
    }

    background: Rectangle {
        color: "#121212"
        border.color: "#2A2A2A"
        border.width: 1
        radius: 12
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 25
        spacing: 15

        // --- POPUP HEADER ---
        RowLayout {
            Layout.fillWidth: true
            ColumnLayout {
                spacing: 2
                Text {
                    text: sipPlannerRoot.currentType.toUpperCase() + " ANALYTICS"
                    color: "white"
                    font.pixelSize: 18; font.bold: true; font.letterSpacing: 2
                }
                Rectangle { Layout.preferredWidth: 40; Layout.preferredHeight: 3; color: breakdownBtn.currentAccent }
            }
            Item { Layout.fillWidth: true }
            ColumnLayout {
                spacing: 0
                Text {
                    text: "TOTAL MONTHLY SIP"
                    color: "#666"; font.pixelSize: 9; font.bold: true; font.letterSpacing: 1
                    Layout.alignment: Qt.AlignRight
                }
                Text {
                    text: root.currencySymbol + " " + analyticsPopup.currentTypeTotal.toLocaleString(Qt.locale(), 'f', 0)
                    color: breakdownBtn.currentAccent; font.pixelSize: 18; font.bold: true
                    Layout.alignment: Qt.AlignRight
                }
            }
            ToolButton {
                text: "×"
                onClicked: analyticsPopup.close()
                contentItem: Text { text: "×"; color: "#666"; font.pixelSize: 28; horizontalAlignment: Text.AlignHCenter }
                background: Rectangle { color: "transparent" }
            }
        }

        // --- CHARTS VIEWPORT ---
        StackLayout {
            id: chartStack
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: sipPlannerRoot.assetTabIndex

            // --- PAGE 0: EQUITY ---
            RowLayout {
                spacing: 15
                SipDonutChart {
                    id: equityCategoryChart
                    title: "MARKET CAP"; assetType: "Equity"; groupField: "category"
                    accentColor: sipPlannerRoot.colorEquity
                }
                SipDonutChart {
                    id: equityInstrumentChart
                    title: "INSTRUMENT"; assetType: "Equity"; groupField: "subType"
                    accentColor: sipPlannerRoot.colorEquity
                }
                SipDonutChart {
                    id: equityMarketChart
                    title: "GEOGRAPHY"; assetType: "Equity"; groupField: "market"
                    accentColor: sipPlannerRoot.colorEquity
                }
            }

            // --- PAGE 1: DEBT ---
            RowLayout {
                spacing: 15
                SipDonutChart {
                    id: debtTypeChart
                    title: "ALLOCATION"; assetType: "Debt"; groupField: "subType"
                    accentColor: sipPlannerRoot.colorDebt
                }
                SipDonutChart {
                    id: debtHoldingsChart
                    title: "TOP HOLDINGS"; assetType: "Debt"; groupField: "name"
                    accentColor: sipPlannerRoot.colorDebt
                }
            }

            // --- PAGE 2: REAL ESTATE ---
            RowLayout {
                spacing: 15
                SipDonutChart {
                    id: reTypeChart
                    title: "TYPE"; assetType: "Real Estate"; groupField: "subType"
                    accentColor: sipPlannerRoot.colorRealEstate
                }
                SipDonutChart {
                    id: reHoldingsChart
                    title: "TOP HOLDINGS"; assetType: "Real Estate"; groupField: "name"
                    accentColor: sipPlannerRoot.colorRealEstate
                }
            }

            // --- PAGE 3: COMMODITY ---
            RowLayout {
                spacing: 15
                SipDonutChart {
                    id: commodityTypeChart
                    title: "TYPE"; assetType: "Commodity"; groupField: "subType"
                    accentColor: sipPlannerRoot.colorCommodity
                }
                SipDonutChart {
                    id: commodityHoldingsChart
                    title: "TOP HOLDINGS"; assetType: "Commodity"; groupField: "name"
                    accentColor: sipPlannerRoot.colorCommodity
                }
            }

            // --- PAGE 4: CRYPTO ---
            RowLayout {
                spacing: 15
                SipDonutChart {
                    id: cryptoHoldingsChart
                    title: "PORTFOLIO SPLIT"; assetType: "Crypto"; groupField: "name"
                    accentColor: sipPlannerRoot.colorCrypto
                }
            }
        }
    }

    // --- REUSABLE DONUT COMPONENT ---
    // Aggregates real SIP entries (via unifiedSipModel.getEntries) by whichever
    // field is requested (category / subType / market / name), so every chart
    // reflects the user's actual data instead of fixed placeholder numbers.
    component SipDonutChart : ChartView {
        property alias series: pieSeries
        property color accentColor: "cyan"
        property string title: ""
        property string assetType: ""
        property string groupField: ""

        readonly property var colorPalette: [
            accentColor,
            Qt.lighter(accentColor, 1.35),
            Qt.darker(accentColor, 1.35),
            Qt.lighter(accentColor, 1.7),
            "#ffffff",
            "#666666"
        ]

        property real total: 0

        function refresh() {
            pieSeries.clear();
            let entries = sipModel.getEntries(assetType);
            let totals = {};
            let sum = 0;
            for (let i = 0; i < entries.length; i++) {
                let e = entries[i];
                let key = (e[groupField] && e[groupField].length > 0) ? e[groupField] : "Other";
                totals[key] = (totals[key] || 0) + e.amount;
                sum += e.amount;
            }
            total = sum;
            if (sum <= 0) return;

            let keys = Object.keys(totals).sort(function(a, b) { return totals[b] - totals[a]; });
            for (let k = 0; k < keys.length; k++) {
                let amt = totals[keys[k]];
                if (amt <= 0) continue;
                let pct = Math.round((amt / sum) * 100);
                let slice = pieSeries.append(keys[k], amt);
                slice.color = colorPalette[k % colorPalette.length];
                slice.borderColor = "#121212";
                slice.label = keys[k] + "  " + pct + "%";
            }
        }

        Component.onCompleted: refresh()

        Layout.fillWidth: true
        Layout.fillHeight: true
        backgroundColor: "transparent"
        theme: ChartView.ChartThemeDark
        antialiasing: true
        legend.alignment: Qt.AlignBottom
        legend.labelColor: "#888"
        legend.font.pixelSize: 10
        legend.visible: total > 0

        PieSeries {
            id: pieSeries
            holeSize: 0.65 // Large donut hole for brutalist look

            // Interaction: Pop out slice on hover
            onHovered: (slice, state) => {
                slice.exploded = state;
                slice.labelVisible = state;
            }
        }

        // Title + live total overlay in the center of the donut hole
        ColumnLayout {
            anchors.centerIn: parent
            visible: total > 0
            spacing: 2
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: title
                color: "#666"
                font.pixelSize: 10; font.bold: true; font.letterSpacing: 1
            }
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: root.currencySymbol + " " + total.toLocaleString(Qt.locale(), 'f', 0)
                color: "#CCC"
                font.pixelSize: 12; font.bold: true
            }
        }

        // Empty state when there's no data yet for this breakdown
        ColumnLayout {
            anchors.centerIn: parent
            visible: total <= 0
            spacing: 4
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "No " + assetType + " SIPs yet"
                color: "#444"; font.pixelSize: 12; font.bold: true
            }
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "Add one from the table to see this breakdown"
                color: "#333"; font.pixelSize: 10
            }
        }
    }
}
