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
            id: portListView
            Layout.fillWidth: true; Layout.fillHeight: true; clip: true; model: proxy
            boundsBehavior: Flickable.StopAtBounds
            rightMargin: 12

            ScrollBar.vertical: ScrollBar {
                id: portScrollBar
                active: true
                policy: ScrollBar.AsNeeded
                contentItem: Rectangle {
                    implicitWidth: 4; implicitHeight: 100; radius: 2
                    color: portScrollBar.pressed ? tableRoot.accent : "#333"
                    Behavior on color { ColorAnimation { duration: 200 } }
                }
                background: Rectangle { implicitWidth: 4; color: "transparent" }
            }

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
                            var t = filterType
                            if (t === "Equity")      return ["Stock", "Mutual Fund", "ETF", "ESOPs", "Private"]
                            if (t === "Debt")        return ["FD/RD", "Bond", "Fund", "Cash & Savings", "Govt. Scheme"]
                            if (t === "Real Estate") return ["Residential", "Commercial", "REITs"]
                            if (t === "Commodity")   return ["Physical", "Digital", "ETF/Fund"]
                            return []
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

                    // Invested — underline on focus/hover so the field is discoverable
                    Item {
                        Layout.preferredWidth: colInvested
                        implicitHeight: investedInput.implicitHeight + 2

                        TextInput {
                            id: investedInput
                            anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter }
                            text: model.invested === 0 ? "" : Number(model.invested).toFixed(0)
                            color: "#999"; font.bold: true
                            horizontalAlignment: Text.AlignRight
                            selectByMouse: true
                            mouseSelectionMode: TextInput.SelectCharacters
                            onTextEdited: { let v = parseFloat(text); model.invested = isNaN(v) ? 0 : v }
                        }
                        Rectangle {
                            anchors.bottom: parent.bottom; width: parent.width; height: 1
                            color: investedInput.activeFocus ? "#a29bfe" : (invHoverMA.containsMouse ? "#444" : "transparent")
                        }
                        MouseArea {
                            id: invHoverMA; anchors.fill: parent; hoverEnabled: true
                            acceptedButtons: Qt.NoButton; cursorShape: Qt.IBeamCursor
                        }
                    }

                    // Current Value — same underline treatment
                    Item {
                        Layout.preferredWidth: colValue
                        implicitHeight: valueInput.implicitHeight + 2

                        TextInput {
                            id: valueInput
                            anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter }
                            text: model.currentValue === 0 ? "" : Number(model.currentValue).toFixed(0)
                            color: "white"; font.bold: true
                            horizontalAlignment: Text.AlignRight
                            selectByMouse: true
                            mouseSelectionMode: TextInput.SelectCharacters
                            onTextEdited: { let v = parseFloat(text); model.currentValue = isNaN(v) ? 0 : v }
                        }
                        Rectangle {
                            anchors.bottom: parent.bottom; width: parent.width; height: 1
                            color: valueInput.activeFocus ? "#00d2ff" : (valHoverMA.containsMouse ? "#444" : "transparent")
                        }
                        MouseArea {
                            id: valHoverMA; anchors.fill: parent; hoverEnabled: true
                            acceptedButtons: Qt.NoButton; cursorShape: Qt.IBeamCursor
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
                        currentIndex: find(goalLink)
                        onActivated: goalLink = (currentText === "- None -") ? "" : currentText
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