import qs.services
import qs.modules.common
import QtQuick
import QtQuick.Layouts
import qs.modules.ii.bar as Bar

MouseArea {
    id: root
    implicitHeight: columnLayout.implicitHeight + 15
    implicitWidth: columnLayout.implicitWidth
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

    ColumnLayout {
        id: columnLayout
        spacing: 10
        anchors.centerIn: parent

        Loader {
            active: ResourceUsage.gpuAvailable || !ResourceUsage.gpuProbeFinished
            visible: active
            Layout.alignment: Qt.AlignHCenter
            sourceComponent: Resource {
                iconName: "memory_alt"
                percentage: ResourceUsage.gpuUsage
                warningThreshold: 100
            }
        }

        Resource {
            Layout.alignment: Qt.AlignHCenter
            iconName: "planner_review"
            percentage: ResourceUsage.cpuUsage
            warningThreshold: Config.options.bar.resources.cpuWarningThreshold
        }

        Resource {
            Layout.alignment: Qt.AlignHCenter
            iconName: "hard_drive_2"
            percentage: ResourceUsage.diskUsedPercentage
            warningThreshold: 100
        }

        Resource {
            Layout.alignment: Qt.AlignHCenter
            iconName: "memory"
            percentage: ResourceUsage.memoryUsedPercentage
            warningThreshold: Config.options.bar.resources.memoryWarningThreshold
        }

    }

    Loader {
        active: true
        sourceComponent: root.compactMode ? resourcesPopupCompact : resourcesPopup
    }

    Component {
        id: resourcesPopup

        Bar.ResourcesPopup {
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

        Bar.ResourcesPopupCompact {
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
