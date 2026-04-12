import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Shapes
import QtQuick.Layouts
import qs.modules.ii.bar as Bar

Item { // Full hitbox
    id: root

    readonly property bool useCompactDateStyle: Config.options.bar.date.layout === "compact"
    readonly property string inlineDate: DateTime.longDate.replace(",", "")
    readonly property var inlineDateParts: inlineDate.split(/\s+/).filter(part => part.length > 0)
    readonly property string inlineDateTop: inlineDateParts.length > 0 ? inlineDateParts[0] : inlineDate
    readonly property string inlineDateBottom: inlineDateParts.length > 1 ? inlineDateParts.slice(1).join(" ") : ""

    implicitHeight: contentLoader.implicitHeight
    implicitWidth: Appearance.sizes.verticalBarWidth
    property var dayOfMonth: DateTime.shortDate.split(/[-\/]/)[0]  // What if 🍔murica🦅? good question
    property var monthOfYear: DateTime.shortDate.split(/[-\/]/)[1]

    Loader {
        id: contentLoader
        anchors.centerIn: parent
        sourceComponent: root.useCompactDateStyle ? compactDateContent : clockStyleDateContent
    }

    Component {
        id: compactDateContent

        Item { // Boundaries for date numbers
            implicitWidth: 24
            implicitHeight: 30

            Shape {
                id: diagonalLine
                property real padding: 4
                anchors.fill: parent
                preferredRendererType: Shape.CurveRenderer

                ShapePath {
                    strokeWidth: 1.2
                    strokeColor: Appearance.colors.colSubtext
                    fillColor: "transparent"
                    startX: parent.width - diagonalLine.padding
                    startY: diagonalLine.padding
                    PathLine {
                        x: diagonalLine.padding
                        y: parent.height - diagonalLine.padding
                    }
                }
            }

            StyledText {
                anchors {
                    top: parent.top
                    left: parent.left
                }
                font.pixelSize: 13
                color: Appearance.colors.colOnLayer1
                text: root.dayOfMonth
            }

            StyledText {
                anchors {
                    bottom: parent.bottom
                    right: parent.right
                }
                font.pixelSize: 13
                color: Appearance.colors.colOnLayer1
                text: root.monthOfYear
            }
        }
    }

    Component {
        id: clockStyleDateContent

        ColumnLayout {
            spacing: 0

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colOnLayer1
                horizontalAlignment: Text.AlignHCenter
                text: root.inlineDateTop
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                visible: root.inlineDateBottom.length > 0
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colOnLayer1
                horizontalAlignment: Text.AlignHCenter
                text: root.inlineDateBottom
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: !Config.options.bar.tooltips.clickToShow

        Loader {
            active: true
            sourceComponent: Config.options.bar.tooltips.compactPopups ? clockPopupCompact : clockPopup
        }

        Component {
            id: clockPopup
            Bar.ClockWidgetPopup {
                hoverTarget: mouseArea
            }
        }

        Component {
            id: clockPopupCompact
            Bar.ClockWidgetPopupCompact {
                hoverTarget: mouseArea
            }
        }
    }
}
