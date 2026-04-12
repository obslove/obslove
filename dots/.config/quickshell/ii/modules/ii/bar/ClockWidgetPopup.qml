import qs.modules.common
import qs.modules.common.widgets
import "./cards"
import "./TimerFormat.js" as TimerFormat
import qs.services
import QtQuick
import QtQuick.Layouts

StyledPopup {
    id: root
    popupRadius: Appearance.rounding.large

    property string formattedDate: Qt.locale().toString(DateTime.clock.date, "MMMM dd, dddd")
    property string formattedTime: DateTime.formatTime(Config.options.time.secondPrecisionTargets.barClock)
    property string formattedUptime: DateTime.uptime
    property string todosSection: getUpcomingTodos(Todo.list)
    property bool todosEmpty: todosSection === ""

    property bool stopwatchPaused: !TimerService.stopwatchRunning && TimerService.stopwatchTime > 0

    function getUpcomingTodos(todos) {
        const unfinishedTodos = todos.filter(function (item) {
            return !item.done;
        });
        if (unfinishedTodos.length === 0) {
            return "";
        }

        // Limit to first 3 todos
        const limitedTodos = unfinishedTodos.slice(0, 3);
        let todoText = limitedTodos.map(function (item, index) {
            return `  • ${item.content}`;
        }).join('\n');

        if (unfinishedTodos.length > 3) {
            todoText += `\n  ${Translation.tr("... and %1 more").arg(unfinishedTodos.length - 3)}`;
        }

        return todoText;
    }

    function getDayProgressPercent() {
        const date = DateTime.clock.date
        const secondsPassed = date.getHours() * 3600 + date.getMinutes() * 60 +date.getSeconds()

        return Math.floor((secondsPassed / 86400) * 100)
    }

    function timerPillText() {
        if (TimerService.pomodoroRunning) {
            return TimerFormat.formatPomodoro(TimerService.pomodoroSecondsLeft);
        }

        if (TimerService.stopwatchTime > 0) {
            return TimerFormat.formatStopwatch(TimerService.stopwatchTime);
        }

        return Translation.tr("Timer Off");
    }

    ColumnLayout {
        id: columnLayout
        anchors.centerIn: parent
        spacing: 12

        HeroCard {
            id: clockHero
            icon: "schedule"

            title: root.formattedTime
            subtitle: root.formattedDate

            pillText: getDayProgressPercent() + "%"
            pillIcon: "clock_loader_60"
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 12

            InfoPill {
                text: root.formattedUptime

                shapeContent: CustomIcon {
                    anchors.centerIn: parent
                    width: 24
                    height: 24
                    source: SystemInfo.distroIcon
                    colorize: true
                    color: Appearance.colors.colOnSecondary
                }
            }

            InfoPill {
                text: root.timerPillText()
                containerColor: TimerService.pomodoroBreak ? Appearance.colors.colTertiaryContainer : (TimerService.pomodoroRunning || TimerService.stopwatchRunning ? Appearance.colors.colPrimaryContainer : Appearance.colors.colSecondaryContainer)
                color: containerColor
                shapeColor: TimerService.pomodoroBreak ? Appearance.colors.colTertiary : (TimerService.pomodoroRunning || TimerService.stopwatchRunning ? Appearance.colors.colPrimary : Appearance.colors.colSecondary)
                symbolColor: TimerService.pomodoroBreak ? Appearance.colors.colOnTertiary : (TimerService.pomodoroRunning || TimerService.stopwatchRunning ? Appearance.colors.colOnPrimary : Appearance.colors.colOnSecondary)
                textColor: TimerService.pomodoroBreak ? Appearance.colors.colOnTertiaryContainer : (TimerService.pomodoroRunning || TimerService.stopwatchRunning ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colOnSecondaryContainer)
                icon: TimerService.pomodoroBreak ? "coffee" : root.stopwatchPaused ? "timer_pause" : TimerService.stopwatchRunning ? "timer_play" : "timer"
            }
        }

        SectionCard {
            title: Translation.tr("To-Do Tasks")
            icon: "checklist"
            subtitle: root.todosSection

            LoadingPlaceholder {
                Layout.preferredHeight: 120
                visible: root.todosEmpty
                loading: false
                emptyText: Translation.tr("No pending tasks")
            }
        }
    }
}
