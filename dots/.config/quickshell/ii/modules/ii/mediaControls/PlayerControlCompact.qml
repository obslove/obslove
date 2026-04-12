pragma ComponentBehavior: Bound
import qs.modules.common
import qs.modules.common.models
import qs.modules.common.widgets
import qs.services
import qs.modules.common.functions
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris

Item {
    id: root
    required property MprisPlayer player
    property var artUrl: player?.trackArtUrl
    property string artDownloadLocation: Directories.coverArt
    property string artFileName: Qt.md5(artUrl)
    property string artFilePath: `${artDownloadLocation}/${artFileName}`
    property color artDominantColor: ColorUtils.mix((colorQuantizer?.colors[0] ?? Appearance.colors.colPrimary), Appearance.colors.colPrimaryContainer, 0.8) || Appearance.m3colors.m3secondaryContainer
    property bool downloaded: false
    property list<real> visualizerPoints: []
    property real maxVisualizerValue: 1000
    property int visualizerSmoothing: 2
    property real radius

    property string displayedArtFilePath: root.downloaded ? Qt.resolvedUrl(artFilePath) : ""

    component TrackChangeButton: RippleButton {
        property int buttonSize: 24
        property bool fill: true

        implicitWidth: buttonSize
        implicitHeight: buttonSize

        property var iconName
        colBackground: ColorUtils.transparentize(blendedColors.colSecondaryContainer, 1)
        colBackgroundHover: blendedColors.colSecondaryContainerHover
        colRipple: blendedColors.colSecondaryContainerActive

        contentItem: MaterialSymbol {
            iconSize: buttonSize
            fill: parent.fill ? 1 : 0
            horizontalAlignment: Text.AlignHCenter
            color: blendedColors.colOnSecondaryContainer
            text: iconName

            Behavior on color {
                animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
            }
        }
    }

    Timer {
        running: root.player?.playbackState == MprisPlaybackState.Playing
        interval: Config.options.resources.updateInterval
        repeat: true
        onTriggered: root.player.positionChanged()
    }

    onArtFilePathChanged: {
        if (root.artUrl.length == 0) {
            root.artDominantColor = Appearance.m3colors.m3secondaryContainer
            return;
        }
        coverArtDownloader.targetFile = root.artUrl
        coverArtDownloader.artFilePath = root.artFilePath
        root.downloaded = false
        coverArtDownloader.running = true
    }

    Process {
        id: coverArtDownloader
        property string targetFile: root.artUrl
        property string artFilePath: root.artFilePath
        command: [ "bash", "-c", `[ -f ${artFilePath} ] || curl -4 -sSL '${targetFile}' -o '${artFilePath}'` ]
        onExited: (_, __) => root.downloaded = true
    }

    ColorQuantizer {
        id: colorQuantizer
        source: root.displayedArtFilePath
        depth: 0
        rescaleSize: 1
    }

    property QtObject blendedColors: AdaptedMaterialScheme {
        color: artDominantColor
    }

    StyledRectangularShadow {
        target: background
    }

    Rectangle {
        id: background
        anchors.fill: parent
        anchors.margins: Appearance.sizes.elevationMargin
        color: ColorUtils.applyAlpha(blendedColors.colLayer0, 1)
        radius: root.radius

        layer.enabled: true
        layer.effect: OpacityMask {
            maskSource: Rectangle {
                width: background.width
                height: background.height
                radius: background.radius
            }
        }

        Image {
            id: blurredArt
            anchors.fill: parent
            source: root.displayedArtFilePath
            sourceSize.width: background.width
            sourceSize.height: background.height
            fillMode: Image.PreserveAspectCrop
            cache: false
            antialiasing: true
            asynchronous: true

            layer.enabled: true
            layer.effect: StyledBlurEffect {
                source: blurredArt
            }

            Rectangle {
                anchors.fill: parent
                color: ColorUtils.transparentize(blendedColors.colLayer0, 0.3)
                radius: root.radius
            }
        }

        WaveVisualizer {
            anchors.fill: parent
            live: root.player?.isPlaying
            points: root.visualizerPoints
            maxVisualizerValue: root.maxVisualizerValue
            smoothing: root.visualizerSmoothing
            color: blendedColors.colPrimary
        }

        RowLayout {
            anchors.fill: parent
            anchors.margins: 13
            spacing: 15

            Rectangle {
                id: artBackground
                Layout.fillHeight: true
                implicitWidth: height
                radius: Appearance.rounding.verysmall
                color: ColorUtils.transparentize(blendedColors.colLayer1, 0.5)

                layer.enabled: true
                layer.effect: OpacityMask {
                    maskSource: Rectangle {
                        width: artBackground.width
                        height: artBackground.height
                        radius: artBackground.radius
                    }
                }

                StyledImage {
                    id: mediaArt
                    property int size: parent.height
                    anchors.fill: parent
                    source: root.displayedArtFilePath
                    fillMode: Image.PreserveAspectCrop
                    cache: false
                    antialiasing: true
                    width: size
                    height: size
                    sourceSize.width: size
                    sourceSize.height: size
                }
            }

            ColumnLayout {
                Layout.fillHeight: true
                spacing: 2

                StyledText {
                    Layout.fillWidth: true
                    font.pixelSize: Appearance.font.pixelSize.large
                    color: blendedColors.colOnLayer0
                    elide: Text.ElideRight
                    text: StringUtils.cleanMusicTitle(root.player?.trackTitle) || "Untitled"
                    animateChange: true
                    animationDistanceX: 6
                    animationDistanceY: 0
                }

                StyledText {
                    Layout.fillWidth: true
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: blendedColors.colSubtext
                    elide: Text.ElideRight
                    text: root.player?.trackArtist
                    animateChange: true
                    animationDistanceX: 6
                    animationDistanceY: 0
                }

                Item {
                    Layout.fillHeight: true
                }

                Item {
                    Layout.fillWidth: true
                    implicitHeight: trackTime.implicitHeight + sliderRow.implicitHeight

                    StyledText {
                        id: trackTime
                        anchors.bottom: sliderRow.top
                        anchors.bottomMargin: 5
                        anchors.left: parent.left
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: blendedColors.colSubtext
                        elide: Text.ElideRight
                        font.features: { "tnum": 1 }
                        text: `${StringUtils.friendlyTimeForSeconds(root.player?.position)} / ${StringUtils.friendlyTimeForSeconds(root.player?.length)}`
                    }

                    RowLayout {
                        id: sliderRow
                        anchors {
                            bottom: parent.bottom
                            left: parent.left
                            right: parent.right
                        }

                        TrackChangeButton {
                            iconName: "skip_previous"
                            downAction: () => root.player?.previous()
                        }

                        Item {
                            Layout.fillWidth: true
                            implicitHeight: Math.max(sliderLoader.implicitHeight, progressBarLoader.implicitHeight)

                            Loader {
                                id: sliderLoader
                                anchors.fill: parent
                                active: root.player?.canSeek ?? false
                                sourceComponent: StyledSlider {
                                    configuration: StyledSlider.Configuration.Wavy
                                    highlightColor: blendedColors.colPrimary
                                    trackColor: blendedColors.colSecondaryContainer
                                    handleColor: blendedColors.colPrimary
                                    value: root.player?.position / root.player?.length
                                    onMoved: root.player.position = value * root.player.length
                                }
                            }

                            Loader {
                                id: progressBarLoader
                                anchors {
                                    verticalCenter: parent.verticalCenter
                                    left: parent.left
                                    right: parent.right
                                }
                                active: !(root.player?.canSeek ?? false)
                                sourceComponent: StyledProgressBar {
                                    wavy: root.player?.isPlaying
                                    highlightColor: blendedColors.colPrimary
                                    trackColor: blendedColors.colSecondaryContainer
                                    value: root.player?.position / root.player?.length
                                }
                            }
                        }

                        TrackChangeButton {
                            iconName: "skip_next"
                            downAction: () => root.player?.next()
                        }

                        TrackChangeButton {
                            iconName: "keep"
                            buttonSize: 18
                            fill: MprisController.activePlayer == root.player
                            downAction: () => MprisController.setActivePlayer(root.player)
                        }
                    }

                    RippleButton {
                        anchors.right: parent.right
                        anchors.bottom: sliderRow.top
                        anchors.bottomMargin: 5
                        property real size: 44
                        implicitWidth: size
                        implicitHeight: size
                        downAction: () => root.player.togglePlaying()

                        buttonRadius: root.player?.isPlaying ? Appearance.rounding.normal : Appearance.rounding.capsuleFor(size)
                        colBackground: "transparent"
                        colBackgroundHover: blendedColors.colPrimaryActive
                        colRipple: blendedColors.colPrimaryActive

                        contentItem: MaterialSymbol {
                            iconSize: Appearance.font.pixelSize.huge
                            fill: 1
                            horizontalAlignment: Text.AlignHCenter
                            color: blendedColors.colOnPrimary
                            text: root.player?.isPlaying ? "pause" : "play_arrow"

                            Behavior on color {
                                animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                            }
                        }
                    }
                }
            }
        }
    }
}
