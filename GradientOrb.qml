import QtQuick
import QtQuick.Effects
import Sukoon
import Sukoon.Backend

// The glowing violet→blush orb used on onboarding, home and Breathe.
// A slowly rotating gradient core + a blurred halo + a coloured MultiEffect glow.
Item {
    id: root
    property real size: 220
    property bool pulse: true          // gentle idle "breathing"
    property real glow: 1.0            // 0..1.5, halo strength
    width: size
    height: size

    readonly property bool _motion: !Comfort.reducedMotion

    // Core, drawn off-screen and then composited with glow + highlight.
    Item {
        id: core
        anchors.centerIn: parent
        width: root.size * 0.78
        height: width
        visible: false

        Rectangle {
            id: grad
            anchors.centerIn: parent
            // oversized so the rotation never shows corners inside the mask
            width: parent.width * 1.5
            height: width
            gradient: Gradient {
                GradientStop { position: 0.0; color: Theme.violet }
                GradientStop { position: 0.55; color: Theme.orchid }
                GradientStop { position: 1.0; color: Theme.blush }
            }
            RotationAnimation on rotation {
                running: root._motion; loops: Animation.Infinite
                from: 0; to: 360; duration: 24000
            }
        }
        // soft inner shading (top light, bottom shadow)
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.18) }
                GradientStop { position: 0.5; color: "transparent" }
                GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.28) }
            }
        }
    }

    Rectangle {
        id: circleMask
        anchors.fill: core
        radius: width / 2
        visible: false
        layer.enabled: true
    }

    // Halo: the same core, much bigger blur, behind everything.
    MultiEffect {
        anchors.centerIn: parent
        width: core.width
        height: core.height
        source: core
        maskEnabled: true
        maskSource: circleMask
        blurEnabled: true
        blur: 1.0
        blurMax: 64
        blurMultiplier: 2.0
        opacity: 0.75 * root.glow
        scale: 1.25
    }

    // The orb itself, with a violet glow.
    MultiEffect {
        id: orb
        anchors.centerIn: parent
        width: core.width
        height: core.height
        source: core
        maskEnabled: true
        maskSource: circleMask
        shadowEnabled: true
        shadowColor: Theme.violet
        shadowBlur: 1.0
        shadowOpacity: 0.8 * root.glow
        shadowVerticalOffset: root.size * 0.06
        shadowHorizontalOffset: 0

        SequentialAnimation on scale {
            running: root.pulse && root._motion; loops: Animation.Infinite
            NumberAnimation { from: 0.96; to: 1.04; duration: 3200; easing.type: Easing.InOutSine }
            NumberAnimation { from: 1.04; to: 0.96; duration: 3200; easing.type: Easing.InOutSine }
        }
    }
}
