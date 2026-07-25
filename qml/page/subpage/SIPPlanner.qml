import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "../../components"

Rectangle {
    id: sipPlannerRoot
    color: "#000000"

    property int assetTabIndex: 0
    property string currentType: ["Equity", "Debt", "Real Estate", "Commodity", "Crypto"][assetTabIndex]

    readonly property color colorEquity: "#00d2ff"
    readonly property color colorDebt: "#a29bfe"
    readonly property color colorCommodity: "#f1c40f"
    readonly property color colorCrypto: "#6c5ce7"
    readonly property color colorRealEstate: "#ff7675"

    property real currentAssetTotal: unifiedSipModel.getTotal(currentType)
    property real globalSipTotal: unifiedSipModel.getTotal("Total")

    Connections {
        target: unifiedSipModel
        // Whenever C++ emits sipUpdated (on add, remove, or edit)
        function onSipUpdated() {
            sipPlannerRoot.currentAssetTotal = unifiedSipModel.getTotal(sipPlannerRoot.currentType)
            sipPlannerRoot.globalSipTotal = unifiedSipModel.getTotal("Total")
        }
    }

    // Ensure the asset total updates when you switch tabs
    onCurrentTypeChanged: {
        sipPlannerRoot.currentAssetTotal = unifiedSipModel.getTotal(sipPlannerRoot.currentType)
    }

    ColumnLayout {
        anchors.fill: parent; spacing: 0
        Layout.topMargin: -15

        // 1. NAV BAR
        Rectangle {
            Layout.fillWidth: true; Layout.preferredHeight: 50; color: "#000000"
            RowLayout {
                anchors.centerIn: parent; spacing: 10
                Repeater {
                    model: [
                        { name: "Equity", col: sipPlannerRoot.colorEquity },
                        { name: "Debt", col: sipPlannerRoot.colorDebt },
                        { name: "Real Estate", col: sipPlannerRoot.colorRealEstate },
                        { name: "Commodity", col: sipPlannerRoot.colorCommodity },
                        { name: "Crypto", col: sipPlannerRoot.colorCrypto }
                    ]
                    delegate: Rectangle {
                        width: 110; height: 28; radius: 14; color: "transparent"
                        border.color: sipPlannerRoot.assetTabIndex === index ? modelData.col : "#2A2A2A"
                        border.width: 2
                        Text {
                            anchors.centerIn: parent; text: modelData.name
                            color: sipPlannerRoot.assetTabIndex === index ? "#ffffff" : "#666"
                            font.bold: true; font.pixelSize: 11
                        }
                        MouseArea { anchors.fill: parent; onClicked: sipPlannerRoot.assetTabIndex = index }
                    }
                }
            }

            // Global Add Button
            Button {
                id: globalAddBtn
                anchors.right: parent.right
                anchors.rightMargin: 20
                anchors.verticalCenter: parent.verticalCenter
                text: "+ ADD " + sipPlannerRoot.currentType.toUpperCase()

                // Dynamic Color Logic
                readonly property color currentAccent: [
                    sipPlannerRoot.colorEquity,
                    sipPlannerRoot.colorDebt,
                    sipPlannerRoot.colorRealEstate,
                    sipPlannerRoot.colorCommodity,
                    sipPlannerRoot.colorCrypto
                ][sipPlannerRoot.assetTabIndex]

                onClicked: unifiedSipModel.addEntry(sipPlannerRoot.currentType)

                // Styled Content (Text)
                contentItem: Text {
                    text: globalAddBtn.text
                    font.bold: true
                    font.pixelSize: 11
                    font.letterSpacing: 1
                    // Text turns black when background fills with color on hover
                    color: globalAddBtn.hovered ? "#000000" : globalAddBtn.currentAccent
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter

                    Behavior on color { ColorAnimation { duration: 150 } }
                }

                // Styled Background (Border & Hover Fill)
                background: Rectangle {
                    implicitWidth: 130
                    implicitHeight: 30
                    // Fills with accent color on hover
                    color: globalAddBtn.hovered ? globalAddBtn.currentAccent : "transparent"
                    border.color: globalAddBtn.currentAccent
                    border.width: 1
                    radius: 4

                    // Subtle glow effect
                    layer.enabled: globalAddBtn.hovered

                    Behavior on color { ColorAnimation { duration: 150 } }
                }

                // Change cursor to pointing hand
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: globalAddBtn.clicked()
                }
            }
        }

        // 2. TABLES
        StackLayout {
            Layout.fillWidth: true; Layout.fillHeight: true
            currentIndex: sipPlannerRoot.assetTabIndex

            SipTable { filterType: "Equity"; accent: sipPlannerRoot.colorEquity }
            SipTable { filterType: "Debt"; accent: sipPlannerRoot.colorDebt }
            SipTable { filterType: "Real Estate"; accent: sipPlannerRoot.colorRealEstate }
            SipTable { filterType: "Commodity"; accent: sipPlannerRoot.colorCommodity }
            SipTable { filterType: "Crypto"; accent: sipPlannerRoot.colorCrypto }
        }

        // 3. SUMMARY BAR (BOTTOM)
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 80
            color: "#ffffff"
            radius: 4
            Layout.margins: 20

            // Top Border
            Rectangle {
                width: parent.width; height: 1
                color: "#2A2A2A"; anchors.top: parent.top
            }

            RowLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 0

                // LEFT: Asset Specific Total (Now Dynamic)
                ColumnLayout {
                    spacing: 2
                    Layout.alignment: Qt.AlignVCenter

                    // Dynamic Label based on active tab
                    Text {
                        // e.g., "TOTAL EQUITY SIP"
                        text: "TOTAL " + sipPlannerRoot.currentType.toUpperCase() + " SIP"
                        color: "#888888"
                        font.bold: true
                        font.pixelSize: 10
                        font.letterSpacing: 1
                    }

                    Label {
                        id: localTotalLabel
                        // Automatically fetches total for the active tab from C++
                        text: root.currencySymbol + " " + sipPlannerRoot.currentAssetTotal.toLocaleString(Qt.locale(), 'f', 0)
                        color: "#000000"
                        font.pixelSize: 22
                        font.bold: true

                        // Delight: Small fade animation when the number changes
                        Behavior on text {
                            SequentialAnimation {
                                NumberAnimation { target: localTotalLabel; property: "opacity"; to: 0.7; duration: 50 }
                                NumberAnimation { target: localTotalLabel; property: "opacity"; to: 1.0; duration: 50 }
                            }
                        }
                    }
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    Button {
                        id: breakdownBtn
                        anchors.centerIn: parent
                        flat: true
                        text: "[ 📊 VIEW BREAKDOWN ]"

                        // Dynamic Accent Color
                        readonly property color currentAccent: [
                            sipPlannerRoot.colorEquity,
                            sipPlannerRoot.colorDebt,
                            sipPlannerRoot.colorRealEstate,
                            sipPlannerRoot.colorCommodity,
                            sipPlannerRoot.colorCrypto
                        ][sipPlannerRoot.assetTabIndex]

                        contentItem: Text {
                            text: breakdownBtn.text
                            color: breakdownBtn.hovered ? "white" : breakdownBtn.currentAccent
                            font.bold: true
                            font.pixelSize: 12
                            font.letterSpacing: 1
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }

                        onClicked: chartsPopup.open()

                        background: Rectangle { color: "transparent" }
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: breakdownBtn.clicked()
                        }
                    }
                }

                // RIGHT: SIP Portfolio Total
                ColumnLayout {
                    spacing: 2
                    Layout.alignment: Qt.AlignVCenter
                    Text {
                        text: "TOTAL SIP"
                        color: "#888888"
                        font.pixelSize: 10; font.bold: true; font.letterSpacing: 1
                        Layout.alignment: Qt.AlignRight
                    }
                    Text {
                        text: root.currencySymbol + " " + sipPlannerRoot.globalSipTotal.toLocaleString(Qt.locale(), 'f', 0)
                        color: "black"
                        font.pixelSize: 24; font.bold: true
                        Layout.alignment: Qt.AlignRight
                    }
                }
            }
        }
    }

    ChartsPopup { id: chartsPopup }
}
