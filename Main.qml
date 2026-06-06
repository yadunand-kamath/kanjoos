import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "qml"
import "qml/page"

Window {
    id: root
    width: 1280
    height: 720
    visible: true
    title: qsTr("kanjoos")

    // GLOBAL PROPERTIES
    property string currencySymbol: "₹" // INR
    property real globalMonthlyIncome: cashflowPage.totalIncome
    property real globalMonthlyExpense: cashflowPage.totalExpense
    property real insuranceTotalFromSafety: 0
    property bool syncInsuranceToCashflow: false

    // ColumnLayout to stack items vertically
    ColumnLayout {
        anchors.fill: parent
        spacing: 0 // No gaps between title, tabs, and content

        // 1. Title Bar
        TitleBar {
            Layout.fillWidth: true
            Layout.preferredHeight: 50
        }

        // 2. Navigation Bar
        TabBar {
            id: navBar
            Layout.fillWidth: true
            spacing: 0

            // Override the background of the TabBar
            background: Rectangle {
                color: "#000000" // Dark grey, slightly lighter than the title bar
            }

            // Custom helper for styled buttons
            component NavButton : TabButton {
                id: tab

                contentItem: Text {
                    text: tab.text
                    font.pixelSize: 12
                    font.weight: tab.checked ? Font.DemiBold : Font.Normal
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    // Active: Black text | Inactive: Silver text
                    color: tab.checked ? "#000000" : "#C0C0C0"

                    Behavior on color { ColorAnimation { duration: 150 } }
                }

                background: Rectangle {
                    // Active: White background | Inactive: Muted gray background
                    color: tab.checked ? "#FFFFFF" : "#1A1A1A"

                    // Add a subtle border to separate inactive tabs
                    border.color: "#000000"
                    border.width: 1

                    Behavior on color { ColorAnimation { duration: 150 } }
                }
            }

            NavButton { text: qsTr("Overview") }
            NavButton { text: qsTr("Cash Flow") }
            NavButton { text: qsTr("Safety net") }
            NavButton { text: qsTr("SIP Planner") }
            NavButton { text: qsTr("Portfolio") }
        }

        // 3. Content Pages
        SwipeView {
            id: mainContent
            Layout.fillWidth: true
            Layout.fillHeight: true

            // Co-ordinate with TabBar
            currentIndex: navBar.currentIndex

            // Disable manual mouse/touch swiping to handle navigation via TabBar
            interactive: false

            // Transition speed
            Component.onCompleted: contentItem.highlightMoveDuration = 300

            // Pages
            Overview { id: overviewPage }
            CashFlow { id: cashflowPage }
            SafetyNet { id: safetynetPage }
            Planning { id: sipPage }
            Portfolio { id: portfolioPage }
        }
    }
}
