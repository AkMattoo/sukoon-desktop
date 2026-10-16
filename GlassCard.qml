import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import Sukoon

// Real frosted glass: samples the aurora backdrop under the card, blurs it,
// clips it to the rounded shape, then tints it and drops a soft shadow.
// Put content inside as children (laid out in `contentItem`).
Item {
    id: root
    property real radius: 24
    property real padding: 20
    property color tint: Theme.glass
    property color borderColor: Theme.glassBorder
    property bool frosted: true
    property bool elevated: true
    default property alias content: inner.data
    readonly property alias contentItem: inner

    // Children should set `width: parent.width`; the card grows to fit their height.
    implicitWidth: inner.childrenRect.width + padding * 2
    implicitHeight: inner.childrenRect.height + padding * 2
    height: implicitHeight

    readonly property Item backdrop: ApplicationWindow.window ? ApplicationWindow.window.backdrop : null

    // Soft drop shadow: a blurred dark copy of the shape, nudged down.
    Rectangle {
        id: shadowShape
        anchors.fill: parent
        anchors.margins: 6
        radius: root.radius
        color: "black"
        visible: false
    }
    MultiEffect {
        anchors.fill: shadowShape
        anchors.topMargin: 6 + 16
        anchors.bottomMargin: 6 - 16
        visible: root.elevated
        source: shadowShape
        blurEnabled: true
        blur: 1.0
        blurMax: 48
        opacity: 0.5
    }

    // Snapshot of whatever is behind this card.
    ShaderEffectSource {
        id: behind
        visible: false
        live: true
        sourceItem: root.frosted ? root.backdrop : null
        width: root.width
        height: root.height
        sourceRect: Qt.rect(0, 0, root.width, root.height)
        recursive: false
    }

    // Keep the sampled rect glued to the card while it scrolls or animates.
    FrameAnimation {
        running: root.frosted && root.backdrop !== null && root.visible
        onTriggered: {
            const p = root.mapToItem(root.backdrop, 0, 0)
            behind.sourceRect = Qt.rect(p.x, p.y, root.width, root.height)
        }
    }

    Rectangle {
        id: shape
        anchors.fill: parent
        radius: root.radius
        visible: false
        layer.enabled: true
    }

    MultiEffect {
        anchors.fill: parent
        visible: root.frosted && root.backdrop !== null
        source: behind
        blurEnabled: true
        blur: 1.0
        blurMax: 48
        saturation: 0.25
        maskEnabled: true
        maskSource: shape
    }

    Rectangle {
        id: panel
        anchors.fill: parent
        radius: root.radius
        color: root.tint
        border.color: root.borderColor
        border.width: 1

        // faint top sheen — sells the "glass"
        Rectangle {
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 1 }
            height: Math.min(parent.height / 2, 60)
            radius: root.radius
            gradient: Gradient {
                GradientStop { position: 0; color: Qt.rgba(1, 1, 1, 0.06) }
                GradientStop { position: 1; color: "transparent" }
            }
        }
    }

    Item {
        id: inner
        x: root.padding
        y: root.padding
        width: root.width - root.padding * 2
        height: childrenRect.height
    }
}
