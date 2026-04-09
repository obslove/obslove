import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

RippleButton {
    id: root
    readonly property string builtInThemeDirectory: Directories.defaultThemes
    readonly property string customThemeDirectory: Directories.customThemes

    property string colorScheme: "scheme-auto"
    property string colorSchemeDisplayName: ""

    property bool builtInTheme: false
    readonly property string builtInThemeFilePath: builtInThemeDirectory + "/" + colorScheme + ".json"
    readonly property string builtInThemeCommand: `jq -r '.primary, .primary_container, .secondary' ${builtInThemeFilePath}`

    property bool customTheme: false
    readonly property string customThemeFilePath: customThemeDirectory + "/" + colorScheme + ".json"
    readonly property string customThemeCommand: `jq -r '.primary, .primary_container, .secondary' ${customThemeFilePath}`  

    readonly property string wallpaperPath: Config.options.background.wallpaperPath
    readonly property string scriptPath: FileUtils.trimFileProtocol(`${Directories.scriptPath}/colors/generate_colors_material.py`)
    readonly property string applyColorScriptPath: FileUtils.trimFileProtocol(`${Directories.scriptPath}/colors/applycolor.sh`)
    readonly property string materialQtScriptPath: FileUtils.trimFileProtocol(`${Directories.scriptPath}/kvantum/materialQT.sh`)
    readonly property string generatedScssPath: FileUtils.trimFileProtocol(`${Directories.state}/user/generated/material_colors.scss`)

    property string fullCommand: `python3 ${root.scriptPath} --path ${root.wallpaperPath} --scheme ${root.colorScheme} --preview`
    readonly property string reapplyExternalThemesCommand: `${root.applyColorScriptPath} && ${root.materialQtScriptPath}`

    // these are not actually primary, secondary and tertiary, they are just the three colors we get from the script
    property color primaryColor: "transparent"
    property color secondaryColor: "transparent"
    property color tertiaryColor: "transparent"

    property bool loaded: false
    property bool shouldLoad: false

    readonly property bool toggled: Config.options.appearance.palette.type === root.colorScheme
    colBackground: toggled ? Appearance.colors.colPrimaryContainer : Appearance.colors.colLayer2
    colBackgroundHover: toggled ? Appearance.colors.colPrimaryContainerHover : Appearance.colors.colLayer2Hover
    colRipple: toggled ? Appearance.colors.colPrimaryContainerActive : Appearance.colors.colLayer2Active

    buttonRadius: Appearance.rounding.small

    Layout.fillWidth: true
    implicitHeight: 64

    onClicked: {
        if (customTheme) {
            Config.options.appearance.palette.type = root.colorScheme;
            Quickshell.execDetached(["bash", "-c", `cp ${root.customThemeFilePath} ${Directories.generatedMaterialThemePath} && rm -f ${root.generatedScssPath} && ${root.reapplyExternalThemesCommand}`]);
        } else if (builtInTheme) {
            Config.options.appearance.palette.type = root.colorScheme;
            Quickshell.execDetached(["bash", "-c", `cp ${root.builtInThemeFilePath} ${Directories.generatedMaterialThemePath} && rm -f ${root.generatedScssPath} && ${root.reapplyExternalThemesCommand}`]);
        } else {
            Config.options.appearance.palette.type = root.colorScheme;
            Quickshell.execDetached(["bash", "-c", `${Directories.wallpaperSwitchScriptPath} --noswitch`]);
        }
    }

    property var effectiveCommand:  root.customTheme ? root.customThemeCommand
                                    : root.builtInTheme ? root.builtInThemeCommand
                                    : root.fullCommand

    onShouldLoadChanged: {
        if (shouldLoad && !loaded) {
            colorFetchProcess.running = true
        }
    }

    Process {
        id: colorFetchProcess
        running: false
        command: ["bash", "-c", root.effectiveCommand]

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    //console.log("[ColorPreviewButton] Command:", root.effectiveCommand)
                    if (root.customTheme || root.builtInTheme) {
                        const colors = this.text.trim().split("\n")
                        root.primaryColor   = colors[0] || "transparent"
                        root.secondaryColor = colors[1] || "transparent"
                        root.tertiaryColor  = colors[2] || "transparent"
                    } else {
                        const data = JSON.parse(this.text)

                        root.primaryColor   = data.primary   || "transparent"
                        root.secondaryColor = data.primary_container || "transparent"
                        root.tertiaryColor  = data.secondary  || "transparent"
                    }

                    root.loaded = true
                    myCanvas.requestPaint()
                } catch (e) {
                    console.log("[ColorPreviewButton] Parse error:", this.text)
                }
            }
        }
    }

    StyledToolTip {
        text: root.colorSchemeDisplayName
    }

    Item {
        anchors.fill: parent

        StyledText {
            anchors.fill: parent
            visible: !root.loaded
            elide: Text.ElideRight
            text: root.colorSchemeDisplayName
            horizontalAlignment: Text.AlignHCenter
            color: Appearance.colors.colOnPrimaryContainer
            font.pixelSize: Appearance.font.pixelSize.small
        }

        Canvas {
            id: myCanvas
            anchors.centerIn: parent
            anchors.margins: 8

            implicitWidth: root.implicitHeight - 16
            implicitHeight: root.implicitHeight - 16

            antialiasing: true

            Connections {
                target: Appearance.rounding
                function onModeChanged() {
                    myCanvas.requestPaint();
                }
            }

            onPaint: {
                var ctx = getContext("2d");
                var centerX = width / 2;
                var centerY = height / 2;
                var radius = width / 2;
                var cornerRadius = Appearance.rounding.capsuleFor(width);

                function roundedRectPath(x, y, w, h, r) {
                    const cappedR = Math.max(0, Math.min(r, Math.min(w, h) / 2));
                    ctx.beginPath();
                    if (cappedR === 0) {
                        ctx.rect(x, y, w, h);
                        return;
                    }

                    ctx.moveTo(x + cappedR, y);
                    ctx.lineTo(x + w - cappedR, y);
                    ctx.arcTo(x + w, y, x + w, y + cappedR, cappedR);
                    ctx.lineTo(x + w, y + h - cappedR);
                    ctx.arcTo(x + w, y + h, x + w - cappedR, y + h, cappedR);
                    ctx.lineTo(x + cappedR, y + h);
                    ctx.arcTo(x, y + h, x, y + h - cappedR, cappedR);
                    ctx.lineTo(x, y + cappedR);
                    ctx.arcTo(x, y, x + cappedR, y, cappedR);
                    ctx.closePath();
                }

                ctx.reset();

                if (!Appearance.rounding.isDefault) {
                    roundedRectPath(0, 0, width, height, cornerRadius);
                    ctx.clip();

                    ctx.fillStyle = root.primaryColor;
                    ctx.fillRect(0, 0, width, centerY);

                    ctx.fillStyle = root.secondaryColor;
                    ctx.fillRect(centerX, centerY, centerX, centerY);

                    ctx.fillStyle = root.tertiaryColor;
                    ctx.fillRect(0, centerY, centerX, centerY);
                } else {
                    ctx.beginPath();
                    ctx.fillStyle = root.primaryColor;
                    ctx.moveTo(centerX, centerY);
                    ctx.arc(centerX, centerY, radius, Math.PI, 0, false);
                    ctx.fill();

                    ctx.beginPath();
                    ctx.fillStyle = root.secondaryColor;
                    ctx.moveTo(centerX, centerY);
                    ctx.arc(centerX, centerY, radius, 0, Math.PI / 2, false);
                    ctx.fill();

                    ctx.beginPath();
                    ctx.fillStyle = root.tertiaryColor;
                    ctx.moveTo(centerX, centerY);
                    ctx.arc(centerX, centerY, radius, Math.PI / 2, Math.PI, false);
                    ctx.fill();
                }
            }
        }
    }
}
