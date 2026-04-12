import qs.modules.common
import qs.services
import QtQuick
import QtQuick.Layouts

MouseArea {
    id: root
    implicitWidth: rowLayout.implicitWidth + rowLayout.anchors.leftMargin + rowLayout.anchors.rightMargin
    implicitHeight: Appearance.sizes.barHeight
    hoverEnabled: !Config.options.bar.tooltips.clickToShow
    cursorShape: Qt.PointingHandCursor
    property bool compactMode: Config.options.bar.tooltips.compactPopups
    property bool popupPinned: false
    property bool suppressHoverPopup: false

    acceptedButtons: Qt.MiddleButton | Qt.BackButton | Qt.ForwardButton | Qt.RightButton | Qt.LeftButton

    onExited: root.suppressHoverPopup = false

    onPressed: mouse => {
        if (mouse.button === Qt.LeftButton) {
            if (root.popupPinned) {
                root.popupPinned = false
                root.suppressHoverPopup = true
            } else {
                root.suppressHoverPopup = false
                root.popupPinned = true
            }
            mouse.accepted = true
        }
    }

    RowLayout {
        id: rowLayout

        spacing: 0
        anchors.fill: parent
        anchors.leftMargin: 4
        anchors.rightMargin: 4

        Resource {
            iconName: "memory_alt"
            percentage: ResourceUsage.gpuAvailable ? ResourceUsage.gpuUsage : 0
            shown: ResourceUsage.gpuAvailable || !ResourceUsage.gpuProbeFinished
            warningThreshold: 100
        }

        Resource {
            iconName: "planner_review"
            percentage: ResourceUsage.cpuUsage
            shown: true
            Layout.leftMargin: shown ? 6 : 0
            warningThreshold: Config.options.bar.resources.cpuWarningThreshold
        }

        Resource {
            iconName: "hard_drive_2"
            percentage: ResourceUsage.diskUsedPercentage
            shown: true
            Layout.leftMargin: shown ? 6 : 0
            warningThreshold: 100
        }

        Resource {
            iconName: "memory"
            percentage: ResourceUsage.memoryUsedPercentage
            shown: true
            Layout.leftMargin: shown ? 6 : 0
            warningThreshold: Config.options.bar.resources.memoryWarningThreshold
        }

    }

    Loader {
        active: true
        sourceComponent: root.compactMode ? resourcesPopupCompact : resourcesPopup
    }

    Component {
        id: resourcesPopup

        ResourcesPopup {
            hoverTarget: root
            forceActive: root.popupPinned
            suppressHover: root.suppressHoverPopup
            dismissOnOutsideClickWhenForced: true
            onOutsideDismissRequested: {
                root.popupPinned = false
                root.suppressHoverPopup = true
            }
        }
    }

    Component {
        id: resourcesPopupCompact

        ResourcesPopupCompact {
            hoverTarget: root
            forceActive: root.popupPinned
            suppressHover: root.suppressHoverPopup
            dismissOnOutsideClickWhenForced: true
            onOutsideDismissRequested: {
                root.popupPinned = false
                root.suppressHoverPopup = true
            }
        }
    }
}
