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

            // Override the background of the TabBar
            background: Rectangle {
                color: "#1a1a1a" // Dark grey, slightly lighter than the title bar
            }

            TabButton {
                text: qsTr("Overview")
            }
            TabButton {
                text: qsTr("Cash Flow")
            }
            TabButton {
                text: qsTr("Safety net")
            }
            TabButton {
                text: qsTr("SIP Planner")
            }
            TabButton {
                text: qsTr("Portfolio")
            }
        }

        // 3. Content Pages
        SwipeView {
            id: mainContent
            Layout.fillWidth: true
            Layout.fillHeight: true

            // Co-ordinate with TabBar
            currentIndex: navBar.currentIndex

            // Disable manual mouse/touch swiping to handle navigation via TabBar
            interactive: true

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
