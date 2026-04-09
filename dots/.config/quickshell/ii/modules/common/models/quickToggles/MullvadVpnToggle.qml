import QtQuick
import Quickshell
import Quickshell.Io
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets

QuickToggleModel {
    id: root

    property string currentStatusLine: ""
    property bool activeState: false

    name: Translation.tr("Mullvad VPN")
    statusText: currentStatusLine || Translation.tr("Unavailable")
    tooltipText: Translation.tr("Mullvad VPN | Right-click to configure")
    icon: "vpn_key"
    available: false
    toggled: activeState

    function refreshState() {
        if (!fetchState.running)
            fetchState.running = true
    }

    function scheduleRefresh() {
        delayedRefresh.restart()
    }

    mainAction: () => {
        root.activeState = !root.activeState
        Quickshell.execDetached(["mullvad", root.activeState ? "connect" : "disconnect"])
        scheduleRefresh()
    }

    altAction: () => {
        Quickshell.execDetached(["bash", "-c", `${Config.options.apps.mullvadVpn}`])
        GlobalStates.sidebarRightOpen = false
    }

    Component.onCompleted: refreshState()

    Timer {
        id: pollingTimer
        interval: 10000
        repeat: true
        running: true
        onTriggered: root.refreshState()
    }

    Timer {
        id: delayedRefresh
        interval: 1200
        repeat: false
        onTriggered: root.refreshState()
    }

    Process {
        id: fetchState
        command: ["bash", "-lc", "mullvad status 2>/dev/null || true"]
        stdout: StdioCollector {
            id: mullvadStatusCollector
            onStreamFinished: {
                const statusText = mullvadStatusCollector.text.trim()
                root.available = statusText.length > 0
                root.currentStatusLine = root.available ? statusText.split("\n")[0].trim() : ""
                if (root.currentStatusLine.includes("Connected"))
                    root.activeState = true
                else if (root.currentStatusLine.includes("Disconnected"))
                    root.activeState = false
            }
        }
        onExited: () => {
            if (!root.available) {
                root.currentStatusLine = ""
                root.activeState = false
            }
        }
    }
}
