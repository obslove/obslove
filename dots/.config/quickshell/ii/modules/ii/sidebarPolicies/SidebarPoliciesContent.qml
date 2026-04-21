import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Qt.labs.synchronizer

Item {
    id: root
    required property var scopeRoot
    property int sidebarPadding: 10
    anchors.fill: parent
    property real animProgress: 0.0
    property bool aiChatEnabled: Config.options.policies.ai !== 0  
    property bool translatorEnabled: Config.options.policies.translator !== 0
    property bool animeEnabled: Config.options.policies.weeb !== 0  
    property bool animeCloset: Config.options.policies.weeb === 2  
    property bool wallpapersEnabled: Config.options.policies.wallpapers !== 0  
    property var tabButtonList: [  
        ...(root.aiChatEnabled ? [{"icon": "neurology", "name": Translation.tr("Intelligence")}] : []),  
        ...(root.translatorEnabled ? [{"icon": "translate", "name": Translation.tr("Translator")}] : []), 
        ...(root.wallpapersEnabled ? [{"icon": "wallpaper", "name": Translation.tr("Wallpapers")}] : []),
        ...((root.animeEnabled && !root.animeCloset) ? [{"icon": "bookmark_heart", "name": Translation.tr("Anime")}] : []) 
    ]
    property int tabCount: swipeView.count

    function focusActiveItem() {
        swipeView.currentItem.forceActiveFocus()
    }

    function applyEntranceAnimation() {
        for (let i = 0; i < mainColumn.children.length; i++) {
            let child = mainColumn.children[i];
            if (!child || !child.visible)
                continue;

            child.opacity = Qt.binding(() => {
                let normalizedDelay = child.y / Math.max(1, mainColumn.height);
                let progress = (root.animProgress - normalizedDelay) / Math.max(0.001, 1.0 - normalizedDelay);
                return Math.max(0, Math.min(1.0, progress));
            });

            child.scale = Qt.binding(() => {
                let normalizedDelay = child.y / Math.max(1, mainColumn.height);
                let progress = (root.animProgress - normalizedDelay) / Math.max(0.001, 1.0 - normalizedDelay);
                return 0.85 + (0.15 * Math.max(0, Math.min(1.0, progress)));
            });
        }
    }

    NumberAnimation on animProgress {
        id: sidebarOpenAnim
        from: 0
        to: 1
        duration: Appearance.animation.elementMove.duration
        easing.type: Appearance.animation.elementMove.type
        easing.bezierCurve: Appearance.animation.elementMove.bezierCurve
    }

    Connections {
        target: GlobalStates

        function onSidebarLeftOpenChanged() {
            if (GlobalStates.sidebarLeftOpen) {
                root.animProgress = 0;
                root.applyEntranceAnimation();
                sidebarOpenAnim.restart();
            }
        }
    }

    Keys.onPressed: (event) => {
        if (event.modifiers === Qt.ControlModifier) {
            if (event.key === Qt.Key_PageDown) {
                swipeView.incrementCurrentIndex()
                event.accepted = true;
            }
            else if (event.key === Qt.Key_PageUp) {
                swipeView.decrementCurrentIndex()
                event.accepted = true;
            }
        }
    }

    ColumnLayout {
        id: mainColumn
        anchors {
            fill: parent
            margins: sidebarPadding
        }
        spacing: sidebarPadding

        Component.onCompleted: {
            root.applyEntranceAnimation()
            if (GlobalStates.sidebarLeftOpen) {
                root.animProgress = 0;
                sidebarOpenAnim.restart()
            }
        }

        onChildrenChanged: root.applyEntranceAnimation()

        Toolbar {
            visible: tabButtonList.length > 1
            Layout.alignment: Qt.AlignHCenter
            enableShadow: false
            colBackground: Appearance.colors.colLayer3
            ToolbarTabBar {
                id: tabBar
                Layout.alignment: Qt.AlignHCenter
                tabButtonList: root.tabButtonList
                currentIndex: Persistent.states.sidebar.policies.tab
                onCurrentIndexChanged: Persistent.states.sidebar.policies.tab = currentIndex
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            implicitWidth: swipeView.implicitWidth
            implicitHeight: swipeView.implicitHeight
            radius: Appearance.rounding.normal
            color: Appearance.colors.colLayer1

            SwipeView { // Content pages
                id: swipeView
                anchors.fill: parent
                spacing: 10
                currentIndex: Persistent.states.sidebar.policies.tab
                onCurrentIndexChanged: Persistent.states.sidebar.policies.tab = currentIndex

                clip: true
                layer.enabled: true
                layer.effect: OpacityMask {
                    maskSource: Rectangle {
                        width: swipeView.width
                        height: swipeView.height
                        radius: Appearance.rounding.small
                    }
                }

                contentChildren: [
                    ...(root.aiChatEnabled ? [aiChat.createObject()] : []),
                    ...(root.translatorEnabled ? [translator.createObject()] : []),
                    ...((root.tabButtonList.length === 0 || (!root.aiChatEnabled && !root.translatorEnabled && root.animeCloset)) ? [placeholder.createObject()] : []),
                    ...(root.wallpapersEnabled ? [wallpaperBrowser.createObject()] : []),
                    ...(root.animeEnabled ? [anime.createObject()] : [])
                ]
            }
        }

        Component {
            id: aiChat
            AiChat {}
        }
        Component {
            id: translator
            Translator {}
        }
        Component {  
            id: wallpaperBrowser  
            WallpaperBrowserUI {}  
        }
        Component {
            id: anime
            Anime {}
        }
        Component {
            id: placeholder
            Item {
                StyledText {
                    anchors.centerIn: parent
                    text: root.animeCloset ? Translation.tr("Nothing") : Translation.tr("Enjoy your empty sidebar...")
                    color: Appearance.colors.colSubtext
                }
            }
        }
    }
}
