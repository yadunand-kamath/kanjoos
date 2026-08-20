import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "../../components"

Rectangle {
    id: retirementRoot
    color: "#121212"

    readonly property bool isReady: (typeof retirementCalc !== "undefined" && retirementCalc !== null)

    // ── DIRECT BINDINGS — no caching, no Connections indirection ───────────────
    // (Context properties never emit change notifications through a
    // Connections{target:} indirection — binding to them directly works fine.)
    readonly property real corpusNeeded:     isReady ? retirementCalc.corpusNeeded : 0
    readonly property real futureMonthlyExp: isReady ? retirementCalc.futureMonthlyExpense : 0
    readonly property real accumulated:      isReady ? retirementAssetModel.totalValueProp : 0
    readonly property real liquidVal:        isReady ? retirementAssetModel.liquidValue : 0
    readonly property real lockedVal:        isReady ? retirementAssetModel.lockedValue : 0
    readonly property int  assetCount:       isReady ? retirementAssetModel.assetCount : 0
    readonly property real shortfall:        isReady ? retirementCalc.shortfall : 0
    readonly property real rawRatio:         isReady ? retirementCalc.fundedRatio : 0
    readonly property real progress:         Math.min(rawRatio, 1.0)

    // Matches EmergencyFund's ramp so the three SafetyNet sub-pages read as one system.
    readonly property color progressColor: {
        var p = rawRatio * 100
        if (p <= 0)   return "#5a0a0a"
        if (p < 25)   return "#c0392b"
        if (p < 50)   return "#e67e22"
        if (p < 75)   return "#f1c40f"
        if (p < 100)  return "#43e97b"
        return "#a29bfe"
    }

    function fmtCr(v) { return v > 0 ? root.currencySymbol + " " + (v/10000000).toFixed(2) + " Cr" : "—" }
    function fmtL(v)  { return v > 0 ? root.currencySymbol + " " + (v/100000).toFixed(2)  + " L"  : "—" }

    // ── Base monthly expenses — defaults from CashFlow, overridable ────────────
    property bool expenseOverridden: false

    Component.onCompleted: {
        if (isReady && !expenseOverridden) retirementCalc.monthlyExpense = root.globalMonthlyExpense
        syncPortfolio()
    }
    Connections {
        target: root
        function onGlobalMonthlyExpenseChanged() {
            if (isReady && !retirementRoot.expenseOverridden) retirementCalc.monthlyExpense = root.globalMonthlyExpense
        }
    }

    // Sync portfolio → retirement asset model whenever portfolio changes
    function syncPortfolio() {
        var items = portfolioModel.getAssetsForGoal("Retirement")
        retirementAssetModel.syncPortfolioAssets(items)
    }

    Connections {
        target: portfolioModel
        function onPortfolioUpdated() { retirementRoot.syncPortfolio() }
    }

    // ── Table column widths — shared by header and every row, no per-row drift ─
    readonly property int colAccent: 6
    readonly property int colType:   80
    readonly property int colValue:  130
    readonly property int colAction: 28

    // ── Advanced assumptions disclosure ─────────────────────────────────────────
    property bool advancedOpen: false

    property string lastUpdated: ""

    ScrollView {
        id: retireScroll
        anchors.fill: parent
        contentWidth: availableWidth
        clip: true

        ColumnLayout {
            id: pageColumn
            width: Math.min(retireScroll.availableWidth * 0.9, 900)
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 16

            Item { Layout.preferredHeight: 2 }

            // ── 1. HERO — ON-TRACK % ──────────────────────────────────────────
            SectionCard {
                accentColor: retirementRoot.progressColor
                Layout.fillWidth: true

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 14

                    Text {
                        text: retirementRoot.assetCount === 0
                              ? "No retirement assets yet"
                              : Math.round(retirementRoot.rawRatio * 100) + "%"
                        color: retirementRoot.progressColor
                        font.pixelSize: retirementRoot.assetCount === 0 ? 22 : 48
                        font.bold: true
                        Layout.alignment: Qt.AlignHCenter
                        Behavior on color { ColorAnimation { duration: 400 } }
                    }
                    Text {
                        text: "OF TARGET CORPUS FUNDED"
                        color: "#888"; font.pixelSize: 11; font.letterSpacing: 2
                        Layout.alignment: Qt.AlignHCenter
                    }

                    ProgressBar {
                        id: heroBar
                        value: retirementRoot.progress
                        Layout.fillWidth: true
                        Layout.preferredHeight: 8
                        Layout.topMargin: 6

                        background: Rectangle { color: "#222"; radius: 4 }
                        contentItem: Item {
                            Rectangle {
                                width: heroBar.visualPosition * parent.width
                                height: 8; radius: 4
                                color: retirementRoot.progressColor
                                Behavior on width { NumberAnimation { duration: 1000; easing.type: Easing.OutExpo } }
                                Behavior on color { ColorAnimation { duration: 400 } }
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.topMargin: 10
                        spacing: 24

                        HeroMetric { label: "CORPUS NEEDED";  value: retirementRoot.fmtCr(retirementRoot.corpusNeeded); accent: "#ffffff" }
                        HeroMetric { label: "ACCUMULATED";    value: retirementRoot.fmtCr(retirementRoot.accumulated);  accent: retirementRoot.progressColor }
                        HeroMetric {
                            label: "SHORTFALL"
                            value: retirementRoot.shortfall > 0 ? retirementRoot.fmtCr(retirementRoot.shortfall) : "None"
                            accent: retirementRoot.shortfall > 0 ? "#c0392b" : "#43e97b"
                        }
                        HeroMetric { label: "MONTHLY EXP AT RETIREMENT"; value: retirementRoot.fmtL(retirementRoot.futureMonthlyExp); accent: "#ffffff" }
                    }
                }
            }

            // ── 2. ASSUMPTIONS CARD ────────────────────────────────────────────
            SectionCard {
                accentColor: "darkblue"
                Layout.fillWidth: true
                enabled: retirementRoot.isReady

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 16

                    Text { text: "ASSUMPTIONS"; color: "blue"; font.bold: true; font.pixelSize: 13; font.letterSpacing: 1.2 }

                    // Primary — Current Age, Retire Age
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 40

                        AssumptionSlider {
                            Layout.fillWidth: true
                            label: "CURRENT AGE"
                            from: 18; to: 60
                            value: retirementRoot.isReady ? retirementCalc.currentAge : 30
                            onMoved: (v) => retirementCalc.currentAge = v
                        }
                        AssumptionSlider {
                            Layout.fillWidth: true
                            label: "RETIRE AGE"
                            from: 30; to: 75
                            value: retirementRoot.isReady ? retirementCalc.retireAge : 60
                            onMoved: (v) => retirementCalc.retireAge = v
                        }
                    }

                    // Primary — Base Monthly Expenses
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Text {
                            text: retirementRoot.expenseOverridden
                                  ? "BASE MONTHLY EXPENSES"
                                  : "BASE MONTHLY EXPENSES (FROM CASHFLOW)"
                            color: "#757575"; font.pixelSize: 10; font.letterSpacing: 1.2
                        }
                        Rectangle {
                            Layout.fillWidth: true; Layout.preferredHeight: 48
                            color: "#1A1A1A"; radius: 10; border.color: "#2A2A2A"
                            RowLayout {
                                anchors.fill: parent
                                Button {
                                    text: "−"; flat: true; palette.buttonText: "white"
                                    onClicked: if (retirementRoot.isReady) {
                                        retirementRoot.expenseOverridden = true
                                        retirementCalc.monthlyExpense = Math.max(0, retirementCalc.monthlyExpense - 1000)
                                    }
                                }
                                Text {
                                    text: retirementRoot.isReady ? retirementCalc.monthlyExpense.toLocaleString(Qt.locale(), 'f', 0) : "0"
                                    color: "white"; font.pixelSize: 18; font.weight: Font.Bold
                                    Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter
                                }
                                Button {
                                    text: "+"; flat: true; palette.buttonText: "white"
                                    onClicked: if (retirementRoot.isReady) {
                                        retirementRoot.expenseOverridden = true
                                        retirementCalc.monthlyExpense += 1000
                                    }
                                }
                            }
                        }
                    }

                    // Advanced disclosure toggle
                    Rectangle {
                        Layout.fillWidth: true; Layout.topMargin: 4
                        height: 1; color: "#1e1e1e"
                    }
                    Rectangle {
                        Layout.fillWidth: true
                        height: 30
                        color: advToggleMA.containsMouse ? "#1a1a1a" : "transparent"
                        radius: 4
                        Behavior on color { ColorAnimation { duration: 120 } }

                        RowLayout {
                            anchors.fill: parent; anchors.leftMargin: 4
                            spacing: 6
                            Text {
                                text: (retirementRoot.advancedOpen ? "▾" : "▸") + "  ADVANCED ASSUMPTIONS"
                                color: "#888"; font.pixelSize: 10; font.letterSpacing: 1; font.bold: true
                            }
                        }
                        MouseArea {
                            id: advToggleMA; anchors.fill: parent; hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: retirementRoot.advancedOpen = !retirementRoot.advancedOpen
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 14
                        visible: retirementRoot.advancedOpen

                        AssumptionSlider {
                            Layout.fillWidth: true
                            label: "LIFE EXPECTANCY"
                            from: 60; to: 100
                            value: retirementRoot.isReady ? retirementCalc.lifeExpectancy : 85
                            onMoved: (v) => retirementCalc.lifeExpectancy = v
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 40
                            AssumptionSlider {
                                Layout.fillWidth: true
                                label: "INFLATION (%)"
                                from: 0; to: 15
                                value: retirementRoot.isReady ? retirementCalc.inflation : 7
                                suffix: "%"
                                onMoved: (v) => retirementCalc.inflation = v
                            }
                            AssumptionSlider {
                                Layout.fillWidth: true
                                label: "POST-RETIRE RETURN (%)"
                                from: 0; to: 15
                                value: retirementRoot.isReady ? retirementCalc.postReturn : 8
                                suffix: "%"
                                onMoved: (v) => retirementCalc.postReturn = v
                            }
                        }

                        AssumptionSlider {
                            Layout.fillWidth: true
                            label: "GOVT. FUND UNLOCK AGE"
                            from: retirementRoot.isReady ? retirementCalc.retireAge : 60
                            to: 75
                            value: retirementRoot.isReady ? retirementCalc.lockedFundOpenAge : 60
                            onMoved: (v) => retirementCalc.lockedFundOpenAge = v
                        }

                        RowLayout {
                            Layout.fillWidth: true; spacing: 12
                            Text {
                                text: "LIFESTYLE"; color: "#757575"; font.pixelSize: 10; font.letterSpacing: 1.2
                                Layout.preferredWidth: 150
                            }
                            CustomComboBox {
                                id: lifestyleCombo
                                Layout.fillWidth: true; Layout.preferredHeight: 34
                                model: ["Kanjoos (Conservative)", "Standard", "Lavish (Luxurious)"]
                                currentIndex: {
                                    if (!retirementRoot.isReady) return 1
                                    var m = retirementCalc.lifestyleMultiplier
                                    return m <= 0.8 ? 0 : (m >= 1.5 ? 2 : 1)
                                }
                                onActivated: (idx) => {
                                    if (retirementRoot.isReady) retirementCalc.lifestyleMultiplier = [0.8, 1.0, 1.5][idx]
                                }
                                background: Rectangle { color: "#1A1A1A"; radius: 8; border.color: "#2A2A2A" }
                                contentItem: Text {
                                    text: lifestyleCombo.displayText
                                    font: lifestyleCombo.font
                                    color: lifestyleCombo.hovered || lifestyleCombo.opened ? "white" : "#888888"
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                    elide: Text.ElideRight
                                }
                            }
                        }
                    }
                }
            }

            // ── 3. COMPACT LIQUIDITY STRIP ─────────────────────────────────────
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6

                Text {
                    text: "LIQUIDITY SPLIT OF ASSETS YOU OWN"
                    color: "#aaaaaa"
                    font.pixelSize: 12; font.bold: true; font.letterSpacing: 1.2
                    Layout.alignment: Qt.AlignHCenter
                }

                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 32

                    readonly property real total:      retirementRoot.accumulated
                    readonly property bool hasAny:      total > 0
                    readonly property real liquidFrac:  hasAny ? retirementRoot.liquidVal / total : 0

                    // Empty state — single neutral outline
                    Rectangle {
                        anchors.fill: parent
                        visible: !parent.hasAny
                        color: "transparent"; radius: 4
                        border.color: "#2a2a2a"; border.width: 1
                    }

                    Item {
                        anchors.fill: parent
                        visible: parent.hasAny

                        Rectangle {
                            id: liquidSeg
                            anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                            width: parent.width * parent.parent.liquidFrac
                            color: "#43e97b"; radius: 4
                            visible: width > 1
                            Behavior on width { NumberAnimation { duration: 500; easing.type: Easing.OutExpo } }
                        }
                        Rectangle {
                            anchors { left: liquidSeg.right; right: parent.right; top: parent.top; bottom: parent.bottom }
                            color: "#F44336"; radius: 4
                            visible: width > 1
                        }
                    }
                }

                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 8
                    visible: retirementRoot.accumulated > 0

                    Text {
                        text: "LIQUID " + retirementRoot.fmtCr(retirementRoot.liquidVal) + " (" + Math.round((retirementRoot.liquidVal / retirementRoot.accumulated) * 100) + "%)"
                        color: "#43e97b"; font.pixelSize: 13; font.weight: Font.Bold
                    }
                    Text { text: "·"; color: "#555"; font.pixelSize: 13 }
                    Text {
                        text: "LOCKED " + retirementRoot.fmtCr(retirementRoot.lockedVal) + " (" + Math.round((retirementRoot.lockedVal / retirementRoot.accumulated) * 100) + "%)"
                        color: "#F44336"; font.pixelSize: 13; font.weight: Font.Bold
                    }
                }
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    visible: retirementRoot.accumulated <= 0
                    text: "ADD ASSETS TO SEE YOUR LIQUID / LOCKED SPLIT"
                    color: "#555"; font.pixelSize: 10
                }
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Split of assets you own today, not of your target corpus"
                    color: "#999"; font.pixelSize: 12; font.italic: true
                }
            }

            // ── 4. VERDICT BAR ──────────────────────────────────────────────────
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8

                Rectangle {
                    id: verdictBar
                    Layout.fillWidth: true
                    Layout.preferredHeight: verdictLabel.implicitHeight + 32
                    color: "#0d0d0d"; radius: 8
                    border.width: 1

                    readonly property color verdictColor: {
                        if (!retirementRoot.isReady) return "#333"
                        switch (retirementCalc.verdictLevel) {
                        case 0:  return "#666"
                        case 1:  return "#c0392b"
                        case 2:  return "#FF9100"
                        default: return "#43e97b"
                        }
                    }
                    border.color: verdictColor

                    Text {
                        id: verdictLabel
                        anchors.fill: parent; anchors.margins: 16
                        text: retirementRoot.isReady ? retirementCalc.verdictText : "Calculating…"
                        color: verdictBar.verdictColor
                        font.pixelSize: 13; font.weight: Font.Medium
                        wrapMode: Text.WordWrap
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 8
                    visible: retirementRoot.isReady && retirementCalc.verdictLevel > 0

                    PremiumPill { label: "LIQUID RUNWAY"; valueText: retirementRoot.isReady ? retirementCalc.liquidRunwayYears + " yrs" : "—"; accent: "#43e97b" }
                    PremiumPill { label: "LOCKED OPENS"; valueText: retirementRoot.isReady ? "Age " + retirementCalc.lockedFundOpenAge : "—"; accent: "#F44336" }
                    PremiumPill {
                        label: "GAP YEARS"
                        valueText: retirementRoot.isReady ? Math.max(0, retirementCalc.lockedFundOpenAge - retirementCalc.retireAge) + " yrs" : "—"
                        accent: "#FF9100"
                    }
                }
            }

            // ── 5. RETIREMENT ASSETS TABLE ─────────────────────────────────────
            ColumnLayout {
                id: assetsColumn
                Layout.fillWidth: true
                spacing: 8

                readonly property int tableWidth: width
                readonly property int nameW: Math.max(140, tableWidth - retirementRoot.colAccent - retirementRoot.colType - retirementRoot.colValue - retirementRoot.colAction - 4*12)

                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 40

                    Text {
                        anchors.centerIn: parent
                        text: "RETIREMENT ASSETS"
                        color: "#cccccc"; font.pixelSize: 13; font.bold: true; font.letterSpacing: 1.2
                    }
                    Text {
                        anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
                        text: "Portfolio-linked rows auto-synced"
                        color: "#999"; font.pixelSize: 12; font.italic: true
                    }
                    Rectangle {
                        anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                        width: 76; height: 26; radius: 4
                        color: addAssetMA.containsMouse ? "#222" : "transparent"
                        border.color: "white"; border.width: 1
                        Behavior on color { ColorAnimation { duration: 120 } }
                        Text { anchors.centerIn: parent; text: "+ ADD"; color: "white"; font.pixelSize: 10; font.bold: true }
                        MouseArea {
                            id: addAssetMA; anchors.fill: parent; hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: retirementAssetModel.addAsset()
                        }
                    }
                }

                // Column headers — same Row/widths as the body
                Row {
                    Layout.fillWidth: true
                    Layout.leftMargin: 4
                    spacing: 12

                    Item { width: retirementRoot.colAccent; height: 22 }
                    Item {
                        width: assetsColumn.nameW; height: 22
                        Text { anchors.verticalCenter: parent.verticalCenter; text: "ASSET"; color: "#aaaaaa"; font.pixelSize: 12; font.weight: Font.DemiBold }
                    }
                    Item {
                        width: retirementRoot.colType; height: 22
                        Text { anchors.verticalCenter: parent.verticalCenter; text: "TYPE"; color: "#aaaaaa"; font.pixelSize: 12; font.weight: Font.DemiBold }
                    }
                    Item {
                        width: retirementRoot.colValue; height: 22
                        Text { anchors.fill: parent; verticalAlignment: Text.AlignVCenter; horizontalAlignment: Text.AlignRight; text: "VALUE"; color: "#aaaaaa"; font.pixelSize: 12; font.weight: Font.DemiBold }
                    }
                    Item { width: retirementRoot.colAction; height: 22 }
                }

                Repeater {
                    id: assetRepeater
                    model: retirementAssetModel

                    delegate: Item {
                        width: assetsColumn.width
                        height: 46

                        readonly property color rowAccent: model.fromPortfolio ? AssetRegistry.colorFor(model.assetType) : "#555555"

                        Rectangle {
                            anchors.fill: parent; radius: 4
                            color: rowHover.containsMouse ? "#1a1a1a" : "transparent"
                        }
                        MouseArea { id: rowHover; anchors.fill: parent; hoverEnabled: true }

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: 4
                            spacing: 12

                            // Accent gutter — always same width; only the bar toggles visible
                            Item {
                                width: retirementRoot.colAccent; height: parent.height
                                Rectangle {
                                    visible: model.fromPortfolio
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 3; height: 28; radius: 2
                                    color: rowAccent
                                }
                            }

                            // Name + type caption
                            Item {
                                width: assetsColumn.nameW; height: parent.height

                                UnderlineCell {
                                    id: nameCell
                                    anchors.left: parent.left; anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.verticalCenterOffset: model.fromPortfolio ? -9 : 0
                                    text: model.name
                                    editable: !model.fromPortfolio
                                    focusColor: rowAccent
                                    onEdited: (t) => retirementAssetModel.setName(index, t)
                                }
                                Text {
                                    visible: model.fromPortfolio
                                    anchors.top: nameCell.bottom; anchors.topMargin: 2
                                    anchors.left: parent.left
                                    text: model.assetType
                                    color: rowAccent; font.pixelSize: 9
                                }
                            }

                            // Liquid/Locked toggle pill
                            Item {
                                width: retirementRoot.colType; height: parent.height
                                Rectangle {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 68; height: 22; radius: 4
                                    color: model.type === "LIQUID" ? "#0a2e14" : "#2e0a0a"
                                    border.color: model.type === "LIQUID" ? "#43e97b" : "#F44336"
                                    border.width: 1
                                    opacity: model.fromPortfolio ? 0.55 : 1.0
                                    Text {
                                        anchors.centerIn: parent
                                        text: model.type
                                        color: model.type === "LIQUID" ? "#43e97b" : "#F44336"
                                        font.pixelSize: 9; font.bold: true
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        enabled: !model.fromPortfolio
                                        cursorShape: model.fromPortfolio ? Qt.ArrowCursor : Qt.PointingHandCursor
                                        onClicked: retirementAssetModel.setLiquid(index, model.type !== "LIQUID")
                                    }
                                }
                            }

                            // Value
                            Item {
                                width: retirementRoot.colValue; height: parent.height

                                UnderlineCell {
                                    anchors.left: parent.left; anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: (Number(model.value) || 0).toFixed(0)
                                    editable: !model.fromPortfolio
                                    focusColor: rowAccent
                                    rightAligned: true
                                    validator: DoubleValidator { bottom: 0 }
                                    onEdited: (t) => retirementAssetModel.setValue(index, parseFloat(t) || 0)
                                }
                            }

                            // Remove button — always same width; only the button toggles visible
                            Item {
                                width: retirementRoot.colAction; height: parent.height
                                Rectangle {
                                    visible: !model.fromPortfolio
                                    anchors.centerIn: parent
                                    width: 22; height: 22; radius: 11
                                    color: removeMA.containsMouse ? "#2e0a0a" : "transparent"
                                    border.color: removeMA.containsMouse ? "#F44336" : "transparent"
                                    Behavior on color { ColorAnimation { duration: 120 } }
                                    Text { anchors.centerIn: parent; text: "×"; color: "#555"; font.pixelSize: 14 }
                                    MouseArea {
                                        id: removeMA; anchors.fill: parent; hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: retirementAssetModel.removeAsset(index)
                                    }
                                }
                            }
                        }

                        Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: "#1E1E1E" }
                    }
                }
            }

            // ── FOOTER DIVIDER ───────────────────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                Layout.topMargin: 8
                height: 1; color: "#555"
            }

            // ── BUTTONS + LAST UPDATED ──────────────────────────────────────────
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                Layout.topMargin: 8

                Text {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: retirementRoot.lastUpdated !== "" ? "Last saved: " + retirementRoot.lastUpdated : ""
                    color: "#444"; font.pixelSize: 10; font.italic: true
                }

                Row {
                    anchors.centerIn: parent
                    spacing: 12

                    SaveButton {
                        onClicked: retirementRoot.lastUpdated = Qt.formatDateTime(new Date(), "dd MMM yyyy, hh:mm")
                    }

                    ClearButton {
                        text: "Clear All"
                        onClicked: {
                            if (retirementRoot.isReady) retirementAssetModel.clearAll()
                            retirementRoot.lastUpdated = Qt.formatDateTime(new Date(), "dd MMM yyyy, hh:mm")
                        }
                    }
                }
            }

            Item { height: 20 }
        }
    }

    // ── INLINE COMPONENTS ─────────────────────────────────────────────────────

    component SectionCard : Rectangle {
        property color accentColor: "white"
        default property alias content: cardContent.data

        color: "#121212"; radius: 10; border.color: "#2A2A2A"
        implicitHeight: cardContent.implicitHeight + 40

        Rectangle {
            width: 3; height: parent.height; radius: 2
            color: accentColor; opacity: 0.6
            anchors { left: parent.left; top: parent.top }
        }

        ColumnLayout {
            id: cardContent
            anchors { top: parent.top; left: parent.left; right: parent.right; margins: 20; leftMargin: 24 }
            spacing: 0
        }
    }

    component SectionDivider : Item {
        Layout.fillWidth: true
        height: 1
        Rectangle { anchors.fill: parent; color: "#1a1a1a" }
    }

    component HeroMetric : ColumnLayout {
        property string label: ""
        property string value: ""
        property color accent: "white"
        Layout.fillWidth: true
        spacing: 4

        Text {
            text: parent.label
            color: "#757575"; font.pixelSize: 10; font.letterSpacing: 1.3
            Layout.alignment: Qt.AlignHCenter
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }
        Text {
            text: parent.value
            color: parent.accent; font.pixelSize: 20; font.weight: Font.Bold
            Layout.alignment: Qt.AlignHCenter
        }
    }

    component AssumptionSlider : RowLayout {
        property string label: ""
        property real from: 0
        property real to: 100
        property real value: 0
        property string suffix: ""
        signal moved(real val)

        spacing: 12

        Text {
            text: label; color: "#757575"; font.pixelSize: 10; font.letterSpacing: 1.2
            Layout.preferredWidth: 150
        }
        CustomSlider {
            Layout.fillWidth: true
            from: parent.from; to: parent.to; value: parent.value
            onMoved: (v) => parent.moved(v)
        }
        Rectangle {
            width: 56; height: 34; radius: 8
            color: "#1A1A1A"; border.color: "#2A2A2A"
            Text {
                anchors.centerIn: parent
                text: parent.parent.value + parent.parent.suffix
                color: "white"; font.pixelSize: 13; font.weight: Font.DemiBold
            }
        }
    }

    component PremiumPill : Rectangle {
        property string label: ""
        property string valueText: ""
        property color accent: "white"

        implicitWidth: pillCol.implicitWidth + 24; implicitHeight: 40; radius: 6
        color: "#0d0d0d"; border.color: "#1e1e1e"

        Column {
            id: pillCol
            anchors.centerIn: parent; spacing: 2
            Text { text: label; color: "#555"; font.pixelSize: 8; font.letterSpacing: 1; anchors.horizontalCenter: parent.horizontalCenter }
            Text { text: valueText; color: accent; font.pixelSize: 12; font.bold: true; anchors.horizontalCenter: parent.horizontalCenter }
        }
    }

    // Editable underline cell, modelled on InsuranceUnderlineInput.
    component UnderlineCell : Item {
        property alias text: field.text
        property bool editable: true
        property color focusColor: "#a29bfe"
        property bool rightAligned: false
        property alias validator: field.validator
        signal edited(string value)

        implicitHeight: field.implicitHeight + 2

        TextField {
            id: field
            anchors.left: parent.left; anchors.right: parent.right
            color: "white"; font.pixelSize: 13
            leftPadding: rightAligned ? 0 : 4
            horizontalAlignment: rightAligned ? Text.AlignRight : Text.AlignLeft
            selectByMouse: true
            readOnly: !editable
            background: Rectangle { color: "transparent" }
            onEditingFinished: if (editable) edited(text)
        }
        Rectangle {
            visible: editable
            anchors.bottom: parent.bottom
            width: parent.width; height: 1
            color: field.activeFocus ? focusColor : (cellHover.containsMouse ? "#444" : "#2A2A2A")
            Behavior on color { ColorAnimation { duration: 150 } }
            MouseArea { id: cellHover; anchors.fill: parent; hoverEnabled: true; acceptedButtons: Qt.NoButton }
        }
    }
}
