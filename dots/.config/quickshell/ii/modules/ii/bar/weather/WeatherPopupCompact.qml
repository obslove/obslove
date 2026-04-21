import qs.services
import qs.modules.common
import qs.modules.common.widgets
import "../cards"

import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import qs.modules.ii.bar

StyledPopup {
    id: root
    popupRadius: Appearance.rounding.large
    contentItem: ColumnLayout {
        spacing: 0

        HeroCard {
            id: weatherHero
            Layout.alignment: Qt.AlignHCenter
            implicitWidth: 340
            implicitHeight: 176
            margins: 16
            iconSize: 104
            icon: Icons.getWeatherIcon(Weather.data.wCode)
            pillText: Weather.data.city || "--"
            pillIcon: Weather.data.city ? "location_on" : ""
            title: Weather.data.temp
            subtitle: Weather.data.wDesc
            titleSize: Math.round(Appearance.font.pixelSize.hugeass * 1.75)
            subtitleSize: Appearance.font.pixelSize.large
        }
    }
}
