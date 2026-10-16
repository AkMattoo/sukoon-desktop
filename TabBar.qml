import QtQuick
import QtQuick.Effects
import Sukoon

// Bottom navigation. The active tab is marked by a glowing gradient tile
// that glides between tabs instead of jumping.
GlassCard {
    id: bar
    property int currentIndex: 0
    signal selected(int index)
    padding: 8
    radius: 26

    readonly property var tabs: [
        { label: "Home",    glyph: "⌂" },
        { label: "Rooms",   glyph: "💬" },
        { label: "Breathe", glyph: "≋" },
        { label: "Buddy",   glyph: "✦" },
        { label: "Circle",  glyph: "◎" }
    ]

    Item {
        width: parent.width
        height: 52
        readonly property real slot: width / bar.tabs.length

        // Sliding glow tile
        Item {
            id: tile
            width: 38; height: 38
            y: 0
            x: parent.slot * bar.currentIndex + (parent.slot - width) / 2
            Behavior on x { SpringAnimation { spring: 3.2; damping: 0.28 } }
            Rectangle {
                id: tileFill
                anchors.fill: parent
                radius: 14
                visible: false
                gradient: Gradient {
                    GradientStop { position: 0; color: Theme.violet }
                    GradientStop { position: 1; color: Theme.orchid }
                }
            }
            MultiEffect {
                anchors.fill: parent
                source: tileFill
                shadowEnabled: true
                shadowColor: Theme.violet
                shadowBlur: 0.9
                shadowOpacity: 0.85
                shadowVerticalOffset: 6
            }
        }

        Row {
            anchors.fill: parent
            Repeater {
                model: bar.tabs
                delegate: MouseArea {
                    required property var modelData
                    required property int index
                    width: parent.width / bar.tabs.length
                    height: parent.height
                    cursorShape: Qt.PointingHandCursor
                    onClicked: bar.selected(index)
                    Accessible.role: Accessible.PageTab
                    Accessible.name: modelData.label

                    readonly property bool active: index === bar.currentIndex
                    Text {
                        y: 0; height: 38
                        anchors.horizontalCenter: parent.horizontalCenter
                        verticalAlignment: Text.AlignVCenter
                        text: modelData.glyph
                        font.pixelSize: 18
                        color: active ? "white" : Theme.lavender
                        Behavior on color { ColorAnimation { duration: 200 } }
                    }
                    Text {
                        anchors.bottom: parent.bottom
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: modelData.label
                        font.family: Theme.fontSans
                        font.pixelSize: 10
                        font.weight: Font.Medium
                        color: active ? Theme.textHi : Theme.textMid
                    }
                }
            }
        }
    }
}
