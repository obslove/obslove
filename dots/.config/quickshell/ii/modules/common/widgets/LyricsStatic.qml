import QtQuick
import qs.services
import qs.modules.common
import qs.modules.common.widgets

StyledText {
    readonly property int currentLineIndex: LyricsService.currentIndex
    readonly property string currentLineText: currentLineIndex >= 0 ? (LyricsService.syncedLines[currentLineIndex]?.text ?? "") : (LyricsService.statusText || "♪")

    Component.onCompleted: {
        LyricsService.initiliazeLyrics()
    }

    font.pixelSize: Appearance.font.pixelSize.smallie
    text: currentLineText
    animateChange: true
    elide: Text.ElideRight
}
