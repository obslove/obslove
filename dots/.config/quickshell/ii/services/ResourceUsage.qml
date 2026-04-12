pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Simple polled resource usage service with RAM, Swap, CPU, storage, and GPU usage.
 */
Singleton {
    id: root
	property real memoryTotal: 1
	property real memoryFree: 0
	property real memoryUsed: memoryTotal - memoryFree
    property real memoryUsedPercentage: memoryUsed / memoryTotal
    property real swapTotal: 1
	property real swapFree: 0
	property real swapUsed: swapTotal - swapFree
    property real swapUsedPercentage: swapTotal > 0 ? (swapUsed / swapTotal) : 0
    property real diskTotal: 1
    property real diskFree: 0
    property real diskUsed: 0
    property real diskUsedPercentage: diskTotal > 0 ? (diskUsed / diskTotal) : 0
    property real cpuUsage: 0
    property bool gpuAvailable: false
    property real gpuUsage: 0
    property real gpuTemperature: -1
    property real gpuMemoryUsed: 0
    property real gpuMemoryTotal: 1
    property var previousCpuStats
    property string cpuModel: "Unknown CPU"
    property string cpuFreq: "-- MHz"
    property string cpuTemp: "--°C"

    property string maxAvailableMemoryString: kbToGbString(ResourceUsage.memoryTotal)
    property string maxAvailableSwapString: kbToGbString(ResourceUsage.swapTotal)
    property string maxAvailableCpuString: "--"

    readonly property int historyLength: Config?.options.resources.historyLength ?? 60
    property list<real> cpuUsageHistory: []
    property list<real> memoryUsageHistory: []
    property list<real> swapUsageHistory: []

    function kbToGbString(kb) {
        return (kb / (1024 * 1024)).toFixed(1) + " GB";
    }

    function updateMemoryUsageHistory() {
        memoryUsageHistory = [...memoryUsageHistory, memoryUsedPercentage]
        if (memoryUsageHistory.length > historyLength) {
            memoryUsageHistory.shift()
        }
    }
    function updateSwapUsageHistory() {
        swapUsageHistory = [...swapUsageHistory, swapUsedPercentage]
        if (swapUsageHistory.length > historyLength) {
            swapUsageHistory.shift()
        }
    }
    function updateCpuUsageHistory() {
        cpuUsageHistory = [...cpuUsageHistory, cpuUsage]
        if (cpuUsageHistory.length > historyLength) {
            cpuUsageHistory.shift()
        }
    }
    function updateHistories() {
        updateMemoryUsageHistory()
        updateSwapUsageHistory()
        updateCpuUsageHistory()
    }

	Timer {
		interval: Config.options?.resources?.updateInterval ?? 3000
        running: true 
        repeat: true
		onTriggered: {
            // Reload files
            fileMeminfo.reload()
            fileStat.reload()

            // Parse memory and swap usage
            const textMeminfo = fileMeminfo.text()
            memoryTotal = Number(textMeminfo.match(/MemTotal: *(\d+)/)?.[1] ?? 1)
            memoryFree = Number(textMeminfo.match(/MemAvailable: *(\d+)/)?.[1] ?? 0)
            swapTotal = Number(textMeminfo.match(/SwapTotal: *(\d+)/)?.[1] ?? 1)
            swapFree = Number(textMeminfo.match(/SwapFree: *(\d+)/)?.[1] ?? 0)

            // Parse CPU usage
            const textStat = fileStat.text()
            const cpuLine = textStat.match(/^cpu\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)/)
            if (cpuLine) {
                const stats = cpuLine.slice(1).map(Number)
                const total = stats.reduce((a, b) => a + b, 0)
                const idle = stats[3]

                if (previousCpuStats) {
                    const totalDiff = total - previousCpuStats.total
                    const idleDiff = idle - previousCpuStats.idle
                    cpuUsage = totalDiff > 0 ? (1 - idleDiff / totalDiff) : 0
                }

                previousCpuStats = { total, idle }
            }

            // Parse CPU info
            fileCpuInfo.reload()
            const textCpu = fileCpuInfo.text()
            if (root.cpuModel === "Unknown CPU" && textCpu.length > 0) {
                const modelMatch = textCpu.match(/model name\s+:\s+(.*)/)
                if (modelMatch) {
                    // i hope these are enough to shorten the string
                    root.cpuModel = modelMatch[1]
                        .replace(/\(.*?\)/g, "")              // (R), (TM) vs
                        .replace(/with.*$/i, "")              // with Radeon...
                        .replace(/@\s*[\d.]+\s*GHz/i, "")     // @ 2.60GHz
                        .replace(/\b\d+-Core\b/gi, "")        // 6-Core
                        .replace(/\b\d+\s*Cores?\b/gi, "")    // 6 Cores
                        .replace(/\bCPU\b/gi, "")
                        .replace(/\bProcessor\b/gi, "")
                        .replace(/\s+/g, " ")
                        .trim()
                }
            }
            const freqMatch = textCpu.match(/cpu MHz\s+:\s+([\d.]+)/)
            if (freqMatch) root.cpuFreq = parseInt(freqMatch[1]) + " MHz"

            if (!fetchCpuTemperatureProc.running) {
                fetchCpuTemperatureProc.running = true
            }
            if (!fetchStorageProc.running) {
                fetchStorageProc.running = true
            }
            if (!fetchGpuProc.running) {
                fetchGpuProc.running = true
            }

            root.updateHistories()
        }
	}

	FileView { id: fileMeminfo; path: "/proc/meminfo" }
    FileView { id: fileStat; path: "/proc/stat" }
    FileView { id: fileCpuInfo; path: "/proc/cpuinfo" }

    Process {
        id: findCpuMaxFreqProc
        environment: ({
            LANG: "C",
            LC_ALL: "C"
        })
        command: ["bash", "-c", "lscpu | grep 'CPU max MHz' | awk '{print $4}'"]
        running: true
        stdout: StdioCollector {
            id: outputCollector
            onStreamFinished: {
                root.maxAvailableCpuString = (parseFloat(outputCollector.text) / 1000).toFixed(0) + " GHz"
            }
        }
    }
    Process {
        id: fetchCpuTemperatureProc
        environment: ({
            LANG: "C",
            LC_ALL: "C"
        })
        command: ["bash", "-lc", "command -v sensors >/dev/null 2>&1 || exit 0; sensors 2>/dev/null | awk '/Package id 0:/ {gsub(/\\+|°C/, \"\", $4); print $4; exit} /Tctl:/ {gsub(/\\+|°C/, \"\", $2); print $2; exit} /Tdie:/ {gsub(/\\+|°C/, \"\", $2); print $2; exit}'"]
        stdout: StdioCollector {
            id: cpuTemperatureCollector
            onStreamFinished: {
                const parsedValue = parseFloat(cpuTemperatureCollector.text.trim())
                root.cpuTemp = Number.isFinite(parsedValue) ? `${Math.round(parsedValue)}°C` : "--°C"
            }
        }
        onExited: (exitCode) => {
            if (exitCode !== 0)
                root.cpuTemp = "--°C"
        }
    }

    Process {
        id: fetchStorageProc
        environment: ({
            LANG: "C",
            LC_ALL: "C"
        })
        command: ["bash", "-lc", "df -kP / 2>/dev/null | awk 'NR==2 {print $2, $3, $4}'"]
        stdout: StdioCollector {
            id: storageCollector
            onStreamFinished: {
                const fields = storageCollector.text.trim().split(/\s+/)
                if (fields.length >= 3) {
                    root.diskTotal = Number(fields[0]) || 1
                    root.diskUsed = Number(fields[1]) || 0
                    root.diskFree = Number(fields[2]) || 0
                }
            }
        }
    }

    Process {
        id: fetchGpuProc
        environment: ({
            LANG: "C",
            LC_ALL: "C"
        })
        command: ["bash", "-lc", "command -v nvidia-smi >/dev/null 2>&1 || exit 0; nvidia-smi --query-gpu=utilization.gpu,temperature.gpu,memory.used,memory.total --format=csv,noheader,nounits 2>/dev/null | head -n1"]
        stdout: StdioCollector {
            id: gpuCollector
            onStreamFinished: {
                const fields = gpuCollector.text.trim().split(/\s*,\s*/)
                if (fields.length >= 4) {
                    root.gpuAvailable = true
                    root.gpuUsage = (Number(fields[0]) || 0) / 100
                    root.gpuTemperature = Number(fields[1])
                    root.gpuMemoryUsed = Number(fields[2]) || 0
                    root.gpuMemoryTotal = Number(fields[3]) || 1
                } else {
                    root.gpuAvailable = false
                    root.gpuUsage = 0
                    root.gpuTemperature = -1
                    root.gpuMemoryUsed = 0
                    root.gpuMemoryTotal = 1
                }
            }
        }
        onExited: (exitCode) => {
            if (exitCode !== 0) {
                root.gpuAvailable = false
                root.gpuUsage = 0
                root.gpuTemperature = -1
                root.gpuMemoryUsed = 0
                root.gpuMemoryTotal = 1
            }
        }
    }

    Component.onCompleted: {
        fetchCpuTemperatureProc.running = true
        fetchStorageProc.running = true
        fetchGpuProc.running = true
    }
}
