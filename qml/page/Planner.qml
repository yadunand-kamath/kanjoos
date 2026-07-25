import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "./subpage"

Rectangle {
    id: plannerRoot
    // Remove anchors.fill: parent here because SwipeView/StackLayout handles sizing
    color: "#000000"

    property int mainTabIndex: 0
    property int assetTabIndex: 0

    ColumnLayout {
        // Use anchors to fill the Rectangle root
        anchors.fill: parent
        spacing: 0

        // ---  MAIN NAVIGATION ---
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 70
            color: "#000000"

            Rectangle {
                id: mainSegmentedControl
                anchors.centerIn: parent
                width: 300 // Adjusted for 2 tabs
                height: 30
                color: "#1E1E1E"
                radius: height / 2
                border.color: "#2A2A2A"

                // The Sliding Pill
                Rectangle {
                    width: (parent.width / 2) - 8
                    height: parent.height - 8
                    x: (plannerRoot.mainTabIndex * (parent.width / 2)) + 4
                    y: 4
                    color: "#333333"
                    radius: height / 2
                    Behavior on x { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                }

                Row {
                    anchors.fill: parent
                    Repeater {
                        model: ["Goals", "SIP Planner"]
                        Item {
                            width: mainSegmentedControl.width / 2; height: 30
                            Text {
                                text: modelData
                                anchors.centerIn: parent
                                font.pixelSize: 13
                                color: plannerRoot.mainTabIndex === index ? "white" : "#777"
                                font.bold: plannerRoot.mainTabIndex === index
                                Behavior on color { ColorAnimation { duration: 200 } }
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: plannerRoot.mainTabIndex = index
                                cursorShape: Qt.PointingHandCursor
                            }
                        }
                    }
                }
            }
        }

        // --- MAIN CONTENT AREA ---
        StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: plannerRoot.mainTabIndex

            // --- VIEW 1: GOALS ---
            Goals { id: goalSubpage }

            // --- VIEW 2: SIP PLANNER ---
            SIPPlanner { id: sipPage }
        }
    }
}