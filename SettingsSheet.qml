import QtQuick
import QtQuick.Controls
import Sukoon
import Sukoon.Backend

// Comfort settings + trusted contact + delete account (SettingsSheet.tsx + DeleteAccount.tsx).
Sheet {
    id: sheet
    title: "Comfort settings"
    subtitle: "Make Sukoon feel gentler. Saved on this device."

    property bool confirmDelete: false
    property string contactMsg: ""

    onOpened: {
        confirmDelete = false
        contactMsg = ""
        Api.getTrustedContact(function (err, c) {
            if (!err && c) { cName.text = c.name || ""; cPhone.text = c.phone || "" }
        })
    }

    component Label_: Text {
        color: Theme.textHi
        font.pixelSize: 14
        font.weight: Font.DemiBold
    }
    component Hint: Text {
        width: parent ? parent.width : 300
        wrapMode: Text.WordWrap
        color: Theme.textMid
        font.pixelSize: 12
    }

    // --- audio wave intensity
    Item {
        width: parent.width; height: 22
        Label_ { text: "Audio wave intensity" }
        Text {
            anchors.right: parent.right
            text: Math.round(Comfort.audioIntensity * 100) + "%"
            color: Theme.textMid; font.family: "monospace"; font.pixelSize: 12
        }
    }
    Slider {
        width: parent.width
        from: 0.3; to: 1.4; stepSize: 0.05
        value: Comfort.audioIntensity
        onMoved: Comfort.audioIntensity = value
    }

    // --- rings
    Switch {
        width: parent.width
        text: "Show glowing speaker rings"
        checked: Comfort.showRings
        onToggled: Comfort.showRings = checked
        contentItem: Text {
            leftPadding: parent.indicator.width + 10
            text: parent.text; color: Theme.textHi; font.pixelSize: 14
            verticalAlignment: Text.AlignVCenter
        }
    }

    // --- motion
    Label_ { text: "Motion" }
    Row {
        width: parent.width
        spacing: 8
        Repeater {
            model: [{ id: "auto", label: "Auto" }, { id: "on", label: "Full" }, { id: "off", label: "Reduced" }]
            delegate: Chip {
                required property var modelData
                width: (parent.width - 16) / 3
                text: modelData.label
                checkable: false
                checked: Comfort.motion === modelData.id
                onClicked: Comfort.motion = modelData.id
            }
        }
    }
    Hint { text: "Reduced turns off the drifting aurora, orb pulses and other ambient animation." }

    Rectangle { width: parent.width; height: 1; color: Theme.hairline }

    // --- trusted contact
    Label_ { text: "Trusted contact" }
    Hint { text: "Someone you'd want to reach quickly. Nothing is ever sent for you — you always press send." }
    Field { id: cName; width: parent.width; placeholder: "Their name"; maxLength: 60 }
    Field { id: cPhone; width: parent.width; placeholder: "Phone number"; maxLength: 20 }
    Row {
        spacing: 8
        GradientButton {
            text: "Save contact"
            height: 44
            enabled: cName.text.trim() !== "" && cPhone.text.trim() !== ""
            onClicked: Api.setTrustedContact(cName.text.trim(), cPhone.text.trim(), function (err) {
                sheet.contactMsg = err ? err : "Saved."
            })
        }
        Button {
            text: "Remove"
            flat: true
            height: 44
            palette.buttonText: Theme.textMid
            onClicked: Api.clearTrustedContact(function (err) {
                if (!err) { cName.text = ""; cPhone.text = "" }
                sheet.contactMsg = err ? err : "Removed."
            })
        }
    }
    Hint { visible: sheet.contactMsg !== ""; text: sheet.contactMsg; color: Theme.aqua }

    Rectangle { width: parent.width; height: 1; color: Theme.hairline }

    // --- delete account
    Label_ { text: "Delete my data" }
    Hint { text: "Removes your handle, check-ins, posts and buddies from Sukoon. This can't be undone." }
    Button {
        text: sheet.confirmDelete ? "Tap again to permanently delete" : "Delete account"
        height: 44
        palette.button: Qt.rgba(1, 0.42, 0.52, 0.15)
        palette.buttonText: Theme.crisis
        onClicked: {
            if (!sheet.confirmDelete) { sheet.confirmDelete = true; return }
            Api.deleteAccount(function (err) {
                if (err) { sheet.contactMsg = err; return }
                sheet.close()   // Session.changed → Main swaps back to onboarding
            })
        }
    }
}
