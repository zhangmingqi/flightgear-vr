pragma Singleton
import QtQml 2.0

QtObject
{
    readonly property int margin: 8
    readonly property int roundRadius: 6

    readonly property int inset: 20
    readonly property int strutSize: 50

    readonly property string frameColor: "#68A6E1"
    readonly property string minorFrameColor: "#9f9f9f"

    readonly property string themeColor: "#1b7ad3"
    readonly property string destructiveActionColor: "#c62703"

    readonly property string activeColor: Qt.darker(themeColor)

    readonly property string inactiveThemeColor: "#9f9f9f"
    readonly property string disabledThemeColor: disabledTextColor

    readonly property string baseTextColor: "#3f3f3f"

    readonly property int baseFontPixelSize: 12
    readonly property int subHeadingFontPixelSize: 14
    readonly property int headingFontPixelSize: 18

    readonly property string disabledTextColor: "#5f5f5f"

    readonly property double panelOpacity: 0.5
}

