import QtQuick
import QtQuick.Layouts

import qs.modules.common
import qs.modules.common.widgets

Rectangle {
    id: heroCardRoot

    Layout.fillWidth: true
    Layout.preferredHeight: implicitHeight
    Layout.preferredWidth: implicitWidth
    implicitWidth: compactMode ? 360 : 440  // fixed sizes to keep consistency
    implicitHeight: compactMode ? 150 : 180

    radius: Appearance.rounding.normal
    color: Appearance.colors.colPrimaryContainer

    property bool compactMode: false

    property int margins: compactMode ? 16 : 14
    property int iconSize: compactMode ? 104 : 124
    property real iconFontSize: heroCardRoot.iconSize * 0.48

    property string shapeString: "Cookie9Sided"
    property string icon: ""

    property string title: ""
    property string subtitle: ""
    property int titleSize: compactMode ? Appearance.font.pixelSize.huge : Appearance.font.pixelSize.hugeass * 2
    property int subtitleSize: Appearance.font.pixelSize.large

    property string pillText: ""
    property string pillIcon: ""

    property color shapeColor: Appearance.colors.colPrimary
    property color symbolColor: Appearance.colors.colOnPrimary
    property color textColor: Appearance.colors.colOnPrimaryContainer

    default property alias content: extraContent.data
    property alias shapeContent: shapeItem.data
    property int spacing: 12
    readonly property real textBlockWidth: Math.max(compactMode ? 200 : 220, heroCardRoot.width - heroCardRoot.iconSize - heroCardRoot.margins * 3)

    MaterialShape {
        id: shapeItem
        shapeString: heroCardRoot.shapeString
        implicitSize: heroCardRoot.iconSize
        color: heroCardRoot.shapeColor
        anchors {
            verticalCenter: parent.verticalCenter
            left: parent.left
            margins: heroCardRoot.margins
        }

        MaterialSymbol {
            id: iconSymbol
            visible: heroCardRoot.icon !== "" && shapeItem.children.length <= 1
            anchors.centerIn: parent
            text: heroCardRoot.icon
            iconSize: heroCardRoot.iconFontSize
            color: heroCardRoot.symbolColor
        }
    }

    Rectangle {
        id: pillContainer
        visible: heroCardRoot.pillText !== "" && heroCardRoot.pillIcon !== ""
        implicitHeight: cityRow.implicitHeight + 12
        implicitWidth: cityRow.implicitWidth + 20
        radius: Appearance.rounding.full
        color: Appearance.colors.colOnPrimary
        anchors {
            right: parent.right
            top: parent.top
            margins: heroCardRoot.margins
        }

        RowLayout {
            id: cityRow
            anchors.centerIn: parent
            spacing: 6

            MaterialSymbol {
                text: heroCardRoot.pillIcon
                iconSize: Appearance.font.pixelSize.small
                color: Appearance.colors.colOnSecondaryContainer
                Layout.bottomMargin: 1
            }
            StyledText {
                text: heroCardRoot.pillText
                font {
                    weight: Font.Bold
                    pixelSize: Appearance.font.pixelSize.small
                }
                color: Appearance.colors.colOnSecondaryContainer
                elide: Text.ElideRight
                Layout.maximumWidth: 120
                Layout.topMargin: 1 // to center the text
            }
        }
    }

    ColumnLayout {
        id: rightColumn
        anchors {
            verticalCenter: parent.verticalCenter
            verticalCenterOffset: 4
            right: parent.right
            top: pillContainer.visible ? pillContainer.bottom : undefined
            rightMargin: heroCardRoot.margins
            topMargin: pillContainer.visible ? 8 : 0
        }
        width: heroCardRoot.textBlockWidth
        spacing: 8

        StyledText {
            text: heroCardRoot.title
            font.pixelSize: heroCardRoot.titleSize
            font.family: Appearance.font.family.title
            font.weight: Font.Black
            color: heroCardRoot.textColor
            horizontalAlignment: Text.AlignRight
            elide: Text.ElideRight
            Layout.alignment: Qt.AlignRight
            Layout.fillWidth: true
        }

        StyledText {
            text: heroCardRoot.subtitle
            font {
                pixelSize: heroCardRoot.subtitleSize
                family: Appearance.font.family.title
                weight: Font.Black
            }
            color: heroCardRoot.textColor
            horizontalAlignment: Text.AlignRight
            elide: Text.ElideRight
            Layout.alignment: Qt.AlignRight
            Layout.fillWidth: true
        }

        ColumnLayout {
            id: extraContent
            Layout.alignment: Qt.AlignRight
            Layout.fillWidth: true
            spacing: 8
        }
    }
}
