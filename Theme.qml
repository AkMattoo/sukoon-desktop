pragma Singleton
import QtQuick

// Colour + type tokens lifted from src/styles.css.
QtObject {
    // surfaces
    readonly property color void_: "#0B0713"
    readonly property color ink: "#0F0A1E"
    readonly property color slate: "#150E29"
    readonly property color elevated: "#1C1436"
    readonly property color hairline: Qt.rgba(1, 1, 1, 0.08)
    readonly property color veil: Qt.rgba(1, 1, 1, 0.04)
    readonly property color glass: Qt.rgba(28/255, 20/255, 54/255, 0.55)
    readonly property color glassBorder: Qt.rgba(1, 1, 1, 0.10)

    // accents
    readonly property color violet: "#7C5CFF"
    readonly property color orchid: "#B06CF0"
    readonly property color blush: "#FF8FB1"
    readonly property color aqua: "#5AD1C9"
    readonly property color lavender: "#9A90B8"
    readonly property color crisis: "#FF6B85"

    // text
    readonly property color textHi: "#F5F1FF"
    readonly property color text: "#CFC6E8"
    readonly property color textMid: "#9A90B8"
    readonly property color textLow: "#6E6488"

    // type (falls back to system fonts if Inter / Fraunces aren't installed)
    readonly property string fontSans: "Inter"
    readonly property string fontDisplay: "Fraunces"

    readonly property int radius: 20
    readonly property int gutter: 20
}
