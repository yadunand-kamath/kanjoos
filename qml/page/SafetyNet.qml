import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "subpage"

Rectangle {
    id: safetyNetRoot
    color: "#121212"

    // Info Title
    function getInfoTitle() {
        if (safetyStack.currentIndex === 0) return "Emergency Fund"
        if (safetyStack.currentIndex === 1) return "Insurance Planning"
        return "Retirement Planning"
    }

    // Info Content
    function getInfoContent() {
        if (safetyStack.currentIndex === 0)
            return "An <b>Emergency Fund</b> is a cash reserve for unplanned or unexpected situations.<br><br>" +
                            "<font color='#FF8F00'><b>TARGET</b><br></font> Aim for <b>6-12 months</b> of income (tool chooses expense if larger than income).<br><br>" +
                            "<font color='#FF8F00'><b>WHERE TO KEEP IT?</b></font><br>" +
                            "The whole point of this fund is to have liquid cash ready to use.<br><br>" +
                            "• OPTION 1 - <b>Isolated:</b> Keep the fund in a dedicated savings account (ideally separate from daily use).<br>" +
                            "• OPTION 2 - <b>Distributed:</b> Keep 1/3 in a  dedicated savings account, and the rest in a liquid fund or FD.<br><br>" +
                            "<i>Choose based on your risk profile, dependents, and priorities.</i>"
        if (safetyStack.currentIndex === 1)
            return "<b>Insurance</b> is a tool for <font color='#00E5FF'>risk transfer</font>, not an investment.<br><br>" +
                    "• <b>Health:</b> Protects your savings from medical inflation.<br>" +
                    "• <b>Life:</b> Critical only if you have dependents to support.<br>" +
                    "• <b>Asset:</b> Protects your high-value physical belongings."
        return "Plan for the sunset years by accounting for inflation and lifestyle maintenance."
    }

    // Info Links
    function getInfoResources() {
        if (safetyStack.currentIndex === 0) { // Emergency Fund
            return [
                { title: "Why Every Indian Household Needs an Emergency Fund", source: "Zerodha Fund House", url: "https://www.zerodhafundhouse.com/blog/why-every-indian-household-needs-an-emergency-fund/" },
                { title: "Why 80% of Emergency Funds fail", source: "LinkedIn", url: "https://www.linkedin.com/posts/abhishek-walia-0710_heres-why-80-of-emergency-funds-fail-activity-7363789392697577474-GFdo?utm_source=social_share_send&utm_medium=android_app&rcm=ACoAACd2gyYBOWB5-ycJUydWTS10j8JrCrh2uDM&utm_campaign=gmail" }
            ];
        }
        if (safetyStack.currentIndex === 1) { // Insurance
            return [
                { title: "Term Insurance Guide", source: "KlarifyLife", url: "https://www.hdfclife.com/klarifylife/term-guide/start-your-term-guide-journey" },
                { title: "Health Insurance Checklist", source: "DITTO", url: "https://joinditto.in" }
            ];
        }
        return []; // Retirement - empty for now
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.topMargin: 10
        anchors.leftMargin: 40
        anchors.rightMargin: 40
        anchors.bottomMargin: 40
        spacing: 30

        // Disclaimer Banner
        Rectangle {
            id: disclaimerBanner
            Layout.fillWidth: true
            Layout.preferredHeight: 30
            Layout.bottomMargin: -20
            color: "#161616" // Subtle dark gray
            border.color: "#222"
            border.width: 1
            radius: 6

            Text {
                anchors.centerIn: parent
                // Constraint width so it wraps nicely on smaller windows
                width: parent.width * 0.8

                text: "⚠️ DISCLAIMER: All suggestions and recommendations are for guidance only. Please do your own due diligence before making any decision."
                color: "#888"
                font.family: "Segoe UI, Roboto, Helvetica, Arial, sans-serif"
                font.pixelSize: 10
                //font.italic: true
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                wrapMode: Text.WordWrap
                renderType: Text.NativeRendering
            }
        }

        // --- NAVIGATION & INFO BAR ---
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 50

            // Sub-Navigation Tabs (Center)
            Rectangle {
                id: segmentedControl
                anchors.centerIn: parent
                width: 420
                height: 30
                color: "#1E1E1E" // Dark gray background
                radius: height / 2
                border.color: "#2A2A2A"
                border.width: 1

                // 1. THE SLIDING PILL (Active Tab Background)
                Rectangle {
                    id: activeHighlight
                    width: (parent.width / 3) - 8 // Divide by 3 tabs, minus padding
                    height: parent.height - 8
                    x: (safetyStack.currentIndex * (parent.width / 3)) + 4
                    y: 4
                    color: "#333333" // Lighter "physical" toggle color
                    radius: height / 2

                    // Delight: Smooth sliding movement
                    Behavior on x {
                        NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
                    }
                }

                // 2. THE LABELS
                Row {
                    anchors.fill: parent
                    Repeater {
                        model: ["Emergency Fund", "Insurance", "Retirement"]

                        Item {
                            width: segmentedControl.width / 3
                            height: segmentedControl.height

                            Text {
                                text: modelData
                                anchors.centerIn: parent
                                font.pixelSize: 14
                                font.weight: safetyStack.currentIndex === index ? Font.Medium : Font.Normal
                                color: safetyStack.currentIndex === index ? "white" : "#777"
                                font.bold: safetyStack.currentIndex === index ? true : false

                                // Smooth color transition
                                Behavior on color { ColorAnimation { duration: 200 } }
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: safetyStack.currentIndex = index
                                cursorShape: Qt.PointingHandCursor
                            }
                        }
                    }
                }
            }

            Item { Layout.fillWidth: true }

            // INFO BUTTON (Top Right)
            Button {
                id: infoBtn
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: "ⓘ"
                flat: true
                font.pixelSize: 20
                palette.buttonText: infoOverlay.visible ? "#4CAF50" : "#888"
                onClicked: infoOverlay.visible = !infoOverlay.visible
            }
        }

        // PAGE LAYOUT
        StackLayout {
            id: safetyStack
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: 0

            // -- SUB PAGE 1: EMERGENCY FUND --
            EmergencyFund { id : emergencyFundSubPage }

            // --- SUB PAGE 2: INSURANCE ---
            InsuranceTracker { id : insuranceTrackerSubPage }

            // --- SUB PAGE 3: RETIREMENT ---
            Retirement {
                id: retirementSubPage
            }
        }
    }

    // --- HELP OVERLAY (10% Delight) ---
    Rectangle {
        id: infoOverlay
        anchors.fill: parent
        color: "#f2121212" // Semi-transparent dark
        visible: false
        z: 100 // Ensure it's on top

        MouseArea { anchors.fill: parent } // Prevent clicks through to page

        // Close Button (Top Right)
        Button {
            id: closeInfoBtn
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.margins: 30 // Whitespace delight
            anchors.rightMargin: 60
            z: 101 // Ensure it sits above the ScrollView

            flat: true
            hoverEnabled: true
            onClicked: infoOverlay.visible = false

            // Custom Close Icon
            contentItem: Text {
                text: "✕"
                font.pixelSize: 24
                font.weight: Font.Light
                color: closeInfoBtn.hovered ? "white" : "#666"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter

                Behavior on color { ColorAnimation { duration: 200 } }
            }

            background: Rectangle {
                implicitWidth: 40
                implicitHeight: 40
                color: closeInfoBtn.hovered ? "#333" : "transparent"
                radius: 20
                Behavior on color { ColorAnimation { duration: 200 } }
            }
        }

        // Use a ScrollView to handle long text
        ScrollView {
            id: infoScroll
            anchors.fill: parent
            anchors.margins: 40 // Padding so content doesn't touch screen edges
            contentWidth: availableWidth // Ensures ColumnLayout doesn't horizontal scroll
            clip: true // Prevents content from drawing outside the scroll area

            ColumnLayout {
                anchors.centerIn: parent
                width: infoScroll.availableWidth
                spacing: 25

                Text {
                    text: getInfoTitle()
                    color: {
                        if (safetyStack.currentIndex === 0) return "#FF8F00" // Dark Orange
                        if (safetyStack.currentIndex === 1) return "#00E5FF" // Turquoise
                        return "#A033FF"                                    // Purple
                    }
                    font.pixelSize: 32; font.bold: true
                    Layout.alignment: Qt.AlignHCenter
                }

                Text {
                    text: getInfoContent()
                    color: "white"; font.pixelSize: 16; lineHeight: 1.3; wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter; Layout.fillWidth: true
                }

                // Tip Box
                Rectangle {
                    Layout.preferredWidth: 500
                    Layout.preferredHeight: 70
                    Layout.alignment: Qt.AlignHCenter
                    color: "#1a1305" // Dark amber
                    border.color: "#FF8F00"
                    border.width: 1
                    radius: 8
                    visible: safetyStack.currentIndex === 0 // Show only for EF

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 15
                        spacing: 15
                        Text { text: "⚠️"; font.pixelSize: 22 }
                        Text {
                            Layout.fillWidth: true
                            text: "1. Don't keep emergency funds in <b>equity markets</b> or <b>illiquid assets.</b><br>" +
                                  "2. Don't forget to <b>refill<\b> the fund after use."
                            color: "#FFCC80"
                            font.pixelSize: 13
                            textFormat: Text.StyledText
                            wrapMode: Text.WordWrap
                        }
                    }
                }

                Text {
                    text: "RECOMMENDED RESOURCES"
                    color: "#444"
                    font.pixelSize: 10
                    font.letterSpacing: 2
                    Layout.alignment: Qt.AlignHCenter
                    font.weight: Font.Bold
                    visible: getInfoResources().length > 0
                }

                RowLayout {
                    Layout.alignment: Qt.AlignHCenter // Align the whole row to center
                    spacing: 15

                    Repeater {
                        model: getInfoResources()

                        ResourceLink {
                            // Give cards a fixed width so they fit in a row
                            Layout.preferredWidth: 200
                            title: modelData.title
                            source: modelData.source
                            url: modelData.url
                        }
                    }
                }
            }
        }
    }

    component ResourceLink : Rectangle {
        property string title: ""
        property string url: ""
        property string source: ""

        Layout.preferredWidth: 200
        Layout.preferredHeight: 80
        color: "#1a1a1a"
        radius: 10
        border.color: mouseArea.containsMouse ? "#0066CC" : "#333"
        border.width: 1

        Behavior on border.color { ColorAnimation { duration: 150 } }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 4

            RowLayout {
                Layout.fillWidth: true
                Text { text: "🔗"; font.pixelSize: 12; opacity: 0.5 }
                Item { Layout.fillWidth: true } // Spacer
                Text { text: "↗"; color: "#0000FF"; font.pixelSize: 14; visible: mouseArea.containsMouse }
            }

            Text {
                text: title; color: "white"; font.pixelSize: 12; font.weight: Font.Medium
                elide: Text.ElideRight; Layout.fillWidth: true
            }

            Text {
                text: source; color: "#555"; font.pixelSize: 9; font.letterSpacing: 1
                elide: Text.ElideRight; Layout.fillWidth: true
            }
        }

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: Qt.openUrlExternally(url)
        }
    }
}