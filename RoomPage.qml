import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import Sukoon
import Sukoon.Backend

// routes/rooms.$roomId.tsx — live room: real occupancy, captions, chat, "I need support".
// Connects to the same /ws signaling socket as the web app.
Item {
    id: page
    property string roomId: ""
    property var room: null
    property bool reported: false
    property var helpResult: null

    RoomSocket {
        id: sock
        onCrisisNudge: ApplicationWindow.window.openSos(true)
    }

    Component.onCompleted: {
        Api.room(roomId, function (err, r) { if (!err) page.room = r })
        sock.join(Api.wsBase, roomId, Session.handle)
    }
    Component.onDestruction: sock.leave()

    Column {
        id: top
        width: Math.min(page.width, 480) - 40
        x: (page.width - width) / 2
        topPadding: 20
        spacing: 12

        Row {
            spacing: 10
            Chip { checkable: false; text: "‹  Rooms"; onClicked: StackView.view.pop() }
            Chip {
                checkable: false
                text: page.reported ? "Reported — thank you" : "⚑ Report room"
                enabled: !page.reported
                onClicked: Api.report(page.roomId, "room reported", function (err) { if (!err) page.reported = true })
            }
        }

        GlassCard {
            width: parent.width
            Row {
                width: parent.width
                spacing: 14
                Item {
                    width: 64; height: 64
                    // speaker "presence" ring that glows harder with more people
                    Rectangle {
                        id: halo
                        anchors.fill: parent
                        radius: 32
                        visible: false
                        gradient: Gradient {
                            GradientStop { position: 0; color: Theme.violet }
                            GradientStop { position: 1; color: Theme.blush }
                        }
                    }
                    MultiEffect {
                        anchors.fill: parent
                        source: halo
                        shadowEnabled: Comfort.showRings
                        shadowColor: Theme.orchid
                        shadowBlur: 1
                        shadowOpacity: Math.min(1, 0.3 + sock.occupancy * 0.12) * Comfort.audioIntensity
                        SequentialAnimation on scale {
                            running: sock.occupancy > 1 && !Comfort.reducedMotion; loops: Animation.Infinite
                            NumberAnimation { from: 1; to: 1.06; duration: 1400; easing.type: Easing.InOutSine }
                            NumberAnimation { from: 1.06; to: 1; duration: 1400; easing.type: Easing.InOutSine }
                        }
                    }
                    Text { anchors.centerIn: parent; text: page.room ? page.room.emoji : "🌙"; font.pixelSize: 28 }
                }
                Column {
                    width: parent.width - 78
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4
                    Text {
                        width: parent.width
                        text: page.room ? page.room.title : "Joining…"
                        wrapMode: Text.WordWrap
                        color: Theme.textHi; font.family: Theme.fontDisplay; font.pixelSize: 20
                    }
                    Text {
                        text: sock.status === "connected"
                              ? (sock.occupancy > 0 ? "● " + sock.occupancy + " here with you" : "● Connected")
                              : sock.status === "connecting" ? "Connecting…" : (sock.error || "Offline")
                        color: sock.status === "connected" ? Theme.aqua : sock.status === "error" ? Theme.crisis : Theme.textMid
                        font.pixelSize: 12
                    }
                }
            }
        }

        // someone in the room asked for support
        GlassCard {
            visible: !!sock.helpAlert.handle
            width: parent.width
            borderColor: Qt.rgba(1, 107/255, 133/255, 0.5)
            padding: 14
            Row {
                width: parent.width
                spacing: 10
                Text {
                    width: parent.width - 40
                    wrapMode: Text.WordWrap
                    textFormat: Text.StyledText
                    text: "<b>" + (sock.helpAlert.handle || "") + "</b> asked for support" + (sock.helpAlert.note ? ": “" + sock.helpAlert.note + "”" : ".") + " A kind word goes a long way."
                    color: Theme.textHi; font.pixelSize: 13
                }
                Text { text: "✕"; color: Theme.textMid; MouseArea { anchors.fill: parent; onClicked: sock.dismissHelpAlert() } }
            }
        }

        // live captions (from speakers on the web/mobile app)
        Column {
            visible: sock.captions.length > 0
            width: parent.width
            Repeater {
                model: sock.captions
                delegate: Text {
                    required property var modelData
                    width: parent.width
                    wrapMode: Text.WordWrap
                    textFormat: Text.StyledText
                    text: "<font color='#9A90B8'>" + modelData.handle + ":</font> " + modelData.text
                    color: Theme.text; font.pixelSize: 13
                }
            }
        }
    }

    // chat — a frosted panel with the list laid over it
    GlassCard {
        id: chatCard
        anchors { top: top.bottom; topMargin: 12; bottom: composer.top; bottomMargin: 10 }
        width: top.width
        x: top.x
    }
    ListView {
            id: chat
            anchors.fill: chatCard
            anchors.margins: 12
            clip: true
            spacing: 8
            model: sock.messages
            onCountChanged: positionViewAtEnd()
            delegate: Column {
                required property var modelData
                width: chat.width
                readonly property bool mine: modelData.handle === Session.handle
                Text {
                    anchors.right: mine ? parent.right : undefined
                    text: modelData.handle
                    color: mine ? Theme.blush : Theme.textMid
                    font.pixelSize: 10
                }
                Rectangle {
                    anchors.right: mine ? parent.right : undefined
                    width: Math.min(msg.implicitWidth + 24, chat.width * 0.8)
                    height: msg.implicitHeight + 16
                    radius: 14
                    color: mine ? Qt.rgba(124/255, 92/255, 1, 0.35) : Qt.rgba(1, 1, 1, 0.06)
                    border.color: Theme.hairline
                    Text {
                        id: msg
                        anchors.centerIn: parent
                        width: Math.min(implicitWidth, chat.width * 0.8 - 24)
                        wrapMode: Text.WordWrap
                        text: modelData.text
                        color: Theme.textHi
                        font.pixelSize: 13
                    }
                }
            }
            Text {
                anchors.centerIn: parent
                visible: chat.count === 0
                width: parent.width - 40
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                text: "Nothing said yet. You can just sit here — that counts too."
                color: Theme.textLow
                font.pixelSize: 13
            }
    }

    Column {
        id: composer
        width: top.width
        x: top.x
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 16
        spacing: 8

        Row {
            width: parent.width
            spacing: 8
            Field {
                id: input
                width: parent.width - 98
                placeholder: "Say something kind…"
                enabled: sock.status === "connected"
                onAccepted: send()
                function send() { sock.sendChat(text); text = "" }
            }
            GradientButton {
                width: 90; height: 46
                text: "Send"
                enabled: input.text.trim() !== "" && sock.status === "connected"
                onClicked: input.send()
            }
        }
        AbstractButton {
            width: parent.width
            height: 40
            onClicked: helpSheet.open()
            background: Rectangle {
                radius: 14
                color: Qt.rgba(1, 107/255, 133/255, 0.12)
                border.color: Qt.rgba(1, 107/255, 133/255, 0.4)
            }
            contentItem: Text {
                text: "♥  I need support"
                color: Theme.crisis
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                font.pixelSize: 13; font.weight: Font.DemiBold
            }
        }
    }

    // HelpSignal.tsx — explicit request; nothing is sent on the student's behalf.
    Sheet {
        id: helpSheet
        title: "Ask for support"
        subtitle: "The room will see that you'd like a kind word. If you've saved a trusted contact, you'll get one-tap links — you press send."
        onOpened: page.helpResult = null

        Field { id: helpNote; width: parent.width; placeholder: "Anything you want to add? (optional)"; maxLength: 200 }
        GradientButton {
            width: parent.width
            text: "Send signal"
            colors: ["#ff5a78", "#ff8fb1", "#ffb3c7"]
            onClicked: {
                sock.sendHelpSignal(helpNote.text)
                Api.helpSignal({ roomId: page.roomId, note: helpNote.text, scope: "both" }, function (err, r) {
                    page.helpResult = err ? { message: err } : r
                })
            }
        }
        Text {
            visible: !!page.helpResult
            width: parent.width
            wrapMode: Text.WordWrap
            text: page.helpResult ? page.helpResult.message || "" : ""
            color: Theme.aqua; font.pixelSize: 12
        }
        Row {
            visible: !!(page.helpResult && page.helpResult.contact)
            spacing: 8
            Repeater {
                model: page.helpResult && page.helpResult.contact
                       ? [{ l: "Call", u: page.helpResult.contact.callLink },
                          { l: "SMS", u: page.helpResult.contact.smsLink },
                          { l: "WhatsApp", u: page.helpResult.contact.whatsappLink }] : []
                delegate: Chip {
                    required property var modelData
                    checkable: false
                    text: modelData.l + " " + (page.helpResult.contact.name || "")
                    onClicked: Qt.openUrlExternally(modelData.u)
                }
            }
        }
        Button {
            text: "See crisis helplines"
            flat: true
            palette.buttonText: Theme.textMid
            onClicked: { helpSheet.close(); ApplicationWindow.window.openSos(false) }
        }
    }
}
