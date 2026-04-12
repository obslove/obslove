import qs.modules.common
import qs.modules.common.widgets
import qs.services
import "./cards"
import QtQuick
import QtQuick.Layouts
import Quickshell.Services.UPower

StyledPopup {
    id: root
    popupRadius: Appearance.rounding.large

    property int cardMargins: 14
    property int cardSpacing: 8
    property int gridSpacing: 8

    function formatGB(kb) {
        return (kb / (1024 * 1024)).toFixed(1) + " GB";
    }

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

    component CompactStatChip: Rectangle {
        id: chip
        required property string label
        required property string value
        property string symbol: ""
        property color chipColor: Appearance.colors.colSurfaceContainerHighest
        property color chipTextColor: Appearance.colors.colOnSurface

        implicitHeight: chipRow.implicitHeight + 8
        implicitWidth: chipRow.implicitWidth + 12
        radius: Appearance.rounding.full
        color: chipColor
        RowLayout {
            id: chipRow
            anchors.centerIn: parent
            spacing: 4

            MaterialSymbol {
                visible: chip.symbol !== ""
                text: chip.symbol
                fill: 1
                iconSize: Appearance.font.pixelSize.small
                color: Appearance.colors.colOnSurfaceVariant
            }

            StyledText {
                text: chip.label
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colOnSurfaceVariant
            }

            StyledText {
                text: chip.value
                font.pixelSize: Appearance.font.pixelSize.smaller
                font.weight: Font.Bold
                color: chip.chipTextColor
            }
        }
    }

    component SectionDivider: Rectangle {
        Layout.fillWidth: true
        height: 1
        radius: 1
        color: Appearance.colors.colSurfaceContainerHighest
    }

    contentItem: ColumnLayout {
        anchors.centerIn: parent
        spacing: 12

        HeroCard {
            Layout.minimumWidth: 700
            icon: root.powerProfileIcon(PowerProfiles.profile)
            title: Translation.tr("Power Profile")
            subtitle: root.powerProfileLabel(PowerProfiles.profile)

            RowLayout {
                Layout.alignment: Qt.AlignRight
                spacing: 6

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
                        implicitHeight: modeRow.implicitHeight + 10
                        implicitWidth: modeRow.implicitWidth + 14

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: PowerProfiles.profile = parent.modelData
                        }

                        RowLayout {
                            id: modeRow
                            anchors.centerIn: parent
                            spacing: 6

                            MaterialSymbol {
                                text: root.powerProfileIcon(modelData)
                                fill: 0
                                iconSize: Appearance.font.pixelSize.normal
                                color: active
                                    ? activeContentColor
                                    : inactiveContentColor
                            }

                            StyledText {
                                text: root.powerProfileLabel(modelData)
                                font.pixelSize: Appearance.font.pixelSize.small
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
            columnSpacing: root.gridSpacing
            rowSpacing: root.gridSpacing
            uniformCellWidths: true

            Loader {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignTop
                active: ResourceUsage.gpuAvailable
                sourceComponent: SectionCard {
                    Layout.fillWidth: true
                    margins: root.cardMargins
                    spacing: root.cardSpacing
                    showDivider: false
                    title: Translation.tr("GPU")
                    subtitle: ResourceUsage.gpuModel !== "Unknown GPU" ? ResourceUsage.gpuModel : ""
                    icon: "memory_alt"
                    headerExtra: [
                        InfoPill {
                            Layout.fillWidth: false
                            compact: true
                            text: root.formatPercentage(ResourceUsage.gpuUsage)
                            icon: "memory_alt"
                            pillHeight: 24
                            shapeSize: 14
                            horizontalPadding: 6
                            textHorizontalOffset: 4
                            textPixelSize: Appearance.font.pixelSize.smaller
                            iconPixelSize: Appearance.font.pixelSize.smaller
                            containerColor: Appearance.colors.colPrimaryContainer
                            shapeColor: Appearance.colors.colPrimary
                            symbolColor: Appearance.colors.colOnPrimary
                            textColor: Appearance.colors.colOnPrimaryContainer
                        }
                    ]

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        SectionDivider {}

                        RowLayout {
                            Layout.fillWidth: true

                            StyledText {
                                text: Translation.tr("Usage")
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                color: Appearance.colors.colOnSurfaceVariant
                            }

                            Item {
                                Layout.fillWidth: true
                            }

                            StyledText {
                                text: root.formatPercentage(ResourceUsage.gpuUsage)
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                font.weight: Font.Bold
                                color: Appearance.colors.colOnSurface
                            }
                        }

                        StyledProgressBar {
                            Layout.fillWidth: true
                            value: ResourceUsage.gpuUsage
                            valueBarHeight: 7
                            valueBarGap: 4
                            highlightColor: Appearance.colors.colPrimary
                            trackColor: Appearance.colors.colSurfaceContainerHighest
                        }

                        SectionDivider {}

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 6

                            CompactStatChip {
                                label: Translation.tr("Temp")
                                value: root.formatTemperature(ResourceUsage.gpuTemperature)
                                symbol: "device_thermostat"
                                chipColor: Appearance.colors.colPrimaryContainer
                            }

                            Loader {
                                active: ResourceUsage.gpuMemoryTotal > 1
                                sourceComponent: CompactStatChip {
                                    label: Translation.tr("VRAM")
                                    value: `${(ResourceUsage.gpuMemoryUsed / 1024).toFixed(1)}/${(ResourceUsage.gpuMemoryTotal / 1024).toFixed(1)} GB`
                                    symbol: "memory"
                                    chipColor: Appearance.colors.colSecondaryContainer
                                }
                            }
                        }
                    }
                }
            }

            SectionCard {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignTop
                margins: root.cardMargins
                spacing: root.cardSpacing
                showDivider: false
                title: Translation.tr("CPU")
                subtitle: ResourceUsage.cpuModel !== "Unknown CPU" ? ResourceUsage.cpuModel : ""
                icon: "planner_review"
                headerExtra: [
                    InfoPill {
                        Layout.fillWidth: false
                        compact: true
                        text: root.formatPercentage(ResourceUsage.cpuUsage)
                        icon: "planner_review"
                        pillHeight: 24
                        shapeSize: 14
                        horizontalPadding: 6
                        textHorizontalOffset: 4
                        textPixelSize: Appearance.font.pixelSize.smaller
                        iconPixelSize: Appearance.font.pixelSize.smaller
                        containerColor: Appearance.colors.colSecondaryContainer
                        shapeColor: Appearance.colors.colSecondary
                        symbolColor: Appearance.colors.colOnSecondary
                        textColor: Appearance.colors.colOnSecondaryContainer
                    }
                ]

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    SectionDivider {}

                    RowLayout {
                        Layout.fillWidth: true

                        StyledText {
                            text: Translation.tr("Usage")
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: Appearance.colors.colOnSurfaceVariant
                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        StyledText {
                            text: root.formatPercentage(ResourceUsage.cpuUsage)
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            font.weight: Font.Bold
                            color: Appearance.colors.colOnSurface
                        }
                    }

                    StyledProgressBar {
                        Layout.fillWidth: true
                        value: ResourceUsage.cpuUsage
                        valueBarHeight: 7
                        valueBarGap: 4
                        highlightColor: Appearance.colors.colPrimary
                        trackColor: Appearance.colors.colSurfaceContainerHighest
                    }

                    SectionDivider {}

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        CompactStatChip {
                            label: Translation.tr("Temp")
                            value: root.formatCpuTemperature()
                            symbol: "device_thermostat"
                            chipColor: Appearance.colors.colPrimaryContainer
                        }

                        CompactStatChip {
                            label: Translation.tr("Max")
                            value: ResourceUsage.maxAvailableCpuString
                            symbol: "speed"
                            chipColor: Appearance.colors.colSecondaryContainer
                        }
                    }
                }
            }

            SectionCard {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignTop
                margins: root.cardMargins
                spacing: root.cardSpacing
                showDivider: false
                title: Translation.tr("Storage")
                icon: "hard_drive_2"
                headerExtra: [
                    InfoPill {
                        Layout.fillWidth: false
                        compact: true
                        text: root.formatPercentage(ResourceUsage.diskUsedPercentage)
                        icon: "hard_drive_2"
                        pillHeight: 24
                        shapeSize: 14
                        horizontalPadding: 6
                        textHorizontalOffset: 4
                        textPixelSize: Appearance.font.pixelSize.smaller
                        iconPixelSize: Appearance.font.pixelSize.smaller
                        containerColor: Appearance.colors.colTertiaryContainer
                        shapeColor: Appearance.colors.colTertiary
                        symbolColor: Appearance.colors.colOnTertiary
                        textColor: Appearance.colors.colOnTertiaryContainer
                    }
                ]

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    SectionDivider {}

                    RowLayout {
                        Layout.fillWidth: true

                        StyledText {
                            text: Translation.tr("Usage")
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: Appearance.colors.colOnSurfaceVariant
                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        StyledText {
                            text: root.formatPercentage(ResourceUsage.diskUsedPercentage)
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            font.weight: Font.Bold
                            color: Appearance.colors.colOnSurface
                        }
                    }

                    StyledProgressBar {
                        Layout.fillWidth: true
                        value: ResourceUsage.diskUsedPercentage
                        valueBarHeight: 7
                        valueBarGap: 4
                        highlightColor: Appearance.colors.colPrimary
                        trackColor: Appearance.colors.colSurfaceContainerHighest
                    }

                    SectionDivider {}

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        CompactStatChip {
                            label: Translation.tr("Used")
                            value: root.formatGB(ResourceUsage.diskUsed)
                            symbol: "clock_loader_60"
                            chipColor: Appearance.colors.colPrimaryContainer
                        }

                        CompactStatChip {
                            label: Translation.tr("Free")
                            value: root.formatGB(ResourceUsage.diskFree)
                            symbol: "check_circle"
                            chipColor: Appearance.colors.colSecondaryContainer
                        }
                    }

                    CompactStatChip {
                        Layout.alignment: Qt.AlignLeft
                        label: Translation.tr("Total")
                        value: root.formatGB(ResourceUsage.diskTotal)
                        symbol: "hard_drive_2"
                        chipColor: Appearance.colors.colTertiaryContainer
                    }
                }
            }

            SectionCard {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignTop
                margins: root.cardMargins
                spacing: root.cardSpacing
                showDivider: false
                title: Translation.tr("RAM")
                icon: "memory"
                headerExtra: [
                    RowLayout {
                        spacing: 6

                        InfoPill {
                            Layout.fillWidth: false
                            compact: true
                            text: `${Translation.tr("RAM")} ${root.formatPercentage(ResourceUsage.memoryUsedPercentage)}`
                            icon: "memory"
                            pillHeight: 24
                            shapeSize: 14
                            horizontalPadding: 6
                            textHorizontalOffset: 4
                            textPixelSize: Appearance.font.pixelSize.smaller
                            iconPixelSize: Appearance.font.pixelSize.smaller
                            containerColor: Appearance.colors.colPrimaryContainer
                            shapeColor: Appearance.colors.colPrimary
                            symbolColor: Appearance.colors.colOnPrimary
                            textColor: Appearance.colors.colOnPrimaryContainer
                        }

                        Rectangle {
                            width: 1
                            height: 12
                            radius: 1
                            color: Appearance.colors.colSurfaceContainerHighest
                            visible: ResourceUsage.swapTotal > 0
                        }

                        InfoPill {
                            Layout.fillWidth: false
                            compact: true
                            visible: ResourceUsage.swapTotal > 0
                            text: `${Translation.tr("Swap")} ${root.formatPercentage(ResourceUsage.swapUsedPercentage)}`
                            icon: "swap_horiz"
                            pillHeight: 24
                            shapeSize: 14
                            horizontalPadding: 6
                            textHorizontalOffset: 4
                            textPixelSize: Appearance.font.pixelSize.smaller
                            iconPixelSize: Appearance.font.pixelSize.smaller
                            containerColor: Appearance.colors.colSecondaryContainer
                            shapeColor: Appearance.colors.colSecondary
                            symbolColor: Appearance.colors.colOnSecondary
                            textColor: Appearance.colors.colOnSecondaryContainer
                        }
                    }
                ]

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    SectionDivider {}

                    RowLayout {
                        Layout.fillWidth: true

                        StyledText {
                            text: Translation.tr("Usage")
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: Appearance.colors.colOnSurfaceVariant
                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        StyledText {
                            text: root.formatPercentage(ResourceUsage.memoryUsedPercentage)
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            font.weight: Font.Bold
                            color: Appearance.colors.colOnSurface
                        }
                    }

                    StyledProgressBar {
                        Layout.fillWidth: true
                        value: ResourceUsage.memoryUsedPercentage
                        valueBarHeight: 7
                        valueBarGap: 4
                        highlightColor: Appearance.colors.colPrimary
                        trackColor: Appearance.colors.colSurfaceContainerHighest
                    }

                    SectionDivider {}

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        CompactStatChip {
                            label: Translation.tr("Used")
                            value: root.formatGB(ResourceUsage.memoryUsed)
                            symbol: "clock_loader_60"
                            chipColor: Appearance.colors.colPrimaryContainer
                        }

                        CompactStatChip {
                            label: Translation.tr("Free")
                            value: root.formatGB(ResourceUsage.memoryFree)
                            symbol: "check_circle"
                            chipColor: Appearance.colors.colSecondaryContainer
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        CompactStatChip {
                            label: Translation.tr("Total")
                            value: root.formatGB(ResourceUsage.memoryTotal)
                            symbol: "memory"
                            chipColor: Appearance.colors.colTertiaryContainer
                        }
                    }
                }
            }
        }
    }
}
