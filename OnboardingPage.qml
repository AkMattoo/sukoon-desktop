import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import Sukoon
import Sukoon.Backend

// routes/index.tsx — pick a college (optional), pick what's weighing on you, enter anonymously.
Item {
    id: page

    property var college: null          // { id, name, city }
    property var results: []
    property var tags: []
    property bool loading: false
    property string error: ""

    function toggleTag(t) {
        const i = tags.indexOf(t)
        tags = i >= 0 ? tags.filter(x => x !== t) : tags.concat([t])
    }

    function enter() {
        loading = true; error = ""
        consentSheet().ask(function () {
            Api.guest(college ? college.id : "", tags, function (err) {
                loading = false
                if (err) error = err
                // success: Session.changed → Main swaps to the app shell
            })
        }, function () { loading = false })
    }
    function consentSheet() { return ApplicationWindow.window.consent }

    Timer {
        id: debounce
        interval: 150
        onTriggered: {
            const q = search.text.trim()
            if (!q || page.college) { page.results = []; return }
            Api.colleges(q, function (err, list) { if (!err && search.text.trim() === q) page.results = list })
        }
    }

    Flickable {
        anchors.fill: parent
        contentHeight: col.height + 40
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: col
            width: Math.min(page.width, 460) - 40
            x: (page.width - width) / 2
            topPadding: 40
            spacing: 16

            GradientOrb {
                size: 200
                anchors.horizontalCenter: parent.horizontalCenter
            }
            Header {
                width: parent.width
                topPadding: 4
                accent: "Sukoon"
                subtitle: "A calm, anonymous space to be heard."
            }

            GlassCard {
                width: parent.width
                z: 5   // dropdown floats over the next card
                Column {
                    width: parent.width
                    spacing: 8
                    Text { text: "YOUR COLLEGE"; color: Theme.textMid; font.pixelSize: 11; font.letterSpacing: 1.8 }
                    Field {
                        id: search
                        width: parent.width
                        leading: "⌕"
                        placeholder: "Search — e.g. IIT Bombay"
                        onTextChanged: {
                            if (page.college && text !== page.college.name) page.college = null
                            debounce.restart()
                        }
                    }
                    Text {
                        text: "Optional. Used only to match your Campus Circle."
                        color: Theme.textMid; font.pixelSize: 11
                    }
                }

                // results dropdown
                GlassCard {
                    visible: page.results.length > 0
                    y: search.y + search.height + 6
                    width: parent.width
                    padding: 4
                    radius: 16
                    tint: Qt.rgba(26/255, 17/255, 48/255, 0.96)
                    Column {
                        width: parent.width
                        Repeater {
                            model: page.results
                            delegate: ItemDelegate {
                                required property var modelData
                                width: parent.width
                                height: 42
                                background: Rectangle { radius: 12; color: parent.hovered ? Qt.rgba(1, 1, 1, 0.05) : "transparent" }
                                contentItem: Item {
                                    Text { x: 10; anchors.verticalCenter: parent.verticalCenter; text: modelData.name; color: Theme.textHi; font.pixelSize: 13; elide: Text.ElideRight; width: parent.width - 100 }
                                    Text { anchors.right: parent.right; anchors.rightMargin: 10; anchors.verticalCenter: parent.verticalCenter; text: modelData.city || ""; color: Theme.textMid; font.pixelSize: 11 }
                                }
                                onClicked: {
                                    page.college = modelData
                                    search.text = modelData.name
                                    page.results = []
                                }
                            }
                        }
                    }
                }
            }

            GlassCard {
                width: parent.width
                Column {
                    width: parent.width
                    spacing: 12
                    Text { text: "WHAT'S WEIGHING ON YOU?"; color: Theme.textMid; font.pixelSize: 11; font.letterSpacing: 1.8 }
                    Flow {
                        width: parent.width
                        spacing: 8
                        Repeater {
                            model: Catalog.stressTags
                            delegate: Chip {
                                required property string modelData
                                text: modelData
                                checked: page.tags.indexOf(modelData) >= 0
                                onClicked: page.toggleTag(modelData)
                            }
                        }
                    }
                }
            }

            GlassCard {
                width: parent.width
                padding: 16
                Row {
                    width: parent.width
                    spacing: 12
                    Text { text: "🛡"; font.pixelSize: 18; color: Theme.aqua }
                    Text {
                        width: parent.width - 34
                        wrapMode: Text.WordWrap
                        textFormat: Text.StyledText
                        text: "No email. No name. You get a random handle like <font color='#F5F1FF'><tt>QuietFox42</tt></font>. Nothing here is public unless you post it."
                        color: Theme.textMid
                        font.pixelSize: 12
                    }
                }
            }

            GradientButton {
                width: parent.width
                height: 56
                icon_: "✦"
                text: page.loading ? "Preparing your space…" : "Enter anonymously  →"
                busy: page.loading
                enabled: page.tags.length > 0 && !page.loading
                onClicked: page.enter()
            }
            Text {
                visible: page.error !== ""
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                text: page.error
                color: Theme.crisis
                font.pixelSize: 12
            }
        }
    }
}
