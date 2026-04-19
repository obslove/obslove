import qs.modules.common
import QtQuick

/**
 * Recreation of GTK revealer. Expects one single child.
 */
Item {
    id: root
    property bool reveal
    property bool vertical: false
    readonly property Item contentChild: children.length > 0 ? children[0] : null
    clip: true

    implicitWidth: (reveal || vertical) ? (contentChild?.implicitWidth ?? childrenRect.width) : 0
    implicitHeight: (reveal || !vertical) ? (contentChild?.implicitHeight ?? childrenRect.height) : 0
    visible: reveal || (implicitWidth > 0 && !vertical) || (implicitHeight > 0 && vertical)

    Behavior on implicitWidth {
        enabled: !vertical
        animation: Appearance.animation.elementMoveEnter.numberAnimation.createObject(this)
    }
    Behavior on implicitHeight {
        enabled: vertical
        animation: Appearance.animation.elementMoveEnter.numberAnimation.createObject(this)
    }
}
