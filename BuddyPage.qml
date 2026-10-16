import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import Sukoon
import Sukoon.Backend

// routes/buddy.tsx — your wellness buddies, people you could pair with, and check-ins.
Item {
    id: page
    property var buddies: []
    property var candidates: []
    property var received: []
    property bool loading: true
    property int adding: -1
    property bool matching: false

    function load() {
        loading = true
        let pending = 3
        const done = () => { if (--pending === 0) loading = false }
        Api.buddies(function (e, d) { if (!e) buddies = d; done() })
        Api.buddyCandidates(function (e, d) { if (!e) candidates = d; done() })
        Api.buddyCheckins(function (e, d) { if (!e) received = d; done() })
    }
    function flash(m) { ApplicationWindow.window.toast(m) }

    Component.onCompleted: load()

    Flickable {
        anchors.fill: parent
        contentHeight: col.height + 24
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: col
            width: page.width - 40
            x: 20
            spacing: 14

            Header {
                eyebrow: "Wellness buddy"
                title: "Someone in"
                accent: "your corner"
                subtitle: "Pair up anonymously with students carrying similar stress. Send a check-in when you think of them."
            }

            GradientButton {
                width: parent.width
                icon_: "✦"
                text: page.matching ? "Finding someone…" : "Surprise me with a buddy"
                busy: page.matching
                enabled: !page.matching
                onClicked: {
                    page.matching = true
                    Api.matchBuddy(function (err, m) {
                        page.matching = false
                        if (err) return page.flash(err)
                        page.flash(m.matched ? "You're paired with " + m.buddy.handle + " 💜" : (m.message || "No one to match right now — try again soon."))
                        page.load()
                    })
                }
            }

            BusyIndicator { visible: page.loading && page.buddies.length === 0; running: visible; anchors.horizontalCenter: parent.horizontalCenter }

            // my buddies
            Section { text: "YOUR BUDDIES"; visible: page.buddies.length > 0 }
            Repeater {
                model: page.buddies
                delegate: BuddyCard { required property var modelData; buddy: modelData }
            }

            // check-ins received
            Section { text: "CHECK-INS FOR YOU"; visible: page.received.length > 0 }
            Repeater {
                model: page.received
                delegate: GlassCard {
                    required property var modelData
                    width: col.width
                    padding: 16
                    Column {
                        width: parent.width
                        spacing: 4
                        Text { text: modelData.from_handle + "  ·  " + modelData.ago; color: Theme.blush; font.pixelSize: 11 }
                        Text { width: parent.width; wrapMode: Text.WordWrap; text: modelData.message; color: Theme.textHi; font.pixelSize: 14 }
                    }
                }
            }

            // candidates
            Section { text: "PEOPLE WHO GET IT"; visible: page.candidates.length > 0 }
            Repeater {
                model: page.candidates
                delegate: GlassCard {
                    required property var modelData
                    width: col.width
                    padding: 16
                    Row {
                        width: parent.width
                        spacing: 10
                        Avatar { handle: modelData.handle }
                        Column {
                            width: parent.width - 150
                            anchors.verticalCenter: parent.verticalCenter
                            Text { text: modelData.handle; color: Theme.textHi; font.pixelSize: 14; font.weight: Font.DemiBold }
                            Text {
                                width: parent.width
                                wrapMode: Text.WordWrap
                                text: modelData.sharedTags && modelData.sharedTags.length ? "Also: " + modelData.sharedTags.join(", ") : modelData.reason
                                color: Theme.textMid; font.pixelSize: 12
                            }
                        }
                        GradientButton {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 92; height: 38
                            text: page.adding === modelData.id ? "…" : "Pair up"
                            enabled: page.adding < 0
                            onClicked: {
                                page.adding = modelData.id
                                Api.chooseBuddy(modelData.id, function (err, r) {
                                    page.adding = -1
                                    if (err) return page.flash(err)
                                    page.flash(r.already ? "You're already buddies." : "Paired with " + modelData.handle + " 💜")
                                    page.load()
                                })
                            }
                        }
                    }
                }
            }

            Text {
                visible: !page.loading && page.buddies.length === 0 && page.candidates.length === 0
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                text: "No buddies yet. Tap “Surprise me” — someone else is hoping for a buddy too."
                color: Theme.textMid; font.pixelSize: 13
            }
        }
    }

    component Section: Text {
        color: Theme.textMid
        font.pixelSize: 11
        font.letterSpacing: 1.8
        topPadding: 6
    }

    // Gradient initial with a soft glow.
    component Avatar: Item {
        id: av
        property string handle: ""
        width: 42; height: 42
        Rectangle {
            id: avFill
            anchors.fill: parent
            radius: 21
            visible: false
            gradient: Gradient {
                GradientStop { position: 0; color: Theme.violet }
                GradientStop { position: 1; color: Theme.aqua }
            }
        }
        MultiEffect {
            anchors.fill: parent
            source: avFill
            shadowEnabled: true
            shadowColor: Theme.violet
            shadowBlur: 0.7
            shadowOpacity: 0.6
        }
        Text { anchors.centerIn: parent; text: av.handle.charAt(0); color: "white"; font.pixelSize: 17; font.weight: Font.Bold }
    }

    // A buddy with an inline "send a check-in" composer.
    component BuddyCard: GlassCard {
        id: bc
        property var buddy
        property bool sending: false
        property string status: ""
        width: col.width
        Column {
            width: parent.width
            spacing: 10
            Row {
                spacing: 10
                Avatar { handle: bc.buddy.buddy_handle }
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    Text { text: bc.buddy.buddy_handle; color: Theme.textHi; font.pixelSize: 15; font.weight: Font.DemiBold }
                    Text { text: bc.buddy.match_reason || ""; color: Theme.textMid; font.pixelSize: 12 }
                }
            }
            Row {
                width: parent.width
                spacing: 8
                Field { id: msgField; width: parent.width - 90; placeholder: "Thinking of you — how's today?"; maxLength: 280 }
                GradientButton {
                    width: 82; height: 46
                    text: bc.sending ? "…" : "Send"
                    enabled: msgField.text.trim() !== "" && !bc.sending
                    onClicked: {
                        bc.sending = true; bc.status = ""
                        Api.checkin(bc.buddy.id, msgField.text.trim(), function (err) {
                            bc.sending = false
                            if (err) { bc.status = err; return }
                            msgField.text = ""
                            bc.status = "Sent 💜"
                        })
                    }
                }
            }
            Text { visible: bc.status !== ""; text: bc.status; color: Theme.aqua; font.pixelSize: 12 }
        }
    }
}
