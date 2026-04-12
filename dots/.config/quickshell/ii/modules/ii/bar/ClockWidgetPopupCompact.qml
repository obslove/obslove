import qs.modules.common
import qs.services
import qs.modules.common.widgets
import "./cards"

StyledPopup {
    contentItem: HeroCard {
        id: clockHero
        anchors.centerIn: parent
        implicitWidth: 400
        implicitHeight: 168
        margins: 16
        iconSize: 108
        icon: "schedule"
        title: DateTime.formatTime(Config.options.time.secondPrecisionTargets.barClock)
        subtitle: Qt.locale().toString(DateTime.clock.date, "MMMM dd, dddd")
        titleSize: Math.round(Appearance.font.pixelSize.hugeass * 1.85)
        subtitleSize: Appearance.font.pixelSize.large
    }
}
