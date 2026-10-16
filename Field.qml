import QtQuick
import QtQuick.Controls
import Sukoon

// Dark, rounded input. `multiline` swaps in a TextArea.
Item {
    id: root
    property alias text: proxy.text
    property string placeholder: ""
    property string leading: ""        // e.g. "⌕"
    property bool multiline: false
    property int maxLength: 500
    property int boxHeight: multiline ? 84 : 46
    signal accepted()

    implicitHeight: boxHeight
    implicitWidth: 300

    // Single source of truth for the text, whichever editor is active.
    QtObject { id: proxy; property string text: "" }

    Rectangle {
        anchors.fill: parent
        radius: 16
        color: Qt.rgba(0, 0, 0, 0.22)
        border.color: (single.activeFocus || area.activeFocus) ? Qt.rgba(1, 1, 1, 0.30) : Qt.rgba(1, 1, 1, 0.10)
        Behavior on border.color { ColorAnimation { duration: 150 } }
    }

    Text {
        id: lead
        visible: root.leading !== ""
        text: root.leading
        color: Theme.textMid
        font.pixelSize: 16
        x: 14
        anchors.verticalCenter: root.multiline ? undefined : parent.verticalCenter
        y: root.multiline ? 12 : 0
    }

    TextField {
        id: single
        visible: !root.multiline
        anchors.fill: parent
        leftPadding: lead.visible ? 38 : 14
        rightPadding: 14
        background: null
        color: Theme.textHi
        placeholderText: root.placeholder
        placeholderTextColor: Theme.textLow
        font.family: Theme.fontSans
        font.pixelSize: 14
        maximumLength: root.maxLength
        text: proxy.text
        onTextEdited: proxy.text = text
        onAccepted: root.accepted()
        selectByMouse: true
    }

    ScrollView {
        visible: root.multiline
        anchors.fill: parent
        TextArea {
            id: area
            leftPadding: 14; rightPadding: 14; topPadding: 12
            background: null
            color: Theme.textHi
            wrapMode: TextArea.Wrap
            placeholderText: root.placeholder
            placeholderTextColor: Theme.textLow
            font.family: Theme.fontSans
            font.pixelSize: 14
            text: proxy.text
            selectByMouse: true
            onTextChanged: {
                if (text.length > root.maxLength) text = text.slice(0, root.maxLength)
                if (proxy.text !== text) proxy.text = text
            }
        }
    }
}
