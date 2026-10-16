import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import Sukoon
import Sukoon.Backend

ApplicationWindow {
    id: win
    width: 430
    height: 900
    minimumWidth: 360
    minimumHeight: 640
    visible: true
    title: "Sukoon — a calm, anonymous space to be heard"
    color: Theme.void_
    font.family: Theme.fontSans

    // Every GlassCard samples this for its frosted backdrop.
    property Item backdrop: aurora

    // ---- navigation helpers used by pages ----
    function openRoom(roomId) {
        Session.saveLastRoom(roomId)
        nav.push(roomPage, { roomId: roomId })
    }
    function goTab(i) { if (nav.depth > 1) nav.pop(null); shell.tab = i }
    function openSos(proactive) { sos.proactive = !!proactive; sos.open() }
    function toast(msg) { toaster.show(msg) }

    AuroraBackground {
        id: aurora
        anchors.fill: parent
        intensity: shell.tab === 2 && Breath.running ? 1.35 : 1.0
        Behavior on intensity { NumberAnimation { duration: 1200 } }
    }

    StackView {
        id: nav
        anchors.fill: parent
        initialItem: Session.signedIn ? appShell : onboarding

        // calm cross-fade + lift between screens
        pushEnter: Transition {
            ParallelAnimation {
                NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 320 }
                NumberAnimation { property: "y"; from: 24; to: 0; duration: 380; easing.type: Easing.OutCubic }
            }
        }
        pushExit: Transition { NumberAnimation { property: "opacity"; to: 0; duration: 200 } }
        popEnter: Transition { NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 260 } }
        popExit: Transition {
            ParallelAnimation {
                NumberAnimation { property: "opacity"; to: 0; duration: 220 }
                NumberAnimation { property: "y"; to: 24; duration: 220 }
            }
        }
        replaceEnter: pushEnter
        replaceExit: pushExit
    }

    Connections {
        target: Session
        function onChanged() {
            const wantShell = Session.signedIn
            const onShell = nav.get(0) && nav.get(0).objectName === "shell"
            if (wantShell && !onShell) nav.replace(null, appShell)
            else if (!wantShell && onShell) nav.replace(null, onboarding)
        }
    }
    Connections {
        target: Api
        function onCrisis() { win.openSos(true) }
        function onSessionExpired() { win.toast("Your session expired — please enter again.") }
    }

    Component { id: onboarding; OnboardingPage {} }
    Component { id: roomPage; RoomPage {} }

    // Shell kept as a property so goTab() can reach it from anywhere.
    property alias shell: shellHolder.shell
    QtObject { id: shellHolder; property var shell: ({ tab: 0 }) }

    Component {
        id: appShell
        Item {
            id: shellRoot
            objectName: "shell"
            property int tab: 0
            Component.onCompleted: shellHolder.shell = shellRoot

            // single centred phone-width column at every window size
            Item {
                id: column
                width: Math.min(parent.width, 480)
                height: parent.height
                anchors.horizontalCenter: parent.horizontalCenter

                Loader {
                    id: page
                    anchors { left: parent.left; right: parent.right; top: parent.top; bottom: footer.top }
                    sourceComponent: [homeC, roomsC, breatheC, buddyC, circleC][shellRoot.tab]
                    onLoaded: { fade.restart() }
                    ParallelAnimation {
                        id: fade
                        NumberAnimation { target: page.item; property: "opacity"; from: 0; to: 1; duration: 320 }
                        NumberAnimation { target: page.item; property: "y"; from: 16; to: 0; duration: 380; easing.type: Easing.OutCubic }
                    }
                }

                // sticky footer: settings · SOS · tabs, over a fade to the void colour
                Rectangle {
                    anchors.fill: footer
                    anchors.topMargin: -30
                    gradient: Gradient {
                        GradientStop { position: 0; color: "transparent" }
                        GradientStop { position: 0.45; color: Qt.rgba(11/255, 7/255, 19/255, 0.92) }
                    }
                }
                Column {
                    id: footer
                    anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: 12 }
                    spacing: 8

                    Item {
                        width: parent.width
                        height: 46
                        RoundButton {
                            id: settingsBtn
                            width: 44; height: 44
                            text: "⚙"
                            font.pixelSize: 17
                            Accessible.name: "Open comfort settings"
                            onClicked: settings.open()
                            palette.button: Theme.glass
                            palette.buttonText: Theme.textHi
                        }
                        SosButton {
                            anchors.right: parent.right
                            onClicked: win.openSos(false)
                        }
                    }
                    TabBar {
                        width: parent.width
                        currentIndex: shellRoot.tab
                        onSelected: (i) => shellRoot.tab = i
                    }
                }
            }

            Component { id: homeC; HomePage {} }
            Component { id: roomsC; RoomsPage {} }
            Component { id: breatheC; BreathePage {} }
            Component { id: buddyC; BuddyPage {} }
            Component { id: circleC; CirclePage {} }
        }
    }

    // The SOS button gets its own warm glow that gently pulses so it's always findable.
    component SosButton: AbstractButton {
        id: sosBtn
        width: 96; height: 46
        hoverEnabled: true
        Accessible.name: "Open crisis helplines"
        scale: down ? 0.95 : 1
        Behavior on scale { NumberAnimation { duration: 110 } }
        background: Item {
            Rectangle {
                id: sosFill
                anchors.fill: parent
                radius: height / 2
                visible: false
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0; color: "#ff5a78" }
                    GradientStop { position: 1; color: "#ff8fb1" }
                }
            }
            MultiEffect {
                anchors.fill: parent
                source: sosFill
                shadowEnabled: true
                shadowColor: "#ff5a78"
                shadowBlur: 1.0
                shadowVerticalOffset: 6
                SequentialAnimation on shadowOpacity {
                    running: !Comfort.reducedMotion; loops: Animation.Infinite
                    NumberAnimation { from: 0.45; to: 0.85; duration: 1600; easing.type: Easing.InOutSine }
                    NumberAnimation { from: 0.85; to: 0.45; duration: 1600; easing.type: Easing.InOutSine }
                }
            }
        }
        contentItem: Text {
            text: "♥  SOS"
            color: "white"
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: 14
            font.weight: Font.DemiBold
        }
    }

    // Dev aid: run with --tour to step through every tab and sheet (smoke test / screenshots).
    Timer {
        property int step: 0
        interval: 900; repeat: true
        running: Qt.application.arguments.indexOf("--tour") >= 0 && Session.signedIn
        onTriggered: {
            const acts = [() => goTab(1), () => goTab(2), () => Breath.beginCalm(), () => goTab(3), () => goTab(4),
                          () => openRoom("1"), () => nav.pop(), () => openSos(true), () => sos.close(),
                          () => settings.open(), () => settings.close(), () => { Breath.stop(); goTab(0) }]
            if (step < acts.length) acts[step++]()
            else Qt.quit()
        }
    }

    SosSheet { id: sos }
    SettingsSheet { id: settings }
    ConsentSheet { id: consentSheet }
    readonly property alias consent: consentSheet

    Toast { id: toaster; parent: Overlay.overlay }
}
