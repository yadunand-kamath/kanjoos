import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "./subpage"
import "../components"

Rectangle {
    id: portfolioRoot
    color: "#000000"

    property int assetTabIndex: 0
    readonly property var typeNames: ["Equity", "Debt", "Real Estate", "Commodity", "Crypto"]
    property string currentType: typeNames[assetTabIndex]

    readonly property color colorEquity:     "#00d2ff"
    readonly property color colorDebt:       "#a29bfe"
    readonly property color colorRealEstate: "#ff7675"
    readonly property color colorGold:       "#f1c40f"
    readonly property color colorCrypto:     "#6c5ce7"

    property real currentAssetTotal: portfolioModel.getTotalValue(currentType)
    property real netWorth: portfolioModel.getTotalValue("Total")

    Connections {
        target: portfolioModel
        function onPortfolioUpdated() {
            portfolioRoot.currentAssetTotal = portfolioModel.getTotalValue(portfolioRoot.currentType)
            portfolioRoot.netWorth = portfolioModel.getTotalValue("Total")
        }
    }

    onCurrentTypeChanged: {
        portfolioRoot.currentAssetTotal = portfolioModel.getTotalValue(portfolioRoot.currentType)
    }

    ColumnLayout {
        anchors.fill: parent; spacing: 0

        // ── NAV BAR ───────────────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true; Layout.preferredHeight: 50; color: "#000000"

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12; anchors.rightMargin: 12
                spacing: 8

                // Left group: Save / Clear Asset / Clear All
                SaveButton {
                    text: "Save"
                    onClicked: { /* persistence hook */ }
                }

                // Clear Asset — accent text + red border on hover
                PortfolioNavBtn {
                    label: "Clear " + portfolioRoot.currentType
                    accentColor: [
                        portfolioRoot.colorEquity, portfolioRoot.colorDebt,
                        portfolioRoot.colorRealEstate, portfolioRoot.colorGold,
                        portfolioRoot.colorCrypto
                    ][portfolioRoot.assetTabIndex]
                    onTap: portfolioModel.clearAsset(portfolioRoot.currentType)
                }

                // Clear All — red border on hover only
                PortfolioNavBtn {
                    label: "Clear All"
                    onTap: portfolioModel.clearAll()
                }

                Item { Layout.fillWidth: true }

                // Center: asset type tab pills
                Repeater {
                    model: ListModel {
                        ListElement { name: "Equity";      color: "#00d2ff" }
                        ListElement { name: "Debt";        color: "#a29bfe" }
                        ListElement { name: "Real Estate"; color: "#ff7675" }
                        ListElement { name: "Commodity";   color: "#f1c40f" }
                        ListElement { name: "Crypto";      color: "#6c5ce7" }
                    }
                    delegate: Rectangle {
                        width: 110; height: 26; radius: 13; color: "transparent"
                        border.color: portfolioRoot.assetTabIndex === index ? model.color : "#2A2A2A"
                        border.width: 2
                        Text {
                            anchors.centerIn: parent; text: model.name
                            color: portfolioRoot.assetTabIndex === index ? "#ffffff" : "#666"
                            font.bold: true; font.pixelSize: 11
                        }
                        MouseArea { anchors.fill: parent; onClicked: portfolioRoot.assetTabIndex = index }
                    }
                }

                Item { Layout.fillWidth: true }

                // Right: Add button (accent-colored for active tab)
                Button {
                    id: globalAddBtn
                    text: "+ ADD " + portfolioRoot.currentType.toUpperCase()

                    readonly property color currentAccent: [
                        portfolioRoot.colorEquity, portfolioRoot.colorDebt,
                        portfolioRoot.colorRealEstate, portfolioRoot.colorGold, portfolioRoot.colorCrypto
                    ][portfolioRoot.assetTabIndex]

                    onClicked: portfolioModel.addEntry(portfolioRoot.currentType)

                    contentItem: Text {
                        text: globalAddBtn.text; font.bold: true; font.pixelSize: 11; font.letterSpacing: 1
                        color: globalAddBtn.hovered ? "#000000" : globalAddBtn.currentAccent
                        horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                    background: Rectangle {
                        implicitWidth: 140; implicitHeight: 30
                        color: globalAddBtn.hovered ? globalAddBtn.currentAccent : "transparent"
                        border.color: globalAddBtn.currentAccent; border.width: 1; radius: 4
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                }
            }
        }

        // 2. CONTENT
        StackLayout {
            Layout.fillWidth: true; Layout.fillHeight: true
            currentIndex: portfolioRoot.assetTabIndex
            PortfolioTable { filterType: "Equity"; accent: portfolioRoot.colorEquity }
            PortfolioTable { filterType: "Debt"; accent: portfolioRoot.colorDebt }
            PortfolioTable { filterType: "Real Estate"; accent: portfolioRoot.colorRealEstate }
            PortfolioTable { filterType: "Commodity"; accent: portfolioRoot.colorGold }
            PortfolioTable { filterType: "Crypto"; accent: portfolioRoot.colorCrypto }
        }

        // 3. FOOTER
        Rectangle {
            Layout.fillWidth: true; Layout.preferredHeight: 80; color: "#ffffff"; radius: 4; Layout.margins: 15
            RowLayout {
                anchors.fill: parent; anchors.margins: 20; spacing: 0

                ColumnLayout {
                    spacing: 2; Layout.alignment: Qt.AlignVCenter
                    Text {
                        text: "TOTAL " + portfolioRoot.currentType.toUpperCase() + " VALUE"
                        color: "#888888"; font.pixelSize: 10; font.bold: true; font.letterSpacing: 1
                    }
                    Text {
                        text: root.currencySymbol + " " + portfolioRoot.currentAssetTotal.toLocaleString(Qt.locale(), 'f', 0)
                        color: [
                            portfolioRoot.colorEquity, portfolioRoot.colorDebt,
                            portfolioRoot.colorRealEstate, portfolioRoot.colorGold, portfolioRoot.colorCrypto
                        ][portfolioRoot.assetTabIndex]
                        font.pixelSize: 22; font.bold: true
                    }
                }

                Item {
                    Layout.fillWidth: true; Layout.fillHeight: true

                    Rectangle {
                        id: pBreakdownBtn
                        anchors.centerIn: parent
                        width: pBreakdownLabel.implicitWidth + 32
                        height: 34; radius: 4
                        color: pBreakdownMA.containsMouse
                               ? Qt.rgba(pAccent.r, pAccent.g, pAccent.b, 0.12) : "transparent"
                        border.color: pBreakdownMA.containsMouse ? pAccent : "#333"; border.width: 1
                        Behavior on color        { ColorAnimation { duration: 150 } }
                        Behavior on border.color { ColorAnimation { duration: 150 } }

                        readonly property color pAccent: [
                            portfolioRoot.colorEquity, portfolioRoot.colorDebt,
                            portfolioRoot.colorRealEstate, portfolioRoot.colorGold, portfolioRoot.colorCrypto
                        ][portfolioRoot.assetTabIndex]

                        Text {
                            id: pBreakdownLabel; anchors.centerIn: parent
                            text: "📊  VIEW BREAKDOWN"
                            color: pBreakdownMA.containsMouse ? pBreakdownBtn.pAccent : "#555"
                            font.bold: true; font.pixelSize: 12; font.letterSpacing: 1
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                        MouseArea {
                            id: pBreakdownMA; anchors.fill: parent; hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: portfolioChartsPopup.open()
                        }
                    }
                }

                ColumnLayout {
                    spacing: 2; Layout.alignment: Qt.AlignVCenter
                    Text {
                        text: "TOTAL PORTFOLIO VALUE"; color: "#888888"
                        font.pixelSize: 10; font.bold: true; font.letterSpacing: 1; Layout.alignment: Qt.AlignRight
                    }
                    Text {
                        text: root.currencySymbol + " " + portfolioRoot.netWorth.toLocaleString(Qt.locale(), 'f', 0)
                        color: "#000000"; font.pixelSize: 22; font.bold: true; Layout.alignment: Qt.AlignRight
                    }
                }
            }
        }
    }

    PortfolioChartsPopup { id: portfolioChartsPopup }

    // ── PortfolioNavBtn ────────────────────────────────────────────────────────
    // Ghost button for the action bar.
    // accentColor: when set, text glows to that color on hover (Clear Asset).
    //              No accent = plain red-border style (Clear All).
    component PortfolioNavBtn : Rectangle {
        property string label: ""
        property color accentColor: "transparent"
        signal tap()

        readonly property bool hasAccent: accentColor.a > 0

        implicitWidth: pBtnLabel.implicitWidth + 20
        implicitHeight: 28
        radius: 4
        color: pNavMA.containsMouse ? "#2e0a0a" : "transparent"
        border.width: 1
        border.color: pNavMA.containsMouse ? "#8b0000" : "#2A2A2A"

        Behavior on color        { ColorAnimation { duration: 120 } }
        Behavior on border.color { ColorAnimation { duration: 120 } }

        Text {
            id: pBtnLabel
            anchors.centerIn: parent
            text: parent.label
            color: pNavMA.containsMouse
                       ? (parent.hasAccent ? parent.accentColor : "#ccc")
                       : "#666"
            font.pixelSize: 11; font.bold: true
            Behavior on color { ColorAnimation { duration: 120 } }
        }

        MouseArea {
            id: pNavMA
            anchors.fill: parent; hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.tap()
        }
    }
}