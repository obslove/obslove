pragma Singleton

import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Io
import qs

Singleton {
    id: root

    readonly property string hyprlandRulesPath: Directories.config.replace("file://", "") + "/hypr/hyprland/rules.conf"
    readonly property string vynxCliPath: Directories.cliPath
    readonly property string managedSettingsTitleRegex: "title:^(illogical-impulse Settings|illogical-impulse Welcome|Shell conflicts killer)$"
    readonly property string managedNoBlurRule: "windowrule = match:title ^(illogical-impulse Settings|illogical-impulse Welcome|Shell conflicts killer)$, no_blur on"
    property string desiredBlurState: "on"
    property bool pendingRulesSync: false

    Timer {
        id: startupAppearanceSyncTimer
        interval: 250
        repeat: true
        running: false
        onTriggered: {
            if (!Config.ready) return
            root.syncAppearanceConfig()
            stop()
        }
    }

    FileView {
        id: rulesFileView
        path: root.hyprlandRulesPath
        watchChanges: false

        onLoaded: {
            if (!root.pendingRulesSync)
                return

            root.pendingRulesSync = false

            const originalText = rulesFileView.text()
            const nextText = root.rewriteRulesText(originalText, root.desiredBlurState)

            if (nextText === originalText)
                return

            rulesFileView.setText(nextText)
            Quickshell.execDetached(["hyprctl", "reload"])
        }

        onLoadFailed: error => {
            root.pendingRulesSync = false
            console.warn("[HyprlandSettings] Failed to load blur rules:", error)
        }
    }

    function applyLiveKeyword(key, value) {
        Quickshell.execDetached(["hyprctl", "keyword", key, String(value)])
    }

    function rewriteRulesText(originalText, blurState) {
        const sourceText = originalText || ""
        const enabled = blurState === "on"
        const managedSettingsRule = enabled ? `# ${root.managedNoBlurRule}` : root.managedNoBlurRule
        const replacementEntries = [
            ["layerrule = match:namespace quickshell:.*, blur_popups ", `layerrule = match:namespace quickshell:.*, blur_popups ${blurState}`],
            ["layerrule = match:namespace quickshell:.*, blur ", `layerrule = match:namespace quickshell:.*, blur ${blurState}`],
            ["layerrule = match:namespace quickshell:.*, ignore_alpha ", "layerrule = match:namespace quickshell:.*, ignore_alpha 0"],
            ["layerrule = match:namespace quickshell:overlay, ignore_alpha ", "layerrule = match:namespace quickshell:overlay, ignore_alpha 0"],
            ["layerrule = match:namespace quickshell:popup, ignore_alpha ", "layerrule = match:namespace quickshell:popup, ignore_alpha 0"],
            ["layerrule = match:namespace quickshell:mediaControls, ignore_alpha ", "layerrule = match:namespace quickshell:mediaControls, ignore_alpha 0"],
            ["layerrule = match:namespace quickshell:session, blur ", `layerrule = match:namespace quickshell:session, blur ${blurState}`],
        ]

        const lines = sourceText.length > 0 ? sourceText.split("\n") : []
        const seen = ({})
        const newLines = []
        let settingsInserted = false

        for (let i = 0; i < replacementEntries.length; ++i)
            seen[replacementEntries[i][0]] = false

        for (const line of lines) {
            if (line.includes(root.managedNoBlurRule))
                continue

            let replaced = false
            for (const [prefix, replacement] of replacementEntries) {
                if (!line.startsWith(prefix))
                    continue

                newLines.push(replacement)
                seen[prefix] = true
                replaced = true
                break
            }

            if (replaced)
                continue

            newLines.push(line)

            if (line === "windowrule = match:title .*Shell conflicts.*, float on") {
                newLines.push(managedSettingsRule)
                settingsInserted = true
            }
        }

        if (!settingsInserted)
            newLines.push(managedSettingsRule)

        for (const [prefix, replacement] of replacementEntries) {
            if (!seen[prefix])
                newLines.push(replacement)
        }

        let nextText = newLines.join("\n")
        if (sourceText.endsWith("\n") || nextText.length > 0)
            nextText += "\n"

        return nextText
    }

    function syncManagedWindowBlur(enabled) {
        Quickshell.execDetached([
            "hyprctl",
            "setprop",
            root.managedSettingsTitleRegex,
            "noblur",
            enabled ? "unset" : "1"
        ])
    }

    function runPersistCommand(command) {
        if (!command || command.length === 0)
            return;

        Quickshell.execDetached(["bash", "-c", command])
    }

    function changeKey(key, value) {
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

        runPersistCommand(sedCmd)
    }

    function changeAnimation(animName, style) {
        const safeCheck = /['"\\`$|&;]/
        if (safeCheck.test(String(animName)) || safeCheck.test(String(style))) {
            console.error("[HyprlandConfig] Unsafe characters rejected:", animName, style)
            return
        }

        const sedCmd = `[ -x '${root.vynxCliPath}' ] && '${root.vynxCliPath}' hyprset anim '${animName}' '${style}' >/dev/null 2>&1 || true`

        runPersistCommand(sedCmd)
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
        root.syncManagedWindowBlur(enabled)
        root.pendingRulesSync = true
        rulesFileView.reload()
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
