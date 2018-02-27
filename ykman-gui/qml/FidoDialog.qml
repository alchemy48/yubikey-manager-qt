import QtQuick 2.5
import QtQuick.Controls 1.4
import QtQuick.Layouts 1.1
import QtQuick.Dialogs 1.2

DefaultDialog {

    title: qsTr("Configure FIDO 2")
    minimumHeight: calculated()
    minimumWidth: 350
    height: calculated()
    width: 350

    property var device
    property bool hasPin
    property int pinRetries

    function calculated() {
        var stackItem = stack.currentItem
        var doubleMargins = margins * 2
        return stackItem ? stackItem.implicitHeight + doubleMargins : 0
    }

    function load() {
        stack.push({
                       item: initial,
                       immediate: true,
                       replace: true
                   })

        function handlePinResp(resp) {
            hasPin = resp
            if (hasPin) {
                device.fido_pin_retries(handleRetriesResp)
            } else {
                show()
            }
        }
        function handleRetriesResp(resp) {
            pinRetries = resp
            show()
        }

        device.fido_has_pin(handlePinResp)
    }

    function getPinMessage() {
        if (hasPin) {
            return qsTr("A PIN is set, ") + pinRetries + qsTr(" retries left.")
        } else {
            return qsTr("No PIN is set.")
        }
    }

    StackView {
        id: stack
        anchors.fill: parent
        initialItem: initial
    }

    Component {
        id: initial
        ColumnLayout {
            GroupBox {
                Layout.fillWidth: true
                title: qsTr("PIN Management")
                RowLayout {
                    anchors.fill: parent
                    Label {
                        text: getPinMessage()
                    }
                    Button {
                        text: qsTr("Set PIN...")
                        Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                        onClicked: stack.push({
                                                  item: fidoChangePinDialog,
                                                  immediate: true
                                              })
                    }
                }
            }

            GroupBox {
                Layout.fillWidth: true
                title: qsTr("Reset FIDO 2")
                ColumnLayout {
                    anchors.fill: parent
                    Label {
                        text: qsTr(
                                  "Delete all FIDO credentials and remove PIN.")
                    }
                    Button {
                        text: qsTr("Reset...")
                        Layout.alignment: Qt.AlignRight | Qt.AlignBottom
                        onClicked: stack.push({
                                                  item: fidoResetDialog,
                                                  immediate: true
                                              })
                    }
                }
            }

            RowLayout {
                Layout.alignment: Qt.AlignRight | Qt.AlignBottom
                Button {
                    text: qsTr("Cancel")
                    onClicked: close()
                }
            }
        }
    }

    Component {
        id: fidoChangePinDialog
        FidoChangePinDialog {
        }
    }

    Component {
        id: fidoResetDialog
        FidoResetDialog {
        }
    }
}