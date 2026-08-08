import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "./subpage"

Rectangle {
    id: portfolioRoot
    color: "#000000"

    property int assetTabIndex: 0
    property string currentType: ["Equity", "Debt", "Real Estate", "Commodity", "Crypto"][assetTabIndex]

    // Accents
    readonly property color colorEquity: "#00d2ff"
    readonly property color colorDebt: "#a29bfe"
    readonly property color colorGold: "#f1c40f"
    readonly property color colorCrypto: "#6c5ce7"
    readonly property color colorRealEstate: "#ff7675"

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

        // 1. NAV BAR
        Rectangle {
            Layout.fillWidth: true; Layout.preferredHeight: 50; color: "#000000"
            RowLayout {
                anchors.centerIn: parent; spacing: 10
                Repeater {
                    model: [
                        { name: "Equity", col: portfolioRoot.colorEquity },
                        { name: "Debt", col: portfolioRoot.colorDebt },
                        { name: "Real Estate", col: portfolioRoot.colorRealEstate },
                        { name: "Commodity", col: portfolioRoot.colorGold },
                        { name: "Crypto", col: portfolioRoot.colorCrypto }
                    ]
                    delegate: Rectangle {
                        width: 110; height: 26; radius: 13; color: "transparent"
                        border.color: portfolioRoot.assetTabIndex === index ? modelData.col : "#2A2A2A"
                        border.width: 2
                        Text {
                            anchors.centerIn: parent; text: modelData.name
                            color: portfolioRoot.assetTabIndex === index ? "#ffffff" : "#666"
                            font.bold: true; font.pixelSize: 11
                        }
                        MouseArea { anchors.fill: parent; onClicked: portfolioRoot.assetTabIndex = index }
                    }
                }
            }

            // ADD BUTTON
            Button {
                id: globalAddBtn
                anchors.right: parent.right; anchors.rightMargin: 20
                anchors.verticalCenter: parent.verticalCenter
                text: "+ ADD " + portfolioRoot.currentType.toUpperCase()

                readonly property color currentAccent: [
                    portfolioRoot.colorEquity, portfolioRoot.colorDebt,
                    portfolioRoot.colorRealEstate, portfolioRoot.colorGold, portfolioRoot.colorCrypto
                ][portfolioRoot.assetTabIndex]

                onClicked: portfolioModel.addEntry(portfolioRoot.currentType)

                contentItem: Text {
                    text: globalAddBtn.text
                    font.bold: true; font.pixelSize: 11; font.letterSpacing: 1
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

        // 3. FOOTER (Matching Goals)
        Rectangle {
            Layout.fillWidth: true; Layout.preferredHeight: 80; color: "#ffffff"; radius: 4; Layout.margins: 15
            RowLayout {
                anchors.fill: parent; anchors.margins: 20
                ColumnLayout {
                    spacing: 2
                    Text { text: "TOTAL " + portfolioRoot.currentType.toUpperCase() + " VALUE"; color: "#888"; font.pixelSize: 10; font.bold: true }
                    Text {
                        text: root.currencySymbol + " " + portfolioRoot.currentAssetTotal.toLocaleString(Qt.locale(), 'f', 0)
                        color: "black"; font.pixelSize: 22; font.bold: true
                    }
                }
                Item { Layout.fillWidth: true }
                ColumnLayout {
                    Layout.alignment: Qt.AlignRight
                    Text { text: "TOTAL PORTFOLIO VALUE"; color: "#888"; font.pixelSize: 10; font.bold: true; Layout.alignment: Qt.AlignRight }
                    Text {
                        text: root.currencySymbol + " " + portfolioRoot.netWorth.toLocaleString(Qt.locale(), 'f', 0)
                        color: "black"; font.pixelSize: 22; font.bold: true; Layout.alignment: Qt.AlignRight
                    }
                }
            }
        }
    }
}