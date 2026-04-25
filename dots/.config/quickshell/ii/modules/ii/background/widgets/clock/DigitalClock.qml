pragma ComponentBehavior: Bound

import qs.services
import qs.modules.common
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: clockColumn
    spacing: 4

    readonly property bool colorful: Config.options.background.widgets.clock.digital.colorful
    readonly property bool showColon: Config.options.background.widgets.clock.digital.showColon
    readonly property bool showSeconds: Config.options.time.secondPrecision
    readonly property string sampleSuffix: {
        if (clockColumn.timeParts.suffix.length === 0) return "";
        return clockColumn.timeParts.suffix === clockColumn.timeParts.suffix.toUpperCase() ? "PM" : "pm";
    }
    readonly property string formattedTime: DateTime.formatTime()
    readonly property var timeParts: {
        const match = clockColumn.formattedTime.match(/^(\d{1,2}):(\d{2})(?::(\d{2}))?(?:\s+(.+))?$/);
        if (!match) {
            return {
                hour: "00",
                minute: "00",
                second: "00",
                suffix: ""
            };
        }
        return {
            hour: match[1].padStart(2, "0"),
            minute: match[2].padStart(2, "0"),
            second: (match[3] ?? "00").padStart(2, "0"),
            suffix: match[4] ?? ""
        };
    }

    property bool isVertical: Config.options.background.widgets.clock.digital.vertical
    property color colText: Appearance.colors.colOnSecondaryContainer
    property color colTextSecondary: Appearance.colors.colOnLayer3
    property color colTextTertiary: Appearance.colors.colOnLayer3
    property var textHorizontalAlignment: Text.AlignHCenter

    component TimeText: ClockText {
        property real sizeScale: 1

        font {
            pixelSize: Config.options.background.widgets.clock.digital.font.size * sizeScale
            weight: Config.options.background.widgets.clock.digital.font.weight
            family: Config.options.background.widgets.clock.digital.font.family
            variableAxes: ({
                    "wdth": Config.options.background.widgets.clock.digital.font.width,
                    "ROND": Config.options.background.widgets.clock.digital.font.roundness
                })
        }
    }

    Item {
        Layout.alignment: Qt.AlignHCenter
        Layout.fillWidth: false
        implicitWidth: timeMeasureRow.implicitWidth
        implicitHeight: timeRow.implicitHeight

        RowLayout {
            id: timeMeasureRow
            opacity: 0
            spacing: timeRow.spacing

            TimeText {
                text: "88"
            }

            TimeText {
                visible: !clockColumn.isVertical && showColon
                text: ":"
            }
            TimeText {
                visible: !clockColumn.isVertical
                text: "88"
            }
            TimeText {
                visible: !clockColumn.isVertical && clockColumn.showSeconds && showColon
                text: ":"
            }
            TimeText {
                visible: !clockColumn.isVertical && clockColumn.showSeconds
                text: "88"
            }
            TimeText {
                visible: !clockColumn.isVertical && clockColumn.sampleSuffix.length > 0
                text: clockColumn.sampleSuffix
                sizeScale: 0.58
            }
        }

        RowLayout {
            id: timeRow
            anchors.centerIn: parent
            spacing: 0

            TimeText {
                text: clockColumn.timeParts.hour
                color: clockColumn.colText
                horizontalAlignment: Text.AlignHCenter
            }
            TimeText {
                visible: !clockColumn.isVertical && showColon
                text: ":"
                color: colorful ? clockColumn.colTextSecondary : clockColumn.colText
                horizontalAlignment: clockColumn.textHorizontalAlignment
            }
            TimeText {
                visible: !clockColumn.isVertical
                text: clockColumn.timeParts.minute
                color: colorful ? clockColumn.colTextTertiary : clockColumn.colText
                horizontalAlignment: clockColumn.textHorizontalAlignment
            }
            TimeText {
                visible: !clockColumn.isVertical && clockColumn.showSeconds && showColon
                text: ":"
                color: colorful ? clockColumn.colTextSecondary : clockColumn.colText
                horizontalAlignment: clockColumn.textHorizontalAlignment
            }
            TimeText {
                visible: !clockColumn.isVertical && clockColumn.showSeconds
                text: clockColumn.timeParts.second
                color: colorful ? clockColumn.colTextSecondary : clockColumn.colText
                horizontalAlignment: clockColumn.textHorizontalAlignment
            }
            TimeText {
                visible: !clockColumn.isVertical && clockColumn.timeParts.suffix.length > 0
                text: clockColumn.timeParts.suffix
                color: colorful ? clockColumn.colTextSecondary : clockColumn.colText
                horizontalAlignment: clockColumn.textHorizontalAlignment
                sizeScale: 0.58
            }
        }
    }

    Loader {
        Layout.topMargin: -40
        Layout.fillWidth: true
        active: clockColumn.isVertical
        visible: active
        sourceComponent: TimeText {
            text: clockColumn.showSeconds
                ? `${clockColumn.timeParts.minute}:${clockColumn.timeParts.second}${clockColumn.timeParts.suffix.length > 0 ? ` ${clockColumn.timeParts.suffix}` : ""}`
                : `${clockColumn.timeParts.minute}${clockColumn.timeParts.suffix.length > 0 ? ` ${clockColumn.timeParts.suffix}` : ""}`
            color: colorful ? clockColumn.colTextTertiary : clockColumn.colText
            horizontalAlignment: clockColumn.textHorizontalAlignment
        }
    }

    ClockText {
        visible: Config.options.background.widgets.clock.digital.showDate
        Layout.topMargin: -20
        Layout.fillWidth: true
        text: DateTime.longDate
        color: colorful ? clockColumn.colTextSecondary : clockColumn.colText
        horizontalAlignment: clockColumn.textHorizontalAlignment
    }

    ClockText {
        visible: Config.options.background.widgets.clock.quote.enable && Config.options.background.widgets.clock.quote.text.length > 0
        font.pixelSize: Appearance.font.pixelSize.normal
        text: Config.options.background.widgets.clock.quote.text
        animateChange: false
        color: clockColumn.colTextSecondary
        horizontalAlignment: clockColumn.textHorizontalAlignment
    }
}
