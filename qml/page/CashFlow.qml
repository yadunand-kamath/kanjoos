import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtCharts

Rectangle {
    id: cashflowRoot
    color: "#121212"

    // properies
    readonly property real totalIncome: Number(income1.text) + Number(income2.text) + Number(income3.text) + Number(income4.text)
    readonly property real totalExpense: Number(expense1.text) + Number(expense2.text) + Number(expense3.text) + Number(expense4.text)
    readonly property real totalSurplus: totalIncome - totalExpense
    readonly property real savingsRate: totalIncome > 0 ? (totalSurplus / totalIncome) * 100 : 0
    property int currentQuoteIndex: 1

    // Determine Savings Rate color
    function getSavingsColor(rate) {
        if (totalSurplus <= 0) return "#F44336"; // Red for deficit
        if (rate <= 15) return "#FF9800";       // Orange for low savings
        if (rate <= 35) return "#FFEB3B";       // Yellow for decent savings
        return "#4CAF50";                       // Green for great savings
    }

    function getSummaryText() {
        if (totalIncome == 0 && totalExpense == 0) return "Enter your Income & Expenses";
        if (totalSurplus >= 0) return "Investable Surplus: " + root.currencySymbol + totalSurplus.toLocaleString(Qt.locale(), 'f', 0);
        if (totalSurplus < 0) return "Deficit: " + root.currencySymbol + totalSurplus.toLocaleString(Qt.locale(), 'f', 0);
    }

    // quotes
    property var quotes: [
        { text: "Saving is the gap between your ego and your income.", author: ""},
        { text: "Beware of little expenses. A small leak will sink a great ship.", author: "— Benjamin Franklin" },
        { text: "Do not save what is left after spending, but spend what is left after saving.", author: "— Warren Buffett" },
        { text: "The secret to getting rich is not in making more money, but in keeping more of the money you make.", author: "— John D. Rockefeller" }
    ]

    // Column to stack quote + cards
    ColumnLayout {
        anchors.fill: parent
        spacing: 10
        anchors.margins: 20

        // Clear Button
        Button {
            text: "Clear All"
            flat: true
            Layout.alignment: Qt.AlignHCenter
            onClicked: {
                income1.text = ''; income2.text = ''; income3.text = ''; income4.text = '';
                expense1.text = ''; expense2.text = ''; expense3.text = ''; expense4.text = '';
            }
        }

        // Cards Arrangement
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 20
            anchors.margins: 20

            // 1. Income Card
            Rectangle {
                id: incomeCard
                color: "#1a2e1a"
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                Layout.fillHeight: true
                radius: 10
                border.color: "#4CAF50" // green
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 15

                    // Heading
                    Text {
                        text: "INCOME"
                        color: "#4CAF50"; font.bold: true; font.pixelSize: 18
                        Layout.alignment: Qt.AlignHCenter
                        horizontalAlignment: Text.AlignHCenter
                        Layout.bottomMargin: 10
                    }

                    // Inputs
                    InputRow { id: income1; label: "Salary"; accentColor: "#4CAF50" }
                    InputRow { id: income2; label: "Business"; accentColor: "#4CAF50" }
                    InputRow { id: income3; label: "Rental"; accentColor: "#4CAF50" }
                    InputRow { id: income4; label: "Other"; accentColor: "#4CAF50" }

                    // Spacer
                    Item { Layout.fillHeight: true }

                    // Savings Rate Box
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.bottomMargin: 15
                        height: 50
                        color: "#111"
                        radius: 6
                        border.color: getSavingsColor(savingsRate)
                        border.width: 1
                        visible: totalIncome > 0

                        Column {
                            anchors.centerIn: parent
                            Text {
                                text: "SAVINGS RATE"
                                color: "#aaa"; font.pixelSize: 10; anchors.horizontalCenter: parent.horizontalCenter
                            }
                            Text {
                                text: savingsRate.toFixed(1) + "%"
                                color: getSavingsColor(savingsRate)
                                font.bold: true; font.pixelSize: 18; anchors.horizontalCenter: parent.horizontalCenter
                            }
                        }
                    }

                    // Total
                    Text {
                        text: "Total Income: " + root.currencySymbol + totalIncome.toLocaleString(Qt.locale(), 'f', 0)
                        color: "#4CAF50"; font.pixelSize: 22; font.bold: true
                        Layout.alignment: Qt.AlignHCenter
                    }
                }
            }

            // 2. Surplus Chart Card
            Rectangle {
                id: surplusCard
                color: "#252525"
                Layout.fillWidth: true
                Layout.preferredWidth: 2
                Layout.fillHeight: true
                radius: 10
                border.color: "#333333"
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 15

                    // Motivation text
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 80
                        spacing: 2

                        Text {
                            text: quotes[currentQuoteIndex].text
                            color: "white"; font.italic: true; font.pixelSize: 12
                            wrapMode: Text.WordWrap
                            horizontalAlignment: Text.AlignHCenter
                            Layout.fillWidth: true
                        }

                        Text {
                            text: quotes[currentQuoteIndex].author
                            color: "#666"; font.pixelSize: 10; Layout.alignment: Qt.AlignHCenter
                        }

                        Timer {
                            interval: 8000; running: true; repeat: true
                            onTriggered: currentQuoteIndex = (currentQuoteIndex + 1) % quotes.length
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        // Donut Pie Chart
                        ChartView {
                            anchors.fill: parent
                            backgroundColor: "transparent"
                            legend.alignment: Qt.AlignBottom
                            legend.labelColor: "white"
                            antialiasing: true

                            PieSeries {
                                id: pieSeries
                                holeSize: 0.5
                                size: 0.7

                                // Slice 1: Placeholder slice
                                PieSlice {
                                    id: emptySlice
                                    label: "No Data"
                                    value: (totalIncome + totalExpense === 0) ? 1 : 0
                                    Behavior on value {
                                        NumberAnimation { duration: 500; easing.type: Easing.OutCubic }
                                    }
                                    color: "#333333" // Dark gray
                                    labelVisible: false
                                }
                                // Slice 2: Expenses
                                PieSlice {
                                    label: "Expenses (" + (totalIncome > 0 ? ((totalExpense / totalIncome) * 100).toFixed(2) : "0.00") + "%) of Income"
                                    value: (totalIncome + totalExpense > 0) ? totalExpense : 0
                                    Behavior on value {
                                        NumberAnimation { duration: 500; easing.type: Easing.OutCubic }
                                    }
                                    color: "#F44336" // Red
                                    labelVisible: value > 0
                                    labelColor: "#aaaaaa"
                                }

                                // Slice 3: Savings
                                PieSlice {
                                    id: savingsSlice
                                    label: "Savings (" + (totalIncome > 0 && totalIncome >= totalExpense ? ((totalSurplus / totalIncome) * 100).toFixed(2) : "0.00") + "%) of Income"
                                    // If expenses exceed income, we show 0 for savings to keep the chart from breaking
                                    value: (totalIncome + totalExpense > 0) ? Math.max(0, totalSurplus) : 0
                                    Behavior on value {
                                        NumberAnimation { duration: 500; easing.type: Easing.OutCubic }
                                    }
                                    color: "#4CAF50" // Green
                                    labelVisible: value > 0
                                    labelColor: "#aaaaaa"
                                }
                            }
                        }

                        // Value inside donut hole
                        // Center Text inside donut hole
                        Column {
                            anchors.centerIn: parent
                            spacing: -2 // Tighten the gap between label and value

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                font.pixelSize: 24
                                font.bold: true
                                // Reuse the color logic function we created earlier
                                color: getSavingsColor(savingsRate)
                                text: {
                                    if (totalSurplus < 0) return "⚠️"
                                    return savingsRate.toFixed(0) + "%"
                                }
                            }
                        }
                    }

                    Text {
                        text: getSummaryText()
                        color: (totalIncome === 0 && totalExpense === 0) ? "#C0C0C0" : (totalSurplus > 0 ? "#4CAF50" : "#F44336")
                        font.pixelSize: 20
                        font.bold: true
                        Layout.alignment: Qt.AlignHCenter
                    }
                    Text {
                        visible: totalSurplus <= 0
                        text: "Reduce expenses to start investing"
                        color: "#666"
                        font.pixelSize: 11
                        Layout.alignment: Qt.AlignHCenter
                    }
                }
            }

            // 3. Expense Card
            Rectangle {
                id: expenseSheet
                color: "#2e1a1a"

                Layout.fillWidth: true
                Layout.preferredWidth: 1
                Layout.fillHeight: true
                radius: 10
                border.color: "#F44336"
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 15

                    // Heading
                    Text {
                        text: "EXPENSES"
                        color: "#F44336"; font.bold: true; font.pixelSize: 18
                        Layout.alignment: Qt.AlignHCenter
                        horizontalAlignment: Text.AlignHCenter
                        Layout.bottomMargin: 10
                    }

                    // Inputs
                    InputRow { id: expense1; label: "Survival"; placeholder: "Rent, Bills, Groceries"; accentColor: "#F44336" }
                    InputRow { id: expense2; label: "Lifestyle"; placeholder: "Shopping, Movies, Eating out"; accentColor: "#F44336" }
                    InputRow { id: expense3; label: "Obligations"; placeholder: "EMIs, Loans, Insurance premiums"; accentColor: "#F44336" }
                    InputRow { id: expense4; label: "Unplanned"; placeholder: "Other"; accentColor: "#F44336" }

                    // Spacer
                    Item { Layout.fillHeight: true }

                    // Deficit Warning Box
                    Rectangle {
                        visible: totalSurplus < 0
                        Layout.alignment: Qt.AlignHCenter
                        Layout.fillWidth: true
                        Layout.bottomMargin: 15
                        height: 60
                        color: "#111"
                        border.color: "#F44336"
                        border.width: 1
                        radius: 8

                        Column {
                            anchors.centerIn: parent
                            spacing: 4

                            // Small warning icon
                            Row {
                                anchors.horizontalCenter: parent.horizontalCenter
                                spacing: 8
                                Text { text: "⚠️"; font.pixelSize: 14 }
                                Text {
                                    text: "WARNING: DEFICIT"
                                    color: "#F44336"
                                    font.bold: true
                                    font.pixelSize: 14
                                }
                            }

                            Text {
                                text: "Spending exceeds Earnings! Be more kanjoos... 🤷"
                                color: "#ff8a80" // Lighter pinkish-red for better readability
                                font.pixelSize: 11
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                        }
                    }

                    // Total
                    Text {
                        text: "Total Expense: " + root.currencySymbol + totalExpense.toLocaleString(Qt.locale(), 'f', 0)
                        color: "#F44336"; font.pixelSize: 22; font.bold: true
                        Layout.alignment: Qt.AlignHCenter
                    }
                }
            }
        }
    }

    // Reusable component for input fields
    component InputRow : RowLayout {
        property alias text: input.text
        property string label: ""
        property string placeholder: ""
        property color accentColor: "#4CAF50" // Default to Green

        Text { text: label; color: "white"; Layout.preferredWidth: 80 }

        TextField {
            id: input
            placeholderText: (placeholder == "") ? "0" : placeholder
            color: "white"
            Layout.fillWidth: true
            inputMethodHints: Qt.ImhFormattedNumbersOnly // Opens number pad on mobile

            onTextEdited: {
                // Remove leading zeros using Regex: replace "0" at start with nothing
                // unless the whole string is just "0"
                if (text.length > 1 && text.startsWith("0") && !text.startsWith("0.")) {
                    text = text.replace(/^0+/, '');
                }
            }

            // Allow only numbers
            validator: DoubleValidator { bottom: 0 }

            background: Rectangle {
                color: "#333"
                radius: 4
                implicitHeight: 30
                // Change border color when the user clicks into the field
                border.color: input.activeFocus ? accentColor : "transparent"
                border.width: 1
            }
        }
    }
}