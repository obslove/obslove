import QtQuick
import qs.modules.common
import qs.modules.common.models.quickToggles
import qs.modules.common.widgets

QuickToggleButton {
    id: root

    property MullvadVpnToggle mullvadToggle: MullvadVpnToggle {}

    visible: mullvadToggle.available
    toggled: mullvadToggle.toggled
    buttonIcon: mullvadToggle.icon

    onClicked: {
        mullvadToggle.mainAction()
    }

    altAction: mullvadToggle.altAction

    StyledToolTip {
        text: root.mullvadToggle.tooltipText
    }
}
