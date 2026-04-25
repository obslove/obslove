import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Shapes
import QtQuick.Layouts
import qs.modules.ii.bar as Bar

Item { // Full hitbox
    id: root

    readonly property bool useStackedLayout: Config.options.bar.date.layout === "stacked"
    readonly property string minimalDate: DateTime.longDate.replace(",", "")
    readonly property var minimalDateParts: minimalDate.split(/\s+/).filter(part => part.length > 0)
    readonly property string minimalDateTop: minimalDateParts.length > 0 ? minimalDateParts[0] : minimalDate
    readonly property string minimalDateBottom: minimalDateParts.length > 1 ? minimalDateParts.slice(1).join(" ") : ""

    implicitHeight: contentLoader.implicitHeight
    implicitWidth: Appearance.sizes.verticalBarWidth
    property var dayOfMonth: DateTime.shortDate.split(/[-\/]/)[0]  // What if 🍔murica🦅? good question
    property var monthOfYear: DateTime.shortDate.split(/[-\/]/)[1]

    Loader {
        id: contentLoader
        anchors.centerIn: parent
        sourceComponent: root.useStackedLayout ? stackedDateContent : minimalDateContent
    }

    Component {
        id: stackedDateContent

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
        id: minimalDateContent

        ColumnLayout {
            spacing: 0

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colOnLayer1
                horizontalAlignment: Text.AlignHCenter
                text: root.minimalDateTop
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                visible: root.minimalDateBottom.length > 0
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colOnLayer1
                horizontalAlignment: Text.AlignHCenter
                text: root.minimalDateBottom
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
