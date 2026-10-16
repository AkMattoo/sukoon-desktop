import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import Sukoon

// Toggle pill. Selected = hero gradient with glow; otherwise a quiet outline.
AbstractButton {
    id: chip
    checkable: true
    hoverEnabled: true
    implicitHeight: 34
    implicitWidth: t.implicitWidth + 28
    scale: down ? 0.95 : 1
    Behavior on scale { NumberAnimation { duration: 110 } }

    background: Item {
        Rectangle {
            id: on
            anchors.fill: parent
            radius: height / 2
            visible: false
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: Theme.violet }
                GradientStop { position: 1; color: Theme.orchid }
            }
        }
        MultiEffect {
            anchors.fill: on
            source: on
            opacity: chip.checked ? 1 : 0
            shadowEnabled: true
            shadowColor: Theme.violet
            shadowBlur: 0.8
            shadowOpacity: 0.7
            shadowVerticalOffset: 5
            Behavior on opacity { NumberAnimation { duration: 180 } }
        }
        Rectangle {
            anchors.fill: parent
            radius: height / 2
            visible: !chip.checked
            color: chip.hovered ? Qt.rgba(1, 1, 1, 0.09) : Qt.rgba(1, 1, 1, 0.05)
            border.color: Qt.rgba(1, 1, 1, 0.15)
        }
    }
    contentItem: Text {
        id: t
        text: chip.text
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        color: chip.checked ? "white" : Theme.lavender
        font.family: Theme.fontSans
        font.pixelSize: 13
        font.weight: Font.Medium
    }
}
