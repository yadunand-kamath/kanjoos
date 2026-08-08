import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import FinancialComponents 1.0
import "../../components"

Item {
    id: tableRoot
    property string filterType: ""
    property color accent: "white"

    readonly property real colNum: 30
    readonly property real colName: 250
    readonly property real colMarket: 85
    readonly property real colType: 95
    readonly property real colCat: 75
    readonly property real colInvested: 80
    readonly property real colValue: 80
    readonly property real colReturn: 70
    readonly property real colMoney: 100
    readonly property real colGoal: 160

    SipFilterProxy { // Reusing the same proxy logic
        id: proxy
        sourceModel: portfolioModel
        filterType: tableRoot.filterType
    }

    ColumnLayout {
        anchors.fill: parent; anchors.margins: 15; spacing: 10

        // Header
        Rectangle {
            Layout.fillWidth: true; height: 35; color: "#1A1A1A"; radius: 2
            RowLayout {
                anchors.fill: parent; anchors.leftMargin: 15; anchors.rightMargin: 15; spacing: 10
                HeaderLabel { text: "ASSET NAME"; Layout.preferredWidth: colName }
                HeaderLabel { text: "MARKET"; Layout.preferredWidth: colMarket; visible: filterType === "Equity" }
                HeaderLabel { text: "INSTRUMENT"; Layout.preferredWidth: colType; visible: filterType !== "Crypto" }
                HeaderLabel { text: "CATEGORY"; Layout.preferredWidth: colCat; visible: filterType === "Equity" }
                HeaderLabel { text: "INVESTED"; Layout.preferredWidth: colInvested; horizontalAlignment: Text.AlignRight }
                HeaderLabel { text: "VALUE"; Layout.preferredWidth: colValue; horizontalAlignment: Text.AlignRight }
                HeaderLabel { text: "RETURNS"; Layout.preferredWidth: colReturn; horizontalAlignment: Text.AlignRight }
                HeaderLabel { text: "LINKED GOAL"; Layout.preferredWidth: colGoal }
                Item { Layout.preferredWidth: 30 }
            }
        }

        ListView {
            id: portListView // ADD ID
            Layout.fillWidth: true; Layout.fillHeight: true; clip: true; model: proxy

            delegate: Rectangle {
                // FIX: Use ID instead of parent to avoid null width crash
                width: portListView.width
                implicitHeight: 48
                color: "transparent"
                Rectangle { width: parent.width; height: 1; color: "#2A2A2A"; anchors.bottom: parent.bottom }

                RowLayout {
                    anchors.fill: parent; anchors.leftMargin: 15; anchors.rightMargin: 15; spacing: 10

                    TextInput {
                        text: model.name; color: "white"; Layout.preferredWidth: colName
                        onTextEdited: model.name = text; selectByMouse: true
                    }

                    // Market (Equity Only)
                    CustomComboBox {
                        visible: filterType === "Equity"
                        Layout.preferredWidth: colMarket
                        model: ["Domestic", "International", "Private"]
                        currentIndex: find(model.market); onActivated: model.market = currentText
                    }

                    // Instrument Type
                    CustomComboBox {
                        visible: filterType !== "Crypto"
                        Layout.preferredWidth: colType
                        model: {
                            if (filterType === "Equity") return ["Stock", "Mutual Fund", "ETF", "ESOPs"]
                            if (filterType === "Debt") return ["FD/RD", "Bond", "Fund", "Govt. Scheme"]
                            if (filterType === "Real Estate") return ["Residential", "Commercial", "REITs"]
                            return ["Physical", "Digital", "ETF/Fund", "Other"]
                        }
                        currentIndex: find(model.subType); onActivated: model.subType = currentText
                    }

                    // Category (Equity Only)
                    CustomComboBox {
                        visible: filterType === "Equity"
                        Layout.preferredWidth: colCat
                        model: ["Large", "Mid", "Small", "Flexi/Multi"]
                        currentIndex: find(model.category); onActivated: model.category = currentText
                    }

                    TextInput {
                        text: model.invested === 0 ? "" : Number(model.invested).toFixed(0) // Prevents 2e+05
                        color: "#999"; Layout.preferredWidth: colInvested; horizontalAlignment: Text.AlignRight
                        font.bold: true
                        onTextEdited: {
                            let val = parseFloat(text)
                            model.invested = isNaN(val) ? 0 : val
                        }
                    }

                    TextInput {
                        text: model.currentValue === 0 ? "" : Number(model.currentValue).toFixed(0) // Prevents 2e+05
                        color: "white"; font.bold: true; Layout.preferredWidth: colValue; horizontalAlignment: Text.AlignRight
                        onTextEdited: {
                            let val = parseFloat(text)
                            model.currentValue = isNaN(val) ? 0 : val
                        }
                    }

                    Text {
                        text: model.returns.toFixed(1) + "%"
                        color: model.returns >= 0 ? "#43e97b" : "#ff0000"
                        Layout.preferredWidth: colReturn; horizontalAlignment: Text.AlignRight; font.bold: true
                    }

                    CustomComboBox {
                        Layout.preferredWidth: colGoal
                        model: goalModel.goalNamesWithNone

                        // Set index: find the current goalLink in the list of names
                        currentIndex: find(model.goalLink)

                        onActivated: {
                            // If "- None -" is picked, we store it as an empty string to "unselect"
                            model.goalLink = (currentText === "- None -") ? "" : currentText
                        }
                    }

                    ToolButton {
                        text: "×"
                        onClicked: proxy.removeRow(index)
                        contentItem: Text { text: "×"; color: "#444"; font.pixelSize: 18; horizontalAlignment: Text.AlignHCenter }
                    }
                }
            }
        }
    }

    component HeaderLabel : Text {
        color: "#888888"
        font.pixelSize: 10
        font.bold: true
        font.letterSpacing: 1
        verticalAlignment: Text.AlignVCenter
    }
}