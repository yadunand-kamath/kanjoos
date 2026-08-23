import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Popup {
    id: portfolioAnalyticsPopup
    // Sized/centered against the top-level window (root), matching SipChartsPopup.
    parent: Overlay.overlay
    width: root.width * 0.92
    height: root.height * 0.86
    x: (parent.width - width) / 2
    y: (parent.height - height) / 2
    modal: true
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    // Internal tab index — 0=overview, 1=equity, 2=debt, 3=re, 4=commodity, 5=crypto
    property int popupTabIndex: 0

    // Liquidity sub-type definitions (matching PortfolioModel::getAssetsForGoal)
    readonly property var liquidEquity:    ["Stock", "Mutual Fund", "ETF", "ESOPs"]
    readonly property var liquidDebt:      ["FD/RD", "Bond", "Fund", "Cash & Savings"]
    readonly property var liquidRE:        ["REITs"]
    readonly property var liquidCommodity: ["ETF/Fund", "Digital"]
    // Crypto: all liquid

    onOpened: {
        popupTabIndex = 0
        refreshAll()
    }

    Connections {
        target: portfolioModel
        function onPortfolioUpdated() { if (portfolioAnalyticsPopup.opened) refreshAll() }
    }

    function refreshAll() {
        pOverviewAssetChart.refresh()
        pOverviewLiquidityChart.refresh()
        pEquityCapChart.refresh()
        pEquityInstrumentChart.refresh()
        pEquityGeographyChart.refresh()
        pDebtSplitChart.refresh()
        pDebtLiquidityChart.refresh()
        pReSplitChart.refresh()
        pReLiquidityChart.refresh()
        pCommoditySplitChart.refresh()
        pCommodityLiquidityChart.refresh()
        pCryptoSplitChart.refresh()
    }

    Overlay.modal: Rectangle { color: "#CC000000" }

    background: Rectangle {
        color: "#0d0d0d"
        border.color: "#2A2A2A"; border.width: 1
        radius: 14
    }

    readonly property var tabNames: ["OVERVIEW", "EQUITY", "DEBT", "REAL ESTATE", "COMMODITY", "CRYPTO"]
    readonly property color colorEquity:     "#00d2ff"
    readonly property color colorDebt:       "#a29bfe"
    readonly property color colorRealEstate: "#ff7675"
    readonly property color colorCommodity:  "#f1c40f"
    readonly property color colorCrypto:     "#6c5ce7"

    readonly property var tabColors: [
        "#ffffff",
        portfolioAnalyticsPopup.colorEquity,
        portfolioAnalyticsPopup.colorDebt,
        portfolioAnalyticsPopup.colorRealEstate,
        portfolioAnalyticsPopup.colorCommodity,
        portfolioAnalyticsPopup.colorCrypto
    ]

    readonly property color accent: popupTabIndex === 0 ? "#ffffff" : tabColors[popupTabIndex]

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 14

        // ── HEADER ────────────────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true

            ColumnLayout {
                spacing: 4
                Text {
                    text: portfolioAnalyticsPopup.popupTabIndex === 0
                          ? "PORTFOLIO  ANALYTICS"
                          : portfolioAnalyticsPopup.tabNames[portfolioAnalyticsPopup.popupTabIndex] + "  BREAKDOWN"
                    color: "white"; font.pixelSize: 20; font.bold: true; font.letterSpacing: 2
                }
                Rectangle {
                    width: 36; height: 2; radius: 1
                    color: portfolioAnalyticsPopup.accent
                    Behavior on color { ColorAnimation { duration: 200 } }
                }
            }

            Item { Layout.fillWidth: true }

            ColumnLayout {
                spacing: 2; Layout.alignment: Qt.AlignRight
                Text {
                    text: portfolioAnalyticsPopup.popupTabIndex === 0 ? "TOTAL PORTFOLIO VALUE" : "TYPE VALUE"
                    color: "#444"; font.pixelSize: 9; font.letterSpacing: 1
                    Layout.alignment: Qt.AlignRight
                }
                Text {
                    text: {
                        if (portfolioAnalyticsPopup.popupTabIndex === 0)
                            return root.currencySymbol + " " + portfolioModel.getTotalValue("Total").toLocaleString(Qt.locale(), 'f', 0)
                        var t = portfolioAnalyticsPopup.tabNames[portfolioAnalyticsPopup.popupTabIndex]
                        var typeStr = t === "REAL ESTATE" ? "Real Estate"
                                    : t.charAt(0) + t.slice(1).toLowerCase()
                        return root.currencySymbol + " " + portfolioModel.getTotalValue(typeStr).toLocaleString(Qt.locale(), 'f', 0)
                    }
                    color: portfolioAnalyticsPopup.accent; font.pixelSize: 20; font.bold: true
                    Layout.alignment: Qt.AlignRight
                    Behavior on color { ColorAnimation { duration: 200 } }
                }
            }

            Item { width: 12 }

            Rectangle {
                width: 32; height: 32; radius: 16
                color: pCloseHover.containsMouse ? "#222" : "transparent"
                Behavior on color { ColorAnimation { duration: 150 } }
                Text { anchors.centerIn: parent; text: "×"; color: "#666"; font.pixelSize: 22 }
                MouseArea { id: pCloseHover; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: portfolioAnalyticsPopup.close() }
            }
        }

        // ── TAB PILLS ─────────────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Repeater {
                model: portfolioAnalyticsPopup.tabNames
                delegate: Rectangle {
                    height: 26; radius: 13
                    width: pTabPillText.implicitWidth + 20
                    color: "transparent"
                    border.width: 2
                    border.color: portfolioAnalyticsPopup.popupTabIndex === index
                                  ? portfolioAnalyticsPopup.tabColors[index]
                                  : (portfolioModel.getTotalValue(
                                         index === 0 ? "Total" :
                                         modelData === "REAL ESTATE" ? "Real Estate" :
                                         modelData.charAt(0) + modelData.slice(1).toLowerCase()
                                     ) > 0 ? "#444" : "#222")
                    Behavior on border.color { ColorAnimation { duration: 150 } }

                    Text {
                        id: pTabPillText
                        anchors.centerIn: parent
                        text: modelData
                        font.bold: true; font.pixelSize: 10; font.letterSpacing: 0.5
                        color: portfolioAnalyticsPopup.popupTabIndex === index
                               ? "#ffffff"
                               : (portfolioModel.getTotalValue(
                                      index === 0 ? "Total" :
                                      modelData === "REAL ESTATE" ? "Real Estate" :
                                      modelData.charAt(0) + modelData.slice(1).toLowerCase()
                                  ) > 0 ? "#999" : "#333")
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }

                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: portfolioAnalyticsPopup.popupTabIndex = index
                    }
                }
            }

            Item { Layout.fillWidth: true }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: "#1e1e1e" }

        // ── CHARTS ────────────────────────────────────────────────────────────
        StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: portfolioAnalyticsPopup.popupTabIndex

            // ── Overview (index 0) ────────────────────────────────────────────
            RowLayout {
                spacing: 16
                Item { Layout.fillWidth: true }
                PortfolioDonutChart {
                    id: pOverviewAssetChart; title: "ASSET MIX"; accentColor: "#00d2ff"; assetType: "Total"; useAssetMixMode: true
                    Layout.fillWidth: true; Layout.minimumWidth: 220; Layout.maximumWidth: portfolioAnalyticsPopup.width * 0.36; Layout.fillHeight: true
                }
                PortfolioDonutChart {
                    id: pOverviewLiquidityChart; title: "LIQUIDITY MIX"; accentColor: "#43e97b"; assetType: "Total"; useLiquidityMode: true
                    liquidColor: "#43e97b"; lockedColor: "#F44336"
                    Layout.fillWidth: true; Layout.minimumWidth: 220; Layout.maximumWidth: portfolioAnalyticsPopup.width * 0.36; Layout.fillHeight: true
                }
                Item { Layout.fillWidth: true }
            }

            // ── Equity (index 1) ──────────────────────────────────────────────
            RowLayout {
                spacing: 16
                PortfolioDonutChart { id: pEquityCapChart;       title: "MARKET CAP"; assetType: "Equity"; groupField: "category"; accentColor: portfolioAnalyticsPopup.colorEquity; Layout.fillWidth: true; Layout.minimumWidth: 220; Layout.maximumWidth: portfolioAnalyticsPopup.width * 0.3; Layout.fillHeight: true }
                PortfolioDonutChart { id: pEquityInstrumentChart; title: "INSTRUMENT"; assetType: "Equity"; groupField: "subType";  accentColor: portfolioAnalyticsPopup.colorEquity; Layout.fillWidth: true; Layout.minimumWidth: 220; Layout.maximumWidth: portfolioAnalyticsPopup.width * 0.3; Layout.fillHeight: true }
                PortfolioDonutChart { id: pEquityGeographyChart;  title: "GEOGRAPHY";  assetType: "Equity"; groupField: "market";   accentColor: portfolioAnalyticsPopup.colorEquity; Layout.fillWidth: true; Layout.minimumWidth: 220; Layout.maximumWidth: portfolioAnalyticsPopup.width * 0.3; Layout.fillHeight: true }
            }

            // ── Debt (index 2) ────────────────────────────────────────────────
            RowLayout {
                spacing: 16
                Item { Layout.fillWidth: true }
                PortfolioDonutChart { id: pDebtSplitChart; title: "ALLOCATION"; assetType: "Debt"; groupField: "subType"; accentColor: portfolioAnalyticsPopup.colorDebt; Layout.fillWidth: true; Layout.minimumWidth: 220; Layout.maximumWidth: portfolioAnalyticsPopup.width * 0.3; Layout.fillHeight: true }
                PortfolioDonutChart {
                    id: pDebtLiquidityChart; title: "LIQUIDITY"; assetType: "Debt"; useLiquidityMode: true
                    liquidSubTypes: portfolioAnalyticsPopup.liquidDebt; liquidColor: "#43e97b"; lockedColor: "#F44336"; accentColor: portfolioAnalyticsPopup.colorDebt
                    Layout.fillWidth: true; Layout.minimumWidth: 220; Layout.maximumWidth: portfolioAnalyticsPopup.width * 0.3; Layout.fillHeight: true
                }
                Item { Layout.fillWidth: true }
            }

            // ── Real Estate (index 3) ─────────────────────────────────────────
            RowLayout {
                spacing: 16
                Item { Layout.fillWidth: true }
                PortfolioDonutChart { id: pReSplitChart; title: "TYPE"; assetType: "Real Estate"; groupField: "subType"; accentColor: portfolioAnalyticsPopup.colorRealEstate; Layout.fillWidth: true; Layout.minimumWidth: 220; Layout.maximumWidth: portfolioAnalyticsPopup.width * 0.3; Layout.fillHeight: true }
                PortfolioDonutChart {
                    id: pReLiquidityChart; title: "LIQUIDITY"; assetType: "Real Estate"; useLiquidityMode: true
                    liquidSubTypes: portfolioAnalyticsPopup.liquidRE; liquidColor: "#43e97b"; lockedColor: "#F44336"; accentColor: portfolioAnalyticsPopup.colorRealEstate
                    Layout.fillWidth: true; Layout.minimumWidth: 220; Layout.maximumWidth: portfolioAnalyticsPopup.width * 0.3; Layout.fillHeight: true
                }
                Item { Layout.fillWidth: true }
            }

            // ── Commodity (index 4) ───────────────────────────────────────────
            RowLayout {
                spacing: 16
                Item { Layout.fillWidth: true }
                PortfolioDonutChart { id: pCommoditySplitChart; title: "TYPE"; assetType: "Commodity"; groupField: "subType"; accentColor: portfolioAnalyticsPopup.colorCommodity; Layout.fillWidth: true; Layout.minimumWidth: 220; Layout.maximumWidth: portfolioAnalyticsPopup.width * 0.3; Layout.fillHeight: true }
                PortfolioDonutChart {
                    id: pCommodityLiquidityChart; title: "LIQUIDITY"; assetType: "Commodity"; useLiquidityMode: true
                    liquidSubTypes: portfolioAnalyticsPopup.liquidCommodity; liquidColor: "#43e97b"; lockedColor: "#F44336"; accentColor: portfolioAnalyticsPopup.colorCommodity
                    Layout.fillWidth: true; Layout.minimumWidth: 220; Layout.maximumWidth: portfolioAnalyticsPopup.width * 0.3; Layout.fillHeight: true
                }
                Item { Layout.fillWidth: true }
            }

            // ── Crypto (index 5) ──────────────────────────────────────────────
            RowLayout {
                spacing: 16
                Item { Layout.fillWidth: true }
                PortfolioDonutChart {
                    id: pCryptoSplitChart; title: "BY ASSET"; assetType: "Crypto"; groupField: "name"; accentColor: portfolioAnalyticsPopup.colorCrypto
                    Layout.fillWidth: true; Layout.minimumWidth: 220; Layout.maximumWidth: portfolioAnalyticsPopup.width * 0.3; Layout.fillHeight: true
                }
                Item { Layout.fillWidth: true }
            }
        }
    }

    // ── PORTFOLIO DONUT CHART COMPONENT ───────────────────────────────────────
    // Same canvas donut as SipChartsPopup but reads from portfolioModel.getEntries()
    // using `value` (currentValue) field instead of `amount`.
    component PortfolioDonutChart : Item {
        id: pDonutRoot
        property color accentColor: "#00d2ff"
        property string title: ""
        property string assetType: ""
        property string groupField: ""

        property bool useLiquidityMode: false
        property bool useAssetMixMode:  false
        property bool allCryptoLiquid:  false
        property var  liquidSubTypes:   []
        property color liquidColor: "#43e97b"
        property color lockedColor: "#F44336"

        Layout.fillWidth: true
        Layout.fillHeight: true

        property var slices: []
        property real total: 0

        readonly property var colorPalette: [
            accentColor,
            Qt.rgba(1, 1, 1, 0.75),
            Qt.lighter(accentColor, 1.5),
            Qt.darker(accentColor, 1.6),
            "#555555",
            Qt.lighter(accentColor, 2.0)
        ]

        readonly property var assetTypeColors: [
            "#00d2ff", "#a29bfe", "#ff7675", "#f1c40f", "#6c5ce7"
        ]
        readonly property var assetTypeNames: ["Equity", "Debt", "Real Estate", "Commodity", "Crypto"]

        readonly property var liquidByType: ({
            "Equity":      ["Stock", "Mutual Fund", "ETF", "ESOPs"],
            "Debt":        ["FD/RD", "Bond", "Fund", "Cash & Savings"],
            "Real Estate": ["REITs"],
            "Commodity":   ["ETF/Fund", "Digital"],
            "Crypto":      ["__ALL__"]
        })

        function refresh() {
            if (useLiquidityMode) {
                _refreshLiquidity()
            } else if (useAssetMixMode) {
                _refreshAssetMix()
            } else {
                _refreshGrouped()
            }
            pDonutCanvas.requestPaint()
        }

        function _refreshGrouped() {
            var entries = portfolioModel.getEntries(assetType)
            var totals = {}
            var sum = 0
            for (var i = 0; i < entries.length; i++) {
                var e = entries[i]
                var key = (e[groupField] && e[groupField].length > 0 && e[groupField] !== "-")
                          ? e[groupField] : "Other"
                totals[key] = (totals[key] || 0) + e.value
                sum += e.value
            }
            total = sum
            var keys = Object.keys(totals).sort(function(a, b) { return totals[b] - totals[a] })
            var result = []
            for (var k = 0; k < keys.length; k++) {
                var amt = totals[keys[k]]
                if (amt <= 0) continue
                result.push({
                    label: keys[k],
                    value: amt,
                    pct: Math.round((amt / sum) * 100),
                    color: colorPalette[k % colorPalette.length]
                })
            }
            slices = result
        }

        function _refreshLiquidity() {
            var types = assetType === "Total" ? assetTypeNames : [assetType]
            var liquidAmt = 0
            var lockedAmt = 0
            for (var t = 0; t < types.length; t++) {
                var typeName = types[t]
                var entries = portfolioModel.getEntries(typeName)
                var subs = (allCryptoLiquid && typeName === "Crypto")
                           ? ["__ALL__"]
                           : (liquidSubTypes.length > 0 ? liquidSubTypes : (liquidByType[typeName] || []))
                for (var i = 0; i < entries.length; i++) {
                    var e = entries[i]
                    if (subs[0] === "__ALL__" || subs.indexOf(e.subType) >= 0) {
                        liquidAmt += e.value
                    } else {
                        lockedAmt += e.value
                    }
                }
            }
            var sum = liquidAmt + lockedAmt
            total = sum
            var result = []
            if (sum <= 0) { slices = result; return }
            if (liquidAmt > 0) result.push({ label: "LIQUID", value: liquidAmt, pct: Math.round((liquidAmt/sum)*100), color: liquidColor })
            if (lockedAmt > 0) result.push({ label: "LOCKED", value: lockedAmt, pct: Math.round((lockedAmt/sum)*100), color: lockedColor })
            slices = result
        }

        function _refreshAssetMix() {
            var sum = 0
            for (var i = 0; i < assetTypeNames.length; i++)
                sum += portfolioModel.getTotalValue(assetTypeNames[i])
            total = sum
            if (sum <= 0) { slices = []; return }
            var result = []
            for (var j = 0; j < assetTypeNames.length; j++) {
                var a = portfolioModel.getTotalValue(assetTypeNames[j])
                if (a <= 0) continue
                result.push({
                    label: assetTypeNames[j],
                    value: a,
                    pct: Math.round((a / sum) * 100),
                    color: assetTypeColors[j]
                })
            }
            slices = result
        }

        property int hoveredSlice: -1

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            Text {
                text: pDonutRoot.title
                color: "#555"; font.pixelSize: 10; font.bold: true; font.letterSpacing: 1.5
                Layout.alignment: Qt.AlignHCenter
                Layout.bottomMargin: 8
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                Canvas {
                    id: pDonutCanvas
                    anchors.fill: parent

                    onPaint: {
                        var ctx = getContext("2d")
                        ctx.clearRect(0, 0, width, height)
                        if (pDonutRoot.total <= 0) return

                        var cx = width / 2
                        var cy = height / 2
                        var r  = Math.min(width, height) * 0.42
                        var innerR = r * 0.60
                        var gap = 0.018
                        var startAngle = -Math.PI / 2

                        for (var i = 0; i < pDonutRoot.slices.length; i++) {
                            var s = pDonutRoot.slices[i]
                            var sweep = (s.pct / 100) * 2 * Math.PI
                            var hovered = (pDonutRoot.hoveredSlice === i)
                            var outerR = hovered ? r * 1.06 : r

                            ctx.beginPath()
                            ctx.moveTo(cx + innerR * Math.cos(startAngle + gap / 2),
                                       cy + innerR * Math.sin(startAngle + gap / 2))
                            ctx.arc(cx, cy, outerR, startAngle + gap / 2, startAngle + sweep - gap / 2, false)
                            ctx.arc(cx, cy, innerR, startAngle + sweep - gap / 2, startAngle + gap / 2, true)
                            ctx.closePath()

                            var col = Qt.color(s.color)
                            ctx.fillStyle = hovered
                                ? Qt.rgba(Math.min(1, col.r*1.25), Math.min(1, col.g*1.25), Math.min(1, col.b*1.25), 1)
                                : s.color
                            ctx.fill()
                            startAngle += sweep
                        }

                        ctx.beginPath()
                        ctx.arc(cx, cy, innerR - 1, 0, 2 * Math.PI, false)
                        ctx.fillStyle = "#0d0d0d"
                        ctx.fill()
                    }

                    MouseArea {
                        anchors.fill: parent; hoverEnabled: true
                        onPositionChanged: (mouse) => {
                            if (pDonutRoot.total <= 0) { pDonutRoot.hoveredSlice = -1; return }
                            var cx = pDonutCanvas.width / 2
                            var cy = pDonutCanvas.height / 2
                            var dx = mouse.x - cx; var dy = mouse.y - cy
                            var dist = Math.sqrt(dx*dx + dy*dy)
                            var r = Math.min(pDonutCanvas.width, pDonutCanvas.height) * 0.42
                            var innerR = r * 0.60
                            if (dist < innerR || dist > r * 1.1) { pDonutRoot.hoveredSlice = -1; pDonutCanvas.requestPaint(); return }
                            var angle = Math.atan2(dy, dx) + Math.PI / 2
                            if (angle < 0) angle += 2 * Math.PI
                            var start = 0; var found = -1
                            for (var i = 0; i < pDonutRoot.slices.length; i++) {
                                var sweep = (pDonutRoot.slices[i].pct / 100) * 2 * Math.PI
                                if (angle >= start && angle < start + sweep) { found = i; break }
                                start += sweep
                            }
                            if (pDonutRoot.hoveredSlice !== found) { pDonutRoot.hoveredSlice = found; pDonutCanvas.requestPaint() }
                        }
                        onExited: { pDonutRoot.hoveredSlice = -1; pDonutCanvas.requestPaint() }
                    }
                }

                ColumnLayout {
                    anchors.centerIn: parent; spacing: 2
                    visible: pDonutRoot.total > 0

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: pDonutRoot.hoveredSlice >= 0 ? pDonutRoot.slices[pDonutRoot.hoveredSlice].label : "TOTAL"
                        color: pDonutRoot.hoveredSlice >= 0 ? Qt.color(pDonutRoot.slices[pDonutRoot.hoveredSlice].color) : "#444"
                        font.pixelSize: 9; font.bold: true; font.letterSpacing: 1
                        horizontalAlignment: Text.AlignHCenter
                    }
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: pDonutRoot.hoveredSlice >= 0
                              ? root.currencySymbol + " " + pDonutRoot.slices[pDonutRoot.hoveredSlice].value.toLocaleString(Qt.locale(), 'f', 0)
                              : root.currencySymbol + " " + pDonutRoot.total.toLocaleString(Qt.locale(), 'f', 0)
                        color: pDonutRoot.hoveredSlice >= 0 ? Qt.color(pDonutRoot.slices[pDonutRoot.hoveredSlice].color) : "#aaa"
                        font.pixelSize: 13; font.bold: true; horizontalAlignment: Text.AlignHCenter
                    }
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        visible: pDonutRoot.hoveredSlice >= 0
                        text: pDonutRoot.hoveredSlice >= 0 ? pDonutRoot.slices[pDonutRoot.hoveredSlice].pct + "%" : ""
                        color: "#555"; font.pixelSize: 10; horizontalAlignment: Text.AlignHCenter
                    }
                }

                ColumnLayout {
                    anchors.centerIn: parent; visible: pDonutRoot.total <= 0; spacing: 6
                    Text { Layout.alignment: Qt.AlignHCenter; text: "No data"; color: "#333"; font.pixelSize: 13; font.bold: true }
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "Add " + (pDonutRoot.assetType === "Total" ? "assets" : pDonutRoot.assetType + " assets") + "\nto see this breakdown"
                        color: "#2a2a2a"; font.pixelSize: 10; horizontalAlignment: Text.AlignHCenter; wrapMode: Text.WordWrap
                    }
                }
            }

            Column {
                // Legend rows — fixed height reservation so the canvas above is the
                // same size regardless of how many legend rows this chart has.
                Layout.fillWidth: true
                Layout.preferredHeight: 5 * 20
                Layout.topMargin: 10; Layout.leftMargin: 8; spacing: 5
                visible: pDonutRoot.total > 0
                clip: true

                Repeater {
                    model: pDonutRoot.slices
                    RowLayout {
                        width: parent.width; spacing: 8
                        Rectangle {
                            width: 8; height: 8; radius: 2; color: modelData.color
                            Layout.alignment: Qt.AlignVCenter
                        }
                        Text {
                            text: modelData.label
                            color: pDonutRoot.hoveredSlice === index ? Qt.color(modelData.color) : "#888"
                            font.pixelSize: 10; Layout.fillWidth: true; elide: Text.ElideRight
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                        Text {
                            text: modelData.pct + "%"
                            color: pDonutRoot.hoveredSlice === index ? Qt.color(modelData.color) : "#555"
                            font.pixelSize: 10; font.bold: true; Layout.rightMargin: 8
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                    }
                }
            }
        }
    }
}
