import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts
import "./cards"

StyledPopup {
    id: root
    popupRadius: Appearance.rounding.large

    function formatTime(seconds) {
        var h = Math.floor(seconds / 3600);
        var m = Math.floor((seconds % 3600) / 60);
        if (h > 0)
            return `${h}h, ${m}m`;
        else
            return `${m}m`;
    }

    contentItem: ColumnLayout {
        spacing: 0

        HeroCard {
            id: batteryHero
            Layout.alignment: Qt.AlignHCenter
            compactMode: true
            icon: "battery_android_full"

            title: {
                if (Battery.chargeState == 4) {
                    return Translation.tr("Fully charged");
                } else if (Battery.chargeState == 1) {
                    return Translation.tr("Charging:") + ` ${Battery.energyRate.toFixed(2)}W`;
                } else {
                    return Translation.tr("Discharging:") + ` ${Battery.energyRate.toFixed(2)}W`;
                }
            }
            subtitle: Battery.isCharging
                ? Translation.tr("Time to full:") + ` ${formatTime(Battery.timeToFull)}`
                : Translation.tr("Time to empty:") + ` ${formatTime(Battery.timeToEmpty)}`

            pillText: `${Battery.health.toFixed(1)}%`
            pillIcon: "battery_android_full"
        }
    }
}
