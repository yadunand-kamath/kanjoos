import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "../../components"

Popup {
    id: diagPopup
    parent: Overlay.overlay
    width: 540; height: 560
    x: (parent.width - width) / 2
    y: (parent.height - height) / 2
    modal: true
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    padding: 0

    property string category: "Life"
    property bool expenseOverridden: false
    signal expenseEdited()
    readonly property color accent: category === "Life" ? "#FFC400"
                                  : category === "Health" ? "#00E5FF" : "#FF9100"

    readonly property bool isReady: (typeof insuranceCalc !== "undefined" && insuranceCalc !== null)

    function openFor(cat) { category = cat; open() }

    function fmtCr(v) { return v > 0 ? root.currencySymbol + " " + (v/10000000).toFixed(2) + " Cr" : "—" }
    function fmtL(v)  { return v > 0 ? root.currencySymbol + " " + (v/100000).toFixed(2)  + " L"  : "—" }

    Overlay.modal: Rectangle { color: "#CC000000" }
    background: Rectangle { color: "#0d0d0d"; border.color: "#2A2A2A"; border.width: 1; radius: 14 }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 14

        // Header
        RowLayout {
            Layout.fillWidth: true
            Text {
                text: "⚡ CALCULATE NEED — " + diagPopup.category.toUpperCase()
                color: diagPopup.accent; font.pixelSize: 15; font.bold: true; font.letterSpacing: 1
                Layout.fillWidth: true
            }
            Rectangle {
                width: 28; height: 28; radius: 14
                color: closeMA.containsMouse ? "#2e0a0a" : "transparent"
                Text { anchors.centerIn: parent; text: "×"; color: "#888"; font.pixelSize: 16 }
                MouseArea { id: closeMA; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: diagPopup.close() }
            }
        }

        InsuranceCheckBox {
            Layout.fillWidth: true
            visible: diagPopup.category === "Life"
            label: "I have dependents"
            accent: diagPopup.accent
            checked: diagPopup.isReady ? insuranceCalc.hasDependents : false
            onToggled: (v) => { if (diagPopup.isReady) insuranceCalc.hasDependents = v }
        }

        InsuranceUnderlineInput {
            Layout.fillWidth: true
            visible: diagPopup.category === "Life"
            label: "OUTSTANDING LOANS"
            focusColor: diagPopup.accent
            validator: DoubleValidator { bottom: 0; notation: DoubleValidator.StandardNotation }
            text: diagPopup.isReady ? insuranceCalc.totalLoans.toFixed(0) : "0"
            onEdited: (v) => { if (diagPopup.isReady) insuranceCalc.setTotalLoans(parseFloat(v) || 0) }
        }

        InsuranceUnderlineInput {
            id: expenseField
            Layout.fillWidth: true
            label: diagPopup.expenseOverridden ? "ANNUAL EXPENSES" : "ANNUAL EXPENSES (FROM CASHFLOW)"
            focusColor: diagPopup.accent
            validator: DoubleValidator { bottom: 0; notation: DoubleValidator.StandardNotation }
            text: diagPopup.isReady ? insuranceCalc.annualExpenses.toFixed(0) : "0"
            onEdited: (v) => {
                diagPopup.expenseOverridden = true
                diagPopup.expenseEdited()
                if (diagPopup.isReady) insuranceCalc.setAnnualExpenses(parseFloat(v) || 0)
            }
        }

        InsuranceUnderlineInput {
            Layout.fillWidth: true
            label: "FUTURE MILESTONES"
            focusColor: diagPopup.accent
            validator: DoubleValidator { bottom: 0; notation: DoubleValidator.StandardNotation }
            text: diagPopup.isReady ? insuranceCalc.futureMilestones.toFixed(0) : "0"
            onEdited: (v) => { if (diagPopup.isReady) insuranceCalc.setFutureMilestones(parseFloat(v) || 0) }
        }

        InsuranceUnderlineInput {
            Layout.fillWidth: true
            label: "CURRENT LIQUID ASSETS (FROM PORTFOLIO)"
            focusColor: diagPopup.accent
            validator: DoubleValidator { bottom: 0; notation: DoubleValidator.StandardNotation }
            text: diagPopup.isReady ? insuranceCalc.currentLiquidAssets.toFixed(0) : "0"
            onEdited: (v) => { if (diagPopup.isReady) insuranceCalc.setCurrentLiquidAssets(parseFloat(v) || 0) }
        }

        ColumnLayout {
            Layout.fillWidth: true
            visible: diagPopup.category === "Health"
            spacing: 6

            RowLayout {
                Layout.fillWidth: true
                Text { text: "HEALTH MULTIPLIER"; color: "#757575"; font.pixelSize: 10; font.letterSpacing: 1.2; Layout.fillWidth: true }
                Text {
                    text: (diagPopup.isReady ? insuranceCalc.healthMultiplier.toFixed(1) : "12.5") + "×"
                    color: diagPopup.accent; font.pixelSize: 13; font.bold: true
                }
            }
            CustomSlider {
                Layout.fillWidth: true
                accentColor: diagPopup.accent
                from: 20; to: 30
                value: diagPopup.isReady ? insuranceCalc.healthMultiplier * 2 : 25
                onMoved: (v) => { if (diagPopup.isReady) insuranceCalc.setHealthMultiplier(v / 2) }
            }
        }

        Item { Layout.fillHeight: true }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4

            Text {
                text: "RECOMMENDED COVER"
                color: "#757575"; font.pixelSize: 10; font.letterSpacing: 1.2
                Layout.alignment: Qt.AlignHCenter
            }
            Text {
                text: diagPopup.isReady
                      ? diagPopup.fmtCr(diagPopup.category === "Life" ? insuranceCalc.recommendedLifeCover : insuranceCalc.recommendedHealthCover)
                      : "—"
                color: diagPopup.accent; font.pixelSize: 30; font.bold: true
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
            }
            Text {
                visible: diagPopup.isReady && (diagPopup.category === "Life" ? insuranceCalc.lifeVerdictLevel > 0 : insuranceCalc.healthVerdictLevel > 0) && diagPopup.category === "Life"
                text: diagPopup.isReady ? insuranceCalc.lifeCoverDirective : ""
                color: "blue"; font.pixelSize: 12; font.italic: true
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
            }
        }

        SaveButton {
            Layout.alignment: Qt.AlignHCenter
            onClicked: diagPopup.close()
        }
    }
}
