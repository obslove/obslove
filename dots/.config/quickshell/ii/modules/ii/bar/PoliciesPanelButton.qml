import QtQuick
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets

RippleButton {
    id: leftSidebarButton

    property bool showPing: false
    readonly property real sideButtonIconSize: 20
    readonly property string resolvedIconSource: {
        const icon = Config.options.bar.topLeftIcon;
        if (icon === "distro")
            return SystemInfo.distroIcon;
        if (!icon || icon.length === 0)
            return "spark-symbolic";
        if (icon.includes("/") || icon.endsWith(".svg") || icon.endsWith("-symbolic"))
            return icon;
        return `${icon}-symbolic`;
    }

    property real buttonPadding: 5
    implicitWidth: distroIcon.width + buttonPadding * 2
    implicitHeight: distroIcon.height + buttonPadding * 2
    buttonRadius: Appearance.rounding.barControl(implicitHeight)
    colBackgroundHover: Appearance.colors.colLayer1Hover
    colRipple: Appearance.colors.colLayer1Active
    colBackgroundToggled: Appearance.colors.colSecondaryContainer
    colBackgroundToggledHover: Appearance.colors.colSecondaryContainerHover
    colRippleToggled: Appearance.colors.colSecondaryContainerActive
    toggled: GlobalStates.sidebarLeftOpen

    onPressed: {
        GlobalStates.sidebarLeftOpen = !GlobalStates.sidebarLeftOpen;
    }

    Connections {
        target: Ai
        function onResponseFinished() {
            if (GlobalStates.sidebarLeftOpen) return;
            leftSidebarButton.showPing = true;
        }
    }

    Connections {
        target: Booru
        function onResponseFinished() {
            if (GlobalStates.sidebarLeftOpen) return;
            leftSidebarButton.showPing = true;
        }
    }

    Connections {
        target: GlobalStates
        function onSidebarLeftOpenChanged() {
            leftSidebarButton.showPing = false;
        }
    }

    CustomIcon {
        id: distroIcon
        anchors.centerIn: parent
        width: leftSidebarButton.sideButtonIconSize
        height: leftSidebarButton.sideButtonIconSize
        source: leftSidebarButton.resolvedIconSource
        colorize: true
        color: Appearance.colors.colOnLayer0

        Rectangle {
            opacity: leftSidebarButton.showPing ? 1 : 0
            visible: opacity > 0
            anchors {
                bottom: parent.bottom
                right: parent.right
                bottomMargin: -2
                rightMargin: -2
            }
            implicitWidth: 8
            implicitHeight: 8
            radius: Appearance.rounding.barControl(implicitHeight)
            color: Appearance.colors.colTertiary

            Behavior on opacity {
                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
            }
        }
    }
}
