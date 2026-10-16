import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import Sukoon
import Sukoon.Backend

// routes/breathe.tsx — the orb grows on the in-breath, holds, and shrinks on the
// long out-breath. Timing lives in C++ (Breath); QML only animates to it.
Item {
    id: page

    Flickable {
        anchors.fill: parent
        contentHeight: Math.max(col.height + 24, height)
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: col
            width: page.width - 40
            x: 20
            topPadding: 40
            spacing: 18

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Breath.patternLabel.toUpperCase()
                color: Theme.textMid
                font.pixelSize: 11
                font.letterSpacing: 1.8
            }

            Item {
                id: stage
                width: 320; height: 320
                anchors.horizontalCenter: parent.horizontalCenter

                // Ripple rings that leave the orb on every in-breath.
                Repeater {
                    model: 3
                    delegate: Rectangle {
                        id: ring
                        required property int index
                        anchors.centerIn: parent
                        width: 220; height: 220
                        radius: width / 2
                        color: "transparent"
                        border.color: Theme.orchid
                        border.width: 2
                        opacity: 0
                        visible: Comfort.showRings && !Comfort.reducedMotion
                        Connections {
                            target: Breath
                            function onStateChanged() {
                                if (Breath.running && Breath.phaseKey === "in") ripple.restart()
                            }
                        }
                        SequentialAnimation {
                            id: ripple
                            PauseAnimation { duration: ring.index * 500 }
                            ParallelAnimation {
                                NumberAnimation { target: ring; property: "scale"; from: 0.8; to: 1.5; duration: 2600; easing.type: Easing.OutCubic }
                                NumberAnimation { target: ring; property: "opacity"; from: 0.55; to: 0; duration: 2600 }
                            }
                        }
                        layer.enabled: true
                        layer.effect: MultiEffect { blurEnabled: true; blur: 0.35; blurMax: 16 }
                    }
                }

                GradientOrb {
                    id: orb
                    anchors.centerIn: parent
                    size: 300
                    pulse: !Breath.running
                    glow: Breath.running && Breath.phaseKey === "hold" ? 1.4 : 1.0
                    Behavior on glow { NumberAnimation { duration: 900 } }

                    scale: Breath.targetScale * 0.87
                    Behavior on scale {
                        NumberAnimation {
                            duration: Breath.running ? Breath.phaseSeconds * 1000 : 600
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: [0.4, 0, 0.4, 1, 1, 1]
                        }
                    }
                }

                Column {
                    anchors.centerIn: parent
                    spacing: 2
                    Text {
                        id: phaseText
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Breath.phaseName
                        color: "white"
                        font.family: Theme.fontDisplay
                        font.pixelSize: 24
                        // fade between phase names instead of snapping
                        Behavior on text {
                            SequentialAnimation {
                                NumberAnimation { target: phaseText; property: "opacity"; to: 0; duration: 150 }
                                PropertyAction {}
                                NumberAnimation { target: phaseText; property: "opacity"; to: 1; duration: 250 }
                            }
                        }
                    }
                    Text {
                        visible: Breath.running
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Breath.remaining
                        color: "white"
                        font.family: Theme.fontDisplay
                        font.pixelSize: 44
                        layer.enabled: true
                        layer.effect: MultiEffect {
                            shadowEnabled: true; shadowColor: "black"; shadowBlur: 0.6; shadowOpacity: 0.4
                        }
                    }
                }
            }

            GradientButton {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 160; height: 48
                radius: 24
                icon_: Breath.running ? "❚❚" : "▶"
                text: Breath.running ? "Pause" : "Begin"
                onClicked: Breath.running ? Breath.stop() : Breath.beginCalm()
            }

            AbstractButton {
                id: over
                anchors.horizontalCenter: parent.horizontalCenter
                height: 36
                implicitWidth: overText.implicitWidth + 32
                hoverEnabled: true
                onClicked: Breath.beginGrounding()
                background: Rectangle {
                    radius: height / 2
                    color: Qt.rgba(90/255, 209/255, 201/255, over.hovered ? 0.2 : 0.12)
                    border.color: Qt.rgba(90/255, 209/255, 201/255, 0.4)
                }
                contentItem: Text {
                    id: overText
                    text: "≈  I feel overstimulated"
                    color: Theme.aqua
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }

            Text {
                width: 260
                anchors.horizontalCenter: parent.horizontalCenter
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                text: Breath.pattern === "grounding"
                      ? "You're safe. The out-breath is longer than the in-breath — that's what tells your body it's safe."
                      : "Inhale through your nose. Hold. Exhale slowly through your mouth. Let it be uneven — that's okay."
                color: Theme.textLow
                font.pixelSize: 12
            }
        }
    }
}
