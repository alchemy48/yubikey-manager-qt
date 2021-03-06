import QtQuick 2.5
import QtQuick.Controls 1.4
import QtQuick.Layouts 1.2
import QtQuick.Dialogs 1.2
import QtQuick.Window 2.2
import Qt.labs.settings 1.0

ApplicationWindow {
    id: app
    title: qsTr("YubiKey Manager")
    visible: true

    minimumHeight: calcHeight()
    height: minimumHeight
    minimumWidth: calcWidth()
    width: minimumWidth
    Component.onDestruction: saveScreenLayout()
    Component.onCompleted: ensureValidWindowPosition()
    property int margins: 12

    function calcWidth() {
        return mainStack.currentItem ? Math.max(
                                           350,
                                           mainStack.currentItem.implicitWidth + (margins * 2)) : 0
    }

    function calcHeight() {
        return mainStack.currentItem ? Math.max(
                                           360,
                                           header.height + mainStack.currentItem.implicitHeight
                                           + (margins * 2)) : 0
    }

    function ensureValidWindowPosition() {
        // If we have the same desktop dimensions as last time, use the saved position.
        // If not, put the window in the middle of the screen.
        var savedScreenLayout = (settings.desktopAvailableWidth === Screen.desktopAvailableWidth)
                && (settings.desktopAvailableHeight === Screen.desktopAvailableHeight)
        app.x = (savedScreenLayout) ? settings.x : Screen.width / 2 - app.width / 2
        app.y = (savedScreenLayout) ? settings.y : Screen.height / 2 - app.height / 2
    }

    function saveScreenLayout() {
        settings.desktopAvailableWidth = Screen.desktopAvailableWidth
        settings.desktopAvailableHeight = Screen.desktopAvailableHeight
    }

    Settings {
        id: settings
        // Keep track of window and desktop dimensions.
        property alias width: app.width
        property alias height: app.height
        property alias x: app.x
        property alias y: app.y
        property var desktopAvailableWidth
        property var desktopAvailableHeight
    }

    menuBar: MainMenuBar {
    }

    AboutPage {
        id: aboutPage
    }

    Shortcut {
        sequence: StandardKey.Close
        onActivated: close()
    }

    // @disable-check M301
    YubiKey {
        id: yk
        onError: console.log(traceback)
        onHasDeviceChanged: mainStack.update()
    }

    Timer {
        id: timer
        triggeredOnStart: true
        interval: 500
        repeat: true
        running: true
        onTriggered: yk.refresh()
    }
    ColumnLayout {
        spacing: 0
        anchors.fill: parent
        Layout.fillWidth: true
        Header {
            id: header
        }
        StackView {
            id: mainStack
            property bool frozen: fidoDialog.visible || slotDialog.visible
                                  || pivManager.visible

            Layout.fillWidth: true
            Layout.fillHeight: true
            initialItem: message
            onCurrentItemChanged: {
                if (currentItem) {
                    currentItem.forceActiveFocus()
                }
            }
            onFrozenChanged: {
                if (!frozen) {
                    update()
                }
            }

            function update() {
                connectionsDialog.close()
                if (!frozen) {
                    clear()
                    push(yk.hasDevice ? deviceInfo : message)
                }
            }
        }
    }

    Component {
        id: message
        ColumnLayout {
            anchors.fill: parent
            Layout.fillHeight: true
            Layout.fillWidth: true
            Label {
                Layout.fillHeight: true
                Layout.fillWidth: true
                text: if (yk.nDevices == 0) {
                          qsTr("No YubiKey detected.")
                      } else if (yk.nDevices == 1) {
                          qsTr("Connecting to YubiKey...")
                      } else {
                          qsTr("Multiple YubiKeys detected!")
                      }
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }

    Component {
        id: deviceInfo
        DeviceInfo {
            device: yk
        }
    }

    SlotDialog {
        id: slotDialog
        device: yk
    }

    PivManager {
        id: pivManager
        device: yk
    }

    ConnectionsDialog {
        id: connectionsDialog
        device: yk
    }

    OpenPgpResetDialog {
        id: openPgpResetDialog
        device: yk
    }

    OpenPgpPinRetries {
        id: openPgpPinRetries
        device: yk
    }

    OpenPgpTouchPolicy {
        id: openPgpTouchPolicy
        device: yk
    }

    OpenPgpShowStatus {
        id: openPgpStatus
        device: yk
    }

    FidoDialog {
        id: fidoDialog
        device: yk
    }

    TouchYubiKey {
        id: touchYubiKeyPrompt
    }

    MessageDialog {
        id: openPgpResetConfirm
        icon: StandardIcon.Information
        title: qsTr("OpenPGP functionality has been reset.")
        text: qsTr("All data has been cleared and default PINs are set.")
        standardButtons: StandardButton.Ok
    }

    MessageDialog {
        id: openPgpTouchConfirm
        icon: StandardIcon.Information
        title: qsTr("Touch Policy for OpenPGP")
        text: qsTr("A new touch policy for OpenPGP has been set.")
        standardButtons: StandardButton.Ok
    }
    MessageDialog {
        id: openPgpPinRetriesConfirm
        icon: StandardIcon.Information
        title: qsTr("Pin retries for OpenPGP")
        text: qsTr("New pin retries for OpenPGP has been set.")
        standardButtons: StandardButton.Ok
    }

    ClipBoard {
        id: clipboard
    }

    function copyToClipboard(value) {
        clipboard.setClipboard(value)
    }

    function supportsOpenPgpTouch() {
        // Touch policy for OpenPGP is available from version 4.2.0.
        return parseInt(yk.version.split('.').join('')) >= 420
    }

    function supportsOpenPgpPinRetries() {
        // Note: this only works for YK4. NEOs below 1.0.7 doesn't support this,
        // but since we need to select the applet to get the OpenPGP version,
        // we allow all NEOs to try.
        var version = yk.version.split('.').join('')
        return version < 400 || version > 431
    }

    function clearsPinWhenSettingPinRetries() {
        var version = yk.version.split('.').join('')
        return version < 400
    }

    function enableLogging(logLevel) {
        yk.enableLogging(logLevel, null)
    }
    function enableLoggingToFile(logLevel, logFile) {
        yk.enableLogging(logLevel, logFile)
    }
    function disableLogging() {
        yk.disableLogging()
    }
}
