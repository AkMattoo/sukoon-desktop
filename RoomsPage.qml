import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import Sukoon
import Sukoon.Backend

// routes/rooms.index.tsx — vent rooms with honest live counts, filters, and "open your own".
Item {
    id: page

    property var filters: ({ scope: "all", theme: "", language: "", activeOnly: false })
    property var rooms: []
    property bool loading: true
    property string error: ""
    property var liveCounts: ({})
    property int totalLive: -1
    readonly property bool hasCollege: Session.collegeId !== ""
    property bool showFilters: false

    function setFilter(k, v) {
        const f = Object.assign({}, filters); f[k] = v; filters = f
        load()
    }
    function load() {
        loading = true; error = ""
        Api.rooms(filters, function (err, list) {
            loading = false
            if (err) error = err; else rooms = list
        })
    }
    readonly property int activeFilterCount:
        (filters.theme ? 1 : 0) + (filters.language ? 1 : 0) + (filters.activeOnly ? 1 : 0) + (filters.scope !== "all" ? 1 : 0)

    Component.onCompleted: { load(); poll.triggered() }
    Timer {
        id: poll
        interval: 5000; repeat: true; running: true
        onTriggered: Api.roomsLive(function (err, r) {
            if (err) return
            page.liveCounts = r.counts || {}
            page.totalLive = r.totalLive
        })
    }

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
                eyebrow: page.totalLive > 0 ? page.totalLive + " people in rooms right now" : "Vent rooms"
                title: "Say it"
                accent: "out loud"
                subtitle: "Drop into a room with students who get it. Listen, speak, or just sit with people."
            }

            // scope segmented control
            Row {
                width: parent.width
                spacing: 8
                Repeater {
                    model: [{ id: "all", label: "All" }, { id: "campus", label: "🎓 Campus" }, { id: "india", label: "🌏 All-India" }]
                    delegate: Chip {
                        required property var modelData
                        width: (parent.width - 16) / 3
                        text: modelData.label
                        enabled: modelData.id !== "campus" || page.hasCollege
                        opacity: enabled ? 1 : 0.4
                        checkable: false
                        checked: page.filters.scope === modelData.id
                        onClicked: page.setFilter("scope", modelData.id)
                    }
                }
            }

            Row {
                spacing: 8
                Chip {
                    checkable: false
                    text: "⚙ Filters" + (page.activeFilterCount ? " · " + page.activeFilterCount : "")
                    onClicked: page.showFilters = !page.showFilters
                }
                Chip {
                    checkable: false
                    text: "＋ Open a room"
                    onClicked: createSheet.open()
                }
            }

            // filter panel (expands)
            GlassCard {
                width: parent.width
                visible: opacity > 0
                opacity: page.showFilters ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 200 } }
                Column {
                    width: parent.width
                    spacing: 10
                    Text { text: "THEME"; color: Theme.textMid; font.pixelSize: 11; font.letterSpacing: 1.6 }
                    Flow {
                        width: parent.width; spacing: 6
                        Repeater {
                            model: Catalog.roomThemes
                            delegate: Chip {
                                required property var modelData
                                text: modelData.emoji + " " + modelData.label
                                checked: page.filters.theme === modelData.id
                                onClicked: page.setFilter("theme", checked ? modelData.id : "")
                            }
                        }
                    }
                    Text { text: "LANGUAGE"; color: Theme.textMid; font.pixelSize: 11; font.letterSpacing: 1.6 }
                    Flow {
                        width: parent.width; spacing: 6
                        Repeater {
                            model: Catalog.roomLanguages
                            delegate: Chip {
                                required property var modelData
                                text: modelData.label
                                checked: page.filters.language === modelData.id
                                onClicked: page.setFilter("language", checked ? modelData.id : "")
                            }
                        }
                    }
                    Row {
                        spacing: 8
                        Chip {
                            text: "● Live now only"
                            checked: page.filters.activeOnly
                            onClicked: page.setFilter("activeOnly", checked)
                        }
                        Chip {
                            checkable: false
                            text: "Clear"
                            visible: page.activeFilterCount > 0
                            onClicked: { page.filters = { scope: "all", theme: "", language: "", activeOnly: false }; page.load() }
                        }
                    }
                }
            }

            // continue where you left off
            RoomCard {
                visible: Session.lastRoom !== "" && page.rooms.some(r => r.id === Session.lastRoom)
                room: page.rooms.find(r => r.id === Session.lastRoom) || null
                eyebrow: "↺  Pick up where you left off"
            }

            BusyIndicator {
                visible: page.loading && page.rooms.length === 0
                running: visible
                anchors.horizontalCenter: parent.horizontalCenter
            }
            Text {
                visible: page.error !== ""
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                text: page.error + "\nPull the filters again or tap Clear to retry."
                color: Theme.crisis; font.pixelSize: 12
            }
            Text {
                visible: !page.loading && !page.error && page.rooms.length === 0
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                text: "No rooms match. Open your own — someone else is probably waiting for one."
                color: Theme.textMid; font.pixelSize: 13
                topPadding: 20
            }

            Repeater {
                model: page.rooms
                delegate: RoomCard {
                    required property var modelData
                    room: modelData
                }
            }
        }
    }

    // ---- one room row
    component RoomCard: AbstractButton {
        id: card
        property var room: null
        property string eyebrow: ""
        readonly property int live: room ? (page.liveCounts[room.id] !== undefined ? page.liveCounts[room.id] : room.liveCount) : 0
        width: col.width
        height: inner.height
        hoverEnabled: true
        enabled: room !== null
        scale: down ? 0.98 : (hovered ? 1.01 : 1)
        Behavior on scale { NumberAnimation { duration: 140 } }
        onClicked: ApplicationWindow.window.openRoom(room.id)
        background: null
        contentItem: GlassCard {
            id: inner
            borderColor: card.hovered ? Qt.rgba(176/255, 108/255, 240/255, 0.45) : Theme.glassBorder
            Behavior on borderColor { ColorAnimation { duration: 180 } }
            Column {
                width: parent.width
                spacing: 6
                Text { visible: card.eyebrow !== ""; text: card.eyebrow; color: Theme.aqua; font.pixelSize: 11 }
                Row {
                    width: parent.width
                    spacing: 12
                    Rectangle {
                        width: 46; height: 46; radius: 15
                        color: Qt.rgba(1, 1, 1, 0.06)
                        border.color: Theme.hairline
                        Text { anchors.centerIn: parent; text: card.room ? card.room.emoji : ""; font.pixelSize: 22 }
                    }
                    Column {
                        width: parent.width - 58
                        spacing: 3
                        Text {
                            width: parent.width
                            text: card.room ? card.room.title : ""
                            elide: Text.ElideRight
                            color: Theme.textHi; font.pixelSize: 15; font.weight: Font.DemiBold
                        }
                        Text {
                            width: parent.width
                            visible: !!(card.room && card.room.description)
                            text: card.room ? card.room.description : ""
                            elide: Text.ElideRight
                            color: Theme.textMid; font.pixelSize: 12
                        }
                        Row {
                            spacing: 8
                            LiveDot { active: card.live > 0; anchors.verticalCenter: parent.verticalCenter }
                            Text {
                                text: card.live > 0 ? card.live + " here now" : "Quiet — be the first"
                                color: card.live > 0 ? Theme.aqua : Theme.textLow
                                font.pixelSize: 12
                            }
                            Text {
                                visible: !!(card.room && card.room.isFull)
                                text: "· Full"
                                color: Theme.crisis; font.pixelSize: 12
                            }
                            Text {
                                text: card.room ? "· " + (card.room.scope === "campus" ? "Campus" : "All-India") + " · " + card.room.language.toUpperCase() : ""
                                color: Theme.textLow; font.pixelSize: 12
                            }
                        }
                    }
                }
            }
        }
    }

    // Glowing, breathing "live" dot.
    component LiveDot: Item {
        id: dot
        property bool active: false
        width: 10; height: 10
        Rectangle {
            id: core
            anchors.fill: parent
            radius: 5
            color: dot.active ? Theme.aqua : Theme.textLow
        }
        MultiEffect {
            anchors.fill: core
            source: core
            visible: dot.active
            shadowEnabled: true
            shadowColor: Theme.aqua
            shadowBlur: 0.8
            SequentialAnimation on shadowOpacity {
                running: dot.active && !Comfort.reducedMotion; loops: Animation.Infinite
                NumberAnimation { from: 0.3; to: 1; duration: 900 }
                NumberAnimation { from: 1; to: 0.3; duration: 900 }
            }
        }
    }

    // ---- create room
    Sheet {
        id: createSheet
        title: "Open a room"
        subtitle: "Give it a gentle name. People see the title and theme."
        property string theme: "general"
        property string language: "en"
        property bool campusOnly: false
        property string err: ""
        onOpened: { err = ""; titleField.text = ""; descField.text = "" }

        Field { id: titleField; width: parent.width; placeholder: "e.g. Night-before-exam nerves"; maxLength: 80 }
        Field { id: descField; width: parent.width; multiline: true; placeholder: "What's this room for? (optional)"; maxLength: 200 }
        Flow {
            width: parent.width; spacing: 6
            Repeater {
                model: Catalog.roomThemes
                delegate: Chip {
                    required property var modelData
                    text: modelData.emoji + " " + modelData.label
                    checked: createSheet.theme === modelData.id
                    onClicked: createSheet.theme = modelData.id
                }
            }
        }
        Flow {
            width: parent.width; spacing: 6
            Repeater {
                model: Catalog.roomLanguages
                delegate: Chip {
                    required property var modelData
                    text: modelData.label
                    checked: createSheet.language === modelData.id
                    onClicked: createSheet.language = modelData.id
                }
            }
        }
        Row {
            spacing: 10
            Chip {
                text: "🎓 Campus only"
                visible: page.hasCollege
                checked: createSheet.campusOnly
                onClicked: createSheet.campusOnly = checked
            }
            SpinBox {
                id: cap
                from: 0; to: 50; value: 0
                editable: true
                textFromValue: function (v) { return v === 0 ? "No limit" : v + " people" }
            }
        }
        GradientButton {
            width: parent.width
            text: "Open room"
            enabled: titleField.text.trim().length >= 3
            onClicked: Api.createRoom({
                title: titleField.text.trim(), theme: createSheet.theme, description: descField.text.trim(),
                language: createSheet.language, campusOnly: createSheet.campusOnly, capacity: cap.value
            }, function (err, room) {
                if (err) { createSheet.err = err; return }
                createSheet.close()
                page.load()
                ApplicationWindow.window.openRoom(room.id)
            })
        }
        Text { visible: createSheet.err !== ""; width: parent.width; wrapMode: Text.WordWrap; text: createSheet.err; color: Theme.crisis; font.pixelSize: 12 }
    }
}
