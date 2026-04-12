pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.utils
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris

Item {
    id: root

    required property MprisPlayer player
    property color dimColor: Qt.rgba(1, 1, 1, 0.35)
    property color indicatorColor: "red"
    property color indicatorShapeColor: "blue"

    readonly property bool hasSyncedLines: lrclib.lines.length > 0
    readonly property bool useGradientMask: Config.options.bar.mediaPlayer.lyrics.useGradientMask

    LrclibLyrics {
        id: lrclib
        enabled: (root.player?.trackTitle?.length > 0) && (root.player?.trackArtist?.length > 0)
        title: root.player?.trackTitle ?? ""
        artist: root.player?.trackArtist ?? ""
        duration: root.player?.length ?? 0
        position: root.player?.position ?? 0
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 4

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: !root.hasSyncedLines

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 12

                Rectangle {
                    id: indicatorBg
                    Layout.alignment: Qt.AlignHCenter
                    width: 48
                    height: 48
                    radius: Appearance.rounding.token(24)
                    color: root.indicatorColor

                    property double baseShapeSize: 48 * 0.7
                    property double leapZoomSize: baseShapeSize * 1.2
                    property double leapZoomProgress: 0
                    property int shapeIndex: 0
                    property double continuousRotation: 0
                    property double leapRotation: 0
                    rotation: continuousRotation + leapRotation

                    property list<var> shapes: [
                        MaterialShape.Shape.SoftBurst,
                        MaterialShape.Shape.Cookie9Sided,
                        MaterialShape.Shape.Pentagon,
                        MaterialShape.Shape.Pill,
                        MaterialShape.Shape.Sunny,
                        MaterialShape.Shape.Cookie4Sided,
                        MaterialShape.Shape.Oval,
                    ]

                    RotationAnimation on continuousRotation {
                        running: lrclib.loading
                        duration: 12000
                        loops: Animation.Infinite
                        from: 0
                        to: 360
                    }

                    Timer {
                        interval: 800
                        running: lrclib.loading
                        repeat: true
                        onTriggered: leapAnim.start()
                    }

                    ParallelAnimation {
                        id: leapAnim
                        PropertyAction {
                            target: indicatorBg
                            property: "shapeIndex"
                            value: (indicatorBg.shapeIndex + 1) % indicatorBg.shapes.length
                        }
                        RotationAnimation {
                            target: indicatorBg
                            direction: RotationAnimation.Shortest
                            property: "leapRotation"
                            to: (indicatorBg.leapRotation + 90) % 360
                            duration: 350
                            easing.type: Easing.InOutQuad
                        }
                        NumberAnimation {
                            target: indicatorBg
                            property: "leapZoomProgress"
                            from: 0
                            to: 1
                            duration: 750
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Appearance.animationCurves.standard
                        }
                    }

                    MaterialShape {
                        anchors.centerIn: parent
                        shape: indicatorBg.shapes[indicatorBg.shapeIndex]
                        implicitSize: {
                            const leapZoomDiff = indicatorBg.leapZoomSize - indicatorBg.baseShapeSize
                            const progressFirstHalf = Math.min(indicatorBg.leapZoomProgress, 0.5) * 2
                            const progressSecondHalf = Math.max(indicatorBg.leapZoomProgress - 0.5, 0) * 2
                            return indicatorBg.baseShapeSize + leapZoomDiff * progressFirstHalf - leapZoomDiff * progressSecondHalf
                        }
                        color: root.indicatorShapeColor
                        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                    }
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    horizontalAlignment: Text.AlignHCenter
                    color: root.dimColor
                    font.pixelSize: Appearance.font.pixelSize.small
                    text: lrclib.displayText || Translation.tr("No synced lyrics")
                }
            }
        }

        LyricScroller {
            id: lyricScroller
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: root.hasSyncedLines
            initializeService: false
            useExternalSource: true
            externalLines: lrclib.lines
            externalCurrentIndex: lrclib.currentIndex
            externalStatusText: lrclib.displayText
            defaultLyricsSize: Appearance.font.pixelSize.small
            halfVisibleLines: 2
            rowHeight: 20
            downScale: 0.98
            gradientDensity: 0.25
            useGradientMask: root.useGradientMask
            textAlign: "left"
        }
    }
}
