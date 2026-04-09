import QtQuick
import qs.modules.common

Rectangle {
    radius: Appearance.rounding.capsuleFor(Math.min(width, height))
}
