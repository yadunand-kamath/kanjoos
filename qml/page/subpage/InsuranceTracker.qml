import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: insurancePage
    Layout.fillWidth: true
    Layout.fillHeight: true

    // --- LOGIC PROPERTIES ---
    readonly property bool isReady: (typeof insuranceCalc !== "undefined" && insuranceCalc !== null)
    property int currentCardIndex: 0
    property bool isHealthCorporate: false
    property bool hasDependents: isReady ? insuranceCalc.hasDependents : true

    // Frequency state: 0 = Monthly, 1 = Annual
    property int healthFreq: 0
    property int lifeFreq: 0

    // Per-card Policy Vault storage (Health vs Life are tracked separately)
    property var healthPolicyVault: ({ policyNumber: "", nominee: "", tpaContact: "", docLocation: "" })
    property var lifePolicyVault: ({ policyNumber: "", nominee: "", tpaContact: "", docLocation: "" })

    readonly property real totalInsurancePremium: {
        if (!healthPremiumField || !lifePremiumField || !assetModel) return 0;

        let healthInput = (parseFloat(healthPremiumField.text) || 0) / (healthFreq === 1 ? 12 : 1);
        let lifeInput = hasDependents ? (parseFloat(lifePremiumField.text) || 0) / (lifeFreq === 1 ? 12 : 1) : 0;

        let assetInput = 0;
        for(let i=0; i < assetModel.count; i++) {
            let item = assetModel.get(i);
            let val = parseFloat(item.premium) || 0;
            assetInput += (item.freq === 1) ? (val / 12) : val;
        }
        return healthInput + lifeInput + assetInput;
    }

    onTotalInsurancePremiumChanged: { root.insuranceTotalFromSafety = totalInsurancePremium }

    readonly property real totalSumInsured: {
        if (!healthCover || !lifeCover || !assetModel) return 0;

        let healthInput = parseFloat(healthCover.text) || 0;
        let lifeInput = hasDependents ? (parseFloat(lifeCover.text) || 0) : 0;

        let assetInput = 0;
        for (let i = 0; i < assetModel.count; i++) {
            assetInput += parseFloat(assetModel.get(i).cover) || 0;
        }
        return healthInput + lifeInput + assetInput;
    }

    readonly property real lifeCoverGap: isReady && hasDependents ? (insuranceCalc.recommendedLifeCover - (parseFloat(lifeCover ? lifeCover.text : "0") || 0)) : 0

    ListModel {
        id: assetModel
        Component.onCompleted: {
            clear() // Ensure it starts fresh
            append({"name": "", "cover": "0", "premium": "0", "freq": 0})
        }
    }

    // --- MAIN LAYOUT ---
    ColumnLayout {
        anchors.fill: parent
        spacing: 20

        // CAROUSEL SECTION
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 10

            Button {
                text: "❮"; flat: true; font.pixelSize: 32
                Layout.alignment: Qt.AlignVCenter
                palette.buttonText: "#444"
                onClicked: currentCardIndex = (currentCardIndex > 0) ? currentCardIndex - 1 : 2
            }

            StackLayout {
                id: insuranceStack
                currentIndex: currentCardIndex
                Layout.fillWidth: true
                Layout.fillHeight: true

                // CARD 1: HEALTH
                InsuranceBigCard {
                    title: "HEALTH INSURANCE"; accentColor: "#00E5FF"
                    description: "Essential medical protection."

                    // Header Toggle
                    headerSlot: CheckBox {
                        id: corporateHealthCheck
                        text: "This is a Corporate Plan"
                        checked: isHealthCorporate
                        onClicked: isHealthCorporate = checked

                        padding: 0; topPadding: 0; bottomPadding: 0; leftPadding: 0; rightPadding: 0

                        indicator: Rectangle {
                            implicitWidth: 16
                            implicitHeight: 16
                            radius: 4
                            color: "#000"
                            border.color: parent.checked ? "#00E5FF" : "#999"

                            // Centering logic
                            anchors.verticalCenter: parent.verticalCenter

                            Rectangle {
                                anchors.centerIn: parent
                                width: 8; height: 8; radius: 2
                                color: "#00E5FF"
                                visible: corporateHealthCheck.checked
                            }
                        }

                        contentItem: Text {
                            text: parent.text
                            font.pixelSize: 11
                            color: parent.checked ? "#00E5FF" : "#999"

                            // Horizontal spacing: box width + gap
                            leftPadding: parent.indicator.width + 10

                            // Double-layer vertical centering
                            verticalAlignment: Text.AlignVCenter
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 15

                        InsuranceInput { id: healthCover; label: "Sum Insured"; symbol: root.currencySymbol; borderColor: "#00E5FF" }

                        FrequencyPremiumInput {
                            label: "Premium Amount"
                            fieldId: "healthPremiumField"; freqIndex: healthFreq
                            onFreqChanged: (idx) => healthFreq = idx
                        }

                        PolicyVaultButton { accent: "#00E5FF"; onClicked: policyPopup.openFor("health") }

                        Item { Layout.fillHeight: true }
                        Text { text: "RECOMMENDED COVER: 10-15x Monthly Expenses"; color: "#2196F3"; font.pixelSize: 11; font.bold: true; Layout.alignment: Qt.AlignHCenter }
                    }
                }

                // CARD 2: LIFE
                InsuranceBigCard {
                    title: "LIFE INSURANCE"; accentColor: "#FFC400"
                    opacity: hasDependents ? 1.0 : 0.4
                    description: "Securing family's future."

                    headerSlot: CheckBox {
                        id: dependentsCheck
                        text: "I have dependents"
                        checked: hasDependents
                        onClicked: {
                            if(isReady) {
                                insuranceCalc.hasDependents = checked
                            }
                        }

                        padding: 0; topPadding: 0; bottomPadding: 0; leftPadding: 0; rightPadding: 0

                        indicator: Rectangle {
                            implicitWidth: 16
                            implicitHeight: 16
                            radius: 4
                            color: "#000"
                            border.color: parent.checked ? "#FFC400" : "#999"

                            // Centering logic
                            anchors.verticalCenter: parent.verticalCenter

                            Rectangle {
                                anchors.centerIn: parent
                                width: 8; height: 8; radius: 2
                                color: "#FFC400"
                                visible: dependentsCheck.checked
                            }
                        }

                        contentItem: Text {
                            text: parent.text
                            font.pixelSize: 11
                            color: parent.checked ? "#FFC400" : "#999"

                            // Horizontal spacing: box width + gap
                            leftPadding: parent.indicator.width + 10

                            // Double-layer vertical centering
                            verticalAlignment: Text.AlignVCenter
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 15

                        InsuranceInput { id: lifeCover; label: "Term Cover"; symbol: root.currencySymbol; enabled: hasDependents; borderColor: "#FFC400" }

                        Text {
                            visible: hasDependents && lifeCover.text !== ""
                            text: lifeCoverGap > 0
                                  ? "Shortfall: " + root.currencySymbol + (lifeCoverGap/10000000).toFixed(2) + " Cr"
                                  : "Fully Covered ✓"
                            color: lifeCoverGap > 0 ? "#FF0000" : "#43e97b"
                            font.pixelSize: 11; font.bold: true
                        }

                        FrequencyPremiumInput {
                            label: "Premium Amount"
                            fieldId: "lifePremiumField"
                            freqIndex: lifeFreq
                            onFreqChanged: (idx) => lifeFreq = idx
                        }

                        PolicyVaultButton { accent: "#FFC400"; onClicked: policyPopup.openFor("life") }

                        Item { Layout.fillHeight: true }
                        Text {
                            text: "RECOMMENDED COVER: " + root.currencySymbol +
                                  (isReady ? (insuranceCalc.recommendedLifeCover/10000000).toFixed(2) : "0.00") + " Cr"
                            color: "#2196F3"; font.pixelSize: 11; font.bold: true; Layout.alignment: Qt.AlignHCenter
                        }
                        Text {
                            visible: isReady
                            text: insuranceCalc.lifeCoverDirective
                            color: "#666"; font.pixelSize: 10
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }
                }

                // --- CARD 3: ASSET INSURANCE ---
                InsuranceBigCard {
                    title: "ASSET INSURANCE"; accentColor: "#FF9100"
                    description: "Protection for your vehicles and property."

                    ColumnLayout {
                        Layout.fillWidth: true; Layout.fillHeight: true; spacing: 15

                        Button {
                            text: "+ Add New Asset"; flat: true; Layout.alignment: Qt.AlignHCenter
                            palette.buttonText: "#FF9100"
                            onClicked: assetModel.append({"name": "", "cover": "0", "premium": "0", "freq": 0})
                        }

                        ScrollView {
                            Layout.fillWidth: true; Layout.fillHeight: true; clip: true
                            ColumnLayout {
                                width: parent.width; spacing: 15 // Increased spacing for breathability

                                Repeater {
                                    model: assetModel
                                    RowLayout {
                                        id: assetRow
                                        Layout.fillWidth: true; spacing: 12
                                        readonly property int rowIdx: index

                                        // Asset Name
                                        ColumnLayout {
                                            spacing: 4; Layout.preferredWidth: 250
                                            Text { text: "ASSET NAME"; color: "#444"; font.pixelSize: 8 }
                                            TextField {
                                                placeholderText: "House/Car"; text: model.name; Layout.fillWidth: true
                                                color: "white"; font.pixelSize: 13
                                                background: Rectangle { color: "#111"; radius: 6; implicitHeight: 36; border.color: "#2A2A2A" }
                                                onTextEdited: assetModel.setProperty(rowIdx, "name", text)
                                            }
                                        }

                                        // Cover
                                        ColumnLayout {
                                            spacing: 4; Layout.fillWidth: true; Layout.preferredWidth: 250
                                            Text { text: "SUM INSURED"; color: "#444"; font.pixelSize: 8 }
                                            TextField {
                                                placeholderText: "0"; text: model.cover; Layout.fillWidth: true; leftPadding: 25
                                                color: "white"; font.pixelSize: 13
                                                background: Rectangle {
                                                    color: "#111"; radius: 6; implicitHeight: 36; border.color: "#2A2A2A"
                                                    Text { text: root.currencySymbol; color: "#444"; anchors.left: parent.left; anchors.leftMargin: 8; anchors.verticalCenter: parent.verticalCenter }
                                                }
                                                validator: DoubleValidator { bottom: 0 }
                                                // Clean leading zeros
                                                onTextEdited: {
                                                    if (text.length > 1 && text.startsWith("0") && !text.startsWith("0.")) {
                                                        text = text.replace(/^0+/, '');
                                                    }
                                                    assetModel.setProperty(rowIdx, "cover", text)
                                                }
                                            }
                                        }

                                        // Premium + Toggle
                                        ColumnLayout {
                                            spacing: 4; Layout.preferredWidth: 320
                                            Text { text: "PREMIUM AMOUNT"; color: "#444"; font.pixelSize: 8 }
                                            RowLayout {
                                                spacing: 8;
                                                TextField {
                                                    placeholderText: "0"; text: model.premium; Layout.fillWidth: true; leftPadding: 20
                                                    color: "white"; font.pixelSize: 13; font.bold: true
                                                    validator: DoubleValidator { bottom: 0 }

                                                    // Clean leading zeros
                                                    onTextEdited: {
                                                        if (text.length > 1 && text.startsWith("0") && !text.startsWith("0.")) {
                                                            text = text.replace(/^0+/, '');
                                                        }
                                                        assetModel.setProperty(rowIdx, "premium", text)
                                                    }
                                                    background: Rectangle {
                                                        color: "#111"; radius: 6; implicitHeight: 36; border.color: "#2A2A2A"
                                                        Text { text: root.currencySymbol; color: "#444"; anchors.left: parent.left; anchors.leftMargin: 6; anchors.verticalCenter: parent.verticalCenter }
                                                    }
                                                }
                                                FrequencyToggle {
                                                    currentIndex: model.freq
                                                    onChanged: (idx) => assetModel.setProperty(rowIdx, "freq", idx)
                                                }
                                            }
                                        }

                                        Button {
                                            text: "×"; flat: true; palette.buttonText: "#FF0000"
                                            Layout.alignment: Qt.AlignBottom; Layout.bottomMargin: 2
                                            onClicked: assetModel.remove(rowIdx); visible: assetModel.count > 1
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            Button {
                text: "❯"; flat: true; font.pixelSize: 32
                Layout.alignment: Qt.AlignVCenter
                palette.buttonText: "#444"
                onClicked: currentCardIndex = (currentCardIndex < 2) ? currentCardIndex + 1 : 0
            }
        }

        // CAROUSEL PAGE INDICATOR
        Row {
            Layout.alignment: Qt.AlignHCenter
            spacing: 8

            Repeater {
                model: 3
                Rectangle {
                    readonly property bool active: currentCardIndex === index
                    width: active ? 22 : 8; height: 8; radius: 4
                    color: active ? "#FFFFFF" : "#444"

                    Behavior on width { NumberAnimation { duration: 200 } }
                    Behavior on color { ColorAnimation { duration: 200 } }

                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: currentCardIndex = index }
                }
            }
        }

        // SUMMARY BAR
        Rectangle {
            Layout.fillWidth: true; Layout.preferredHeight: 70
            color: "#121212"; radius: 12; border.color: "#2A2A2A"
            RowLayout {
                anchors.fill: parent; anchors.margins: 20

                CheckBox {
                    id: syncCheck
                    text: "Sync to CashFlow";
                    checked: root.syncInsuranceToCashflow
                    onClicked: root.syncInsuranceToCashflow = checked

                    padding: 0; topPadding: 0; bottomPadding: 0; leftPadding: 0; rightPadding: 0

                    indicator: Rectangle {
                        implicitWidth: 18
                        implicitHeight: 18
                        radius: 4
                        color: "#000"
                        border.color: parent.checked ? "#4CAF50" : "#999"

                        // Centering logic
                        anchors.verticalCenter: parent.verticalCenter

                        Rectangle {
                            anchors.centerIn: parent
                            width: 8; height: 8; radius: 2
                            color: "#4CAF50"
                            visible: syncCheck.checked
                        }
                    }

                    contentItem: Text {
                        text: parent.text
                        font.pixelSize: 12
                        color: parent.checked ? "#4CAF50" : "#999"

                        // Horizontal spacing: box width + gap
                        leftPadding: parent.indicator.width + 10

                        // Double-layer vertical centering
                        verticalAlignment: Text.AlignVCenter
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                Item { Layout.fillWidth: true }

                ColumnLayout {
                    spacing: 2
                    Layout.alignment: Qt.AlignHCenter

                    Text {
                        text: currentCardIndex === 0 ? "Ensure dependents are covered." : (currentCardIndex === 1 ? "Avoid ULIPs." : "Insure high-value assets.")
                        color: "#999"; font.pixelSize: 12; font.bold: true; Layout.alignment: Qt.AlignHCenter
                    }

                    // CORPORATE WARNING
                    Text {
                        visible: isHealthCorporate && currentCardIndex === 0
                        text: "⚠️ Corporate cover ends on job exit. Getting a personal plan is highly recommended."
                        color: "#FF0000"; font.pixelSize: 12; font.bold: true; Layout.alignment: Qt.AlignHCenter

                        opacity: visible ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: 300 } }
                    }

                    Text {
                        visible: !hasDependents && currentCardIndex === 1
                        text: "Life Insurance is generally not required if you do not have dependents."
                        color: "#2196F3"; font.pixelSize: 12; font.bold: true; Layout.alignment: Qt.AlignHCenter

                        opacity: visible ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: 300 } }
                    }
                }
                Item { Layout.fillWidth: true }
                Column {
                    Layout.alignment: Qt.AlignRight
                    Text { text: "TOTAL SUM INSURED"; color: "#888"; font.pixelSize: 9; Layout.alignment: Qt.AlignRight }
                    Text { text: root.currencySymbol + " " + totalSumInsured.toLocaleString(Qt.locale(), 'f', 0); color: "#AAA"; font.pixelSize: 16; font.bold: true; Layout.alignment: Qt.AlignRight }
                }
                Item { Layout.preferredWidth: 30 }
                Column {
                    Layout.alignment: Qt.AlignRight
                    Text { text: "TOTAL MONTHLY PREMIUM"; color: "#888"; font.pixelSize: 9; Layout.alignment: Qt.AlignRight }
                    Text { text: root.currencySymbol + " " + totalInsurancePremium.toLocaleString(Qt.locale(), 'f', 0); color: "white"; font.pixelSize: 22; font.bold: true }
                }
            }
        }
    }

    // POLICY DETAILS POPUP
    Popup {
        id: policyPopup
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2
        width: 400
        height: 500
        modal: true
        focus: true
        dim: true
        Overlay.modal: Rectangle { color: "#80000000" }
        background: Rectangle { color: "#121212"; border.color: "#2A2A2A"; radius: 16 }

        property string activeCard: "health"
        readonly property color activeAccent: activeCard === "health" ? "#00E5FF" : "#FFC400"

        function openFor(cardKey) {
            activeCard = cardKey;
            let data = cardKey === "health" ? healthPolicyVault : lifePolicyVault;
            policyNumberField.text = data.policyNumber;
            nomineeField.text = data.nominee;
            tpaField.text = data.tpaContact;
            docField.text = data.docLocation;
            open();
        }

        function save() {
            let data = activeCard === "health" ? healthPolicyVault : lifePolicyVault;
            data.policyNumber = policyNumberField.text;
            data.nominee = nomineeField.text;
            data.tpaContact = tpaField.text;
            data.docLocation = docField.text;
            close();
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 25
            spacing: 20

            // CENTERED HEADING
            Text {
                text: (policyPopup.activeCard === "health" ? "🏥 Health" : "❤ Life") + " Policy Vault"
                color: "white"
                font.pixelSize: 18
                font.bold: true
                Layout.alignment: Qt.AlignHCenter // Center in Layout
                horizontalAlignment: Text.AlignHCenter
            }

            // FULL-WIDTH SCROLLABLE FIELDS
            ScrollView {
                id: vaultScroll
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                ColumnLayout {
                    // Critical: Width must be bound to ScrollView to allow children to fill
                    width: vaultScroll.availableWidth
                    spacing: 15

                    VaultField {
                        id: policyNumberField
                        label: "POLICY NUMBER"
                        placeholder: "e.g. HDFC-12345"
                        Layout.fillWidth: true
                    }
                    VaultField {
                        id: nomineeField
                        label: "NOMINEE NAME"
                        placeholder: "e.g. Spouse / Parent"
                        Layout.fillWidth: true
                    }
                    VaultField {
                        id: tpaField
                        label: "TPA / CLAIM CONTACT"
                        placeholder: "1800-XXX-XXXX"
                        Layout.fillWidth: true
                    }
                    VaultField {
                        id: docField
                        label: "DOCUMENT LOCATION"
                        placeholder: "e.g. Black folder, cupboard"
                        Layout.fillWidth: true
                    }
                }
            }

            Button {
                text: "Save & Close"
                Layout.fillWidth: true
                onClicked: policyPopup.save()
                background: Rectangle {
                    color: policyPopup.activeAccent
                    radius: 8
                    implicitHeight: 40
                }
                contentItem: Text {
                    text: "Save & Close"
                    color: "black"
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }
    }

    // --- REUSABLE CARD HELPERS ---
    property Component cardCheckIndicator: Rectangle {
        implicitWidth: 16; implicitHeight: 16; radius: 4; color: "#000"; border.color: "#333"
        Rectangle { anchors.centerIn: parent; width: 8; height: 8; radius: 2; color: "#00E5FF"; visible: parent.parent.checked }
    }
    property Component cardCheckLabel: Text {
        text: parent.text; font.pixelSize: 11; color: parent.checked ? "white" : "#666"; leftPadding: 22; verticalAlignment: Text.AlignVCenter
    }

    component InsuranceBigCard : Rectangle {
        property string title: ""; property string description: ""; property color accentColor: "white"
        property alias headerSlot: headerRight.data
        default property alias content: cardContent.data

        color: "#121212"; radius: 16; border.color: "#2A2A2A"; border.width: 1

        ColumnLayout {
            anchors.fill: parent; anchors.margins: 25; spacing: 12
            RowLayout {
                Layout.fillWidth: true
                Column {
                    Text { text: title; color: accentColor; font.bold: true; font.pixelSize: 16; font.letterSpacing: 1 }
                    Text { text: description; color: "#666"; font.pixelSize: 11 }
                }
                Item { Layout.fillWidth: true }
                RowLayout { id: headerRight } // Destination for the Checkbox
            }
            Rectangle { Layout.fillWidth: true; height: 1; color: "#2A2A2A" }
            ColumnLayout { id: cardContent; Layout.fillWidth: true; Layout.fillHeight: true; spacing: 15 }
        }
    }

    component InsuranceInput : ColumnLayout {
        property string label: ""
        property string symbol: ""
        property color borderColor: "#FFFFFF"
        property alias text: field.text

        spacing: 4

        Text {
            text: label
            color: "#757575"
            font.pixelSize: 10
            font.letterSpacing: 1
        }

        TextField {
            id: field
            placeholderText: "0"
            color: "white"
            font.bold: true
            font.pixelSize: 15
            Layout.fillWidth: true
            leftPadding: 35

            validator: DoubleValidator { bottom: 0 }

            // Clean leading zeros
            onTextEdited: {
                if (text.length > 1 && text.startsWith("0") && !text.startsWith("0.")) {
                    text = text.replace(/^0+/, '');
                }
            }

            background: Rectangle {
                color: "#000000"
                radius: 8
                implicitHeight: 38
                border.color: field.activeFocus ? borderColor : "#2A2A2A"
                border.width: 1

                // Static Currency Symbol
                Text {
                    text: symbol
                    color: "#444"
                    font.pixelSize: 14
                    anchors.left: parent.left
                    anchors.leftMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }
    }

    component FrequencyPremiumInput : ColumnLayout {
        property string label: ""; property string fieldId: ""; property int freqIndex: 0
        signal freqChanged(int idx)
        spacing: 4

        Text { text: label; color: "#757575"; font.pixelSize: 10; font.letterSpacing: 1 }

        RowLayout {
            spacing: 10
            TextField {
                id: premField; placeholderText: "0"; color: "white"; font.bold: true; Layout.fillWidth: true; leftPadding: 30
                font.pixelSize: 15

                validator: DoubleValidator { bottom: 0 }

                // Clean leading zeros
                onTextEdited: {
                    if (text.length > 1 && text.startsWith("0") && !text.startsWith("0.")) {
                        text = text.replace(/^0+/, '');
                    }
                }

                background: Rectangle {
                    color: "#000"; border.color: "#2A2A2A"; radius: 6; implicitHeight: 38
                    Text {
                        text: root.currencySymbol
                        color: "#444"
                        font.pixelSize: 14
                        anchors.left: parent.left
                        anchors.leftMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
                Component.onCompleted: {
                    if (fieldId === "healthPremiumField") healthPremiumField = premField
                    if (fieldId === "lifePremiumField") lifePremiumField = premField
                }
            }
            FrequencyToggle {
                currentIndex: freqIndex
                onChanged: (idx) => freqChanged(idx)
            }
        }
    }

    component FrequencyToggle : Row {
        property int currentIndex: 0
        signal changed(int index)
        spacing: 0

        Repeater {
            model: ["Monthly", "Annual"]
            Button {
                id: toggleBtn
                text: modelData
                flat: true
                implicitWidth: 70; implicitHeight: 32
                // Active: White, Inactive: Muted Gray
                palette.buttonText: currentIndex === index ? "white" : "#444"
                onClicked: parent.changed(index)

                background: Rectangle {
                    color: currentIndex === index ? "#2A2A2A" : "#111"
                    border.color: "#2A2A2A"
                    // Rounded edges for the ends
                    radius: index === 0 ? 4 : 0
                    bottomRightRadius: index === 1 ? 4 : 0
                    topRightRadius: index === 1 ? 4 : 0
                }
            }
        }
    }

    component PolicyVaultButton : Button {
        property color accent: "white"
        text: "📄 Policy Vault - Enter your policy details"; flat: true; Layout.fillWidth: true
        palette.buttonText: hovered ? "white" : accent; font.pixelSize: 11
        background: Rectangle { color: "transparent"; border.color: parent.hovered ? accent : "#2A2A2A"; border.width: 1; radius: 6; implicitHeight: 32 }
    }

    component VaultField : ColumnLayout {
        property string label: ""; property string placeholder: ""
        property alias text: field.text
        spacing: 4
        Text { text: label; color: "#757575"; font.pixelSize: 9; font.letterSpacing: 1 }
        TextField {
            id: field
            Layout.fillWidth: true; placeholderText: placeholder; color: "white"
            background: Rectangle { color: "#000"; border.color: "#2A2A2A"; radius: 6; implicitHeight: 36 }
        }
    }

    // Proxy properties to bridge component internal fields to the main logic
    property var healthPremiumField: null
    property var lifePremiumField: null
}