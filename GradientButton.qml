import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import Sukoon

// The "gradient-hero" button: violet → orchid → blush with a coloured glow
// that blooms on hover and a soft press-in.
AbstractButton {
    id: control
    property string icon_: ""          // emoji/glyph shown before the text
    property bool busy: false
    property real radius: 18
    property var colors: [Theme.violet, Theme.orchid, Theme.blush]
    property bool glowing: true

    implicitHeight: 52
    implicitWidth: label.implicitWidth + 48
    hoverEnabled: true
    opacity: enabled ? 1 : 0.4
    scale: down ? 0.97 : 1
    Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }
    Behavior on opacity { NumberAnimation { duration: 150 } }

    background: Item {
        Rectangle {
            id: fill
            anchors.fill: parent
            radius: control.radius
            visible: false
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: control.colors[0] }
                GradientStop { position: 0.6; color: control.colors[1] }
                GradientStop { position: 1.0; color: control.colors[2] }
            }
        }
        MultiEffect {
            anchors.fill: fill
            source: fill
            shadowEnabled: control.glowing
            shadowColor: control.colors[0]
            shadowBlur: 1.0
            shadowOpacity: control.hovered ? 0.9 : 0.6
            shadowVerticalOffset: 8
            brightness: control.hovered ? 0.06 : 0
            Behavior on shadowOpacity { NumberAnimation { duration: 200 } }
            Behavior on brightness { NumberAnimation { duration: 200 } }
        }
    }

    contentItem: Item {
      implicitWidth: row.implicitWidth
      implicitHeight: row.implicitHeight
      Row {
        id: row
        spacing: 8
        anchors.centerIn: parent
        BusyIndicator {
            visible: control.busy
            running: visible
            width: 18; height: 18
            anchors.verticalCenter: parent.verticalCenter
        }
        Text {
            visible: control.icon_ !== "" && !control.busy
            text: control.icon_
            font.pixelSize: 16
            color: "white"
            anchors.verticalCenter: parent.verticalCenter
        }
        Text {
            id: label
            text: control.text
            color: "white"
            font.family: Theme.fontSans
            font.pixelSize: 15
            font.weight: Font.DemiBold
            anchors.verticalCenter: parent.verticalCenter
        }
      }
    }
}
