import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import Sukoon
import Sukoon.Backend

// Crisis helplines. Numbers are hardcoded so they work offline; the last
// helpline the student tried floats to the top.
Sheet {
    id: sheet
    property bool proactive: false
    title: "You matter 💜"
    subtitle: proactive
        ? "It sounds like things feel really heavy right now. You deserve support — please reach out to someone who can help."
        : "You're not alone. One tap connects you to a trained listener in India, free and confidential."

    readonly property var last: Session.lastSos
    readonly property var ordered: {
        const all = Catalog.helplines
        if (!last || !last.number) return all
        const hit = all.filter(h => h.number === last.number)
        return hit.length ? hit.concat(all.filter(h => h.number !== last.number)) : all
    }

    Rectangle {
        visible: !!(sheet.last && sheet.last.name)
        width: parent.width
        height: 38
        radius: 14
        color: Qt.rgba(1, 1, 1, 0.05)
        border.color: Qt.rgba(1, 1, 1, 0.10)
        Text {
            anchors.verticalCenter: parent.verticalCenter
            x: 12
            text: sheet.last && sheet.last.name
                  ? "🕑  Last tried: <b>" + sheet.last.name + "</b> · " + Session.timeAgo(sheet.last.at)
                  : ""
            textFormat: Text.StyledText
            color: Theme.textMid
            font.pixelSize: 12
        }
    }

    Repeater {
        model: sheet.ordered
        delegate: AbstractButton {
            id: line
            required property var modelData
            width: parent.width
            height: 64
            hoverEnabled: true
            scale: down ? 0.98 : 1
            Behavior on scale { NumberAnimation { duration: 100 } }
            onClicked: {
                Session.saveLastSos(modelData.name, modelData.number)
                Qt.openUrlExternally("tel:" + modelData.number.replace(/[^0-9+]/g, ""))
            }
            background: Rectangle {
                radius: 16
                color: line.hovered ? Qt.rgba(1, 1, 1, 0.10) : Qt.rgba(1, 1, 1, 0.05)
                border.color: Qt.rgba(1, 1, 1, 0.10)
            }
            contentItem: Item {
                Column {
                    x: 16
                    anchors.verticalCenter: parent.verticalCenter
                    Text { text: line.modelData.name; color: Theme.textHi; font.pixelSize: 15; font.weight: Font.DemiBold }
                    Text { text: line.modelData.desc; color: Theme.textMid; font.pixelSize: 12 }
                }
                Row {
                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 10
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: line.modelData.number
                        color: Theme.text
                        font.family: "monospace"
                        font.pixelSize: 13
                    }
                    Item {
                        width: 36; height: 36
                        Rectangle {
                            id: dial
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
                            source: dial
                            shadowEnabled: true
                            shadowColor: Theme.violet
                            shadowBlur: 0.7
                            shadowOpacity: line.hovered ? 0.9 : 0.5
                        }
                        Text { anchors.centerIn: parent; text: "✆"; color: "white"; font.pixelSize: 16 }
                    }
                }
            }
        }
    }

    Text {
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        text: "Anonymous. Free. Judgement-free."
        color: Theme.textMid
        font.pixelSize: 12
        topPadding: 6
    }
}
