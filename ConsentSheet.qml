import QtQuick
import QtQuick.Controls
import Sukoon
import Sukoon.Backend

// Every student accepts this before their first session
// (the backend requires agreedToTerms: true on /api/auth/guest).
Sheet {
    id: sheet
    title: "A calm space, with a few ground rules"
    subtitle: "Sukoon is an anonymous space where students support each other. Please read and agree first."
    closePolicy: Popup.NoAutoClose

    property var _onAgree: null
    property var _onLeave: null

    // Runs onAgree straight away if this version was already accepted.
    function ask(onAgree, onLeave) {
        if (Session.hasAgreed) { onAgree(); return }
        _onAgree = onAgree
        _onLeave = onLeave || null
        agreeBox.checked = false
        open()
    }

    Repeater {
        model: Catalog.agreementClauses
        delegate: Column {
            required property var modelData
            width: parent.width
            spacing: 2
            Text {
                width: parent.width
                text: modelData.h
                wrapMode: Text.WordWrap
                color: Theme.textHi
                font.pixelSize: 14
                font.weight: Font.DemiBold
            }
            Text {
                width: parent.width
                text: modelData.p
                wrapMode: Text.WordWrap
                color: "#B7AECB"
                font.pixelSize: 13
                lineHeight: 1.15
            }
        }
    }

    CheckBox {
        id: agreeBox
        width: parent.width
        text: "I have read and agree. I understand Sukoon is peer support, not professional help, and I am 18 or older."
        contentItem: Text {
            leftPadding: agreeBox.indicator.width + 10
            text: agreeBox.text
            wrapMode: Text.WordWrap
            color: Theme.textHi
            font.pixelSize: 13
        }
    }

    Row {
        width: parent.width
        spacing: 10
        Button {
            text: "Not now"
            flat: true
            height: 50
            palette.buttonText: "#B7AECB"
            onClicked: { sheet.close(); if (sheet._onLeave) sheet._onLeave() }
        }
        GradientButton {
            width: parent.width - 110
            text: "Agree & continue"
            enabled: agreeBox.checked
            onClicked: {
                Session.acceptAgreement()
                sheet.close()
                if (sheet._onAgree) sheet._onAgree()
            }
        }
    }
}
