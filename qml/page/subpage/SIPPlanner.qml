import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "../../components"

Rectangle {
    id: sipPlannerRoot
    color: "#000000"

    property int assetTabIndex: 0
    readonly property var typeNames: ["Equity", "Debt", "Real Estate", "Commodity", "Crypto"]
    property string currentType: typeNames[assetTabIndex]

    readonly property color colorEquity:     "#00d2ff"
    readonly property color colorDebt:       "#a29bfe"
    readonly property color colorRealEstate: "#ff7675"
    readonly property color colorCommodity:  "#f1c40f"
    readonly property color colorCrypto:     "#6c5ce7"

    property real currentAssetTotal: sipModel.getTotal(currentType)
    property real globalSipTotal: sipModel.getTotal("Total")

    Connections {
        target: sipModel
        // Whenever C++ emits sipUpdated (on add, remove, or edit)
        function onSipUpdated() {
            sipPlannerRoot.currentAssetTotal = sipModel.getTotal(sipPlannerRoot.currentType)
            sipPlannerRoot.globalSipTotal = sipModel.getTotal("Total")
        }
    }

    // Ensure the asset total updates when you switch tabs
    onCurrentTypeChanged: {
        sipPlannerRoot.currentAssetTotal = sipModel.getTotal(sipPlannerRoot.currentType)
    }

    ColumnLayout {
        anchors.fill: parent; spacing: 0
        Layout.topMargin: -15

        // ── NAV BAR ───────────────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true; Layout.preferredHeight: 50; color: "#000000"

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 8

                // Left group: Save / Clear Asset / Clear All
                SaveButton {
                    text: "Save"
                    onClicked: { /* persistence hook */ }
                }

                // Clear Asset — accent text + red border on hover
                NavBtn {
                    label: "Clear " + sipPlannerRoot.currentType
                    accentColor: [
                        sipPlannerRoot.colorEquity, sipPlannerRoot.colorDebt,
                        sipPlannerRoot.colorRealEstate, sipPlannerRoot.colorCommodity,
                        sipPlannerRoot.colorCrypto
                    ][sipPlannerRoot.assetTabIndex]
                    onTap: sipModel.clearAsset(sipPlannerRoot.currentType)
                }

                // Clear All — plain red border on hover (no accent text)
                NavBtn {
                    label: "Clear All"
                    onTap: sipModel.clearAll()
                }

                // Center: asset type tabs
                Item { Layout.fillWidth: true }

                Repeater {
                    model: ListModel {
                        ListElement { name: "Equity";      color: "#00d2ff" }
                        ListElement { name: "Debt";        color: "#a29bfe" }
                        ListElement { name: "Real Estate"; color: "#ff7675" }
                        ListElement { name: "Commodity";   color: "#f1c40f" }
                        ListElement { name: "Crypto";      color: "#6c5ce7" }
                    }
                    delegate: Rectangle {
                        width: 110; height: 28; radius: 14; color: "transparent"
                        border.color: sipPlannerRoot.assetTabIndex === index ? model.color : "#2A2A2A"
                        border.width: 2
                        Text {
                            anchors.centerIn: parent; text: model.name
                            color: sipPlannerRoot.assetTabIndex === index ? "#ffffff"
                                 : (sipModel.getTotal(model.name) > 0 ? "#cccccc" : "#333")
                            font.bold: true; font.pixelSize: 11
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                        ToolTip.visible: tabMA.containsMouse && sipModel.getTotal(model.name) === 0
                        ToolTip.text: "No " + model.name + " SIPs yet"
                        ToolTip.delay: 600
                        MouseArea { id: tabMA; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: sipPlannerRoot.assetTabIndex = index }
                    }
                }

                Item { Layout.fillWidth: true }

                // Right: Add button (accent-colored, matches active tab)
                Button {
                    id: globalAddBtn
                    text: "+ ADD " + sipPlannerRoot.currentType.toUpperCase()

                    readonly property color currentAccent: [
                        sipPlannerRoot.colorEquity, sipPlannerRoot.colorDebt,
                        sipPlannerRoot.colorRealEstate, sipPlannerRoot.colorCommodity,
                        sipPlannerRoot.colorCrypto
                    ][sipPlannerRoot.assetTabIndex]

                    onClicked: sipModel.addEntry(sipPlannerRoot.currentType)

                    contentItem: Text {
                        text: globalAddBtn.text; font.bold: true; font.pixelSize: 11; font.letterSpacing: 1
                        color: globalAddBtn.hovered ? "#000000" : globalAddBtn.currentAccent
                        horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                    background: Rectangle {
                        implicitWidth: 130; implicitHeight: 30
                        color: globalAddBtn.hovered ? globalAddBtn.currentAccent : "transparent"
                        border.color: globalAddBtn.currentAccent; border.width: 1; radius: 4
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: globalAddBtn.clicked()
                    }
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

            RowLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 0

                // LEFT: Asset Specific Total
                ColumnLayout {
                    spacing: 2
                    Layout.alignment: Qt.AlignVCenter

                    Text {
                        text: "TOTAL " + sipPlannerRoot.currentType.toUpperCase() + " SIP"
                        color: "#888888"
                        font.bold: true; font.pixelSize: 10; font.letterSpacing: 1
                    }

                    Label {
                        id: localTotalLabel
                        text: root.currencySymbol + " " + sipPlannerRoot.currentAssetTotal.toLocaleString(Qt.locale(), 'f', 0)
                        color: [
                            sipPlannerRoot.colorEquity, sipPlannerRoot.colorDebt,
                            sipPlannerRoot.colorRealEstate, sipPlannerRoot.colorCommodity,
                            sipPlannerRoot.colorCrypto
                        ][sipPlannerRoot.assetTabIndex]
                        font.pixelSize: 22; font.bold: true

                        Behavior on text {
                            SequentialAnimation {
                                NumberAnimation { target: localTotalLabel; property: "opacity"; to: 0.6; duration: 50 }
                                NumberAnimation { target: localTotalLabel; property: "opacity"; to: 1.0; duration: 100 }
                            }
                        }
                    }
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    // VIEW BREAKDOWN — ghost button, accent border, accent text hover
                    Rectangle {
                        id: breakdownBtn
                        anchors.centerIn: parent
                        width: breakdownLabel.implicitWidth + 32
                        height: 34; radius: 4
                        color: breakdownMA.containsMouse ? Qt.rgba(breakdownBtn.accent.r, breakdownBtn.accent.g, breakdownBtn.accent.b, 0.12) : "transparent"
                        border.color: breakdownMA.containsMouse ? breakdownBtn.accent : "#333"
                        border.width: 1

                        readonly property color accent: [
                            sipPlannerRoot.colorEquity, sipPlannerRoot.colorDebt,
                            sipPlannerRoot.colorRealEstate, sipPlannerRoot.colorCommodity,
                            sipPlannerRoot.colorCrypto
                        ][sipPlannerRoot.assetTabIndex]

                        Behavior on color        { ColorAnimation { duration: 150 } }
                        Behavior on border.color { ColorAnimation { duration: 150 } }

                        Text {
                            id: breakdownLabel
                            anchors.centerIn: parent
                            text: "📊  VIEW BREAKDOWN"
                            color: breakdownMA.containsMouse ? breakdownBtn.accent : "#555"
                            font.bold: true; font.pixelSize: 12; font.letterSpacing: 1
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }

                        MouseArea {
                            id: breakdownMA; anchors.fill: parent; hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: chartsPopup.open()
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
                        color: "#000000"
                        font.pixelSize: 24; font.bold: true
                        Layout.alignment: Qt.AlignRight
                    }
                }
            }
        }
    }

    SipChartsPopup { id: chartsPopup }

    // ── NavBtn ─────────────────────────────────────────────────────────────────
    // Ghost button for the action bar.
    // accentColor: when set, text glows to that color on hover (used for Clear Asset).
    //              When transparent (default), text stays white/grey and border glows red.
    component NavBtn : Rectangle {
        property string label: ""
        property color accentColor: "transparent"   // set for Clear Asset buttons
        signal tap()

        // Has an accent = "Clear Asset" style; no accent = "Clear All" style
        readonly property bool hasAccent: accentColor.a > 0

        implicitWidth: navLabel.implicitWidth + 20
        implicitHeight: 28
        radius: 4
        color: navMA.containsMouse ? "#2e0a0a" : "transparent"
        border.width: 1
        border.color: navMA.containsMouse ? "#8b0000" : "#2A2A2A"

        Behavior on color        { ColorAnimation { duration: 120 } }
        Behavior on border.color { ColorAnimation { duration: 120 } }

        Text {
            id: navLabel
            anchors.centerIn: parent
            text: parent.label
            // Accent text for Clear Asset; plain #ccc otherwise
            color: navMA.containsMouse
                       ? (parent.hasAccent ? parent.accentColor : "#ccc")
                       : "#666"
            font.pixelSize: 11; font.bold: true; font.letterSpacing: 0.5
            Behavior on color { ColorAnimation { duration: 120 } }
        }

        MouseArea {
            id: navMA
            anchors.fill: parent; hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.tap()
        }
    }
}
