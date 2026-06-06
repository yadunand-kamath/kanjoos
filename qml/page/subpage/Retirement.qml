import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "../../components"

Rectangle {
    id: retirementRoot
    color: "#121212"

    ScrollView {
        id: retireScroll
        anchors.fill: parent
        anchors.topMargin: -20
        contentWidth: availableWidth
        clip: true

        ColumnLayout {
            width: parent.width
            anchors.margins: 5
            spacing: 10

            // 1. PREMIUM HEADER SUMMARY
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 20
                spacing: 50

                // Column 1
                Column {
                    Layout.fillWidth: true
                    spacing: 4
                    Text { text: "FIRE CORPUS NEEDED"; color: "#757575"; font.pixelSize: 10; font.letterSpacing: 1.3; anchors.horizontalCenter: parent.horizontalCenter }
                    Text {
                        text: isReady ? (root.currencySymbol + (retirementCalc.corpusNeeded / 10000000).toFixed(2) + " Cr") : "0.00 Cr"
                        color: "#00FF00"; font.pixelSize: 24; font.weight: Font.Bold
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }
                // Column 2
                Column {
                    Layout.fillWidth: true
                    spacing: 4
                    Text { text: "YEARS TO RETIREMENT"; color: "#757575"; font.pixelSize: 10; font.letterSpacing: 1.3; anchors.horizontalCenter: parent.horizontalCenter }
                    Text {
                        text: isReady ? (retirementCalc.retireAge - retirementCalc.currentAge) : "0"
                        color: "#FFFFFF"; font.pixelSize: 24; font.weight: Font.Bold
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }
                // Column 3
                Column {
                    Layout.fillWidth: true
                    spacing: 4
                    Text { text: "MONTHLY EXPENSES AT RETIREMENT"; color: "#757575"; font.pixelSize: 10; font.letterSpacing: 1.3; anchors.horizontalCenter: parent.horizontalCenter }
                    Text {
                        text: isReady ? (root.currencySymbol + " " + ((retirementCalc.monthlyExpense * Math.pow(1 + (retirementCalc.inflation/100), (retirementCalc.retireAge - retirementCalc.currentAge))) / 100000).toFixed(2) + " L") : "0.00 L"
                        color: "#FFFFFF"; font.pixelSize: 24; font.weight: Font.Bold; anchors.horizontalCenter: parent.horizontalCenter
                    }
                }
            }

            // 2. INPUT DASHBOARD CARD
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 320
                color: "#121212"
                radius: 10
                border.color: "#2A2A2A"

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 25
                    spacing: 10

                    // Row 1: Ages
                    RowLayout {
                        spacing: 40
                        // Current Age block
                        RowLayout {
                            Layout.preferredWidth: 120
                            spacing: 5
                            Text { text: "CURRENT AGE"; color: "#757575"; font.pixelSize: 10; font.letterSpacing: 1.3; Layout.preferredWidth: 100 }
                            CustomSlider {
                                Layout.fillWidth: true
                                from: 18; to: 60
                                value: isReady ? retirementCalc.currentAge : 30
                                onMoved: (v)=> { if(isReady) retirementCalc.currentAge=v }
                            }
                            RetireValueBox { text: isReady ? retirementCalc.currentAge : 0 }
                        }
                        // Retire Age block
                        RowLayout {
                            Layout.preferredWidth: 120
                            spacing: 5
                            Text { text: "RETIRE AGE"; color: "#757575"; font.pixelSize: 10; font.letterSpacing: 1.3; Layout.preferredWidth: 100 }
                            CustomSlider {
                                Layout.fillWidth: true
                                from: 30; to: 75
                                value: isReady ? retirementCalc.retireAge : 60
                                onMoved: (v)=> { if(isReady) retirementCalc.retireAge=v }
                            }
                            RetireValueBox { text: isReady ? retirementCalc.retireAge : 0 }
                        }
                    }

                    // Row 2: Life Expectancy (Full width)
                    RowLayout {
                        spacing: 5
                        Text { text: "LIFE EXPECTANCY"; color: "#757575"; font.pixelSize: 10; font.letterSpacing: 1.3; Layout.preferredWidth: 140 }
                        CustomSlider {
                            Layout.fillWidth: true
                            from: 60; to: 100
                            value: isReady ? retirementCalc.lifeExpectancy : 80
                            onMoved: (v)=> { if(isReady) retirementCalc.lifeExpectancy=v }
                        }
                        RetireValueBox { text: isReady ? retirementCalc.lifeExpectancy : 0 }
                    }

                    // Row 3: Monthly Expenses (Stepper Style)
                    RowLayout {
                        spacing: 24
                        Layout.fillWidth: true

                        // Expense Stepper
                        ColumnLayout {
                            Layout.fillWidth: true; Layout.preferredWidth: 2; spacing: 8
                            Text { text: "BASE MONTHLY EXPENSES"; color: "#757575"; font.pixelSize: 10; font.letterSpacing: 1.2 }
                            Rectangle {
                                Layout.fillWidth: true; Layout.preferredHeight: 48; color: "#1A1A1A"; radius: 10; border.color: "#2A2A2A"
                                RowLayout {
                                    anchors.fill: parent
                                    Button { text: "−"; flat: true; onClicked: if(isReady) retirementCalc.monthlyExpense -= 1000; palette.buttonText: "white" }
                                    Text { text: isReady ? retirementCalc.monthlyExpense.toLocaleString(Qt.locale(), 'f', 0) : "0"; color: "white"; font.pixelSize: 18; font.weight: Font.Bold; Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter }
                                    Button { text: "+"; flat: true; onClicked: if(isReady) retirementCalc.monthlyExpense += 1000; palette.buttonText: "white" }
                                }
                            }
                        }

                        // Lifestyle Selector (The Modifier)
                        ColumnLayout {
                            Layout.fillWidth: true; Layout.preferredWidth: 1; spacing: 8
                            Text { text: "LIFESTYLE"; color: "#757575"; font.pixelSize: 10; font.letterSpacing: 1.3 }
                            ComboBox {
                                id: lifestyleCombo
                                Layout.fillWidth: true; Layout.preferredHeight: 48
                                model: ["Kanjoos (Conservative)", "Standard", "Lavish (Luxurious)"]
                                currentIndex: 1 // Standard by default
                                onActivated: (index) => {
                                    if(!isReady) return;
                                    if(index === 0) retirementCalc.lifestyleMultiplier = 0.8;
                                    else if(index === 1) retirementCalc.lifestyleMultiplier = 1.0;
                                    else retirementCalc.lifestyleMultiplier = 1.5;
                                }
                                // Styled to match the brutalist theme
                                background: Rectangle { color: "#1A1A1A"; radius: 10; border.color: "#2A2A2A" }
                                contentItem: Text { text: lifestyleCombo.displayText; color: "white"; leftPadding: 12; verticalAlignment: Text.AlignVCenter; font.weight: Font.Medium }
                            }
                        }
                    }

                    // Row 4: Inflation & Returns
                    RowLayout {
                        spacing: 40
                        RowLayout {
                            Layout.preferredWidth: 120; spacing: 5
                            Text { text: "INFLATION (%)"; color: "#757575"; font.pixelSize: 10; font.letterSpacing: 1.3; Layout.preferredWidth: 140 }
                            CustomSlider { Layout.fillWidth: true; from: 1; to: 15; value: isReady ? retirementCalc.inflation : 1; onMoved: (v)=>retirementCalc.inflation=v }
                            RetireValueBox { text: isReady ? retirementCalc.inflation + "%" : "0%" }
                        }
                        RowLayout {
                            Layout.preferredWidth: 120; spacing: 15
                            Text {
                                text: "POST-RETIRE RETURN (%)"; color: "#757575"; font.pixelSize: 10; font.letterSpacing: 1.3
                                Layout.preferredWidth: 140; wrapMode: Text.NoWrap
                            }
                            CustomSlider { Layout.fillWidth: true; from: 1; to: 15; value: isReady ? retirementCalc.postReturn : 1; onMoved: (v)=>retirementCalc.postReturn=v }
                            RetireValueBox { text: isReady ? retirementCalc.postReturn + "%" : "0%" }
                        }
                    }
                }
            }

            // 3. BAR GRAPH
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 16
                visible: isReady

                // Stacked Liquidity Bar
                Text {
                    text: "CORPUS LIQUIDITY SPLIT";
                    color: "#757575"; font.pixelSize: 10; font.letterSpacing: 1.5
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 60
                    color: "transparent"

                    RowLayout {
                        anchors.fill: parent
                        spacing: 4

                        // SEGMENT 1: LIQUID
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredWidth: isReady ? (1.0 - retirementCalc.lockedRatio) * 100 : 50
                            Layout.fillHeight: true
                            color: "#00FF00" // Strict Pure Green
                            radius: 4

                            Column {
                                anchors.centerIn: parent
                                Text {
                                    text: "LIQUID (" + (isReady ? ((1.0 - retirementCalc.lockedRatio) * 100).toFixed(0) : "0") + "%)"
                                    color: "black"; font.pixelSize: 10; font.weight: Font.Bold; anchors.horizontalCenter: parent.horizontalCenter
                                }
                                Text {
                                    text: root.currencySymbol + " " + (isReady ? ((retirementCalc.corpusNeeded * (1.0 - retirementCalc.lockedRatio)) / 10000000).toFixed(2) : "0.00") + " Cr"
                                    color: "black"; font.pixelSize: 12; font.weight: Font.Black; anchors.horizontalCenter: parent.horizontalCenter
                                }
                            }
                        }

                        // SEGMENT 2: LOCKED
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredWidth: isReady ? retirementCalc.lockedRatio * 100 : 50
                            Layout.fillHeight: true
                            color: "#FF0000" //"#1A1A1A" // Dark Brutalist gray
                            //border.color: "#FF0000" // Strict Pure Red border for "Locked"
                            //border.width: 1
                            radius: 4

                            Column {
                                anchors.centerIn: parent
                                Text {
                                    text: "LOCKED (" + (isReady ? (retirementCalc.lockedRatio * 100).toFixed(0) : "0") + "%)"
                                    color: "black"; font.pixelSize: 10; font.weight: Font.Bold; anchors.horizontalCenter: parent.horizontalCenter
                                }
                                Text {
                                    text: root.currencySymbol + " " + (isReady ? ((retirementCalc.corpusNeeded * retirementCalc.lockedRatio) / 10000000).toFixed(2) : "0.00") + " Cr"
                                    color: "black"; font.pixelSize: 12; font.weight: Font.Black; anchors.horizontalCenter: parent.horizontalCenter
                                }
                            }
                        }
                    }
                }

                // Verdict Banner
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: verdictLabel.implicitHeight + 32
                    color: "#121212"
                    border.color: "#2A2A2A"
                    radius: 8

                    Text {
                        id: verdictLabel
                        anchors.fill: parent
                        anchors.margins: 16
                        text: isReady ? retirementCalc.verdictText : "retirementCalculating liquidity risk..."
                        color: text.includes("⚠️") ? "#FF0000" : "#00FF00" // Dynamic pure color
                        font.pixelSize: 13
                        font.weight: Font.Medium
                        wrapMode: Text.WordWrap
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter

                        // Animation for verdict changes
                        Behavior on opacity { NumberAnimation { duration: 200 } }
                    }
                }
            }

            // 4. ASSET TABLE
            ColumnLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 250
                Text { text: "EXISTING RETIREMENT ASSETS"; color: "#757575"; font.pixelSize: 10; font.letterSpacing: 1 }

                ListView {
                    id: assetView
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    model: retirementAssetModel
                    clip: true
                    header: RowLayout {
                        width: assetView.width; height: 30
                        Text { text: "ASSET"; color: "#444"; font.pixelSize: 10; Layout.preferredWidth: 200 }
                        Text { text: "TYPE"; color: "#444"; font.pixelSize: 10; Layout.preferredWidth: 100 }
                        Text { text: "VALUE"; color: "#444"; font.pixelSize: 10; Layout.fillWidth: true; horizontalAlignment: Text.AlignRight }
                    }
                    delegate: Rectangle {
                        width: assetView.width; height: 45; color: "transparent"
                        border.color: "#121212"
                        RowLayout {
                            anchors.fill: parent; anchors.rightMargin: 10
                            Text {
                                text: model.name || ""; color: "white"; font.pixelSize: 14; Layout.preferredWidth: 200
                            }
                            Text {
                                text: model.type || ""; color: model.type === "LIQUID" ? "#00FF00" : "#FF0000"
                                font.pixelSize: 10; font.bold: true; Layout.preferredWidth: 100
                            }
                            Text {
                                text: root.currencySymbol + " " + (Number(model.value) || 0).toLocaleString(Qt.locale(), 'f', 0)
                                color: "white"; font.pixelSize: 14; Layout.fillWidth: true; horizontalAlignment: Text.AlignRight
                            }
                        }
                    }
                }
            }

            // 4. BRIDGE PHASE SUMMARY
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 10
                Text { text: "CORPUS ALLOCATION: BRIDGE VS TRADITIONAL"; color: "#757575"; font.pixelSize: 10 }
                RowLayout {
                    Layout.fillWidth: true; height: 12; spacing: 2
                    Rectangle { Layout.fillWidth: true; Layout.preferredWidth: 30; color: "#00FF00"; radius: 2 } // Bridge
                    Rectangle { Layout.fillWidth: true; Layout.preferredWidth: 70; color: "#121212"; radius: 2; border.color: "#2A2A2A" } // Trad
                }
                RowLayout {
                    Text { text: "Bridge (To Age 60)"; color: "#00FF00"; font.pixelSize: 9 }
                    Item { Layout.fillWidth: true }
                    Text { text: "Traditional (Post 60)"; color: "#757575"; font.pixelSize: 9 }
                }
            }
        }
    }

    // Custom Component for Sliders
    component RetireSlider : ColumnLayout {
        property string label: ""; property real value: 0; property real min: 0; property real max: 100
        signal moved(real val)
        RowLayout {
            Text { text: label; color: "#757575"; font.pixelSize: 10 }
            Item { Layout.fillWidth: true }
            Text { text: value.toFixed(0); color: "white"; font.bold: true; font.pixelSize: 12 }
        }
        Slider {
            id: control
            Layout.preferredHeight: 20
            Layout.fillWidth: true; from: min; to: max; value: parent.value
            onMoved: parent.moved(value)
            background: Rectangle {
                height: 4; color: "#2A2A2A"; radius: 2
                Rectangle { width: control.visualPosition * parent.width; height: parent.height; color: "#00FF00"; radius: 2 }
            }
            handle: Rectangle {
                width: 14; height: 14; radius: 7; color: "#00FF00"; border.width: 2
                x: control.leftPadding + control.visualPosition * (control.availableWidth - width)
                y: control.topPadding + control.availableHeight / 2 - height / 2
            }
        }
    }

    // Retirement Data Box
    component RetireValueBox : Rectangle {
        property alias text: label.text
        width: 60
        height: 40
        color: "#1A1A1A"
        radius: 8
        border.color: "#2A2A2A"

        Text {
            id: label
            anchors.centerIn: parent
            color: "#FFFFFF"
            font.pixelSize: 14
            font.weight: Font.DemiBold
        }
    }
}