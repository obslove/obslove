import QtQuick
import QtQuick.Layouts

import qs.modules.common
import qs.modules.common.widgets

Rectangle {
    id: root

    Layout.fillWidth: true
    implicitHeight: pillHeight
    implicitWidth: compact
        ? compactRow.implicitWidth + horizontalPadding * 2
        : shapeSize + pillText.implicitWidth + horizontalPadding * 2 + textHorizontalOffset
    radius: Appearance.rounding.full

    color: containerColor

    property bool compact: false
    property int pillHeight: 64
    property int horizontalPadding: 12
    property int textHorizontalOffset: 9
    property int textPixelSize: Appearance.font.pixelSize.large
    property int iconPixelSize: Appearance.font.pixelSize.large
    property string shapeString: "Circle"
    property int shapeSize: 40
    property string icon: ""

    property color containerColor: Appearance.colors.colSecondaryContainer
    property color shapeColor: Appearance.colors.colSecondary
    property color symbolColor: Appearance.colors.colOnSecondary
    property color textColor: Appearance.colors.colOnSecondaryContainer

    default property alias shapeContent: shapeItem.children
    property alias textContent: pillText.children
    property alias text: pillText.text

    MaterialShape {
        id: shapeItem
        visible: !root.compact
        shapeString: root.shapeString
        implicitSize: root.shapeSize
        color: root.shapeColor
        anchors {
            left: parent.left
            leftMargin: root.horizontalPadding
            verticalCenter: parent.verticalCenter
        }

        MaterialSymbol {
            id: iconSymbol
            visible: root.icon !== "" && shapeItem.children.length <= 1
            anchors.centerIn: parent
            text: root.icon
            iconSize: root.iconPixelSize
            color: root.symbolColor
            fill: 1
        }
    }

    StyledText {
        id: pillText
        visible: !root.compact
        anchors {
            verticalCenter: parent.verticalCenter
            horizontalCenter: parent.horizontalCenter
            horizontalCenterOffset: root.textHorizontalOffset
        }
        font.pixelSize: root.textPixelSize
        font.family: Appearance.font.family.title
        font.weight: Font.Bold
        color: root.textColor
    }

    RowLayout {
        id: compactRow
        visible: root.compact
        anchors.centerIn: parent
        spacing: 4

        MaterialShape {
            visible: root.icon !== ""
            shapeString: root.shapeString
            implicitSize: root.shapeSize
            color: root.shapeColor

            MaterialSymbol {
                anchors.centerIn: parent
                text: root.icon
                iconSize: root.iconPixelSize
                color: root.symbolColor
            }
        }

        StyledText {
            text: root.text
            font.pixelSize: root.textPixelSize
            font.family: Appearance.font.family.title
            font.weight: Font.Bold
            color: root.textColor
        }
    }
}
