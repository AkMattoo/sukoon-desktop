import QtQuick
import QtQuick.Effects
import Sukoon

// Page header: eyebrow, big serif title (with an optional gradient word), rule, subtitle.
Column {
    id: root
    property string eyebrow: ""
    property string title: ""
    property string accent: ""        // rendered in the gradient after `title`
    property string subtitle: ""
    width: parent ? parent.width : 360
    topPadding: 40
    bottomPadding: 16
    spacing: 0

    Text {
        visible: root.eyebrow !== ""
        text: root.eyebrow.toUpperCase()
        color: Theme.textMid
        font.family: Theme.fontSans
        font.pixelSize: 11
        font.letterSpacing: 1.8
        bottomPadding: 8
    }
    Row {
        spacing: 8
        Text {
            text: root.title
            color: Theme.textHi
            font.family: Theme.fontDisplay
            font.pixelSize: 32
        }
        GradientText {
            visible: root.accent !== ""
            text: root.accent
            pixelSize: 32
        }
    }
    Item { width: 1; height: 16 }
    Rectangle {
        width: 48; height: 2; radius: 1
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0; color: Theme.violet }
            GradientStop { position: 1; color: "transparent" }
        }
    }
    Item { width: 1; height: 12 }
    Text {
        visible: root.subtitle !== ""
        width: Math.min(root.width, 380)
        wrapMode: Text.WordWrap
        text: root.subtitle
        color: Theme.textMid
        font.family: Theme.fontSans
        font.pixelSize: 14
    }

    // Text filled with the hero gradient (MultiEffect mask over a gradient rect).
    component GradientText: Item {
        id: gt
        property alias text: src.text
        property int pixelSize: 32
        width: src.implicitWidth
        height: src.implicitHeight
        Text {
            id: src
            visible: false
            font.family: Theme.fontDisplay
            font.pixelSize: gt.pixelSize
            color: "white"
            layer.enabled: true
        }
        Rectangle {
            id: fill
            anchors.fill: parent
            visible: false
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: Theme.violet }
                GradientStop { position: 0.5; color: Theme.orchid }
                GradientStop { position: 1; color: Theme.blush }
            }
        }
        MultiEffect {
            anchors.fill: parent
            source: fill
            maskEnabled: true
            maskSource: src
        }
    }
}
