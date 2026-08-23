import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Popup {
    id: analyticsPopup
    // Sized/centered against the top-level window (root), not the immediate
    // parent — SIPPlanner sits nested a level deeper (under its own Goals/SIP
    // Planner sub-tab header) than Portfolio's root, so parent.height differs
    // between the two pages even though both should show equally sized popups.
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

    // Liquidity sub-type lists (shared across donut helpers)
    readonly property var liquidEquity:    ["Stock", "Mutual Fund", "ETF", "ESOPs"]
    readonly property var liquidDebt:      ["FD/RD", "Bond", "Fund", "Cash & Savings"]
    readonly property var liquidRE:        ["REITs"]
    readonly property var liquidCommodity: ["ETF/Fund", "Digital"]
    // Crypto: all liquid

    onOpened: {
        popupTabIndex = 0
        refreshAll()
    }

    // Allow SIPPlanner to open directly to a specific asset tab
    function openToAsset(assetIdx) {
        popupTabIndex = assetIdx + 1   // +1 because 0 is overview
        open()
    }

    Connections {
        target: sipModel
        function onSipUpdated() { if (analyticsPopup.opened) refreshAll() }
    }

    function refreshAll() {
        overviewAssetChart.refresh()
        overviewLiquidityChart.refresh()
        equityCategoryChart.refresh()
        equityInstrumentChart.refresh()
        equityGeographyChart.refresh()
        debtTypeChart.refresh()
        debtLiquidityChart.refresh()
        reSplitChart.refresh()
        reLiquidityChart.refresh()
        commoditySplitChart.refresh()
        commodityLiquidityChart.refresh()
        cryptoSplitChart.refresh()
    }

    Overlay.modal: Rectangle { color: "#CC000000" }

    background: Rectangle {
        color: "#0d0d0d"
        border.color: "#2A2A2A"; border.width: 1
        radius: 14
    }

    // Accent color tied to active popup tab (0=overview uses white)
    readonly property color accent: popupTabIndex === 0 ? "#ffffff"
        : [
            sipPlannerRoot.colorEquity, sipPlannerRoot.colorDebt,
            sipPlannerRoot.colorRealEstate, sipPlannerRoot.colorCommodity,
            sipPlannerRoot.colorCrypto
          ][popupTabIndex - 1]

    readonly property var tabNames:   ["OVERVIEW", "EQUITY", "DEBT", "REAL ESTATE", "COMMODITY", "CRYPTO"]
    readonly property var tabColors:  ["#ffffff",
        sipPlannerRoot.colorEquity, sipPlannerRoot.colorDebt,
        sipPlannerRoot.colorRealEstate, sipPlannerRoot.colorCommodity,
        sipPlannerRoot.colorCrypto]

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
                    text: analyticsPopup.popupTabIndex === 0
                          ? "SIP  ANALYTICS"
                          : analyticsPopup.tabNames[analyticsPopup.popupTabIndex] + "  BREAKDOWN"
                    color: "white"; font.pixelSize: 20; font.bold: true; font.letterSpacing: 2
                }
                Rectangle {
                    width: 36; height: 2; radius: 1
                    color: analyticsPopup.accent
                    Behavior on color { ColorAnimation { duration: 200 } }
                }
            }

            Item { Layout.fillWidth: true }

            ColumnLayout {
                spacing: 2; Layout.alignment: Qt.AlignRight
                Text {
                    text: analyticsPopup.popupTabIndex === 0 ? "TOTAL MONTHLY SIP" : "TYPE MONTHLY SIP"
                    color: "#444"; font.pixelSize: 9; font.letterSpacing: 1
                    Layout.alignment: Qt.AlignRight
                }
                Text {
                    text: {
                        if (analyticsPopup.popupTabIndex === 0)
                            return root.currencySymbol + " " + sipModel.getTotal("Total").toLocaleString(Qt.locale(), 'f', 0)
                        var t = analyticsPopup.tabNames[analyticsPopup.popupTabIndex]
                        return root.currencySymbol + " " + sipModel.getTotal(t.charAt(0) + t.slice(1).toLowerCase().replace(" estate", " Estate")).toLocaleString(Qt.locale(), 'f', 0)
                    }
                    color: analyticsPopup.accent; font.pixelSize: 20; font.bold: true
                    Layout.alignment: Qt.AlignRight
                    Behavior on color { ColorAnimation { duration: 200 } }
                }
            }

            Item { width: 12 }

            // Close button
            Rectangle {
                width: 32; height: 32; radius: 16
                color: closeHover.containsMouse ? "#222" : "transparent"
                Behavior on color { ColorAnimation { duration: 150 } }
                Text { anchors.centerIn: parent; text: "×"; color: "#666"; font.pixelSize: 22 }
                MouseArea { id: closeHover; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: analyticsPopup.close() }
            }
        }

        // ── TAB PILLS ─────────────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Repeater {
                model: analyticsPopup.tabNames
                delegate: Rectangle {
                    height: 26; radius: 13
                    width: tabPillText.implicitWidth + 20
                    color: "transparent"
                    border.width: 2
                    border.color: analyticsPopup.popupTabIndex === index
                                  ? analyticsPopup.tabColors[index]
                                  : (sipModel.getTotal(
                                         index === 0 ? "Total" :
                                         analyticsPopup.tabNames[index] === "REAL ESTATE" ? "Real Estate" :
                                         analyticsPopup.tabNames[index].charAt(0) + analyticsPopup.tabNames[index].slice(1).toLowerCase()
                                     ) > 0 ? "#444" : "#222")

                    Behavior on border.color { ColorAnimation { duration: 150 } }

                    Text {
                        id: tabPillText
                        anchors.centerIn: parent
                        text: modelData
                        font.bold: true; font.pixelSize: 10; font.letterSpacing: 0.5
                        color: analyticsPopup.popupTabIndex === index
                               ? "#ffffff"
                               : (sipModel.getTotal(
                                      index === 0 ? "Total" :
                                      analyticsPopup.tabNames[index] === "REAL ESTATE" ? "Real Estate" :
                                      analyticsPopup.tabNames[index].charAt(0) + analyticsPopup.tabNames[index].slice(1).toLowerCase()
                                  ) > 0 ? "#999" : "#333")
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }

                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: analyticsPopup.popupTabIndex = index
                    }
                }
            }

            Item { Layout.fillWidth: true }
        }

        // Thin separator
        Rectangle { Layout.fillWidth: true; height: 1; color: "#1e1e1e" }

        // ── CHARTS ────────────────────────────────────────────────────────────
        StackLayout {
            id: chartStack
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: analyticsPopup.popupTabIndex

            // ── Overview (index 0) ────────────────────────────────────────────
            RowLayout {
                spacing: 16
                Item { Layout.fillWidth: true }
                SipDonutChart {
                    id: overviewAssetChart
                    title: "ASSET MIX"
                    accentColor: "#00d2ff"
                    groupField: "__assetType"
                    assetType: "Total"
                    useAssetMixMode: true
                    Layout.fillWidth: true
                    Layout.minimumWidth: 220
                    Layout.maximumWidth: analyticsPopup.width * 0.36
                    Layout.fillHeight: true
                }
                SipDonutChart {
                    id: overviewLiquidityChart
                    title: "LIQUIDITY MIX"
                    accentColor: "#43e97b"
                    assetType: "Total"
                    useLiquidityMode: true
                    liquidColor: "#43e97b"
                    lockedColor: "#F44336"
                    Layout.fillWidth: true
                    Layout.minimumWidth: 220
                    Layout.maximumWidth: analyticsPopup.width * 0.36
                    Layout.fillHeight: true
                }
                Item { Layout.fillWidth: true }
            }

            // ── Equity (index 1) ──────────────────────────────────────────────
            RowLayout {
                spacing: 16
                SipDonutChart { id: equityCategoryChart;   title: "MARKET CAP"; assetType: "Equity"; groupField: "category"; accentColor: sipPlannerRoot.colorEquity; Layout.fillWidth: true; Layout.minimumWidth: 220; Layout.maximumWidth: analyticsPopup.width * 0.3; Layout.fillHeight: true }
                SipDonutChart { id: equityInstrumentChart; title: "INSTRUMENT"; assetType: "Equity"; groupField: "subType";  accentColor: sipPlannerRoot.colorEquity; Layout.fillWidth: true; Layout.minimumWidth: 220; Layout.maximumWidth: analyticsPopup.width * 0.3; Layout.fillHeight: true }
                SipDonutChart { id: equityGeographyChart;  title: "GEOGRAPHY";  assetType: "Equity"; groupField: "market";   accentColor: sipPlannerRoot.colorEquity; Layout.fillWidth: true; Layout.minimumWidth: 220; Layout.maximumWidth: analyticsPopup.width * 0.3; Layout.fillHeight: true }
            }

            // ── Debt (index 2) ────────────────────────────────────────────────
            RowLayout {
                spacing: 16
                Item { Layout.fillWidth: true }
                SipDonutChart { id: debtTypeChart; title: "ALLOCATION"; assetType: "Debt"; groupField: "subType"; accentColor: sipPlannerRoot.colorDebt; Layout.fillWidth: true; Layout.minimumWidth: 220; Layout.maximumWidth: analyticsPopup.width * 0.3; Layout.fillHeight: true }
                SipDonutChart {
                    id: debtLiquidityChart; title: "LIQUIDITY"; assetType: "Debt"; useLiquidityMode: true
                    liquidSubTypes: analyticsPopup.liquidDebt; liquidColor: "#43e97b"; lockedColor: "#F44336"; accentColor: sipPlannerRoot.colorDebt
                    Layout.fillWidth: true; Layout.minimumWidth: 220; Layout.maximumWidth: analyticsPopup.width * 0.3; Layout.fillHeight: true
                }
                Item { Layout.fillWidth: true }
            }

            // ── Real Estate (index 3) ─────────────────────────────────────────
            RowLayout {
                spacing: 16
                Item { Layout.fillWidth: true }
                SipDonutChart { id: reSplitChart; title: "TYPE"; assetType: "Real Estate"; groupField: "subType"; accentColor: sipPlannerRoot.colorRealEstate; Layout.fillWidth: true; Layout.minimumWidth: 220; Layout.maximumWidth: analyticsPopup.width * 0.3; Layout.fillHeight: true }
                SipDonutChart {
                    id: reLiquidityChart; title: "LIQUIDITY"; assetType: "Real Estate"; useLiquidityMode: true
                    liquidSubTypes: analyticsPopup.liquidRE; liquidColor: "#43e97b"; lockedColor: "#F44336"; accentColor: sipPlannerRoot.colorRealEstate
                    Layout.fillWidth: true; Layout.minimumWidth: 220; Layout.maximumWidth: analyticsPopup.width * 0.3; Layout.fillHeight: true
                }
                Item { Layout.fillWidth: true }
            }

            // ── Commodity (index 4) ───────────────────────────────────────────
            RowLayout {
                spacing: 16
                Item { Layout.fillWidth: true }
                SipDonutChart { id: commoditySplitChart; title: "TYPE"; assetType: "Commodity"; groupField: "subType"; accentColor: sipPlannerRoot.colorCommodity; Layout.fillWidth: true; Layout.minimumWidth: 220; Layout.maximumWidth: analyticsPopup.width * 0.3; Layout.fillHeight: true }
                SipDonutChart {
                    id: commodityLiquidityChart; title: "LIQUIDITY"; assetType: "Commodity"; useLiquidityMode: true
                    liquidSubTypes: analyticsPopup.liquidCommodity; liquidColor: "#43e97b"; lockedColor: "#F44336"; accentColor: sipPlannerRoot.colorCommodity
                    Layout.fillWidth: true; Layout.minimumWidth: 220; Layout.maximumWidth: analyticsPopup.width * 0.3; Layout.fillHeight: true
                }
                Item { Layout.fillWidth: true }
            }

            // ── Crypto (index 5) ──────────────────────────────────────────────
            RowLayout {
                spacing: 16
                Item { Layout.fillWidth: true }
                SipDonutChart {
                    id: cryptoSplitChart
                    title: "BY ASSET"
                    assetType: "Crypto"
                    groupField: "name"
                    accentColor: sipPlannerRoot.colorCrypto
                    Layout.fillWidth: true
                    Layout.minimumWidth: 220
                    Layout.maximumWidth: analyticsPopup.width * 0.3
                    Layout.fillHeight: true
                }
                Item { Layout.fillWidth: true }
            }
        }
    }

    // ── CUSTOM DONUT CHART COMPONENT ──────────────────────────────────────────
    // Pure Canvas donut. Supports three modes:
    //   1. Normal groupField mode — groups entries by a field and sums amounts
    //   2. useLiquidityMode — 2 slices: LIQUID / LOCKED, based on liquidSubTypes list
    //   3. useAssetMixMode  — 5 slices: one per asset type using the 5 accent colors
    component SipDonutChart : Item {
        id: donutRoot
        property color accentColor: "#00d2ff"
        property string title: ""
        property string assetType: ""
        property string groupField: ""

        // Liquidity mode
        property bool useLiquidityMode: false
        property bool useAssetMixMode:  false
        property bool allCryptoLiquid:  false
        property var  liquidSubTypes:   []
        property color liquidColor: "#43e97b"
        property color lockedColor: "#F44336"

        Layout.fillWidth: true
        Layout.fillHeight: true

        // Computed slice data — [{label, value, pct, color}]
        property var slices: []
        property real total: 0

        // Six-color colorPalette derived from the accent (renamed from 'palette' to avoid QML reserved name)
        readonly property var colorPalette: [
            accentColor,
            Qt.rgba(1, 1, 1, 0.75),
            Qt.lighter(accentColor, 1.5),
            Qt.darker(accentColor, 1.6),
            "#555555",
            Qt.lighter(accentColor, 2.0)
        ]

        readonly property var assetTypeColors: [
            sipPlannerRoot.colorEquity,
            sipPlannerRoot.colorDebt,
            sipPlannerRoot.colorRealEstate,
            sipPlannerRoot.colorCommodity,
            sipPlannerRoot.colorCrypto
        ]
        readonly property var assetTypeNames: ["Equity", "Debt", "Real Estate", "Commodity", "Crypto"]

        function refresh() {
            if (useLiquidityMode) {
                _refreshLiquidity()
            } else if (useAssetMixMode) {
                _refreshAssetMix()
            } else {
                _refreshGrouped()
            }
            donutCanvas.requestPaint()
        }

        function _refreshGrouped() {
            var entries = sipModel.getEntries(assetType)
            var totals = {}
            var sum = 0
            for (var i = 0; i < entries.length; i++) {
                var e = entries[i]
                var key = (e[groupField] && e[groupField].length > 0) ? e[groupField] : "Other"
                totals[key] = (totals[key] || 0) + e.amount
                sum += e.amount
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
            var types = assetType === "Total"
                ? ["Equity", "Debt", "Real Estate", "Commodity", "Crypto"]
                : [assetType]
            var liquidAmt = 0
            var lockedAmt = 0
            var liquidSubs = {
                "Equity":      ["Stock", "Mutual Fund", "ETF", "ESOPs"],
                "Debt":        ["FD/RD", "Bond", "Fund", "Cash & Savings"],
                "Real Estate": ["REITs"],
                "Commodity":   ["ETF/Fund", "Digital"],
                "Crypto":      ["__ALL__"]
            }
            for (var t = 0; t < types.length; t++) {
                var typeName = types[t]
                var entries = sipModel.getEntries(typeName)
                var subs = allCryptoLiquid && typeName === "Crypto"
                           ? ["__ALL__"]
                           : (liquidSubTypes.length > 0 ? liquidSubTypes : (liquidSubs[typeName] || []))
                for (var i = 0; i < entries.length; i++) {
                    var e = entries[i]
                    if (subs[0] === "__ALL__" || subs.indexOf(e.subType) >= 0) {
                        liquidAmt += e.amount
                    } else {
                        lockedAmt += e.amount
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
            var result = []
            var sum = 0
            for (var i = 0; i < assetTypeNames.length; i++) {
                var amt = sipModel.getTotal(assetTypeNames[i])
                sum += amt
            }
            total = sum
            if (sum <= 0) { slices = []; return }
            for (var j = 0; j < assetTypeNames.length; j++) {
                var a = sipModel.getTotal(assetTypeNames[j])
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

        // Hover state
        property int hoveredSlice: -1

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            // Chart title
            Text {
                text: donutRoot.title
                color: "#555"; font.pixelSize: 10; font.bold: true; font.letterSpacing: 1.5
                Layout.alignment: Qt.AlignHCenter
                Layout.bottomMargin: 8
            }

            // Canvas donut
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                Canvas {
                    id: donutCanvas
                    anchors.fill: parent

                    onPaint: {
                        var ctx = getContext("2d")
                        ctx.clearRect(0, 0, width, height)

                        if (donutRoot.total <= 0) return

                        var cx = width / 2
                        var cy = height / 2
                        var r  = Math.min(width, height) * 0.42
                        var innerR = r * 0.60
                        var gap = 0.018

                        var startAngle = -Math.PI / 2
                        for (var i = 0; i < donutRoot.slices.length; i++) {
                            var s = donutRoot.slices[i]
                            var sweep = (s.pct / 100) * 2 * Math.PI
                            var hovered = (donutRoot.hoveredSlice === i)
                            var outerR = hovered ? r * 1.06 : r

                            ctx.beginPath()
                            ctx.moveTo(cx + innerR * Math.cos(startAngle + gap / 2),
                                       cy + innerR * Math.sin(startAngle + gap / 2))
                            ctx.arc(cx, cy, outerR, startAngle + gap / 2, startAngle + sweep - gap / 2, false)
                            ctx.arc(cx, cy, innerR, startAngle + sweep - gap / 2, startAngle + gap / 2, true)
                            ctx.closePath()

                            var col = Qt.color(s.color)
                            if (hovered) {
                                ctx.fillStyle = Qt.rgba(
                                    Math.min(1, col.r * 1.25),
                                    Math.min(1, col.g * 1.25),
                                    Math.min(1, col.b * 1.25), 1)
                            } else {
                                ctx.fillStyle = s.color
                            }
                            ctx.fill()

                            startAngle += sweep
                        }

                        // Dark hole
                        ctx.beginPath()
                        ctx.arc(cx, cy, innerR - 1, 0, 2 * Math.PI, false)
                        ctx.fillStyle = "#0d0d0d"
                        ctx.fill()
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onPositionChanged: (mouse) => {
                            if (donutRoot.total <= 0) { donutRoot.hoveredSlice = -1; return }
                            var cx = donutCanvas.width / 2
                            var cy = donutCanvas.height / 2
                            var dx = mouse.x - cx
                            var dy = mouse.y - cy
                            var dist = Math.sqrt(dx * dx + dy * dy)
                            var r  = Math.min(donutCanvas.width, donutCanvas.height) * 0.42
                            var innerR = r * 0.60
                            if (dist < innerR || dist > r * 1.1) { donutRoot.hoveredSlice = -1; donutCanvas.requestPaint(); return }

                            var angle = Math.atan2(dy, dx) + Math.PI / 2
                            if (angle < 0) angle += 2 * Math.PI
                            var start = 0
                            var found = -1
                            for (var i = 0; i < donutRoot.slices.length; i++) {
                                var sweep = (donutRoot.slices[i].pct / 100) * 2 * Math.PI
                                if (angle >= start && angle < start + sweep) { found = i; break }
                                start += sweep
                            }
                            if (donutRoot.hoveredSlice !== found) {
                                donutRoot.hoveredSlice = found
                                donutCanvas.requestPaint()
                            }
                        }
                        onExited: { donutRoot.hoveredSlice = -1; donutCanvas.requestPaint() }
                    }
                }

                // Center label
                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 2
                    visible: donutRoot.total > 0

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: donutRoot.hoveredSlice >= 0
                              ? donutRoot.slices[donutRoot.hoveredSlice].label
                              : "TOTAL"
                        color: donutRoot.hoveredSlice >= 0
                               ? Qt.color(donutRoot.slices[donutRoot.hoveredSlice].color)
                               : "#444"
                        font.pixelSize: 9; font.bold: true; font.letterSpacing: 1
                        horizontalAlignment: Text.AlignHCenter
                    }
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: donutRoot.hoveredSlice >= 0
                              ? root.currencySymbol + " " + donutRoot.slices[donutRoot.hoveredSlice].value.toLocaleString(Qt.locale(), 'f', 0)
                              : root.currencySymbol + " " + donutRoot.total.toLocaleString(Qt.locale(), 'f', 0)
                        color: donutRoot.hoveredSlice >= 0
                               ? Qt.color(donutRoot.slices[donutRoot.hoveredSlice].color)
                               : "#aaa"
                        font.pixelSize: 13; font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                    }
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        visible: donutRoot.hoveredSlice >= 0
                        text: donutRoot.hoveredSlice >= 0
                              ? donutRoot.slices[donutRoot.hoveredSlice].pct + "%"
                              : ""
                        color: "#555"; font.pixelSize: 10
                        horizontalAlignment: Text.AlignHCenter
                    }
                }

                // Empty state
                ColumnLayout {
                    anchors.centerIn: parent
                    visible: donutRoot.total <= 0
                    spacing: 6
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "No data"
                        color: "#333"; font.pixelSize: 13; font.bold: true
                    }
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "Add " + (donutRoot.assetType === "Total" ? "SIPs" : donutRoot.assetType + " SIPs") + "\nto see this breakdown"
                        color: "#2a2a2a"; font.pixelSize: 10
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                    }
                }
            }

            // Legend rows — fixed height reservation so the canvas above is the
            // same size regardless of how many legend rows this chart has.
            Column {
                Layout.fillWidth: true
                Layout.preferredHeight: 5 * 20
                Layout.topMargin: 10
                Layout.leftMargin: 8
                spacing: 5
                visible: donutRoot.total > 0
                clip: true

                Repeater {
                    model: donutRoot.slices
                    RowLayout {
                        width: parent.width
                        spacing: 8

                        Rectangle {
                            width: 8; height: 8; radius: 2
                            color: modelData.color
                            Layout.alignment: Qt.AlignVCenter
                        }
                        Text {
                            text: modelData.label
                            color: donutRoot.hoveredSlice === index ? Qt.color(modelData.color) : "#888"
                            font.pixelSize: 10
                            Layout.fillWidth: true; elide: Text.ElideRight
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                        Text {
                            text: modelData.pct + "%"
                            color: donutRoot.hoveredSlice === index ? Qt.color(modelData.color) : "#555"
                            font.pixelSize: 10; font.bold: true
                            Layout.rightMargin: 8
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                    }
                }
            }
        }
    }
}
