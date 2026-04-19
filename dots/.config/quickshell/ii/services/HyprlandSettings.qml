pragma Singleton

import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Io
import qs

Singleton {
    id: root

    readonly property string hyprlandConfigPath: Directories.home.replace("file://", "") + "/.local/share/ii-vynx/hyprland.conf"
    readonly property string hyprlandRulesPath: Directories.config.replace("file://", "") + "/hypr/hyprland/rules.conf"
    readonly property string vynxCliPath: Directories.cliPath
    property string desiredBlurState: "on"
    readonly property string blurRewriteScript: [
        "from pathlib import Path",
        "import subprocess",
        "import sys",
        "",
        "config_path = Path(sys.argv[1])",
        "blur_state = sys.argv[2]",
        "enabled = blur_state == 'on'",
        "",
        "if not config_path.exists():",
        "    raise SystemExit(0)",
        "",
        "original_text = config_path.read_text()",
        "lines = original_text.splitlines()",
        "",
        "settings_rule = 'windowrule = match:title ^(illogical-impulse Settings|illogical-impulse Welcome|Shell conflicts killer)$, no_blur on'",
        "managed_settings_rule = f'# {settings_rule}' if enabled else settings_rule",
        "",
        "replacements = {",
        "    'layerrule = match:namespace quickshell:.*, blur_popups ': f'layerrule = match:namespace quickshell:.*, blur_popups {blur_state}',",
        "    'layerrule = match:namespace quickshell:.*, blur ': f'layerrule = match:namespace quickshell:.*, blur {blur_state}',",
        "    'layerrule = match:namespace quickshell:.*, ignore_alpha ': 'layerrule = match:namespace quickshell:.*, ignore_alpha 0',",
        "    'layerrule = match:namespace quickshell:overlay, ignore_alpha ': 'layerrule = match:namespace quickshell:overlay, ignore_alpha 0',",
        "    'layerrule = match:namespace quickshell:popup, ignore_alpha ': 'layerrule = match:namespace quickshell:popup, ignore_alpha 0',",
        "    'layerrule = match:namespace quickshell:mediaControls, ignore_alpha ': 'layerrule = match:namespace quickshell:mediaControls, ignore_alpha 0',",
        "    'layerrule = match:namespace quickshell:session, blur ': f'layerrule = match:namespace quickshell:session, blur {blur_state}',",
        "}",
        "",
        "new_lines = []",
        "seen = {prefix: False for prefix in replacements}",
        "settings_inserted = False",
        "",
        "for line in lines:",
        "    if settings_rule in line:",
        "        continue",
        "",
        "    replaced = False",
        "    for prefix, replacement in replacements.items():",
        "        if line.startswith(prefix):",
        "            new_lines.append(replacement)",
        "            seen[prefix] = True",
        "            replaced = True",
        "            break",
        "",
        "    if replaced:",
        "        continue",
        "",
        "    new_lines.append(line)",
        "",
        "    if line == 'windowrule = match:title .*Shell conflicts.*, float on':",
        "        new_lines.append(managed_settings_rule)",
        "        settings_inserted = True",
        "",
        "if not settings_inserted:",
        "    new_lines.append(managed_settings_rule)",
        "",
        "for prefix, replacement in replacements.items():",
        "    if not seen[prefix]:",
        "        new_lines.append(replacement)",
        "",
        "new_text = '\\n'.join(new_lines)",
        "if original_text.endswith('\\n') or new_text:",
        "    new_text += '\\n'",
        "",
        "if new_text != original_text:",
        "    config_path.write_text(new_text)",
        "    subprocess.run(['hyprctl', 'reload'], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=False)",
    ].join("\n")

    Timer {
        id: startupAppearanceSyncTimer
        interval: 250
        repeat: true
        running: true
        onTriggered: {
            if (!Config.ready) return
            root.syncAppearanceConfig()
            stop()
        }
    }
    
    Process {
        id: configWriter
        
        running: false
        property string pendingCommand: ""
        command: ["bash", "-c", pendingCommand]

        onExited: (exitCode, exitStatus) => {
            // NOTE: This will not work bc we are running it detached
            if (exitCode === 1) {
                Quickshell.execDetached(["notify-send", Translation.tr("Couldn't change the setting"), Translation.tr("Make sure you have vynx-cli installed"), "-a", "Shell"])
            }
        }
    }

    Process {
        id: blurWriter

        running: false
        property string activeBlurState: root.desiredBlurState
        command: ["python3", "-c", root.blurRewriteScript, root.hyprlandRulesPath, activeBlurState]
        stderr: SplitParser {
            onRead: data => {
                console.warn("[HyprlandSettings] Blur writer stderr:", data.trim())
            }
        }
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                console.warn("[HyprlandSettings] Blur writer failed:", exitCode, exitStatus)
            }

            if (activeBlurState !== root.desiredBlurState) {
                activeBlurState = root.desiredBlurState
                running = true
            }
        }
    }

    function applyLiveKeyword(key, value) {
        Quickshell.execDetached(["hyprctl", "keyword", key, String(value)])
    }

    function changeKey(key, value) {
        if (configWriter.running) {
            console.warn("[HyprlandConfig] Writer busy, skipping")
        }

        if (/['"\\`$|&;]/.test(String(value)) || /['"\\`$|&;]/.test(String(key))) {
            console.error("[HyprlandConfig] Unsafe characters rejected:", key, value)
            return
        }

        applyLiveKeyword(key, value)

        let sedCmd = ""

        if (key.includes(":")) {
            sedCmd = `[ -x '${root.vynxCliPath}' ] && '${root.vynxCliPath}' hyprset key '${key}' '${value}' >/dev/null 2>&1 || true`
        } else {
            // idk.. put smthng here
            return
        }

        if (configWriter.running || sedCmd.length === 0)
            return

        configWriter.pendingCommand = sedCmd
        configWriter.startDetached()
    }

    function changeAnimation(animName, style) {
        if (configWriter.running) {
            console.warn("[HyprlandConfig] Writer busy, skipping")
            return
        }

        const safeCheck = /['"\\`$|&;]/
        if (safeCheck.test(String(animName)) || safeCheck.test(String(style))) {
            console.error("[HyprlandConfig] Unsafe characters rejected:", animName, style)
            return
        }

        const sedCmd = `[ -x '${root.vynxCliPath}' ] && '${root.vynxCliPath}' hyprset anim '${animName}' '${style}' >/dev/null 2>&1 || true`

        configWriter.pendingCommand = sedCmd
        configWriter.startDetached()
    }

    function setLayout(layout) {
        if (layout !== "default" && layout !== "scrolling" && layout !== "dwindle" && layout !== "monocle" && layout !== "master") return
        // console.log("[HyprlandSettings] Setting layout to", layout)
        changeKey("general:layout", layout)
        Persistent.states.hyprland.layout = layout
    }

    function setRounding(rounding) {
        changeKey("decoration:rounding", rounding)
    }

    function setBlurEnabled(enabled) {
        root.desiredBlurState = enabled ? "on" : "off"

        if (blurWriter.running)
            return

        blurWriter.activeBlurState = root.desiredBlurState
        blurWriter.running = true
    }

    function syncAppearanceConfig() {
        if (!Config.ready) return

        setBlurEnabled(Config.options.appearance.transparency.enable && Config.options.appearance.transparency.blur)

        if (Config.options.appearance.toggleWindowRounding)
            setRounding(Appearance.rounding.windowRounding)
    }

    Component.onCompleted: startupAppearanceSyncTimer.restart()

    Connections {
        target: Config
        function onReadyChanged() {
            if (Config.ready)
                startupAppearanceSyncTimer.restart()
        }
    }

    Connections {
        target: Config.options.appearance.transparency
        function onEnableChanged() {
            root.syncAppearanceConfig()
        }
        function onBlurChanged() {
            root.syncAppearanceConfig()
        }
    }

    Connections {
        target: Config.options.appearance
        function onRoundingStyleChanged() {
            if (Config.ready && Config.options.appearance.toggleWindowRounding)
                root.setRounding(Appearance.rounding.windowRounding)
        }
        function onToggleWindowRoundingChanged() {
            if (Config.ready && Config.options.appearance.toggleWindowRounding)
                root.setRounding(Appearance.rounding.windowRounding)
        }
    }
}
