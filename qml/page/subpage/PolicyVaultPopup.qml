import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "../../components"

Popup {
    id: vaultPopup
    parent: Overlay.overlay
    width: 620; height: 600
    x: (parent.width - width) / 2
    y: (parent.height - height) / 2
    modal: true
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    padding: 0

    property string category: "Life"
    readonly property color accent: category === "Life" ? "#FFC400"
                                  : category === "Health" ? "#00E5FF" : "#FF9100"
    readonly property bool isAsset: category === "Asset"

    property var rows: []

    function openFor(cat) { category = cat; refresh(); open() }
    function refresh() { rows = policyModel.policiesFor(category) }

    Connections {
        target: policyModel
        function onPoliciesUpdated() { if (vaultPopup.opened) vaultPopup.refresh() }
    }

    function fmt(v) { return (Number(v) || 0).toLocaleString(Qt.locale(), 'f', 0) }

    Overlay.modal: Rectangle { color: "#CC000000" }
    background: Rectangle { color: "#0d0d0d"; border.color: "#2A2A2A"; border.width: 1; radius: 14 }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 10

        // Header
        RowLayout {
            Layout.fillWidth: true
            Text {
                text: vaultPopup.category.toUpperCase() + " POLICY VAULT"
                color: vaultPopup.accent; font.pixelSize: 15; font.bold: true; font.letterSpacing: 1
                Layout.fillWidth: true
            }
            Rectangle {
                implicitWidth: addLabel.implicitWidth + 20; implicitHeight: 28; radius: 6
                color: "transparent"; border.color: vaultPopup.accent; border.width: 1
                Text { id: addLabel; anchors.centerIn: parent; text: "+ Add Policy"; color: vaultPopup.accent; font.pixelSize: 11; font.bold: true }
                MouseArea {
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked: { policyModel.addPolicy(vaultPopup.category); vaultPopup.refresh() }
                }
            }
            Rectangle {
                width: 28; height: 28; radius: 14
                color: closeMA.containsMouse ? "#2e0a0a" : "transparent"
                Text { anchors.centerIn: parent; text: "×"; color: "#888"; font.pixelSize: 16 }
                MouseArea { id: closeMA; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: vaultPopup.close() }
            }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: "#1e1e1e" }

        // Empty state
        Text {
            visible: vaultPopup.rows.length === 0
            Layout.fillWidth: true
            Layout.topMargin: 30
            text: "No policies yet. Click \"+ Add Policy\" to add your first one."
            color: "#555"; font.pixelSize: 13; font.italic: true
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
        }

        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            visible: vaultPopup.rows.length > 0
            contentWidth: availableWidth

            ColumnLayout {
                width: parent.width
                spacing: 12

                Repeater {
                    model: vaultPopup.rows

                    delegate: Rectangle {
                        required property var modelData
                        readonly property int rowIdx: modelData.index

                        Layout.fillWidth: true
                        Layout.preferredHeight: rowContent.implicitHeight + 28
                        color: "#161616"; radius: 8; border.color: "#2A2A2A"

                        ColumnLayout {
                            id: rowContent
                            anchors.fill: parent
                            anchors.margins: 14
                            spacing: 12

                            // Line 1
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 16
                                Layout.alignment: Qt.AlignTop

                                VaultField {
                                    Layout.fillWidth: true
                                    label: vaultPopup.isAsset ? "ASSET NAME" : "PROVIDER"
                                    focusColor: vaultPopup.accent
                                    text: vaultPopup.isAsset ? modelData.label : modelData.provider
                                    onEdited: (v) => vaultPopup.isAsset ? policyModel.setLabel(rowIdx, v) : policyModel.setProvider(rowIdx, v)
                                }
                                VaultField {
                                    Layout.fillWidth: true
                                    label: "POLICY NUMBER"
                                    focusColor: vaultPopup.accent
                                    text: modelData.policyNumber
                                    onEdited: (v) => policyModel.setPolicyNumber(rowIdx, v)
                                }
                                VaultField {
                                    Layout.fillWidth: true
                                    visible: !vaultPopup.isAsset
                                    label: "NOMINEE"
                                    focusColor: vaultPopup.accent
                                    text: modelData.nominee
                                    onEdited: (v) => policyModel.setNominee(rowIdx, v)
                                }
                            }

                            // Line 2
                            RowLayout {
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignTop
                                spacing: 16

                                VaultField {
                                    Layout.preferredWidth: 130
                                    label: "SUM INSURED"
                                    focusColor: vaultPopup.accent
                                    rightAligned: true
                                    validator: DoubleValidator { bottom: 0; notation: DoubleValidator.StandardNotation }
                                    text: vaultPopup.fmt(modelData.sumInsured)
                                    onEdited: (v) => policyModel.setSumInsured(rowIdx, parseFloat(v) || 0)
                                }
                                VaultField {
                                    Layout.preferredWidth: 130
                                    visible: vaultPopup.isAsset
                                    label: "ASSET VALUE (OPTIONAL)"
                                    focusColor: vaultPopup.accent
                                    rightAligned: true
                                    validator: DoubleValidator { bottom: 0; notation: DoubleValidator.StandardNotation }
                                    text: vaultPopup.fmt(modelData.assetValue)
                                    onEdited: (v) => policyModel.setAssetValue(rowIdx, parseFloat(v) || 0)
                                }
                                VaultField {
                                    Layout.preferredWidth: 100
                                    label: "PREMIUM"
                                    focusColor: vaultPopup.accent
                                    rightAligned: true
                                    validator: DoubleValidator { bottom: 0; notation: DoubleValidator.StandardNotation }
                                    text: vaultPopup.fmt(modelData.premium)
                                    onEdited: (v) => policyModel.setPremium(rowIdx, parseFloat(v) || 0)
                                }

                                FrequencyToggle {
                                    Layout.alignment: Qt.AlignTop
                                    Layout.topMargin: 12
                                    isAnnual: modelData.isAnnual
                                    accent: vaultPopup.accent
                                    onChanged: (annual) => policyModel.setIsAnnual(rowIdx, annual)
                                }

                                Item { Layout.fillWidth: true }

                                Rectangle {
                                    Layout.alignment: Qt.AlignTop
                                    Layout.topMargin: 10
                                    width: 26; height: 26; radius: 13
                                    color: removeMA.containsMouse ? "#2e0a0a" : "transparent"
                                    border.color: removeMA.containsMouse ? "#F44336" : "transparent"
                                    Text { anchors.centerIn: parent; text: "×"; color: "#666"; font.pixelSize: 14 }
                                    MouseArea {
                                        id: removeMA; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onClicked: { policyModel.removePolicy(rowIdx); vaultPopup.refresh() }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: "#1e1e1e" }

        // Footer
        RowLayout {
            Layout.fillWidth: true

            ColumnLayout {
                spacing: 2
                Text { text: "TOTAL SUM INSURED"; color: "#555"; font.pixelSize: 9; font.letterSpacing: 1 }
                Text {
                    text: root.currencySymbol + " " + vaultPopup.fmt(policyModel.sumInsuredFor(vaultPopup.category))
                    color: vaultPopup.accent; font.pixelSize: 15; font.bold: true
                }
            }
            Item { Layout.fillWidth: true }
            ColumnLayout {
                spacing: 2
                Layout.alignment: Qt.AlignRight
                Text { text: "MONTHLY PREMIUM"; color: "#555"; font.pixelSize: 9; font.letterSpacing: 1; Layout.alignment: Qt.AlignRight }
                Text {
                    text: root.currencySymbol + " " + vaultPopup.fmt(policyModel.monthlyPremiumFor(vaultPopup.category))
                    color: "white"; font.pixelSize: 15; font.bold: true
                    Layout.alignment: Qt.AlignRight
                }
            }
            Item { width: 20 }
            SaveButton { onClicked: vaultPopup.close() }
        }
    }
}
