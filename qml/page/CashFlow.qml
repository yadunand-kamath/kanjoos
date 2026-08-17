import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtCharts

import "../components"

Rectangle {
    id: cashflowRoot
    color: "#121212"

    // ── DATA MODELS ───────────────────────────────────────────────────────────
    // Each row has a label, placeholder hint, and a live amount.
    // 4 fixed rows per card; up to 2 extras via "+ Add Category".

    ListModel {
        id: incomeModel
        ListElement { label: "Salary";   placeholder: "0"; amount: 0 }
        ListElement { label: "Business"; placeholder: "0"; amount: 0 }
        ListElement { label: "Rental";   placeholder: "0"; amount: 0 }
        ListElement { label: "Other";    placeholder: "0"; amount: 0 }
    }

    ListModel {
        id: expenseModel
        ListElement { label: "Survival";    placeholder: "Rent, Bills, Groceries";   amount: 0 }
        ListElement { label: "Lifestyle";   placeholder: "Shopping, Movies, Dining"; amount: 0 }
        ListElement { label: "Obligations"; placeholder: "EMIs, Loans, Insurance";   amount: 0 }
        ListElement { label: "Unplanned";   placeholder: "Other";                    amount: 0 }
    }

    // ── COMPUTED TOTALS ───────────────────────────────────────────────────────
    // Iterating the model keeps the totals in sync with dynamic rows and the
    // insurance sync from the Safety Net page.

    readonly property real totalIncome: {
        let t = 0;
        for (let i = 0; i < incomeModel.count; i++) t += incomeModel.get(i).amount;
        return t;
    }

    readonly property real totalExpense: {
        let t = 0;
        for (let i = 0; i < expenseModel.count; i++) t += expenseModel.get(i).amount;
        // Insurance premiums synced from Safety Net → Insurance Tracker
        let syncedAddon = root.syncInsuranceToCashflow ? root.insuranceTotalFromSafety : 0;
        return t + syncedAddon;
    }

    readonly property real totalSurplus: totalIncome - totalExpense
    readonly property real savingsRate:  totalIncome > 0 ? (totalSurplus / totalIncome) * 100 : 0

    // ── LAST UPDATED TIMESTAMP ────────────────────────────────────────────────
    // Stamped when the user clicks Save. Will be persisted in a future release.

    property string lastUpdated: ""

    // ── ANIMATED DISPLAY TOTALS ───────────────────────────────────────────────
    // Separate animated properties so the card totals count up smoothly on
    // each keystroke rather than snapping.

    readonly property int animDuration: 400
    property real animatedIncome:  0
    property real animatedExpense: 0

    Behavior on animatedIncome  { NumberAnimation { duration: animDuration; easing.type: Easing.OutCubic } }
    Behavior on animatedExpense { NumberAnimation { duration: animDuration; easing.type: Easing.OutCubic } }

    onTotalIncomeChanged:  animatedIncome  = totalIncome
    onTotalExpenseChanged: animatedExpense = totalExpense

    // ── HELPER FUNCTIONS ──────────────────────────────────────────────────────

    // Returns a colour based on savings rate health.
    function getSavingsColor(rate) {
        if (totalSurplus <= 0) return "#F44336"; // deficit → red
        if (rate <= 15)        return "#FF9800"; // low     → orange
        if (rate <= 35)        return "#FFEB3B"; // decent  → yellow
        return "#4CAF50";                        // great   → green
    }

    // One-line summary shown in the centre card.
    function getSummaryText() {
        if (totalIncome === 0 && totalExpense === 0)
            return "Enter your Monthly Income & Expenses";
        if (totalSurplus >= 0)
            return "Investable Surplus: " + root.currencySymbol + totalSurplus.toLocaleString(Qt.locale(), 'f', 0);
        else
            return "Deficit: " + root.currencySymbol + Math.abs(totalSurplus).toLocaleString(Qt.locale(), 'f', 0);
    }

    // ── ROTATING QUOTES ───────────────────────────────────────────────────────
    // Two timers: the outer one fades the text out; the inner one advances the
    // index and fades back in, preventing a hard text swap mid-fade.

    property int  currentQuoteIndex: 0
    property real quoteOpacity: 1.0

    property var quotes: [
        { text: "Saving is the gap between your ego and your income.",                                                   author: "" },
        { text: "Beware of little expenses. A small leak will sink a great ship.",                                       author: "— Benjamin Franklin" },
        { text: "Do not save what is left after spending, but spend what is left after saving.",                         author: "— Warren Buffett" },
        { text: "The secret to getting rich is not in making more money, but in keeping more of the money you make.",    author: "— John D. Rockefeller" }
    ]

    Timer {
        interval: 8000; running: true; repeat: true
        onTriggered: { quoteOpacity = 0; quoteAdvanceTimer.start(); }
    }

    Timer {
        id: quoteAdvanceTimer
        interval: 300; repeat: false
        onTriggered: { currentQuoteIndex = (currentQuoteIndex + 1) % quotes.length; quoteOpacity = 1; }
    }

    // ── INPUT ROW COMPONENT ───────────────────────────────────────────────────
    // Shared by both income and expense cards. Emits amountChanged so the
    // parent can write back into the ListModel without coupling to field ids.
    // removable: true shows a × button; only extra (index ≥ 4) rows use it.

    component InputRow : RowLayout {
        id: inputRowRoot

        property string label:       ""
        property string placeholder: ""
        property color  accentColor: "#4CAF50"
        property string symbol:      root.currencySymbol
        property bool   removable:   false

        property real value: 0
        onValueChanged: {
            if (value === 0 && input.text !== "") input.text = "";
        }

        signal amountChanged(real value)
        signal removeRequested()

        // Label column — fixed width so all fields line up
        Text {
            text: label
            color: "#aaa"; font.pixelSize: 13
            Layout.preferredWidth: 80
            elide: Text.ElideRight
        }

        // Number input with ₹ prefix overlay
        TextField {
            id: input
            placeholderText: placeholder !== "" ? placeholder : "0"
            color: "white"
            Layout.fillWidth: true
            leftPadding: 28
            inputMethodHints: Qt.ImhFormattedNumbersOnly

            onTextEdited: {
                // Strip leading zeros while preserving valid decimals (e.g. "0.5").
                // Cursor position is restored so the caret doesn't jump to the end.
                let pos      = cursorPosition;
                let stripped = text.replace(/^0+(\d)/, '$1');
                if (stripped !== text) {
                    let removed      = text.length - stripped.length;
                    text             = stripped;
                    cursorPosition   = Math.max(0, pos - removed);
                }
                inputRowRoot.amountChanged(Number(text) || 0);
            }

            validator: DoubleValidator { bottom: 0; notation: DoubleValidator.StandardNotation }

            background: Rectangle {
                color: "#222"; radius: 8; implicitHeight: 35
                border.color: input.activeFocus ? accentColor : "transparent"
                border.width: 1
            }

            // Currency symbol overlay — purely visual, not part of the value
            Text {
                text: symbol; color: "#666"; font.pixelSize: 14
                anchors.left: parent.left; anchors.leftMargin: 10
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        // × remove button — only visible on dynamically added rows
        Rectangle {
            visible: removable
            width: 22; height: 22; radius: 11
            color: removeArea.containsMouse ? "#3a1a1a" : "transparent"
            border.color: "#F44336"; border.width: 1
            Behavior on color { ColorAnimation { duration: 120 } }

            Text { text: "×"; color: "#F44336"; font.pixelSize: 16; anchors.centerIn: parent }

            MouseArea {
                id: removeArea
                anchors.fill: parent; hoverEnabled: true
                onClicked: inputRowRoot.removeRequested()
            }
        }

        // Convenience helpers used by the Clear button
        function clear()    { input.text = ""; inputRowRoot.amountChanged(0); }
        function getValue() { return Number(input.text) || 0; }
    }

    // ── MAIN LAYOUT ───────────────────────────────────────────────────────────

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 15
        anchors.bottomMargin: 30  // leave room for the timestamp label
        spacing: 10

        // ── CARDS ROW ─────────────────────────────────────────────────────────

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 20

            // ── 1. INCOME CARD ────────────────────────────────────────────────

            Rectangle {
                id: incomeCard
                color: "#1A2E1A"
                Layout.fillWidth: true; Layout.preferredWidth: 1; Layout.fillHeight: true
                radius: 10; border.color: "#4CAF50"; border.width: 1

                ColumnLayout {
                    anchors.fill: parent; anchors.margins: 15

                    Text {
                        text: "MONTHLY INCOME"
                        color: "#4CAF50"; font.bold: true; font.pixelSize: 18
                        Layout.alignment: Qt.AlignHCenter; Layout.bottomMargin: 10
                    }

                    // Income rows — driven by incomeModel
                    Repeater {
                        id: incomeRepeater
                        model: incomeModel
                        delegate: InputRow {
                            label:       model.label
                            placeholder: model.placeholder
                            accentColor: "#4CAF50"
                            removable:   index >= 4  // only extra rows are removable
                            Layout.fillWidth: true
                            value: model.amount
                            onAmountChanged:  (val) => { incomeModel.setProperty(index, "amount", val); }
                            onRemoveRequested: incomeModel.remove(index)
                        }
                    }

                    // Add Category button — hidden once the cap of 6 rows is reached
                    RowLayout {
                        visible: incomeModel.count < 6
                        Layout.fillWidth: true; Layout.topMargin: 4

                        Item { Layout.fillWidth: true }

                        Rectangle {
                            width: 110; height: 24; radius: 5
                            color: addIncomeArea.containsMouse ? "#1f3d1f" : "transparent"
                            border.color: "#4CAF50"; border.width: 1
                            Behavior on color { ColorAnimation { duration: 120 } }

                            Text { text: "+ Add Category"; color: "#4CAF50"; font.pixelSize: 11; anchors.centerIn: parent }

                            MouseArea {
                                id: addIncomeArea; anchors.fill: parent; hoverEnabled: true
                                onClicked: incomeModel.append({ label: "Custom", placeholder: "0", amount: 0 })
                            }
                        }

                        Item { Layout.fillWidth: true }
                    }

                    Item { Layout.fillHeight: true }

                    // Savings rate summary box — hidden until there is income to show
                    Rectangle {
                        Layout.fillWidth: true; Layout.bottomMargin: 15; height: 50
                        color: "#111"; radius: 6
                        border.color: getSavingsColor(savingsRate); border.width: 1
                        visible: totalIncome > 0

                        Column {
                            anchors.centerIn: parent
                            Text {
                                text: "SAVINGS RATE"; color: "#AAA"; font.pixelSize: 10
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                            Text {
                                text: savingsRate.toFixed(1) + "%"
                                color: getSavingsColor(savingsRate); font.bold: true; font.pixelSize: 18
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                        }
                    }

                    Text {
                        text: "Total Income: " + root.currencySymbol + animatedIncome.toLocaleString(Qt.locale(), 'f', 0)
                        color: "#4CAF50"; font.pixelSize: 22; font.bold: true
                        Layout.alignment: Qt.AlignHCenter
                    }
                }
            }

            // ── 2. SURPLUS / CHART CARD ───────────────────────────────────────

            Rectangle {
                id: surplusCard
                color: "#252525"
                Layout.fillWidth: true; Layout.preferredWidth: 2; Layout.fillHeight: true
                radius: 10; border.color: "#333333"; border.width: 1

                ColumnLayout {
                    anchors.fill: parent; anchors.margins: 15

                    // Rotating motivational quote with cross-fade
                    ColumnLayout {
                        Layout.fillWidth: true; Layout.preferredHeight: 80; Layout.bottomMargin: 20
                        spacing: 2

                        Text {
                            text: quotes[currentQuoteIndex].text
                            color: "white"; font.italic: true; font.pixelSize: 12
                            wrapMode: Text.WordWrap; horizontalAlignment: Text.AlignHCenter
                            Layout.fillWidth: true
                            opacity: quoteOpacity
                            Behavior on opacity { NumberAnimation { duration: 300 } }
                        }

                        Text {
                            text: quotes[currentQuoteIndex].author
                            color: "#666"; font.pixelSize: 10; Layout.alignment: Qt.AlignHCenter
                            opacity: quoteOpacity
                            Behavior on opacity { NumberAnimation { duration: 300 } }
                        }

                        Rectangle { color: "silver"; Layout.fillWidth: true; implicitHeight: 1; Layout.topMargin: 10 }
                    }

                    // Surplus / deficit headline
                    Text {
                        text: getSummaryText()
                        color: (totalIncome === 0 && totalExpense === 0) ? "#C0C0C0" : getSavingsColor(savingsRate)
                        font.pixelSize: 22; font.bold: true
                        Layout.alignment: Qt.AlignHCenter
                    }

                    // Donut chart — expenses vs savings as share of income
                    Item {
                        Layout.fillWidth: true; Layout.fillHeight: true

                        ChartView {
                            anchors.fill: parent
                            backgroundColor: "transparent"
                            legend.alignment: Qt.AlignBottom; legend.labelColor: "#AAAAAA"
                            antialiasing: true

                            PieSeries {
                                id: pieSeries
                                holeSize: 0.35; size: 0.6

                                // Placeholder shown when both totals are zero
                                PieSlice {
                                    label: "No Data"
                                    value: (totalIncome + totalExpense === 0) ? 1 : 0
                                    Behavior on value { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
                                    color: "#333333"; labelVisible: false
                                }

                                // Expense slice — shows true % even above 100% in deficit
                                PieSlice {
                                    label: "Expenses (" + (totalIncome > 0 ? ((totalExpense / totalIncome) * 100).toFixed(1) : "0.0") + "%) of Income"
                                    value: (totalIncome + totalExpense > 0) ? totalExpense : 0
                                    Behavior on value { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
                                    color: "#F44336"; labelVisible: value > 0; labelColor: "#AAAAAA"
                                }

                                // Savings slice — clamped to 0 in deficit so the donut doesn't wrap
                                PieSlice {
                                    label: "Savings (" + (totalIncome > 0 && totalSurplus > 0 ? ((totalSurplus / totalIncome) * 100).toFixed(1) : "0.0") + "%) of Income"
                                    value: (totalIncome + totalExpense > 0) ? Math.max(0, totalSurplus) : 0
                                    Behavior on value { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
                                    color: "#4CAF50"; labelVisible: value > 0; labelColor: "#AAAAAA"
                                }
                            }
                        }
                    }

                    // Nudge shown only when there is a deficit
                    Text {
                        visible: totalSurplus <= 0 && totalExpense > 0
                        text: "Reduce expenses to start investing"
                        color: "#2196F3"; font.pixelSize: 17; font.bold: true
                        Layout.alignment: Qt.AlignHCenter; Layout.bottomMargin: 5
                    }
                }
            }

            // ── 3. EXPENSE CARD ───────────────────────────────────────────────

            Rectangle {
                id: expenseCard
                color: "#2E1A1A"
                Layout.fillWidth: true; Layout.preferredWidth: 1; Layout.fillHeight: true
                radius: 10; border.color: "#F44336"; border.width: 1

                ColumnLayout {
                    anchors.fill: parent; anchors.margins: 15

                    Text {
                        text: "MONTHLY EXPENSES"
                        color: "#F44336"; font.bold: true; font.pixelSize: 18
                        Layout.alignment: Qt.AlignHCenter; Layout.bottomMargin: 10
                    }

                    // Expense rows — driven by expenseModel
                    Repeater {
                        id: expenseRepeater
                        model: expenseModel
                        delegate: InputRow {
                            label:       model.label
                            placeholder: model.placeholder
                            accentColor: "#F44336"
                            removable:   index >= 4
                            Layout.fillWidth: true
                            value: model.amount
                            onAmountChanged:   (val) => { expenseModel.setProperty(index, "amount", val); }
                            onRemoveRequested: expenseModel.remove(index)
                        }
                    }

                    // Add Category button — hidden once the cap of 6 rows is reached
                    RowLayout {
                        visible: expenseModel.count < 6
                        Layout.fillWidth: true; Layout.topMargin: 4

                        Item { Layout.fillWidth: true }

                        Rectangle {
                            width: 110; height: 24; radius: 5
                            color: addExpenseArea.containsMouse ? "#3d1f1f" : "transparent"
                            border.color: "#F44336"; border.width: 1
                            Behavior on color { ColorAnimation { duration: 120 } }

                            Text { text: "+ Add Category"; color: "#F44336"; font.pixelSize: 11; anchors.centerIn: parent }

                            MouseArea {
                                id: addExpenseArea; anchors.fill: parent; hoverEnabled: true
                                onClicked: expenseModel.append({ label: "Custom", placeholder: "0", amount: 0 })
                            }
                        }

                        Item { Layout.fillWidth: true }
                    }

                    // Insurance sync badge — visible only when the Safety Net sync is active
                    Rectangle {
                        Layout.fillWidth: true; Layout.preferredHeight: 32
                        Layout.topMargin: 5; Layout.bottomMargin: 5
                        color: "#1a00e5ff"; radius: 6
                        border.color: "#00E5FF"; border.width: 1
                        visible: root.syncInsuranceToCashflow && root.insuranceTotalFromSafety > 0

                        RowLayout {
                            anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 12

                            Text {
                                text: "🛡️ " + root.currencySymbol + root.insuranceTotalFromSafety.toLocaleString(Qt.locale(), 'f', 0)
                                color: "#00E5FF"; font.pixelSize: 11; font.bold: true
                                verticalAlignment: Text.AlignVCenter
                            }
                            Item { Layout.fillWidth: true }
                            Text {
                                text: "Synced from Insurance"
                                color: "#00E5FF"; font.pixelSize: 10; font.italic: true; opacity: 0.8
                            }
                        }
                    }

                    Item { Layout.fillHeight: true }

                    // Deficit warning — uses opacity as the source of truth so the
                    // fade-out Behavior actually fires (visible:false skips animation).
                    Rectangle {
                        id: deficitBox
                        opacity: totalSurplus < 0 ? 1 : 0
                        visible: opacity > 0
                        Behavior on opacity { NumberAnimation { duration: 250 } }
                        Layout.fillWidth: true; Layout.bottomMargin: 15; height: 60
                        color: "#111"; border.color: "#F44336"; border.width: 1; radius: 8

                        Column {
                            anchors.centerIn: parent; spacing: 4

                            Row {
                                anchors.horizontalCenter: parent.horizontalCenter; spacing: 8
                                Text { text: "⚠️"; font.pixelSize: 14 }
                                Text { text: "WARNING: DEFICIT"; color: "#F44336"; font.bold: true; font.pixelSize: 14 }
                            }

                            Text {
                                text: "Your Spendings exceed your Earnings!"
                                color: "#FF8A80"; font.pixelSize: 11
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                        }
                    }

                    Text {
                        text: "Total Expense: " + root.currencySymbol + animatedExpense.toLocaleString(Qt.locale(), 'f', 0)
                        color: "#F44336"; font.pixelSize: 22; font.bold: true
                        Layout.alignment: Qt.AlignHCenter
                    }
                }
            }
        }

        // ── ACTION BUTTONS ────────────────────────────────────────────────────

        RowLayout {
            Layout.fillWidth: true; Layout.preferredHeight: 40
            Layout.alignment: Qt.AlignHCenter
            spacing: 30

            SaveButton {
                id: saveButton
                onClicked: {
                    // Stamp the timestamp; persistence will write this to disk later
                    cashflowRoot.lastUpdated = Qt.formatDateTime(new Date(), "dd MMM yyyy, hh:mm")
                }
            }

            ClearButton {
                id: clearButton
                onClicked: {
                    // Reset all amounts to 0 and remove any extra rows.
                    // Snapshot counts first — model mutation inside the loop changes .count.
                    var ic = incomeModel.count;
                    var ec = expenseModel.count;
                    for (var ii = 0; ii < ic; ii++) incomeModel.setProperty(ii,  "amount", 0);
                    for (var ei = 0; ei < ec; ei++) expenseModel.setProperty(ei, "amount", 0);
                    while (incomeModel.count  > 4) incomeModel.remove(incomeModel.count   - 1);
                    while (expenseModel.count > 4) expenseModel.remove(expenseModel.count - 1);
                }
            }
        }
    }

    // ── LAST UPDATED TIMESTAMP ────────────────────────────────────────────────
    // Anchored outside the ColumnLayout so it doesn't affect card sizing.

    Text {
        anchors.left:   parent.left
        anchors.bottom: parent.bottom
        anchors.margins: 10
        text:  cashflowRoot.lastUpdated !== ""
               ? "Last updated: " + cashflowRoot.lastUpdated
               : "Last updated: —"
        color: "#333"
        font.pixelSize: 10; font.italic: true
    }
}
