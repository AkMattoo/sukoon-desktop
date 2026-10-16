import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import Sukoon
import Sukoon.Backend

// routes/home.tsx — mood check-in, weekly mood chart, "Breathe With Me" entry.
Item {
    id: page

    property int mood: -1
    property bool saving: false
    property bool saved: false
    property string saveError: ""
    property var insights: null
    property bool insightsLoading: true
    property string insightsError: ""
    property int breathing: -1          // -1 = still checking

    function loadInsights() {
        insightsLoading = true; insightsError = ""
        Api.insights(function (err, d) {
            insightsLoading = false
            if (err) insightsError = err; else insights = d
        })
    }
    function submit() {
        if (mood < 0) return
        saving = true; saveError = ""
        Api.logMood(mood, note.text.trim(), function (err) {
            saving = false
            if (err) { saveError = err; return }
            saved = true; note.text = ""; savedTimer.restart()
            loadInsights()
        })
    }

    Component.onCompleted: { loadInsights(); pollBreath.triggered() }
    Timer { id: savedTimer; interval: 2000; onTriggered: page.saved = false }
    Timer {
        id: pollBreath
        interval: 8000; repeat: true; running: true
        onTriggered: Api.breatheLive(function (err, n) { if (!err) page.breathing = n })
    }

    readonly property string partOfDay: {
        const h = new Date().getHours()
        return h < 12 ? "Morning" : h < 17 ? "Afternoon" : "Evening"
    }

    Flickable {
        anchors.fill: parent
        contentHeight: col.height + 24
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: col
            width: page.width - 40
            x: 20
            spacing: 16

            Header {
                eyebrow: page.partOfDay
                title: "Hey"
                accent: Session.handle || "friend"
                subtitle: "How's your heart today?"
            }

            // ---- mood picker
            GlassCard {
                width: parent.width
                Column {
                    width: parent.width
                    spacing: 14
                    Row {
                        width: parent.width
                        spacing: (width - 5 * 56) / 4
                        Repeater {
                            model: Catalog.moods
                            delegate: MoodTile {
                                required property var modelData
                                emoji: modelData.e
                                label: modelData.label
                                selected: page.mood === modelData.v
                                onClicked: page.mood = modelData.v
                            }
                        }
                    }
                    Field {
                        id: note
                        width: parent.width
                        multiline: true
                        maxLength: 280
                        placeholder: "30-second note — how does today feel?"
                    }
                    GradientButton {
                        width: parent.width
                        height: 48
                        busy: page.saving
                        enabled: page.mood >= 0 && !page.saving
                        text: page.saved ? "Saved 💜" : page.saving ? "Saving…" : "Save today's check-in"
                        onClicked: page.submit()
                    }
                    Text {
                        visible: page.saveError !== ""
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                        text: page.saveError + "  · tap save to retry"
                        color: Theme.crisis
                        font.pixelSize: 12
                    }
                }
            }

            // ---- weekly insight
            GlassCard {
                width: parent.width
                Column {
                    width: parent.width
                    spacing: 12
                    Item {
                        width: parent.width; height: 18
                        Text { text: "WEEKLY MOOD INSIGHT"; color: Theme.textMid; font.pixelSize: 11; font.letterSpacing: 1.8 }
                        Text {
                            anchors.right: parent.right
                            visible: !!page.insights
                            text: page.insights
                                  ? (page.insights.trend ? page.insights.trend.charAt(0).toUpperCase() + page.insights.trend.slice(1) + " · " : "")
                                    + "avg " + page.insights.avg.toFixed(1)
                                  : ""
                            color: Theme.textMid; font.pixelSize: 12
                        }
                    }

                    // loading
                    BusyIndicator {
                        visible: page.insightsLoading && !page.insights
                        running: visible
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                    // error
                    Column {
                        visible: page.insightsError !== "" && !page.insights
                        width: parent.width
                        spacing: 6
                        Text { width: parent.width; horizontalAlignment: Text.AlignHCenter; text: "Insights aren't loading"; color: Theme.textHi; font.family: Theme.fontDisplay; font.pixelSize: 17 }
                        Text { width: parent.width; horizontalAlignment: Text.AlignHCenter; wrapMode: Text.WordWrap; text: "Your check-ins are safe — the chart just needs another try."; color: Theme.textMid; font.pixelSize: 12 }
                        Button { anchors.horizontalCenter: parent.horizontalCenter; text: "Try again"; flat: true; palette.buttonText: Theme.aqua; onClicked: page.loadInsights() }
                    }
                    // empty
                    Column {
                        visible: !!page.insights && page.insights.entries === 0
                        width: parent.width
                        topPadding: 10; bottomPadding: 10
                        spacing: 4
                        Text { width: parent.width; horizontalAlignment: Text.AlignHCenter; text: "No check-ins yet this week."; color: Theme.textHi; font.family: Theme.fontDisplay; font.pixelSize: 18 }
                        Text { width: parent.width; horizontalAlignment: Text.AlignHCenter; text: "Your first one starts the picture."; color: Theme.textMid; font.pixelSize: 12 }
                    }
                    // chart
                    MoodChart {
                        visible: !!page.insights && page.insights.entries > 0
                        width: parent.width
                        week: page.insights ? page.insights.week : []
                        insight: page.insights ? page.insights.insight : ""
                    }
                }
            }

            // ---- breathe with me
            AbstractButton {
                width: parent.width
                height: breatheCard.height
                scale: down ? 0.98 : 1
                Behavior on scale { NumberAnimation { duration: 110 } }
                onClicked: ApplicationWindow.window.goTab(2)
                background: null
                contentItem: GlassCard {
                    id: breatheCard
                    width: parent.width
                    Row {
                        width: parent.width
                        spacing: 16
                        GradientOrb { size: 80; glow: 0.8 }
                        Column {
                            width: parent.width - 96
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 4
                            Text { text: "Breathe With Me"; color: Theme.textHi; font.pixelSize: 15; font.weight: Font.DemiBold }
                            Text {
                                text: page.breathing < 0 ? "checking who's here…"
                                    : page.breathing > 0 ? "👥  " + page.breathing + " breathing right now"
                                    : "Nobody right now — start one"
                                font.italic: page.breathing === 0
                                color: Theme.textMid; font.pixelSize: 12
                            }
                            Text { text: "A 4-7-8 pattern. Under 2 minutes."; color: Theme.textLow; font.pixelSize: 12 }
                        }
                    }
                }
            }
        }
    }

    // A mood button: gradient + glow + lift when picked.
    component MoodTile: AbstractButton {
        id: tile
        property string emoji
        property string label
        property bool selected: false
        width: 56; height: 56
        hoverEnabled: true
        Accessible.name: label
        scale: selected ? 1.12 : (down ? 0.94 : 1)
        Behavior on scale { SpringAnimation { spring: 4; damping: 0.3 } }

        background: Item {
            Rectangle {
                id: tileOn
                anchors.fill: parent
                radius: 18
                visible: false
                gradient: Gradient {
                    GradientStop { position: 0; color: Theme.violet }
                    GradientStop { position: 1; color: Theme.blush }
                }
            }
            MultiEffect {
                anchors.fill: parent
                source: tileOn
                opacity: tile.selected ? 1 : 0
                shadowEnabled: true
                shadowColor: Theme.violet
                shadowBlur: 1
                shadowOpacity: 0.75
                shadowVerticalOffset: 8
                Behavior on opacity { NumberAnimation { duration: 200 } }
            }
            Rectangle {
                anchors.fill: parent
                radius: 18
                visible: !tile.selected
                color: tile.hovered ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(1, 1, 1, 0.05)
                border.color: Qt.rgba(1, 1, 1, 0.10)
            }
        }
        contentItem: Text {
            text: tile.emoji
            font.pixelSize: 28
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
    }

    // 7-day bar chart, Mon → Sun. Bars grow in with a stagger; today glows pink.
    component MoodChart: Column {
        id: chart
        property var week: []
        property string insight: ""
        readonly property int todayIdx: { const d = new Date().getDay(); return d === 0 ? 6 : d - 1 }
        spacing: 6

        Row {
            id: bars
            width: parent.width
            height: 112
            spacing: 8
            Repeater {
                model: chart.week
                delegate: Item {
                    required property real modelData
                    required property int index
                    readonly property bool today: index === chart.todayIdx
                    width: (bars.width - 6 * 8) / 7
                    height: bars.height

                    Item {
                        id: barWrap
                        anchors.bottom: parent.bottom
                        width: parent.width
                        property real target: parent.height * Math.max(0.06, modelData / 5)
                        height: 0
                        Component.onCompleted: grow.start()
                        SequentialAnimation {
                            id: grow
                            PauseAnimation { duration: index * 40 }
                            NumberAnimation { target: barWrap; property: "height"; to: barWrap.target; duration: 700; easing.type: Easing.OutBack }
                        }
                        onTargetChanged: if (!grow.running) height = target

                        Rectangle {
                            id: barFill
                            anchors.fill: parent
                            radius: 8
                            visible: false
                            gradient: Gradient {
                                GradientStop { position: 0; color: today ? Theme.blush : Theme.violet }
                                GradientStop { position: 1; color: today ? Theme.violet : Theme.orchid }
                            }
                        }
                        MultiEffect {
                            anchors.fill: parent
                            source: barFill
                            opacity: today ? 1 : 0.62
                            shadowEnabled: today
                            shadowColor: Theme.blush
                            shadowBlur: 0.8
                            shadowOpacity: 0.6
                        }
                    }
                }
            }
        }
        Row {
            width: parent.width
            spacing: 8
            Repeater {
                model: ["M", "T", "W", "T", "F", "S", "S"]
                delegate: Text {
                    required property string modelData
                    required property int index
                    width: (parent.width - 6 * 8) / 7
                    horizontalAlignment: Text.AlignHCenter
                    text: modelData
                    font.pixelSize: 10
                    color: index === chart.todayIdx ? Theme.blush : Theme.textLow
                }
            }
        }
        Text {
            visible: chart.insight !== ""
            width: parent.width
            topPadding: 6
            wrapMode: Text.WordWrap
            text: chart.insight
            color: Theme.textMid
            font.pixelSize: 12
            lineHeight: 1.2
        }
    }
}
