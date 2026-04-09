import QtQuick
import qs.modules.common

Rectangle {
    property double diameter

    implicitWidth: diameter
    implicitHeight: diameter
    radius: Appearance.rounding.capsuleFor(diameter)
}
