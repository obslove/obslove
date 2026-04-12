import qs.modules.common
import qs.modules.common.widgets
import qs.services
import "./cards"
import QtQuick
import QtQuick.Layouts
import Quickshell.Services.UPower

StyledPopup {
    id: root

    function formatPercentage(value) {
        return `${Math.round(value * 100)}%`;
    }

    function formatTemperature(value) {
        return value >= 0 ? `${Math.round(value)}°C` : "--";
    }

    function formatCpuTemperature() {
        return ResourceUsage.cpuTemp || "--";
    }

    function isActivePowerProfile(profile) {
        return PowerProfiles.profile === profile;
    }

    function powerProfileLabel(profile) {
        switch (profile) {
        case PowerProfile.PowerSaver: return Translation.tr("Power Saver");
        case PowerProfile.Balanced: return Translation.tr("Balanced");
        case PowerProfile.Performance: return Translation.tr("Performance");
        default: return "--";
        }
    }

    function powerProfileIcon(profile) {
        switch (profile) {
        case PowerProfile.PowerSaver: return "energy_savings_leaf";
        case PowerProfile.Balanced: return "airwave";
        case PowerProfile.Performance: return "local_fire_department";
        default: return "power";
        }
    }

    contentItem: ColumnLayout {
        anchors.centerIn: parent
        spacing: 12

        HeroCard {
            implicitWidth: 440
            implicitHeight: 168
            margins: 14
            iconSize: 100
            icon: root.powerProfileIcon(PowerProfiles.profile)
            title: Translation.tr("Power Profile")
            subtitle: root.powerProfileLabel(PowerProfiles.profile)
            titleSize: Math.round(Appearance.font.pixelSize.hugeass * 1.65)
            subtitleSize: Appearance.font.pixelSize.large

            RowLayout {
                Layout.alignment: Qt.AlignRight
                spacing: 4

                Repeater {
                    model: PowerProfiles.hasPerformanceProfile
                        ? [PowerProfile.PowerSaver, PowerProfile.Balanced, PowerProfile.Performance]
                        : [PowerProfile.PowerSaver, PowerProfile.Balanced]

                    delegate: Rectangle {
                        required property int modelData

                        readonly property bool active: root.isActivePowerProfile(modelData)
                        readonly property color activeContainerColor: Appearance.colors.colPrimary
                        readonly property color inactiveContainerColor: Qt.alpha(Appearance.colors.colPrimary, 0.28)
                        readonly property color activeContentColor: Appearance.colors.colOnPrimary
                        readonly property color inactiveContentColor: Appearance.colors.colOnPrimaryContainer

                        radius: Appearance.rounding.large
                        color: active
                            ? activeContainerColor
                            : inactiveContainerColor
                        border.width: 0
                        implicitHeight: modeRow.implicitHeight + 8
                        implicitWidth: modeRow.implicitWidth + 12

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: PowerProfiles.profile = parent.modelData
                        }

                        RowLayout {
                            id: modeRow
                            anchors.centerIn: parent
                            spacing: 4

                            MaterialSymbol {
                                text: root.powerProfileIcon(modelData)
                                fill: 0
                                iconSize: Appearance.font.pixelSize.small
                                color: active
                                    ? activeContentColor
                                    : inactiveContentColor
                            }

                            StyledText {
                                text: root.powerProfileLabel(modelData)
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                font.weight: active ? Font.Bold : Font.DemiBold
                                color: active
                                    ? activeContentColor
                                    : inactiveContentColor
                            }
                        }
                    }
                }
            }
        }

        GridLayout {
            Layout.fillWidth: true
            columns: 2
            columnSpacing: 8
            rowSpacing: 8
            uniformCellWidths: true

            MetricCard {
                title: Translation.tr("GPU")
                value: ResourceUsage.gpuAvailable
                    ? `${root.formatPercentage(ResourceUsage.gpuUsage)} • ${root.formatTemperature(ResourceUsage.gpuTemperature)}`
                    : "--"
                symbol: "memory_alt"
                shapeString: "Cookie4Sided"
                accentColor: Appearance.colors.colPrimaryContainer
                symbolColor: Appearance.colors.colOnPrimaryContainer
            }

            MetricCard {
                title: Translation.tr("CPU")
                value: `${root.formatPercentage(ResourceUsage.cpuUsage)} • ${root.formatCpuTemperature()}`
                symbol: "planner_review"
                shapeString: "Pentagon"
                accentColor: Appearance.colors.colSecondaryContainer
                symbolColor: Appearance.colors.colOnSecondaryContainer
            }

            MetricCard {
                title: Translation.tr("Storage")
                value: root.formatPercentage(ResourceUsage.diskUsedPercentage)
                symbol: "hard_drive_2"
                shapeString: "SoftBurst"
                accentColor: Appearance.colors.colTertiaryContainer
                symbolColor: Appearance.colors.colOnTertiaryContainer
            }

            MetricCard {
                title: `${Translation.tr("RAM")} • ${Translation.tr("Swap")}`
                value: ResourceUsage.swapTotal > 0
                    ? `${root.formatPercentage(ResourceUsage.memoryUsedPercentage)} • ${root.formatPercentage(ResourceUsage.swapUsedPercentage)}`
                    : root.formatPercentage(ResourceUsage.memoryUsedPercentage)
                symbol: "memory"
                shapeString: "Cookie4Sided"
                accentColor: Appearance.colors.colPrimaryContainer
                symbolColor: Appearance.colors.colOnPrimaryContainer
            }
        }
    }
}
