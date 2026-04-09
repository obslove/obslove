import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt.labs.folderlistmodel
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.widgets

import QtQml.Models

ContentPage {
    id: page
    forceWidth: true
    readonly property int index: 2 
    property bool register: parent.register ?? false
    property string policiesPanelButtonIconSearch: ""
    property bool policiesPanelButtonIconSelectorOpen: false
    property string dashboardPanelButtonIconSearch: ""
    property bool dashboardPanelButtonIconSelectorOpen: false
    property var allBarButtonIconOptions: []
    function filterBarButtonIconOptions(query) {
        const normalizedQuery = query.trim().toLowerCase();
        if (normalizedQuery.length === 0)
            return allBarButtonIconOptions;
        return allBarButtonIconOptions.filter(option => option.searchText.includes(normalizedQuery));
    }
    readonly property var filteredPoliciesPanelButtonIconOptions: {
        return page.filterBarButtonIconOptions(policiesPanelButtonIconSearch);
    }
    readonly property var filteredDashboardPanelButtonIconOptions: {
        return page.filterBarButtonIconOptions(dashboardPanelButtonIconSearch);
    }

    property var componentMap: ({
        "policies_panel_button": policiesPanelButtonSettings,
        "dashboard_panel_button": dashboardPanelButtonSettings,
        "active_window": activeWindow,
        "clock": clockSettings,
        "date": dateSettings,
        "music_player": musicPlayer,
        "utility_buttons": utilityButtons,
        "system_tray": systemTray,
        "workspaces": workspaces,
        "timer": indicators,
        "record_indicator": indicators
    })

    function scrollTo(stringId) {
        const item = componentMap[stringId]
        page.contentY = item.y
    }

    function prettifyBarButtonIconName(iconValue) {
        if (iconValue === "distro")
            return Translation.tr("Distro");

        let name = iconValue ?? "";
        if (name.endsWith(".svg"))
            name = name.slice(0, -4);
        const slashIndex = name.lastIndexOf("/");
        if (slashIndex !== -1)
            name = name.slice(slashIndex + 1);
        name = name.replace(/-symbolic$/, "");
        return name.replace(/[-_]+/g, " ").trim();
    }

    function resolveBarButtonIconSource(iconValue) {
        if (iconValue === "distro")
            return SystemInfo.distroIcon;
        if (!iconValue || iconValue.length === 0)
            return "spark-symbolic";
        if (iconValue.includes("/") || iconValue.endsWith(".svg") || iconValue.endsWith("-symbolic"))
            return iconValue;
        return `${iconValue}-symbolic`;
    }

    function rebuildBarButtonIconOptions() {
        const options = [{
            displayName: Translation.tr("Distro"),
            searchText: "distro system linux",
            symbol: SystemInfo.distroIcon,
            value: "distro"
        }];

        for (let i = 0; i < rootIconFolder.count; i++) {
            const fileName = rootIconFolder.get(i, "fileName");
            if (!fileName)
                continue;
            options.push({
                displayName: page.prettifyBarButtonIconName(fileName),
                searchText: `root ${fileName.toLowerCase()} ${page.prettifyBarButtonIconName(fileName).toLowerCase()}`,
                symbol: fileName,
                value: fileName
            });
        }

        for (let i = 0; i < fluentIconFolder.count; i++) {
            const fileName = fluentIconFolder.get(i, "fileName");
            if (!fileName)
                continue;
            const relativePath = `fluent/${fileName}`;
            options.push({
                displayName: page.prettifyBarButtonIconName(relativePath),
                searchText: `fluent ${fileName.toLowerCase()} ${page.prettifyBarButtonIconName(relativePath).toLowerCase()}`,
                symbol: relativePath,
                value: relativePath
            });
        }

        page.allBarButtonIconOptions = options;
    }

    FolderListModel {
        id: rootIconFolder
        folder: Qt.resolvedUrl(Quickshell.shellPath("assets/icons"))
        nameFilters: ["*.svg"]
        showDirs: false
        showDotAndDotDot: false
        sortField: FolderListModel.Name
        onCountChanged: page.rebuildBarButtonIconOptions()
    }

    FolderListModel {
        id: fluentIconFolder
        folder: Qt.resolvedUrl(Quickshell.shellPath("assets/icons/fluent"))
        nameFilters: ["*.svg"]
        showDirs: false
        showDotAndDotDot: false
        sortField: FolderListModel.Name
        onCountChanged: page.rebuildBarButtonIconOptions()
    }

    Component.onCompleted: {
        page.rebuildBarButtonIconOptions();
    }


    ContentSection {
        icon: "mobile_layout"
        title: Translation.tr("Bar layout")
        ContentSubsection {
            title: Translation.tr("Left layout")
            tooltip: Translation.tr("Top layout in vertical mode")
            ConfigListView {
                barSection: 0
                listModel: Config.options.bar.layouts.left
                onUpdated: (newList) => {
                    Config.options.bar.layouts.left = newList
                }
            }
        }
        ContentSubsection {
            title: Translation.tr("Center layout")
            tooltip: Translation.tr("Center the component with the button")
            ConfigListView {
                barSection: 1
                listModel: Config.options.bar.layouts.center
                onUpdated: (newList) => {
                    Config.options.bar.layouts.center = newList
                }
            }
        }
        ContentSubsection {
            title: Translation.tr("Right layout")
            tooltip: Translation.tr("Bottom layout in vertical mode")
            ConfigListView {
                barSection: 2
                listModel: Config.options.bar.layouts.right
                onUpdated: (newList) => {
                    Config.options.bar.layouts.right = newList
                }
            }
        }
    }

    ContentSection {
        id: policiesPanelButtonSettings
        icon: "star"
        title: Translation.tr("Policies panel button")

        ContentSubsection {
            title: Translation.tr("Icon")
            tooltip: Translation.tr("Click the current icon card to choose a different icon")

            RippleButton {
                Layout.fillWidth: true
                implicitHeight: previewRow.implicitHeight + 24
                horizontalPadding: 0
                buttonRadius: Appearance.rounding.large
                colBackground: Appearance.colors.colLayer2
                colBackgroundHover: Appearance.colors.colLayer2Hover
                colRipple: Appearance.colors.colLayer2Active

                onClicked: {
                    page.policiesPanelButtonIconSelectorOpen = !page.policiesPanelButtonIconSelectorOpen;
                    if (!page.policiesPanelButtonIconSelectorOpen)
                        page.policiesPanelButtonIconSearch = "";
                }

                contentItem: RowLayout {
                    id: previewRow
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 12

                    Rectangle {
                        implicitWidth: 42
                        implicitHeight: 42
                        radius: Appearance.rounding.full
                        color: Appearance.colors.colLayer1

                        CustomIcon {
                            anchors.centerIn: parent
                            width: 22
                            height: 22
                            source: page.resolveBarButtonIconSource(Config.options.bar.topLeftIcon)
                            colorize: true
                            color: Appearance.colors.colOnLayer0
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        StyledText {
                            text: Translation.tr("Current icon")
                            color: Appearance.colors.colSubtext
                            font.pixelSize: Appearance.font.pixelSize.small
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: page.prettifyBarButtonIconName(Config.options.bar.topLeftIcon)
                            color: Appearance.colors.colOnLayer0
                            font.family: Appearance.font.family.title
                            font.pixelSize: Appearance.font.pixelSize.large
                        }
                    }

                    MaterialSymbol {
                        Layout.alignment: Qt.AlignVCenter
                        text: page.policiesPanelButtonIconSelectorOpen ? "expand_less" : "edit"
                        iconSize: Appearance.font.pixelSize.large
                        color: Appearance.colors.colSubtext
                    }
                }
            }

            Loader {
                active: page.policiesPanelButtonIconSelectorOpen
                visible: active
                Layout.fillWidth: true

                sourceComponent: ColumnLayout {
                    spacing: 8

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        MaterialSymbol {
                            text: "search"
                            iconSize: Appearance.font.pixelSize.huge
                            color: Appearance.colors.colSubtext
                        }

                        ToolbarTextField {
                            Layout.fillWidth: true
                            placeholderText: Translation.tr("Search icons")
                            text: page.policiesPanelButtonIconSearch
                            onTextChanged: page.policiesPanelButtonIconSearch = text
                        }

                        StyledText {
                            text: `${page.filteredPoliciesPanelButtonIconOptions.length}`
                            color: Appearance.colors.colSubtext
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 280
                        radius: Appearance.rounding.large
                        color: Appearance.colors.colLayer1
                        clip: true

                        GridView {
                            id: iconGrid
                            anchors.fill: parent
                            anchors.margins: 8
                            cellWidth: 52
                            cellHeight: 52
                            boundsBehavior: Flickable.DragOverBounds
                            model: page.filteredPoliciesPanelButtonIconOptions
                            ScrollBar.vertical: StyledScrollBar {}

                            delegate: Item {
                                required property var modelData
                                width: iconGrid.cellWidth
                                height: iconGrid.cellHeight

                                SelectionGroupButton {
                                    anchors.centerIn: parent
                                    width: 44
                                    height: 44
                                    leftmost: true
                                    rightmost: true
                                    buttonSymbol: modelData.symbol
                                    toggled: Config.options.bar.topLeftIcon === modelData.value

                                    onClicked: {
                                        Config.options.bar.topLeftIcon = modelData.value;
                                    }

                                    StyledToolTip {
                                        text: modelData.displayName
                                    }
                                }
                            }
                        }

                        StyledText {
                            anchors.centerIn: parent
                            visible: page.filteredPoliciesPanelButtonIconOptions.length === 0
                            text: Translation.tr("No icons found")
                            color: Appearance.colors.colSubtext
                        }
                    }
                }
            }
        }
    }

    ContentSection {
        id: clockSettings
        icon: "schedule"
        title: Translation.tr("Clock")

        ConfigSwitch {
            buttonIcon: "pace"
            text: Translation.tr("Second precision")
            enabled: Config.options.time.secondPrecision
            checked: Config.options.time.secondPrecisionTargets.barClock
            onCheckedChanged: {
                Config.options.time.secondPrecisionTargets.barClock = checked;
            }
            StyledToolTip {
                text: Translation.tr("Controls second display for the main bar clock, vertical bar clock, and waffle bar clock. Requires the global second precision switch.")
            }
        }
    }

    ContentSection {
        id: dateSettings
        icon: "calendar_month"
        title: Translation.tr("Date")

        ContentSubsection {
            title: Translation.tr("Layout")

            ConfigSelectionArray {
                currentValue: {
                    if (Config.options.bar.date.layout === "vertical")
                        return "compact";
                    if (Config.options.bar.date.layout === "horizontal")
                        return "inline";
                    return Config.options.bar.date.layout;
                }
                Component.onCompleted: {
                    if (Config.options.bar.date.layout === "vertical")
                        Config.options.bar.date.layout = "compact";
                    else if (Config.options.bar.date.layout === "horizontal")
                        Config.options.bar.date.layout = "inline";
                }
                onSelected: newValue => {
                    Config.options.bar.date.layout = newValue;
                }
                options: [
                    {
                        displayName: Translation.tr("Compact"),
                        icon: "vertical_distribute",
                        value: "compact"
                    },
                    {
                        displayName: Translation.tr("Inline"),
                        icon: "short_text",
                        value: "inline"
                    }
                ]
            }
        }

        ContentSubsection {
            title: Translation.tr("Format")
            tooltip: Translation.tr("Changes the date format in the bar")

            ConfigSelectionArray {
                currentValue: Config.options.time.dateFormat
                onSelected: newValue => {
                    Config.options.time.dateFormat = newValue;
                }
                options: [
                    {
                        displayName: Translation.tr("Date First dd/MM"),
                        value: "ddd dd/MM"
                    },
                    {
                        displayName: Translation.tr("Month First MM/dd"),
                        value: "ddd MM/dd"
                    }
                ]
            }
        }
    }

    ContentSection {
        icon: "open_in_full"
        title: Translation.tr("Bar sizes")

        ConfigSpinBox {
            icon: "height"
            text: Translation.tr("Bar height")
            value: Config.options.bar.sizes.height
            from: 30
            to: 50
            stepSize: 1
            onValueChanged: {
                Config.options.bar.sizes.height = value;
            }
        }
        ConfigSpinBox {
            icon: "width"
            text: Translation.tr("Bar width")
            value: Config.options.bar.sizes.width
            from: 30
            to: 50
            stepSize: 1
            onValueChanged: {
                Config.options.bar.sizes.width = value;
            }
        }
    }

    ContentSection {
        icon: "spoke"
        title: Translation.tr("Positioning & appearance")

        ConfigRow {
            ContentSubsection {
                title: Translation.tr("Bar position")
                Layout.fillWidth: true

                ConfigSelectionArray {
                    currentValue: (Config.options.bar.bottom ? 1 : 0) | (Config.options.bar.vertical ? 2 : 0)
                    onSelected: newValue => {
                        Config.options.bar.bottom = (newValue & 1) !== 0;
                        Config.options.bar.vertical = (newValue & 2) !== 0;
                    }
                    options: [
                        {
                            displayName: Translation.tr("Top"),
                            icon: "arrow_upward",
                            value: 0 // bottom: false, vertical: false
                        },
                        {
                            displayName: Translation.tr("Left"),
                            icon: "arrow_back",
                            value: 2 // bottom: false, vertical: true
                        },
                        {
                            displayName: Translation.tr("Bottom"),
                            icon: "arrow_downward",
                            value: 1 // bottom: true, vertical: false
                        },
                        {
                            displayName: Translation.tr("Right"),
                            icon: "arrow_forward",
                            value: 3 // bottom: true, vertical: true
                        }
                    ]
                }
            }
            ContentSubsection {
                title: Translation.tr("Automatically hide")
                Layout.fillWidth: false

                ConfigSelectionArray {
                    currentValue: Config.options.bar.autoHide.enable
                    onSelected: newValue => {
                        Config.options.bar.autoHide.enable = newValue; // Update local copy
                    }
                    options: [
                        {
                            displayName: Translation.tr("No"),
                            icon: "close",
                            value: false
                        },
                        {
                            displayName: Translation.tr("Yes"),
                            icon: "check",
                            value: true
                        }
                    ]
                }
            }
        }

        ConfigRow {
            Layout.fillHeight: false
            ContentSubsection {
                title: Translation.tr("Corner style")
                Layout.fillWidth: true

                ConfigSelectionArray {
                    currentValue: Config.options.bar.cornerStyle
                    onSelected: newValue => {
                        Config.options.bar.cornerStyle = newValue; // Update local copy
                    }
                    options: [
                        {
                            displayName: Translation.tr("Hug"),
                            icon: "line_curve",
                            value: 0
                        },
                        {
                            displayName: Translation.tr("Float"),
                            icon: "page_header",
                            value: 1
                        },
                        {
                            displayName: Translation.tr("Rect"),
                            icon: "toolbar",
                            value: 2
                        }
                    ]
                }
            }

            ContentSubsection {
                title: Translation.tr("Group style")
                tooltip: Translation.tr("Island style makes the group background opaque when bar is transparent")
                Layout.fillWidth: false

                ConfigSelectionArray {
                    currentValue: Config.options.bar.barGroupStyle
                    onSelected: newValue => {
                        Config.options.bar.barGroupStyle = newValue; // Update local copy
                    }
                    options: [
                        {
                            displayName: Translation.tr("Pills"),
                            icon: "location_chip",
                            value: 0
                        },
                        {
                            displayName: Translation.tr("Island"),
                            icon: "shadow",
                            value: 1
                        },
                        {
                            displayName: Translation.tr("Transparent"),
                            icon: "opacity",
                            value: 2
                        }
                    ]
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("Bar background style")
            tooltip: Translation.tr("Adaptive style makes the bar background transparent when there are no active windows")
            Layout.fillWidth: false

            ConfigSelectionArray {
                currentValue: Config.options.bar.barBackgroundStyle
                onSelected: newValue => {
                    Config.options.bar.barBackgroundStyle = newValue;
                }
                options: [ 
                    {
                        displayName: Translation.tr("Visible"),
                        icon: "visibility",
                        value: 1
                    }, 
                    {
                        displayName: Translation.tr("Adaptive"),
                        icon: "masked_transitions",
                        value: 2
                    },        
                    {
                        displayName: Translation.tr("Transparent"),
                        icon: "opacity",
                        value: 0
                    }
                ]
            }
        }
    }
    
    ContentSection {
        id: dashboardPanelButtonSettings
        icon: "notifications"
        title: Translation.tr("Dashboard panel button")

        ContentSubsection {
            title: Translation.tr("Icon mode")
            tooltip: Translation.tr("Dynamic keeps the original live indicators. Fixed removes the notification indicators and shows only one fixed icon.")

            ConfigSelectionArray {
                currentValue: Config.options.bar.dashboardPanelButton.iconMode
                onSelected: newValue => {
                    Config.options.bar.dashboardPanelButton.iconMode = newValue;
                }
                options: [
                    {
                        displayName: Translation.tr("Dynamic"),
                        icon: "auto_awesome_motion",
                        value: "dynamic"
                    },
                    {
                        displayName: Translation.tr("Fixed"),
                        icon: "keep",
                        value: "fixed"
                    }
                ]
            }
        }

        ContentSubsection {
            title: Translation.tr("Icon")
            tooltip: Translation.tr("Click the current icon card to choose a different icon")
            visible: Config.options.bar.dashboardPanelButton.iconMode === "fixed"

            RippleButton {
                Layout.fillWidth: true
                implicitHeight: dashboardPreviewRow.implicitHeight + 24
                horizontalPadding: 0
                buttonRadius: Appearance.rounding.large
                colBackground: Appearance.colors.colLayer2
                colBackgroundHover: Appearance.colors.colLayer2Hover
                colRipple: Appearance.colors.colLayer2Active

                onClicked: {
                    page.dashboardPanelButtonIconSelectorOpen = !page.dashboardPanelButtonIconSelectorOpen;
                    if (!page.dashboardPanelButtonIconSelectorOpen)
                        page.dashboardPanelButtonIconSearch = "";
                }

                contentItem: RowLayout {
                    id: dashboardPreviewRow
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 12

                    Rectangle {
                        implicitWidth: 42
                        implicitHeight: 42
                        radius: Appearance.rounding.full
                        color: Appearance.colors.colLayer1

                        CustomIcon {
                            anchors.centerIn: parent
                            width: 22
                            height: 22
                            source: page.resolveBarButtonIconSource(Config.options.bar.dashboardPanelButton.icon)
                            colorize: true
                            color: Appearance.colors.colOnLayer0
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        StyledText {
                            text: Translation.tr("Current icon")
                            color: Appearance.colors.colSubtext
                            font.pixelSize: Appearance.font.pixelSize.small
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: page.prettifyBarButtonIconName(Config.options.bar.dashboardPanelButton.icon)
                            color: Appearance.colors.colOnLayer0
                            font.family: Appearance.font.family.title
                            font.pixelSize: Appearance.font.pixelSize.large
                        }
                    }

                    MaterialSymbol {
                        Layout.alignment: Qt.AlignVCenter
                        text: page.dashboardPanelButtonIconSelectorOpen ? "expand_less" : "edit"
                        iconSize: Appearance.font.pixelSize.large
                        color: Appearance.colors.colSubtext
                    }
                }
            }

            Loader {
                active: page.dashboardPanelButtonIconSelectorOpen
                visible: active
                Layout.fillWidth: true

                sourceComponent: ColumnLayout {
                    spacing: 8

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        MaterialSymbol {
                            text: "search"
                            iconSize: Appearance.font.pixelSize.huge
                            color: Appearance.colors.colSubtext
                        }

                        ToolbarTextField {
                            Layout.fillWidth: true
                            placeholderText: Translation.tr("Search icons")
                            text: page.dashboardPanelButtonIconSearch
                            onTextChanged: page.dashboardPanelButtonIconSearch = text
                        }

                        StyledText {
                            text: `${page.filteredDashboardPanelButtonIconOptions.length}`
                            color: Appearance.colors.colSubtext
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 280
                        radius: Appearance.rounding.large
                        color: Appearance.colors.colLayer1
                        clip: true

                        GridView {
                            id: dashboardIconGrid
                            anchors.fill: parent
                            anchors.margins: 8
                            cellWidth: 52
                            cellHeight: 52
                            boundsBehavior: Flickable.DragOverBounds
                            model: page.filteredDashboardPanelButtonIconOptions
                            ScrollBar.vertical: StyledScrollBar {}

                            delegate: Item {
                                required property var modelData
                                width: dashboardIconGrid.cellWidth
                                height: dashboardIconGrid.cellHeight

                                SelectionGroupButton {
                                    anchors.centerIn: parent
                                    width: 44
                                    height: 44
                                    leftmost: true
                                    rightmost: true
                                    buttonSymbol: modelData.symbol
                                    toggled: Config.options.bar.dashboardPanelButton.icon === modelData.value

                                    onClicked: {
                                        Config.options.bar.dashboardPanelButton.icon = modelData.value;
                                    }

                                    StyledToolTip {
                                        text: modelData.displayName
                                    }
                                }
                            }
                        }

                        StyledText {
                            anchors.centerIn: parent
                            visible: page.filteredDashboardPanelButtonIconOptions.length === 0
                            text: Translation.tr("No icons found")
                            color: Appearance.colors.colSubtext
                        }
                    }
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("Notifications")

            ConfigSwitch {
                buttonIcon: "counter_2"
                text: Translation.tr("Unread indicator: show count")
                checked: Config.options.bar.indicators.notifications.showUnreadCount
                onCheckedChanged: {
                    Config.options.bar.indicators.notifications.showUnreadCount = checked;
                }
            }
        }
    }

    ContentSection {
        id: activeWindow
        icon: "ad"
        title: Translation.tr("Active window")
        ConfigSwitch {
            buttonIcon: "crop_free"
            text: Translation.tr("Use fixed size")
            checked: Config.options.bar.activeWindow.fixedSize
            onCheckedChanged: {
                Config.options.bar.activeWindow.fixedSize = checked;
            }
        }
    }

    ContentSection {
        id: musicPlayer
        icon: "music_cast"
        title: Translation.tr("Media player")

        ConfigRow {
            uniform: true

            ConfigSwitch {
                buttonIcon: "crop_free"
                text: Translation.tr("Use fixed size")
                checked: Config.options.bar.mediaPlayer.useFixedSize
                onCheckedChanged: {
                    Config.options.bar.mediaPlayer.useFixedSize = checked;
                }
            }   

            ConfigSpinBox {
                enabled: !Config.options.bar.vertical && Config.options.bar.mediaPlayer.useFixedSize
                icon: "width_full"
                text: Translation.tr("Custom size")
                value: Config.options.bar.mediaPlayer.customSize
                from: 100
                to: 500
                stepSize: 25
                onValueChanged: {
                    Config.options.bar.mediaPlayer.customSize = value;
                }
            }
        }

        ConfigSpinBox {
            enabled: !Config.options.bar.vertical
            icon: "width_full"
            text: Translation.tr("Lyrics width")
            value: Config.options.bar.mediaPlayer.lyrics.customSize
            from: 100
            to: 750
            stepSize: 25
            onValueChanged: {
                Config.options.bar.mediaPlayer.lyrics.customSize = value;
            }
        }

        ContentSubsection {
            title: Translation.tr("Artwork")

            ConfigSwitch {
                enabled: !Config.options.bar.vertical
                buttonIcon: "image"
                text: Translation.tr("Enable artwork")
                checked: Config.options.bar.mediaPlayer.artwork.enable
                onCheckedChanged: {
                    Config.options.bar.mediaPlayer.artwork.enable = checked;
                }
            }
        }
        
        ContentSubsection {
            title: Translation.tr("Lyrics")

            ConfigRow {
                ConfigSwitch {
                    buttonIcon: "check"
                    text: Translation.tr("Enable")
                    Layout.fillWidth: false
                    checked: Config.options.bar.mediaPlayer.lyrics.enable
                    onCheckedChanged: {
                        Config.options.bar.mediaPlayer.lyrics.enable = checked;
                    }
                    StyledToolTip {
                        text: Translation.tr("Lyrics will be visible when they are fetched with API")
                    }
                }

                Item {
                    Layout.fillWidth: true
                }

                ConfigSelectionArray {
                    Layout.fillWidth: false
                    currentValue: Config.options.bar.mediaPlayer.lyrics.style
                    onSelected: newValue => {
                        Config.options.bar.mediaPlayer.lyrics.style = newValue
                    }
                    options: [
                        {
                            displayName: Translation.tr("Static"),
                            icon: "format_size",
                            value: "static"
                        },
                        {
                            displayName: Translation.tr("Scroller"),
                            icon: "keyboard_double_arrow_up",
                            value: "scroller"
                        }
                    ]
                }
            }

            ConfigSwitch {
                enabled: Config.options.bar.mediaPlayer.lyrics.enable && Config.options.bar.mediaPlayer.lyrics.style === "scroller"
                buttonIcon: "gradient"
                text: Translation.tr("Use gradient mask")
                checked: Config.options.bar.mediaPlayer.lyrics.useGradientMask
                onCheckedChanged: {
                    Config.options.bar.mediaPlayer.lyrics.useGradientMask = checked;
                }
            }
            
        }

    }
    

    ContentSection {
        id: systemTray
        icon: "shelf_auto_hide"
        title: Translation.tr("Tray")

        ConfigSwitch {
            buttonIcon: "keep"
            text: Translation.tr('Make icons pinned by default')
            checked: Config.options.tray.invertPinnedItems
            onCheckedChanged: {
                Config.options.tray.invertPinnedItems = checked;
            }
        }
        
        ConfigSwitch {
            buttonIcon: "colors"
            text: Translation.tr('Tint icons')
            checked: Config.options.tray.monochromeIcons
            onCheckedChanged: {
                Config.options.tray.monochromeIcons = checked;
            }
        }
    }

    ContentSection {
        id: indicators
        icon: "ad"
        title: Translation.tr("Indicators")

        ContentSubsection {
            title: Translation.tr("Timer and pomodoro")

            ConfigRow {
                uniform: true
                ConfigSwitch {
                    buttonIcon: "timer"
                    text: Translation.tr("Show stopwatch")
                    checked: Config.options.bar.timers.showStopwatch
                    onCheckedChanged: {
                        Config.options.bar.timers.showStopwatch = checked;
                    }
                }
                ConfigSwitch {
                    buttonIcon: "search_activity"
                    text: Translation.tr("Show pomodoro")
                    checked: Config.options.bar.timers.showPomodoro
                    onCheckedChanged: {
                        Config.options.bar.timers.showPomodoro = checked;
                    }
                }
            }
        }
        
        ContentSubsection {
            title: Translation.tr("Record")

            ConfigSwitch {
                buttonIcon: "check_indeterminate_small"
                text: Translation.tr("Minimal mode")
                checked: Config.options.bar.indicators.record.minimal
                onCheckedChanged: {
                    Config.options.bar.indicators.record.minimal = checked;
                }
            }
        }
    }

    ContentSection {
        id: utilityButtons
        icon: "widgets"
        title: Translation.tr("Utility buttons")

        ConfigRow {
            uniform: true
            ConfigSwitch {
                buttonIcon: "content_cut"
                text: Translation.tr("Screen snip")
                checked: Config.options.bar.utilButtons.showScreenSnip
                onCheckedChanged: {
                    Config.options.bar.utilButtons.showScreenSnip = checked;
                }
            }
            ConfigSwitch {
                buttonIcon: "colorize"
                text: Translation.tr("Color picker")
                checked: Config.options.bar.utilButtons.showColorPicker
                onCheckedChanged: {
                    Config.options.bar.utilButtons.showColorPicker = checked;
                }
            }
        }
        ConfigRow {
            uniform: true
            ConfigSwitch {
                buttonIcon: "keyboard"
                text: Translation.tr("Keyboard toggle")
                checked: Config.options.bar.utilButtons.showKeyboardToggle
                onCheckedChanged: {
                    Config.options.bar.utilButtons.showKeyboardToggle = checked;
                }
            }
            ConfigSwitch {
                buttonIcon: "mic"
                text: Translation.tr("Mic toggle")
                checked: Config.options.bar.utilButtons.showMicToggle
                onCheckedChanged: {
                    Config.options.bar.utilButtons.showMicToggle = checked;
                }
            }
        }
        ConfigRow {
            uniform: true
            ConfigSwitch {
                buttonIcon: "dark_mode"
                text: Translation.tr("Dark/Light toggle")
                checked: Config.options.bar.utilButtons.showDarkModeToggle
                onCheckedChanged: {
                    Config.options.bar.utilButtons.showDarkModeToggle = checked;
                }
            }
            ConfigSwitch {
                buttonIcon: "speed"
                text: Translation.tr("Performance Profile toggle")
                checked: Config.options.bar.utilButtons.showPerformanceProfileToggle
                onCheckedChanged: {
                    Config.options.bar.utilButtons.showPerformanceProfileToggle = checked;
                }
            }
        }
        ConfigRow {
            uniform: true
            ConfigSwitch {
                buttonIcon: "videocam"
                text: Translation.tr("Record")
                checked: Config.options.bar.utilButtons.showScreenRecord
                onCheckedChanged: {
                    Config.options.bar.utilButtons.showScreenRecord = checked;
                }
            }
        }
    }

    ContentSection {
        id: workspaces
        icon: "workspaces"
        title: Translation.tr("Workspaces")

        ConfigRow {
            uniform: true

            ConfigSwitch {
                buttonIcon: "grid_3x3"
                text: Translation.tr('Use workspace map')
                checked: Config.options.bar.workspaces.useWorkspaceMap
                onCheckedChanged: {
                    Config.options.bar.workspaces.useWorkspaceMap = checked;
                }
                StyledToolTip {
                    text: Translation.tr("Only for multi-monitor setups, you must edit the workspace map manually in config.json\n Refer to the repo wiki for more information")
                }
            }

            ConfigSwitch {
                buttonIcon: "counter_1"
                text: Translation.tr('Always show numbers')
                checked: Config.options.bar.workspaces.alwaysShowNumbers
                onCheckedChanged: {
                    Config.options.bar.workspaces.alwaysShowNumbers = checked;
                }
            }
        }

        ConfigRow {
            uniform: true

            ConfigSwitch {
                buttonIcon: "award_star"
                text: Translation.tr('Show app icons')
                checked: Config.options.bar.workspaces.showAppIcons
                onCheckedChanged: {
                    Config.options.bar.workspaces.showAppIcons = checked;
                }
            }

            ConfigSwitch {
                enabled: Config.options.bar.workspaces.showAppIcons
                buttonIcon: "colors"
                text: Translation.tr('Tint app icons')
                checked: Config.options.bar.workspaces.monochromeIcons
                onCheckedChanged: {
                    Config.options.bar.workspaces.monochromeIcons = checked;
                }
            }
        }

        ConfigSwitch {
            buttonIcon: "hdr_weak"
            text: Translation.tr("Dynamic workspaces")
            checked: Config.options.bar.workspaces.dynamicWorkspaces
            onCheckedChanged: {
                Config.options.bar.workspaces.dynamicWorkspaces = checked;
            }
            StyledToolTip {
                text: Translation.tr("Hides the empty workspaces and only shows the ones with windows")
            }
        }

        ConfigSpinBox {
            enabled: !Config.options.bar.workspaces.dynamicWorkspaces
            icon: "view_column"
            text: Translation.tr("Workspaces shown")
            value: Config.options.bar.workspaces.shown
            from: 1
            to: 30
            stepSize: 1
            onValueChanged: {
                Config.options.bar.workspaces.shown = value;
            }
        }

        ConfigSpinBox {
            icon: "select_window"
            text: Translation.tr("Maximum window count per workspace")
            value: Config.options.bar.workspaces.maxWindowCount
            from: 1
            to: 20
            stepSize: 1
            onValueChanged: {
                Config.options.bar.workspaces.maxWindowCount = value;
            }
        }

        ConfigSpinBox {
            icon: "touch_long"
            text: Translation.tr("Number show delay when pressing Super (ms)")
            value: Config.options.bar.workspaces.showNumberDelay
            from: 0
            to: 1000
            stepSize: 50
            onValueChanged: {
                Config.options.bar.workspaces.showNumberDelay = value;
            }
        }

        ContentSubsection {
            title: Translation.tr("Number style")

            ConfigSelectionArray {
                currentValue: JSON.stringify(Config.options.bar.workspaces.numberMap)
                onSelected: newValue => {
                    Config.options.bar.workspaces.numberMap = JSON.parse(newValue)
                }
                options: [
                    {
                        displayName: Translation.tr("Normal"),
                        icon: "timer_10",
                        value: '[]'
                    },
                    {
                        displayName: Translation.tr("Han chars"),
                        icon: "square_dot",
                        value: '["一","二","三","四","五","六","七","八","九","十","十一","十二","十三","十四","十五","十六","十七","十八","十九","二十"]'
                    },
                    {
                        displayName: Translation.tr("Roman"),
                        icon: "account_balance",
                        value: '["I","II","III","IV","V","VI","VII","VIII","IX","X","XI","XII","XIII","XIV","XV","XVI","XVII","XVIII","XIX","XX"]'
                    }
                ]
            }
        }
    }

    ContentSection {
        icon: "tooltip"
        title: Translation.tr("Tooltips")
        ConfigSwitch {
            buttonIcon: "ads_click"
            text: Translation.tr("Click to show")
            checked: Config.options.bar.tooltips.clickToShow
            onCheckedChanged: {
                Config.options.bar.tooltips.clickToShow = checked;
            }
        }
        ConfigSwitch {
            buttonIcon: "compress"
            text: Translation.tr("Compact popups")
            checked: Config.options.bar.tooltips.compactPopups
            onCheckedChanged: {
                Config.options.bar.tooltips.compactPopups = checked;
            }
        }
        ConfigSwitch {
            buttonIcon: "left_click"
            text: Translation.tr("Open sidebars outside buttons")
            checked: Config.options.bar.tooltips.openSidebarsOutsideButtons
            onCheckedChanged: {
                Config.options.bar.tooltips.openSidebarsOutsideButtons = checked;
            }
        }
        ConfigSwitch {
            buttonIcon: "swap_vert"
            text: Translation.tr("Side scroll adjustments")
            checked: Config.options.bar.sideScrollAdjustments
            onCheckedChanged: {
                Config.options.bar.sideScrollAdjustments = checked;
            }
            StyledToolTip {
                text: Translation.tr("Lets the bar edges change brightness and volume with the mouse wheel")
            }
        }
    }
}
