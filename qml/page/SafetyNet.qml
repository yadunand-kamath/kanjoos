import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: safetyNetRoot
    color: "#121212"

    // Emergeny Fund Properties
    property real currentSavings: parseFloat(savingsInput.text) || 0
    property int multiplierIndex: 0

    readonly property real activeSalary: multiplierIndex === 2 ? parseFloat(salaryInput.text) || 0 : root.globalMonthlyIncome
    readonly property real baseAmount: Math.max(activeSalary, root.globalMonthlyExpense)
    readonly property real activeMultiplier: multiplierIndex === 0 ? 6 : (multiplierIndex === 1 ? 12 : parseFloat(customInput.text) || 0)
    readonly property real targetAmount: baseAmount * activeMultiplier
    readonly property real progress: targetAmount > 0 ? Math.min(currentSavings / targetAmount, 1.0) : 0
    readonly property real runwayMonths: root.globalMonthlyExpense > 0 ? (currentSavings / root.globalMonthlyExpense) : 0

    // Insurance Properties
    property int currentCardIndex: 0
    property bool hasDependents: dependentCheck.checked
    property bool isInsuranceCorporate: corporateCheck.checked

    readonly property real totalInsurancePremium: {
        if (!healthPremium || !lifePremium || !assetModel) return 0;
        let health = parseFloat(healthPremium.monthlyText) || 0;
        let life = hasDependents ? (parseFloat(lifePremium.monthlyText) || 0) : 0;
        let assets = 0;
        for(let i=0; i<assetModel.count; i++)
            assets += parseFloat(assetModel.get(i).monthly || 0);
        return health + life + assets;
    }

    onTotalInsurancePremiumChanged: root.insuranceTotalFromSafety = totalInsurancePremium // Sync to main app

    ListModel {
        id: assetModel
        Component.onCompleted: append({"name": "", "monthly": "0", "annual": "0"}) // Start with one row
    }

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
                font.italic: true
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
                height: 40
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

            // -- PAGE 1: EMERGENCY FUND --
            Item {
                id: emergencyFundPage
                Layout.fillWidth: true
                Layout.fillHeight: true

                ColumnLayout {
                    anchors.centerIn: parent
                    width: parent.width * 0.8
                    spacing: 5 // whitespace between sections

                    // Savings Input
                    ColumnLayout {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.topMargin: 30
                        spacing: 10

                        Text { text: "HOW MUCH DO YOU HAVE SAVED TODAY?"; color: "#888"; font.pixelSize: 11; font.letterSpacing: 1; Layout.alignment: Qt.AlignHCenter }

                        TextField {
                            id: savingsInput
                            placeholderText: "0"
                            color: "white"
                            font.pixelSize: 30
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                            Layout.preferredWidth: 275
                            leftPadding: 40

                            validator: DoubleValidator { bottom: 0 }
                            onTextEdited: if (text.length > 1 && text.startsWith("0") && !text.startsWith("0.")) text = text.replace(/^0+/, '')

                            background: Rectangle {
                                color: "transparent"
                                border.color: savingsInput.activeFocus ? "#FFFFFF" : "#222"
                                border.width: 1
                                radius: 12
                                implicitHeight: 50
                                // Currency symbol in background
                                Text {
                                    text: root.currencySymbol; color: "#333"; font.pixelSize: 30; anchors.left: parent.left; anchors.leftMargin: 20; anchors.verticalCenter: parent.verticalCenter
                                }
                            }
                        }
                    }

                    // Hero Number
                    Column {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 0

                        // Container for the filling effect
                        Item {
                            id: heroContainer
                            width: dummyText.width
                            height: dummyText.height
                            anchors.horizontalCenter: parent.horizontalCenter

                            Text {
                                id: dummyText
                                text: (isNaN(progress) ? "0.0" : (progress * 100).toFixed(1)) + "%"
                                font.pixelSize: 95
                                font.bold: true
                                visible: false
                            }
                            // Base Layer: Dull Gray (Empty State)
                            Text {
                                text: dummyText.text
                                font: dummyText.font
                                color: (progress * 100 < 0.1) ? "#990000" : "#7D7D7D" // Dull gray for the "empty" part
                            }
                            // Fill Layer: Green (Controlled by progress)
                            Item {
                                width: parent.width
                                height: parent.height * progress // Height grows based on %
                                anchors.bottom: parent.bottom
                                clip: true // This creates the "fill" look

                                // Delight: Smoothly animate the "filling" height
                                Behavior on height { NumberAnimation { duration: 1000; easing.type: Easing.OutExpo } }

                                Text {
                                    text: dummyText.text
                                    font: dummyText.font
                                    color: "#4CAF50"
                                    anchors.bottom: parent.bottom // Keep text aligned to bottom
                                }
                            }
                        }

                        Text {
                            text: "OF YOUR FUND SECURED"
                            font.pixelSize: 14
                            font.weight: Font.DemiBold;
                            font.letterSpacing: 4
                            color: "#888"
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                    }

                    // SETTINGS DRAWER
                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.topMargin: 20
                        Layout.bottomMargin: 10
                        spacing: 20

                        // Multipliers
                        Row {
                            spacing: 5
                            Repeater {
                                model: ["6x", "12x", "Custom"]
                                Button {
                                    text: modelData
                                    flat: true
                                    implicitWidth: 70
                                    palette.buttonText: multiplierIndex === index ? "#ECEFF1" : "#555"
                                    font.bold: multiplierIndex === index
                                    onClicked: multiplierIndex = index

                                    background: Rectangle {
                                        color: multiplierIndex === index ? "#252525" : "transparent"
                                        border.color: multiplierIndex === index ? "#ECEFF1" : "transparent"
                                        radius: 6; border.width: 1
                                    }
                                }
                            }
                        }

                        // Custom Inputs
                        RowLayout {
                            visible: multiplierIndex === 2
                            spacing: 12

                            TextField {
                                id: customInput; text: "15"
                                Layout.preferredWidth: 65; font.pixelSize: 13; horizontalAlignment: Text.AlignLeft
                                leftPadding: 10; rightPadding: 22

                                validator: DoubleValidator { bottom: 1 }
                                onTextEdited: text = text.replace(/^0+/, '')

                                background: Rectangle {
                                    color: "#111"; radius: 4; implicitHeight: 36
                                    border.color: customInput.activeFocus ? "#FFFFFF" : "#333"; border.width: 1

                                    Text {
                                        text: "x"; color: "#666";
                                        anchors.right: parent.right; anchors.rightMargin: 8; anchors.verticalCenter: parent.verticalCenter
                                    }
                                }
                            }
                            TextField {
                                id: salaryInput; text: root.globalMonthlyIncome.toString()
                                Layout.preferredWidth: 110; leftPadding: 25;
                                color: "white"; font.pixelSize: 13; horizontalAlignment: Text.AlignLeft

                                validator: DoubleValidator { bottom: 0 }
                                onTextEdited: text = text.replace(/^0+/, '')

                                background: Rectangle {
                                    color: "#111"; radius: 4; implicitHeight: 36
                                    border.color: salaryInput.activeFocus ? "#FFFFFF" : "#333"; border.width: 1
                                    // Currency symbol in custom income input
                                    Text {
                                        text: root.currencySymbol; color: "#666"
                                        anchors.left: parent.left; anchors.leftMargin: 8;
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                }
                            }
                        }
                    }

                    // PROGRESS BAR & STATS
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.topMargin: 20
                        spacing: 20

                        ProgressBar {
                            id: mainBar
                            value: progress
                            Layout.fillWidth: true
                            Layout.preferredHeight: 8
                            background: Rectangle { color: "#222"; radius: 4 }
                            contentItem: Item {
                                Rectangle {
                                    width: mainBar.visualPosition * parent.width
                                    height: 8; radius: 4; color: "#4CAF50"
                                    Behavior on width { NumberAnimation { duration: 1000; easing.type: Easing.OutExpo } }
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            // Target Stat
                            Column {
                                Text { text: "GOAL TARGET (Based on whichever is higher: Income or Expenses)"; color: "#AAA"; font.pixelSize: 10; font.weight: Font.Medium; font.letterSpacing: 1 }
                                Text {
                                    text: (targetAmount > 0) ? root.currencySymbol + targetAmount.toLocaleString(Qt.locale(), 'f', 0) : "Enter your Income in CashFlow or Custom"
                                    color: (targetAmount > 0) ? "#4CAF50" : "#555"
                                    font.pixelSize: 18
                                    font.bold: true
                                }
                            }
                            Item { Layout.fillWidth: true }
                            // Runway Stat
                            Column {
                                Layout.alignment: Qt.AlignRight
                                Text { text: "RUNWAY LEFT (Based on your Expenses)"; color: "#AAA"; font.pixelSize: 10; font.weight: Font.Medium; font.letterSpacing: 1; Layout.alignment: Qt.AlignRight }
                                Text {
                                    text: (runwayMonths > 0) ? runwayMonths.toFixed(1) + " Months" : "Enter your Expenses in CashFlow"
                                    color: (runwayMonths > 0) ? "#2196F3" : "#555"
                                    font.pixelSize: 18
                                    font.bold: true; Layout.alignment: Qt.AlignRight
                                }
                            }
                        }

                        // Button Layout
                        RowLayout {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 40
                            Layout.alignment: Qt.AlignHCenter
                            spacing: 30

                            // ToDo: Save Button
                            Button {
                                id: saveBtn
                                text: "Save"
                                flat: true
                                Layout.alignment: Qt.AlignHCenter
                                palette.buttonText: "white"
                                hoverEnabled: true

                                onClicked: {
                                }

                                background: Rectangle {
                                    implicitWidth: 70
                                    implicitHeight: 22
                                    radius: 6
                                    color: saveBtn.hovered ? "#333" : "#222"

                                    // Smoothly transition the color change
                                    Behavior on color { ColorAnimation { duration: 150 } }

                                    border.width: 1
                                    border.color: saveBtn.hovered ? "white" : "transparent"
                                }
                            }

                            // Clear Button
                            Button {
                                id: clearBtn
                                text: "Clear"
                                flat: true
                                Layout.alignment: Qt.AlignHCenter
                                palette.buttonText: "white"
                                hoverEnabled: true

                                onClicked: { savingsInput.text = '' }

                                background: Rectangle {
                                    implicitWidth: 70
                                    implicitHeight: 22
                                    radius: 6
                                    color: clearBtn.hovered ? "#333" : "#222"

                                    // Smoothly transition the color change
                                    Behavior on color { ColorAnimation { duration: 150 } }

                                    border.width: 1
                                    border.color: clearBtn.hovered ? "white" : "transparent"
                                }
                            }
                        }
                    }
                }
            }

            // --- PAGE 2: INSURANCE ---
            Item {
                id: insurancePage
                Layout.fillWidth: true
                Layout.fillHeight: true

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 5

                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 20
                        Layout.topMargin: -20
                        Layout.bottomMargin: 10

                        // Dependents Check
                        CheckBox {
                            id: dependentCheck
                            text: "I have dependents (spouse, children, or parents)"
                            visible: currentCardIndex === 1
                            checked: false
                            anchors.centerIn: parent
                            scale: 0.7
                            contentItem: Text {
                                text: parent.text
                                font.pixelSize: 15
                                font.bold: parent.checked ? true : false
                                color: parent.checked ? "#E0E0E0" : "#777"
                                leftPadding: parent.indicator.width + parent.spacing
                                verticalAlignment: Text.AlignVCenter
                            }
                        }

                        // Corporate Insurance Check
                        CheckBox {
                            id: corporateCheck
                            text: "This is a Corporate/Group Health plan"
                            visible: currentCardIndex === 0
                            checked: false
                            anchors.centerIn: parent
                            scale: 0.7

                            contentItem: Text {
                                text: parent.text
                                font.pixelSize: 15
                                font.bold: parent.checked ? true : false
                                color: parent.checked ? "#E0E0E0" : "#777"
                                leftPadding: parent.indicator.width + parent.spacing
                                verticalAlignment: Text.AlignVCenter
                                Behavior on color { ColorAnimation { duration: 200 } }
                            }
                        }
                    }

                    // Carousel
                    RowLayout {
                        Layout.fillWidth: true; Layout.fillHeight: true; spacing: 10

                        // Left arrow
                        Button {
                            text: "❮"; flat: true; font.pixelSize: 30; palette.buttonText: "#444"
                            onClicked: currentCardIndex = (currentCardIndex > 0) ? currentCardIndex - 1 : 2
                        }

                        StackLayout {
                            id: insuranceStack; currentIndex: currentCardIndex
                            Layout.fillWidth: true; Layout.fillHeight: true
                            Layout.bottomMargin: 10

                            InsuranceBigCard {
                                title: "HEALTH INSURANCE"; accentColor: "#00E5FF"
                                description: "Essential financial protection from medical inflation."
                                ColumnLayout {
                                    Layout.fillWidth: true; spacing: 12; Layout.bottomMargin: 20
                                    Text { text: "REC. COVER: 10-15x Monthly Expenses"; color: "#4CAF50"; font.pixelSize: 10; Layout.alignment: Qt.AlignHCenter }
                                    InsuranceInput { id: healthCover; label: "Sum Insured"; symbol: root.currencySymbol; borderColor: "#00E5FF" }
                                    DualPremiumInput { id: healthPremium; label: "Premium"; symbol: root.currencySymbol; borderColor: "#00E5FF" }
                               }
                            }

                            InsuranceBigCard {
                                title: "LIFE INSURANCE"; accentColor: "#FFC400"
                                opacity: hasDependents ? 1.0 : 0.3
                                description: hasDependents ? "Protect your family's future." : "Generally not required without dependents."
                                ColumnLayout {
                                    Layout.fillWidth: true; spacing: 12; Layout.bottomMargin: 20
                                    Text { text: "REC. COVER: " + root.currencySymbol + (root.globalMonthlyIncome * 12 * 12).toLocaleString(Qt.locale(), 'f', 0); color: "#4CAF50"; font.pixelSize: 10; Layout.alignment: Qt.AlignHCenter }
                                    InsuranceInput { id: lifeCover; label: "Term Cover"; symbol: root.currencySymbol; enabled: hasDependents; borderColor: "#FFC400" }
                                    DualPremiumInput { id: lifePremium; label: "Premium"; symbol: root.currencySymbol; enabled: hasDependents; borderColor: "#FFC400" }
                                }
                            }

                            InsuranceBigCard {
                                title: "ASSET INSURANCE"; accentColor: "#FF9100"
                                description: "Protect your home and vehicles."
                                ColumnLayout {
                                    spacing: 5; Layout.fillHeight: true; Layout.fillWidth: true

                                    Button {
                                        id: addAssetBtn
                                        text: "+ Add Asset"
                                        flat: true
                                        Layout.alignment: Qt.AlignHCenter
                                        Layout.bottomMargin: 5
                                        palette.buttonText: hovered ? "white" : "#FF9100"
                                        hoverEnabled: true

                                        onClicked: assetModel.append({"name": "", "monthly": "0", "annual": "0"})

                                        background: Rectangle {
                                            implicitWidth: 100
                                            implicitHeight:25
                                            color: addAssetBtn.hovered ? "#333" : "transparent"
                                            radius: 8
                                            border.color: "#FF9100"
                                            border.width: addAssetBtn.hovered ? 1 : 0.5
                                            Behavior on opacity { NumberAnimation { duration: 150 } }
                                        }
                                    }

                                    ScrollView {
                                        id: assetScroll
                                        Layout.fillWidth: true; Layout.fillHeight: true; Layout.preferredHeight: 180; clip: true
                                        ScrollBar.vertical.policy: ScrollBar.AsNeeded

                                        ColumnLayout {
                                            width: assetScroll.availableWidth; Layout.topMargin: 5; spacing: 12
                                            Repeater {
                                                model: assetModel
                                                RowLayout {
                                                    Layout.fillWidth: true; spacing: 10
                                                    TextField {
                                                        placeholderText: "Home, Car, etc."; text: model.name; Layout.preferredWidth: 120; color: "white"
                                                        onTextChanged: assetModel.setProperty(index, "name", text)
                                                        background: Rectangle { color: "#111"; radius: 6; implicitHeight: 32 }
                                                    }
                                                    DualPremiumInput {
                                                        Layout.fillWidth: true; label: ""; symbol: root.currencySymbol;
                                                        borderColor: "#FF9100";
                                                        monthlyText: model.monthly
                                                        annualText: model.annual

                                                        onMonthlyUserEdited: (val) => assetModel.setProperty(index, "monthly", val)
                                                        onAnnualUserEdited: (val) => assetModel.setProperty(index, "annual", val)
                                                    }
                                                    Button { text: "×"; flat: true; palette.buttonText: "red"; onClicked: assetModel.remove(index); visible: assetModel.count > 1 }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        Button {
                            text: "❯"; flat: true; font.pixelSize: 30; palette.buttonText: "#444"
                            onClicked: currentCardIndex = (currentCardIndex < 2) ? currentCardIndex + 1 : 0
                        }
                    }

                    Item { Layout.fillHeight: true }

                    // Summary Bar
                    Rectangle {
                        Layout.fillWidth: true; Layout.preferredHeight: 65; color: "#1a1a1a"; radius: 12; border.color: "#333"
                        RowLayout {
                            anchors.fill: parent; anchors.margins: 10

                            // Sync with Tooltip
                            ColumnLayout {
                                spacing: 0
                                CheckBox {
                                    id: syncCheck
                                    text: "Sync to CashFlow"
                                    onClicked: root.syncInsuranceToCashflow = checked
                                    ToolTip.visible: hovered; ToolTip.text: "Adds total premium to 'Obligations' in CashFlow"

                                    indicator: Rectangle {
                                        implicitWidth: 16
                                        implicitHeight: 16
                                        x: syncCheck.leftPadding
                                        y: parent.height / 2 - height / 2
                                        radius: 3
                                        color: "#1a1a1a"
                                        border.color: syncCheck.checked ? "#4CAF50" : "#666"

                                        Rectangle {
                                            width: 10
                                            height: 10
                                            x: 3
                                            y: 3
                                            radius: 2
                                            color: "#4CAF50"
                                            visible: syncCheck.checked
                                        }
                                    }
                                    contentItem: Text {
                                        text: parent.text; font.pixelSize: 13; leftPadding: 25
                                        color: parent.checked ? "#4CAF50" : "#666"
                                    }
                                }
                            }

                            Item { Layout.fillWidth: true }

                            // Center Insight Text
                            Text {
                                visible: currentCardIndex === 0 && !corporateCheck.checked
                                text: "Ensure parents & children are included"
                                color: "#2196F3"; font.pixelSize: 14; font.bold: true
                                Layout.alignment: Qt.AlignHCenter
                            }

                            Text {
                                visible: currentCardIndex === 1
                                text: "Choose pure Term plans only. Avoid ULIPs."
                                color: "#2196F3"; font.pixelSize: 14; font.bold: true
                                Layout.alignment: Qt.AlignHCenter
                            }

                            Text {
                                visible: currentCardIndex === 2
                                text: "Don't over-insure depreciating assets"
                                color: "#2196F3"; font.pixelSize: 14; font.bold: true
                                Layout.alignment: Qt.AlignHCenter
                            }

                            // Corporate Insurance WARNING
                            Text {
                                visible: corporateCheck.checked && currentCardIndex === 0
                                text: "⚠️ Corporate cover is lost if you change jobs or get fired. Consider a personal base plan."
                                color: "#F44336"
                                font.pixelSize: 14
                                font.bold: true
                                Layout.alignment: Qt.AlignHCenter
                                opacity: visible ? 1 : 0
                                Behavior on opacity { NumberAnimation { duration: 300 } }
                            }

                            Item { Layout.fillWidth: true }

                            Column {
                                Layout.alignment: Qt.AlignRight
                                Text { text: "TOTAL MONTHLY PREMIUM"; color: "#666"; font.pixelSize: 10; Layout.alignment: Qt.AlignRight }
                                Text { text: root.currencySymbol + totalInsurancePremium.toLocaleString(Qt.locale(), 'f', 0); color: "white"; font.pixelSize: 22; font.bold: true }
                            }
                        }
                    }
                }
            }

            Rectangle { color: "transparent"; Text { text: "Retirement Calculator Goes Here"; color: "#333"; anchors.centerIn: parent } }
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

    // Reusable Big Card
    component InsuranceBigCard : Rectangle {
        property string title: ""
        property string icon: ""
        property string description: ""
        property color accentColor: "white"
        default property alias content: cardContent.data

        color: "#161616"; radius: 20; border.color: "#222"
        Layout.fillWidth: true
        Layout.fillHeight: true

        ColumnLayout {
            anchors.fill: parent; anchors.margins: 25; spacing: 12

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 15
                Text { text: icon; font.pixelSize: 32 }
                Text {
                    text: title
                    color: accentColor
                    font.bold: true
                    font.pixelSize: 18
                    font.letterSpacing: 2
               }
            }
            Text {
                text: description
                color: "#888"; font.pixelSize: 13
                Layout.preferredWidth: parent.width * 0.8
                horizontalAlignment: Text.AlignHCenter
                Layout.alignment: Qt.AlignHCenter
                wrapMode: Text.WordWrap
            }
            Rectangle { Layout.fillWidth: true; height: 1; color: "#222" }
            ColumnLayout { id: cardContent; Layout.fillWidth: true; spacing: 10 }
            Item { Layout.fillHeight: true }
        }
    }

    // Reusable Insurance Input
    component InsuranceInput : ColumnLayout {
        property string label: ""; property string symbol: ""
        property alias text: field.text; property color borderColor: "#FFFFFF"
        spacing: 2
        Text { text: label; color: "#888"; font.pixelSize: 11 }
        TextField {
            id: field; placeholderText: "0"
            color: "white"; font.bold: true; font.pixelSize: 16
            Layout.fillWidth: true; leftPadding: 30
            validator: DoubleValidator { bottom: 0 }
            onTextEdited: if (text.length > 1 && text.startsWith("0") && !text.startsWith("0.")) text = text.replace(/^0+/, '')
            background: Rectangle {
                color: "#222"; radius: 8; implicitHeight: 38
                border.color: field.activeFocus ? borderColor : "transparent"
                Text { text: symbol; color: "#555"; anchors.left: parent.left; anchors.leftMargin: 10; anchors.verticalCenter: parent.verticalCenter }
            }
        }
    }

    component DualPremiumInput : ColumnLayout {
        property string label: ""; property string symbol: ""; property color borderColor: "#4CAF50"
        property alias monthlyText: mField.text
        property alias annualText: aField.text

        signal monthlyUserEdited(string val)
        signal annualUserEdited(string val)

        spacing: 4
        Text { text: label; color: "#888"; font.pixelSize: 11; visible: label !== "" }
        RowLayout {
            spacing: 10
            // Monthly input
            TextField {
                id: mField; placeholderText: "Monthly"; color: "white"; font.bold: true; Layout.fillWidth: true; leftPadding: 38
                onTextEdited: {
                    let val = (parseFloat(text) * 12 || 0).toFixed(0)
                    aField.text = val
                    // Notify parent that the user changed the monthly value
                    monthlyUserEdited(text)
                    annualUserEdited(val)
                }
                background: Rectangle { color: "#222"; radius: 6; implicitHeight: 34; border.color: mField.activeFocus ? borderColor : "transparent"
                    Row {
                        anchors.left: parent.left; anchors.leftMargin: 8; anchors.verticalCenter: parent.verticalCenter
                        spacing: 4
                        Text {
                            text: "M"; color: "#444"
                            font.pixelSize: 9; font.bold: true
                            anchors.verticalCenter: parent.verticalCenter

                        }
                        Text {
                            text: root.currencySymbol; color: "#666"
                            font.pixelSize: 13; font.bold: true
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }
            }
            TextField {
                id: aField; placeholderText: "Annual"; color: "white"; font.bold: true; Layout.fillWidth: true; leftPadding: 38
                onTextEdited: {
                    let val = (parseFloat(text) / 12 || 0).toFixed(0)
                    mField.text = val
                    // Notify parent that the user changed the annual value
                    annualUserEdited(text)
                    monthlyUserEdited(val)
                }
                background: Rectangle { color: "#222"; radius: 6; implicitHeight: 34; border.color: aField.activeFocus ? borderColor : "transparent"
                    Row {
                        anchors.left: parent.left; anchors.leftMargin: 8; anchors.verticalCenter: parent.verticalCenter
                        spacing: 4
                        Text {
                            text: "A"; color: "#444"
                            anchors.verticalCenter: parent.verticalCenter
                            font.pixelSize: 9; font.bold: true
                        }
                        Text {
                            text: root.currencySymbol; color: "#666"
                            font.pixelSize: 13; font.bold: true
                            anchors.verticalCenter: parent.verticalCenter
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