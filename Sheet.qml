import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import Sukoon

// Bottom sheet. While open, the whole app behind it is blurred and dimmed
// (a live MultiEffect over a snapshot of the window), and the sheet springs up.
Popup {
    id: sheet
    property string title: ""
    property string subtitle: ""
    default property alias body: bodyCol.data

    parent: Overlay.overlay
    modal: true
    dim: true
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    width: Math.min(parent ? parent.width - 24 : 400, 460)
    x: parent ? (parent.width - width) / 2 : 0
    y: parent ? parent.height - height - 12 : 0
    height: Math.min(card.implicitHeight, parent ? parent.height - 60 : 700)
    padding: 0

    Overlay.modal: Item {
        ShaderEffectSource {
            id: snap
            anchors.fill: parent
            sourceItem: sheet.parent && ApplicationWindow.window ? ApplicationWindow.window.contentItem : null
            live: true
            visible: false
        }
        MultiEffect {
            anchors.fill: parent
            source: snap
            blurEnabled: true
            blur: 0.7
            blurMax: 32
            brightness: -0.25
        }
        Rectangle { anchors.fill: parent; color: Qt.rgba(0, 0, 0, 0.45) }
    }

    enter: Transition {
        ParallelAnimation {
            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 180 }
            NumberAnimation { property: "y"; from: sheet.parent.height; duration: 420; easing.type: Easing.OutBack; easing.overshoot: 0.8 }
        }
    }
    exit: Transition {
        ParallelAnimation {
            NumberAnimation { property: "opacity"; to: 0; duration: 160 }
            NumberAnimation { property: "y"; to: sheet.parent.height; duration: 220; easing.type: Easing.InQuad }
        }
    }

    background: Item {}

    contentItem: Flickable {
        contentHeight: card.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        GlassCard {
            id: card
            width: parent.width
            tint: Qt.rgba(20/255, 14/255, 35/255, 0.92)
            frosted: false       // the modal layer already blurs everything behind
            padding: 22

            Column {
                width: parent.width
                spacing: 14

                Item {
                    width: parent.width
                    height: head.implicitHeight
                    Column {
                        id: head
                        width: parent.width - 40
                        spacing: 4
                        Text {
                            text: sheet.title
                            color: Theme.textHi
                            font.family: Theme.fontSans
                            font.pixelSize: 20
                            font.weight: Font.Bold
                        }
                        Text {
                            visible: sheet.subtitle !== ""
                            width: parent.width
                            text: sheet.subtitle
                            wrapMode: Text.WordWrap
                            color: Theme.textMid
                            font.pixelSize: 13
                        }
                    }
                    RoundButton {
                        anchors.right: parent.right
                        anchors.top: parent.top
                        flat: true
                        text: "✕"
                        Accessible.name: "Close"
                        onClicked: sheet.close()
                        palette.buttonText: Theme.textMid
                    }
                }

                Column {
                    id: bodyCol
                    width: parent.width
                    spacing: 10
                }
            }
        }
    }
}
