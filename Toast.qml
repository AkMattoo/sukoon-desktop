import QtQuick
import Sukoon

// Small floating confirmation ("Thanks for flagging this.").
GlassCard {
    id: toast
    property string message: ""
    function show(msg) { message = msg; hideTimer.restart(); state = "shown" }

    width: Math.min(parent ? parent.width - 40 : 320, 380)
    anchors.horizontalCenter: parent ? parent.horizontalCenter : undefined
    padding: 14
    radius: 18
    opacity: 0
    y: -height
    z: 100
    state: ""
    states: State {
        name: "shown"
        PropertyChanges { toast.opacity: 1; toast.y: 16 }
    }
    transitions: Transition {
        NumberAnimation { properties: "opacity,y"; duration: 260; easing.type: Easing.OutCubic }
    }
    Timer { id: hideTimer; interval: 2600; onTriggered: toast.state = "" }

    Text {
        width: parent.width
        text: toast.message
        wrapMode: Text.WordWrap
        horizontalAlignment: Text.AlignHCenter
        color: Theme.textHi
        font.pixelSize: 13
    }
}
