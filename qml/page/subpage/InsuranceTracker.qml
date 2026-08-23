import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "../../components"

Item {
    id: insurancePage
    Layout.fillWidth: true
    Layout.fillHeight: true

    readonly property bool isReady: (typeof insuranceCalc !== "undefined" && insuranceCalc !== null)

    // ── Sticky expense override — auto-pull from CashFlow until user edits ────
    property bool expenseOverridden: false

    Component.onCompleted: {
        if (isReady && !expenseOverridden) insuranceCalc.setAnnualExpenses(root.globalMonthlyExpense * 12)
        syncLiquid()
        if (isReady) insuranceCalc.setHealthCover(policyModel.healthSumInsured)
    }
    Connections {
        target: root
        function onGlobalMonthlyExpenseChanged() {
            if (insurancePage.isReady && !insurancePage.expenseOverridden)
                insuranceCalc.setAnnualExpenses(root.globalMonthlyExpense * 12)
        }
    }

    // ── Liquid assets auto-fill from Portfolio ─────────────────────────────────
    property var liquidSubTypes: ["Stock","Mutual Fund","ETF","FD/RD","Bond","Fund",
                                  "Cash & Savings","REITs","Digital","ETF/Fund","Crypto"]
    function syncLiquid() {
        if (isReady) insuranceCalc.setCurrentLiquidAssets(portfolioModel.getLiquidValue(liquidSubTypes))
    }
    Connections {
        target: portfolioModel
        function onPortfolioUpdated() { insurancePage.syncLiquid() }
    }

    // ── Feed health cover from PolicyModel into the calculator ─────────────────
    Connections {
        target: policyModel
        function onPoliciesUpdated() {
            if (insurancePage.isReady) insuranceCalc.setHealthCover(policyModel.healthSumInsured)
        }
    }

    // ── Keep premium synced to CashFlow (must not regress) ─────────────────────
    Binding { target: root; property: "insuranceTotalFromSafety"; value: policyModel.totalMonthlyPremium }

    function fmtCr(v) { return v > 0 ? root.currencySymbol + " " + (v/10000000).toFixed(2) + " Cr" : "—" }
    function fmtL(v)  { return v > 0 ? root.currencySymbol + " " + (v/100000).toFixed(2)  + " L"  : "—" }

    function progressColor(rawRatio) {
        var p = rawRatio * 100
        if (p <= 0)   return "#5a0a0a"
        if (p < 25)   return "#c0392b"
        if (p < 50)   return "#e67e22"
        if (p < 75)   return "#f1c40f"
        if (p < 100)  return "#43e97b"
        return "#a29bfe"
    }

    property string lastUpdated: ""

    InsuranceDiagnosticPopup {
        id: diagnosticPopup
        expenseOverridden: insurancePage.expenseOverridden
        onExpenseEdited: insurancePage.expenseOverridden = true
    }
    PolicyVaultPopup { id: vaultPopup }

    ColumnLayout {
        anchors.fill: parent
        anchors.topMargin: -20
        spacing: 12

        // ── LIFE CARD ─────────────────────────────────────────────────────────
        InsuranceCard {
            Layout.fillWidth: true
            Layout.preferredHeight: 126
            category: "Life"
            accentColor: "#FFC400"
            cover: policyModel.lifeSumInsured
            needed: insurancePage.isReady ? insuranceCalc.recommendedLifeCover : 0
            verdictLevel: insurancePage.isReady ? insuranceCalc.lifeVerdictLevel : 0
            adviceText: "Rule of thumb: Buy a pure term plan until age 60."
            policyCount: policyModel.countFor("Life")
            showBar: true
            onCalculateNeed: diagnosticPopup.openFor("Life")
            onOpenVault: vaultPopup.openFor("Life")
        }

        // ── HEALTH CARD ───────────────────────────────────────────────────────
        InsuranceCard {
            Layout.fillWidth: true
            Layout.preferredHeight: 126
            category: "Health"
            accentColor: "#00E5FF"
            cover: policyModel.healthSumInsured
            needed: insurancePage.isReady ? insuranceCalc.recommendedHealthCover : 0
            verdictLevel: insurancePage.isReady ? insuranceCalc.healthVerdictLevel : 0
            adviceText: "Rule of thumb: Cover " + (insurancePage.isReady ? insuranceCalc.healthMultiplier.toFixed(1) : "12.5") + "× your annual expenses."
            policyCount: policyModel.countFor("Health")
            showBar: true
            onCalculateNeed: diagnosticPopup.openFor("Health")
            onOpenVault: vaultPopup.openFor("Health")
        }

        // ── ASSET CARD (no progress bar, per-asset deficit) ──────────────────
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 126
            color: "#121212"; radius: 10; border.color: "#2A2A2A"

            Rectangle {
                width: 3; height: parent.height; radius: 2
                color: "#FF9100"; opacity: 0.6
                anchors { left: parent.left; top: parent.top }
            }

            RowLayout {
                anchors.fill: parent
                anchors.margins: 18
                anchors.leftMargin: 22
                spacing: 20

                ColumnLayout {
                    Layout.preferredWidth: 260
                    spacing: 4
                    Text { text: "ASSET INSURANCE"; color: "#FF9100"; font.pixelSize: 11; font.bold: true; font.letterSpacing: 1.2 }
                    Text {
                        text: insurancePage.fmtCr(policyModel.assetSumInsured)
                        color: "white"; font.pixelSize: 26; font.bold: true
                    }
                    Text {
                        text: policyModel.countFor("Asset") + (policyModel.countFor("Asset") === 1 ? " policy" : " policies")
                        color: "#888"; font.pixelSize: 11
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4
                    Text {
                        visible: policyModel.assetDeficit() > 0
                        text: "Deficit: " + insurancePage.fmtCr(policyModel.assetDeficit())
                        color: "#F44336"; font.pixelSize: 14; font.bold: true
                    }
                    Text {
                        visible: policyModel.assetDeficit() <= 0 && policyModel.countFor("Asset") > 0
                        text: "Fully Covered ✓"
                        color: "#43e97b"; font.pixelSize: 14; font.bold: true
                    }
                    Text {
                        visible: policyModel.countFor("Asset") === 0
                        text: "No assets insured yet. Add optional Asset Value in the Vault to track deficits."
                        color: "#666"; font.pixelSize: 11; font.italic: true
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }
                }

                ColumnLayout {
                    spacing: 8
                    PolicyVaultButton {
                        text: "📄 Policy Vault"
                        accent: "#FF9100"
                        filled: policyModel.countFor("Asset") > 0
                        onClicked: vaultPopup.openFor("Asset")
                    }
                }
            }
        }

        // ── FOOTER ────────────────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 4
            spacing: 16

            InsuranceCheckBox {
                label: "Sync to CashFlow"
                accent: "#00E5FF"
                checked: root.syncInsuranceToCashflow
                onToggled: (v) => root.syncInsuranceToCashflow = v
            }

            Item { Layout.fillWidth: true }

            PremiumPill { label: "TOTAL SUM INSURED"; valueText: insurancePage.fmtCr(policyModel.totalSumInsured); accent: "#a29bfe" }
            PremiumPill { label: "TOTAL MONTHLY PREMIUM"; valueText: root.currencySymbol + " " + policyModel.totalMonthlyPremium.toLocaleString(Qt.locale(), 'f', 0); accent: "#00E5FF" }

            Text {
                text: insurancePage.lastUpdated !== "" ? "Saved: " + insurancePage.lastUpdated : ""
                color: "#444"; font.pixelSize: 9; font.italic: true
            }

            SaveButton {
                onClicked: insurancePage.lastUpdated = Qt.formatDateTime(new Date(), "dd MMM yyyy, hh:mm")
            }
        }
    }

    // ── INLINE COMPONENTS ─────────────────────────────────────────────────────

    component InsuranceCard : Rectangle {
        id: card
        property string category: ""
        property color accentColor: "white"
        property real cover: 0
        property real needed: 0
        property int verdictLevel: 0   // 0=noData 1=critical 2=warn 3=ok
        property string adviceText: ""
        property int policyCount: 0
        property bool showBar: true
        signal calculateNeed()
        signal openVault()

        readonly property real rawRatio: needed > 0 ? cover / needed : 0
        readonly property real progress: Math.min(rawRatio, 1.0)
        readonly property real deficit: Math.max(0, needed - cover)
        readonly property color barColor: insurancePage.progressColor(rawRatio)

        color: "#121212"; radius: 10; border.color: "#2A2A2A"

        Rectangle {
            width: 3; height: parent.height; radius: 2
            color: card.accentColor; opacity: 0.6
            anchors { left: parent.left; top: parent.top }
        }

        RowLayout {
            anchors.fill: parent
            anchors.margins: 18
            anchors.leftMargin: 22
            spacing: 20

            ColumnLayout {
                Layout.preferredWidth: 260
                spacing: 4
                Text { text: card.category.toUpperCase() + " INSURANCE"; color: card.accentColor; font.pixelSize: 11; font.bold: true; font.letterSpacing: 1.2 }
                Text {
                    text: insurancePage.fmtCr(card.cover)
                    color: "white"; font.pixelSize: 26; font.bold: true
                }
                Text {
                    text: card.policyCount + (card.policyCount === 1 ? " policy" : " policies")
                    color: "#888"; font.pixelSize: 11
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6

                // No-data state
                ColumnLayout {
                    Layout.fillWidth: true
                    visible: card.verdictLevel === 0
                    spacing: 4
                    Text {
                        text: "Tell us about your dependents and expenses to size your cover."
                        color: "#666"; font.pixelSize: 12; font.italic: true
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    visible: card.verdictLevel > 0
                    spacing: 6

                    ProgressBar {
                        id: cardBar
                        visible: card.showBar
                        value: card.progress
                        Layout.fillWidth: true
                        Layout.preferredHeight: 7

                        background: Rectangle { color: "#222"; radius: 3 }
                        contentItem: Item {
                            Rectangle {
                                width: cardBar.visualPosition * parent.width
                                height: 7; radius: 3
                                color: card.barColor
                                Behavior on width { NumberAnimation { duration: 800; easing.type: Easing.OutExpo } }
                                Behavior on color { ColorAnimation { duration: 400 } }
                            }
                        }
                    }

                    Text {
                        visible: card.deficit > 0
                        text: "Deficit: " + insurancePage.fmtCr(card.deficit)
                        color: "#F44336"; font.pixelSize: 14; font.bold: true
                    }
                    Text {
                        visible: card.deficit <= 0 && card.cover > 0
                        text: "Fully Covered ✓"
                        color: "#43e97b"; font.pixelSize: 14; font.bold: true
                    }
                    Text {
                        visible: card.deficit > 0 && card.adviceText !== ""
                        text: card.adviceText
                        color: "#888"; font.pixelSize: 10; font.italic: true
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }
                }
            }

            ColumnLayout {
                spacing: 8
                PolicyVaultButton {
                    text: "⚡ Calculate Need"
                    accent: card.accentColor
                    filled: false
                    onClicked: card.calculateNeed()
                }
                PolicyVaultButton {
                    text: "📄 Policy Vault"
                    accent: card.accentColor
                    filled: card.policyCount > 0
                    onClicked: card.openVault()
                }
            }
        }
    }

    component PolicyVaultButton : Rectangle {
        id: btnRoot
        property string text: ""
        property color accent: "white"
        property bool filled: false
        signal clicked()

        implicitWidth: btnLabel.implicitWidth + 24
        implicitHeight: 30
        radius: 6
        color: filled ? Qt.darker(accent, 3.5) : "transparent"
        border.color: accent
        border.width: 1

        Text {
            id: btnLabel
            anchors.centerIn: parent
            text: btnRoot.text
            color: btnRoot.accent
            font.pixelSize: 11; font.bold: true
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: btnRoot.clicked()
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
            Text { text: parent.parent.label; color: "#555"; font.pixelSize: 8; font.letterSpacing: 1; anchors.horizontalCenter: parent.horizontalCenter }
            Text { text: parent.parent.valueText; color: parent.parent.accent; font.pixelSize: 12; font.bold: true; anchors.horizontalCenter: parent.horizontalCenter }
        }
    }
}
