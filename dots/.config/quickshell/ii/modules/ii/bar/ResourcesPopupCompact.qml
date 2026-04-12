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
            Layout.minimumWidth: 360
            icon: root.powerProfileIcon(PowerProfiles.profile)
            iconSize: 100
            title: Translation.tr("Power Profile")
            subtitle: root.powerProfileLabel(PowerProfiles.profile)

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

                        radius: Appearance.rounding.large
                        color: active
                            ? Appearance.colors.colSecondaryContainer
                            : Qt.alpha(Appearance.colors.colOnPrimaryContainer, 0.08)
                        border.width: 1
                        border.color: active
                            ? Qt.alpha(Appearance.colors.colOnSecondaryContainer, 0.16)
                            : Qt.alpha(Appearance.colors.colOnPrimaryContainer, 0.12)
                        implicitHeight: modeRow.implicitHeight + 10
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
                                    ? Appearance.colors.colOnSecondaryContainer
                                    : Appearance.colors.colOnPrimaryContainer
                            }

                            StyledText {
                                text: root.powerProfileLabel(modelData)
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                font.weight: active ? Font.Bold : Font.DemiBold
                                color: active
                                    ? Appearance.colors.colOnSecondaryContainer
                                    : Appearance.colors.colOnPrimaryContainer
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
