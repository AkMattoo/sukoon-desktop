import QtQuick
import QtQuick.Effects
import Sukoon
import Sukoon.Backend

// The app's living background: three soft colour fields drifting behind a
// heavy MultiEffect blur, plus a fixed film-grain layer. Every glass card
// samples this item for its frosted backdrop.
Item {
    id: root
    property bool animate: !Comfort.reducedMotion
    property real intensity: 1.0     // BreathePage turns this up

    Rectangle { anchors.fill: parent; color: Theme.void_ }

    Item {
        id: blobs
        anchors.fill: parent
        visible: false   // rendered only through the blur below

        component Blob: Rectangle {
            id: b
            property real ox: 0
            property real oy: 0
            property real drift: 60
            property int period: 18000
            width: Math.max(root.width, root.height) * 0.75
            height: width
            radius: width / 2
            opacity: 0.55 * root.intensity
            x: ox - width / 2
            y: oy - height / 2

            SequentialAnimation on x {
                running: root.animate; loops: Animation.Infinite
                NumberAnimation { to: b.ox - b.width / 2 + b.drift; duration: b.period; easing.type: Easing.InOutSine }
                NumberAnimation { to: b.ox - b.width / 2 - b.drift; duration: b.period; easing.type: Easing.InOutSine }
            }
            SequentialAnimation on y {
                running: root.animate; loops: Animation.Infinite
                NumberAnimation { to: b.oy - b.height / 2 - b.drift; duration: b.period * 1.3; easing.type: Easing.InOutSine }
                NumberAnimation { to: b.oy - b.height / 2 + b.drift; duration: b.period * 1.3; easing.type: Easing.InOutSine }
            }
        }

        Blob { color: Theme.violet; ox: root.width * 0.15; oy: root.height * 0.10; period: 21000 }
        Blob { color: Theme.orchid; ox: root.width * 0.95; oy: root.height * 0.45; period: 17000; drift: 80; opacity: 0.35 * root.intensity }
        Blob { color: Theme.blush;  ox: root.width * 0.30; oy: root.height * 1.05; period: 25000; opacity: 0.22 * root.intensity }
    }

    MultiEffect {
        anchors.fill: parent
        source: blobs
        blurEnabled: true
        blur: 1.0
        blurMax: 64
        blurMultiplier: 1.6
        saturation: 0.15
        brightness: -0.35   // keep it moody so text stays readable
    }

    // Film grain — subtle, but it's what stops the screen reading as a flat template.
    Canvas {
        anchors.fill: parent
        opacity: 0.06
        renderStrategy: Canvas.Cooperative
        onPaint: {
            const ctx = getContext("2d")
            const img = ctx.createImageData(width, height)
            for (let i = 0; i < img.data.length; i += 4) {
                const v = Math.random() * 255
                img.data[i] = v; img.data[i + 1] = v; img.data[i + 2] = v; img.data[i + 3] = 255
            }
            ctx.drawImage(img, 0, 0)
        }
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
    }
}
