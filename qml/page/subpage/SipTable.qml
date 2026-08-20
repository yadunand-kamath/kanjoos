import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import FinancialComponents 1.0

import "../../components"

Item {
    id: sipTableRoot
    property string filterType: ""
    property color accent: "white"

    // Proxy model per page
    SipFilterProxy {
        id: pageProxy
        sourceModel: sipModel
        filterType: sipTableRoot.filterType
    }

    // Column Width Config
    readonly property real colNum: 35
    readonly property real colName: 200
    readonly property real colMarket: 100
    readonly property real colType: 110
    readonly property real colCat: 100
    readonly property real colGoal: 140
    readonly property real colSIP: 110
    readonly property real colActions: 40

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 15
        spacing: 12

        // --- SECTION HEADER ---
        Text {
            text: filterType.toUpperCase() + " - SYSTEMATIC INVESTMENT PLAN"
            color: accent
            font.bold: true; font.pixelSize: 13; font.letterSpacing: 1

            // Centering Logic
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            //Layout.alignment: Qt.AlignHCenter
        }

        // --- TABLE HEADER ---
        Rectangle {
            Layout.fillWidth: true; height: 32; color: "#1A1A1A"; radius: 2
            RowLayout {
                anchors.fill: parent; anchors.leftMargin: 15; anchors.rightMargin: 15; spacing: 10

                HeaderLabel { text: "#"; Layout.preferredWidth: colNum }
                HeaderLabel { text: "ASSET NAME"; Layout.preferredWidth: colName; Layout.fillWidth: true }

                // Conditional Headers
                HeaderLabel { text: "MARKET"; Layout.preferredWidth: colMarket; visible: filterType === "Equity" }
                HeaderLabel { text: "INSTRUMENT"; Layout.preferredWidth: colType; visible: filterType !== "Crypto" }
                HeaderLabel { text: "CATEGORY"; Layout.preferredWidth: colCat; visible: filterType === "Equity" }

                HeaderLabel { text: "LINKED GOAL"; Layout.preferredWidth: colGoal }
                HeaderLabel { text: "SIP VALUE"; Layout.preferredWidth: colSIP; horizontalAlignment: Text.AlignRight }
                Item { Layout.preferredWidth: colActions }
            }
        }

        // --- TABLE ROWS ---
        ListView {
            id: sipListView
            Layout.fillWidth: true; Layout.fillHeight: true
            model: pageProxy
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            rightMargin: 12

            ScrollBar.vertical: ScrollBar {
                id: scrollBar
                active: true // Keep it visible when scrolling
                policy: ScrollBar.AsNeeded // Show only if content overflows

                contentItem: Rectangle {
                    implicitWidth: 4
                    implicitHeight: 100
                    radius: 2
                    // Use a subtle grey or your Cyan accent
                    color: scrollBar.pressed ? accent : "#333"

                    // Animation for appearance
                    Behavior on color { ColorAnimation { duration: 200 } }
                }

                background: Rectangle {
                    implicitWidth: 4
                    color: "transparent" // Keep background clean
                }
            }

            delegate: Rectangle {
                id: rowRoot
                width: sipListView.width
                implicitHeight: 45
                color: rowMA.containsMouse ? "#121212" : "transparent"

                // Brutalist Bottom Divider
                Rectangle {
                    width: parent.width; height: 1
                    color: "#2A2A2A"; anchors.bottom: parent.bottom
                }

                MouseArea {
                    id: rowMA
                    anchors.fill: parent; hoverEnabled: true
                    propagateComposedEvents: true
                    onClicked: (mouse) => mouse.accepted = false
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 15; anchors.rightMargin: 15
                    spacing: 10

                    Text {
                        text: index + 1
                        color: "#444"
                        Layout.preferredWidth: colNum
                        font.pixelSize: 11; font.family: "Monospace"
                    }

                    // Editable Name (Text Input)
                    TextInput {
                        text: model.name
                        color: "white"
                        font.bold: true; font.pixelSize: 13
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        selectByMouse: true
                        onTextEdited: model.name = text
                    }

                    // Dropdowns
                    CustomComboBox {
                        visible: filterType === "Equity"
                        Layout.preferredWidth: colMarket
                        model: ["Domestic", "International", "Private"]
                        currentIndex: find(market)
                        onActivated: market = currentText
                    }

                    CustomComboBox {
                        id: subTypeCombo
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
                        currentIndex: find(subType)
                        onActivated: subType = currentText
                    }

                    CustomComboBox {
                        visible: filterType === "Equity"
                        Layout.preferredWidth: colCat
                        model: ["Large", "Mid", "Small", "Flexi/Multi"]
                        currentIndex: find(category)
                        onActivated: category = currentText
                    }

                    CustomComboBox {
                        Layout.preferredWidth: colGoal
                        model: goalModel.goalNamesWithNone
                        currentIndex: find(goalLink)
                        onActivated: goalLink = (currentText === "- None -") ? "" : currentText
                    }

                    // SIP Value
                    TextInput {
                        text: model.amount === 0 ? "" : model.amount.toString()
                        color: accent
                        font.bold: true; font.family: "Monospace"; font.pixelSize: 13
                        Layout.preferredWidth: colSIP; horizontalAlignment: Text.AlignRight
                        Layout.alignment: Qt.AlignVCenter
                        validator: DoubleValidator { bottom: 0 }
                        onTextEdited: {
                            let val = parseFloat(text)
                            model.amount = isNaN(val) ? 0 : val
                        }
                    }

                    // Delete Button
                    Button {
                        id: delBtn
                        Layout.preferredWidth: colActions
                        Layout.alignment: Qt.AlignVCenter
                        flat: true
                        onClicked: pageProxy.removeRow(index)
                        contentItem: Text {
                            text: "×"
                            font.pixelSize: 20
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            color: delBtn.hovered ? "#FF0000" : "#444"
                        }
                        background: Rectangle {
                            color: delBtn.hovered ? Qt.rgba(1, 0, 0, 0.1) : "transparent"
                            radius: 4
                        }
                    }
                }
            }
        }
    }

    // Header Label Helper
    component HeaderLabel : Text {
        color: "#888888"; font.pixelSize: 10; font.bold: true; font.letterSpacing: 1
    }
}