import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import Sukoon
import Sukoon.Backend

// routes/circle.tsx — college-scoped anonymous wall: post, heart, report, block.
Item {
    id: page
    property var posts: []
    property bool loading: true
    property string error: ""
    property bool posting: false
    property string postError: ""
    property var hearted: ({})
    property var blocked: ({})
    readonly property bool hasCollege: Session.collegeId !== ""

    function load() {
        loading = true; error = ""
        Api.circle(function (err, list) { loading = false; if (err) error = err; else posts = list })
    }
    function post() {
        const v = composer.text.trim()
        if (!v) return
        posting = true; postError = ""
        Api.postCircle(v, function (err, p) {
            posting = false
            if (err) { postError = err; return }
            composer.text = ""
            posts = [p].concat(posts)
        })
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
                eyebrow: "Campus Circle"
                title: "Your"
                accent: "campus"
                subtitle: "Anonymous notes from students at your college. Be gentle — everyone here is carrying something."
            }

            GlassCard {
                visible: !page.hasCollege
                width: parent.width
                Text {
                    width: parent.width
                    wrapMode: Text.WordWrap
                    text: "Campus Circle needs a college. Sign out from Settings → Delete account to start again with one, or keep using Rooms and Buddy."
                    color: Theme.textMid; font.pixelSize: 13
                }
            }

            GlassCard {
                visible: page.hasCollege
                width: parent.width
                Column {
                    width: parent.width
                    spacing: 10
                    Field { id: composer; width: parent.width; multiline: true; maxLength: 500; placeholder: "Share something — anonymously." }
                    GradientButton {
                        width: parent.width; height: 46
                        busy: page.posting
                        text: page.posting ? "Posting…" : "Post anonymously"
                        enabled: composer.text.trim() !== "" && !page.posting
                        onClicked: page.post()
                    }
                    Text { visible: page.postError !== ""; width: parent.width; wrapMode: Text.WordWrap; text: page.postError; color: Theme.crisis; font.pixelSize: 12 }
                }
            }

            BusyIndicator { visible: page.loading && page.posts.length === 0 && page.hasCollege; running: visible; anchors.horizontalCenter: parent.horizontalCenter }
            Text { visible: page.error !== ""; width: parent.width; wrapMode: Text.WordWrap; horizontalAlignment: Text.AlignHCenter; text: page.error; color: Theme.crisis; font.pixelSize: 12 }

            Repeater {
                model: page.posts
                delegate: GlassCard {
                    id: card
                    required property var modelData
                    required property int index
                    visible: !page.blocked[modelData.handle]
                    width: col.width
                    padding: 16
                    // posts float in one after another
                    opacity: 0
                    Component.onCompleted: appear.start()
                    SequentialAnimation {
                        id: appear
                        PauseAnimation { duration: Math.min(card.index, 8) * 50 }
                        NumberAnimation { target: card; property: "opacity"; to: 1; duration: 300 }
                    }

                    Column {
                        width: parent.width
                        spacing: 8
                        Text { text: card.modelData.handle + "  ·  " + card.modelData.createdAt; color: Theme.textMid; font.pixelSize: 11 }
                        Text { width: parent.width; wrapMode: Text.WordWrap; text: card.modelData.text; color: Theme.textHi; font.pixelSize: 14; lineHeight: 1.15 }
                        Row {
                            spacing: 8
                            HeartButton {
                                count: page.hearted[card.modelData.id] !== undefined ? page.hearted[card.modelData.id] : card.modelData.hearts
                                onClicked: Api.heart(card.modelData.id, function (err, n) {
                                    if (err) return
                                    const h = Object.assign({}, page.hearted); h[card.modelData.id] = n; page.hearted = h
                                })
                            }
                            Chip {
                                checkable: false
                                text: "⚑ Report"
                                onClicked: Api.report(card.modelData.id, "", function (err, msg) { page.flash(err || msg || "Thanks for flagging this.") })
                            }
                            Chip {
                                checkable: false
                                text: "⊘ Block"
                                visible: card.modelData.handle !== Session.handle
                                onClicked: Api.block(card.modelData.handle, function (err) {
                                    if (err) return page.flash(err)
                                    const b = Object.assign({}, page.blocked); b[card.modelData.handle] = true; page.blocked = b
                                    page.flash("You won't see posts from " + card.modelData.handle + ".")
                                })
                            }
                        }
                    }
                }
            }
        }
    }

    // Heart that pops and glows when tapped.
    component HeartButton: AbstractButton {
        id: hb
        property int count: 0
        implicitWidth: row.implicitWidth + 24
        implicitHeight: 34
        onClicked: pop.restart()
        background: Rectangle {
            radius: height / 2
            color: Qt.rgba(1, 143/255, 177/255, 0.10)
            border.color: Qt.rgba(1, 143/255, 177/255, 0.35)
        }
        contentItem: Item {
            Row {
                id: row
                anchors.centerIn: parent
                spacing: 6
                Text {
                    id: heart
                    text: "♥"
                    color: Theme.blush
                    font.pixelSize: 15
                    layer.enabled: true
                    layer.effect: MultiEffect { shadowEnabled: true; shadowColor: Theme.blush; shadowBlur: 0.8; shadowOpacity: 0.7; shadowHorizontalOffset: 0; shadowVerticalOffset: 0 }
                    SequentialAnimation on scale {
                        id: pop
                        running: false
                        NumberAnimation { to: 1.5; duration: 120; easing.type: Easing.OutQuad }
                        NumberAnimation { to: 1.0; duration: 260; easing.type: Easing.OutBack }
                    }
                }
                Text { text: hb.count; color: Theme.text; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
            }
        }
    }
}
