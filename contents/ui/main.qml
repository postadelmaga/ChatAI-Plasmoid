import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid

// Main plasmoid item that contains all the widget functionality
PlasmoidItem {
    id: root

    // Define the available chat models and their properties
    // This property combines both predefined and custom sites
    property var models: {
        // Define base models with their default properties
        let baseModels = [
            {
                "id": "t3",
                "url": "https://t3.chat",
                "text": "T3 Chat",
                "prop": "showT3Chat"
            },
            {
                "id": "duckduckgo",
                "url": "https://duckduckgo.com/chat",
                "text": "DuckDuckGo Chat",
                "prop": "showDuckDuckGoChat"
            },
            {
                "id": "chatgpt",
                "url": "https://chatgpt.com",
                "text": "ChatGPT",
                "prop": "showChatGPT"
            },
            {
                "id": "huggingface",
                "url": "https://huggingface.co/chat",
                "text": "HugginChat",
                "prop": "showHugginChat"
            },
            {
                "id": "copilot",
                "url": "https://copilot.microsoft.com/",
                "text": "Bing Copilot",
                "prop": "showBingCopilot"
            },
            {
                "id": "google",
                "url": "https://gemini.google.com/app",
                "text": "Google Gemini",
                "prop": "showGoogleGemini"
            },
            {
                "id": "blackbox",
                "url": "https://www.blackbox.ai",
                "text": "BlackBox AI",
                "prop": "showBlackBox"
            },
            {
                "id": "you",
                "url": "https://you.com/?chatMode=default",
                "text": "You",
                "prop": "showYou"
            },
            {
                "id": "perplexity",
                "url": "https://www.perplexity.ai",
                "text": "Perplexity",
                "prop": "showPerplexity"
            },
            {
                "id": "lobechat",
                "url": "https://lobechat.com/chat",
                "text": "LobeChat",
                "prop": "showLobeChat"
            },
            {
                "id": "bigagi",
                "url": "https://get.big-agi.com",
                "text": "Big-AGI",
                "prop": "showBigAGI"
            },
            {
                "id": "claude",
                "url": "https://claude.ai/new",
                "text": "Claude",
                "prop": "showClaude"
            },
            {
                "id": "deepseek",
                "url": "https://chat.deepseek.com",
                "text": "DeepSeek",
                "prop": "showDeepSeek"
            },
            {
                "id": "meta",
                "url": "https://www.meta.ai",
                "text": "Meta AI",
                "prop": "showMetaAI"
            },
            {
                "id": "grok",
                "url": "https://x.com/i/grok",
                "text": "Grok",
                "prop": "showGrok"
            }
        ];
        // Add custom sites from configuration to the models list
        let customSites = plasmoid.configuration.customSites || [];
        if (Array.isArray(customSites)) {
            customSites.forEach(site => {
                if (site && typeof site === 'string' && site.includes('|')) {
                    const [name, url] = site.split('|');
                    if (name && url)
                        baseModels.push({
                            "id": name.toLowerCase().replace(/\s+/g, '-'),
                            "url": url,
                            "text": name,
                            "prop": "showCustom_" + name.toLowerCase().replace(/\s+/g, '_')
                        });
                }
            });
        }
        return baseModels;
    }

    // Initialize the plasmoid and check if it should load on startup
    Component.onCompleted: {
        // If loadOnStartup is enabled in configuration
        if (plasmoid.configuration.loadOnStartup) {
            webviewLoader.active = true; // Activate the WebView loader
            root.expanded = true; // Expand the plasmoid
        }
    }

    // Widget appearance when collapsed (icon only)
    compactRepresentation: CompactRepresentation {
        id: compactRep

        models: root.models
        webview: root.webviewRoot ? root.webviewRoot.webview : null
    }

    // Widget appearance when expanded (full view)
    // Uses Item instead of ColumnLayout so that header hide/show animations do not
    // change implicitHeight, which would cause Plasma to reset the popup size.
    fullRepresentation: Item {
        id: mainLayout

        // Expose WebView root for other components
        property alias webviewRoot: webviewLoader.item
        property bool reverseLayout: plasmoid.location === PlasmaCore.Types.TopEdge

        // Set minimum dimensions for the expanded view
        Layout.minimumWidth: Kirigami.Units.gridUnit * 28
        Layout.minimumHeight: Kirigami.Units.gridUnit * 39

        // Add monitor for plasmoid location change
        Connections {
            function onLocationChanged() {
                mainLayout.reverseLayout = plasmoid.location === PlasmaCore.Types.TopEdge;
            }

            target: plasmoid
        }

        // Header component with auto-hide behavior
        Header {
            id: headerRoot

            property bool headerVisible: false
            property bool isInteracting: false
            property bool shouldBeVisible: {
                if (plasmoid.configuration.hideHeader)
                    return false;

                if (!plasmoid.configuration.autoHideHeader)
                    return true;

                return headerVisible || isInteracting || headerMouseArea.containsMouse;
            }

            models: root.models
            width: parent.width
            z: 2 // Increase the z-index to ensure it is above the MouseArea

            // Anchor to top (normal layout) or bottom (reverse/top-panel layout)
            anchors.top: mainLayout.reverseLayout ? undefined : parent.top
            anchors.bottom: mainLayout.reverseLayout ? parent.bottom : undefined

            // Callback to close the WebView and collapse the widget
            closeWebViewCallback: function () {
                webviewLoader.active = false;
                root.expanded = false;
            }
            // Handle navigation
            onGoBackToHomePage: webviewRoot.goBackToHomePage()
            onReloadPageRequested: webviewRoot.reloadPage()
            onNavigateBackRequested: webviewRoot.goBack()
            onNavigateForwardRequested: webviewRoot.goForward()
            onPrintPageRequested: webviewRoot.printPage()
            onToggleSearchRequested: {
                if (webviewRoot && webviewRoot.findBarVisible !== undefined) {
                    webviewRoot.findBarVisible = !webviewRoot.findBarVisible;
                }
            }

            // Animate height directly (not Layout.preferredHeight) so the parent
            // Item's implicitHeight is unaffected and Plasma won't reset popup size.
            height: shouldBeVisible ? implicitHeight : 0
            opacity: shouldBeVisible ? 1 : 0
            clip: true

            // Timer for hiding
            Timer {
                id: hideTimer

                interval: 2000
                onTriggered: {
                    if (!headerRoot.isInteracting)
                        headerRoot.headerVisible = false;
                }
            }

            // Timer to check interactions
            Timer {
                id: interactionTimer

                interval: 500
                repeat: true
                running: headerRoot.isInteracting
                onTriggered: {
                    // Check if there is still interaction with any component
                    let stillInteracting = false;
                    for (let i = 0; i < headerRoot.children.length; i++) {
                        let child = headerRoot.children[i];
                        if (child.activeFocus || (child.hasOwnProperty("pressed") && child.pressed)) {
                            stillInteracting = true;
                            break;
                        }
                    }
                    headerRoot.isInteracting = stillInteracting;
                    if (!stillInteracting && !headerMouseArea.containsMouse)
                        hideTimer.restart();
                }
            }

            // Connections to monitor interactions
            Connections {
                function onActiveFocusChanged() {
                    if (target.activeFocus) {
                        headerRoot.isInteracting = true;
                        hideTimer.stop();
                    }
                }

                target: headerRoot
            }

            // Intercept mouse events
            MouseArea {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.alignment: Qt.AlignTop
                hoverEnabled: true
                propagateComposedEvents: true
                onEntered: {
                    headerRoot.headerVisible = true;
                    hideTimer.stop();
                }
                onExited: {
                    if (!headerRoot.isInteracting)
                        hideTimer.restart();
                }
                onPressed: event => {
                    headerRoot.isInteracting = true;
                    event.accepted = false;
                }
                onReleased: event => {
                    headerRoot.isInteracting = false;
                    if (!containsMouse)
                        hideTimer.restart();

                    event.accepted = false;
                }
            }

            // Animations
            Behavior on height {
                NumberAnimation {
                    duration: 400
                    easing.type: Easing.InOutCubic
                }
            }

            Behavior on opacity {
                NumberAnimation {
                    duration: 400
                    easing.type: Easing.InOutQuad
                }
            }
        }

        // Mouse detection area — thin strip at the panel edge that triggers header reveal
        MouseArea {
            id: headerMouseArea

            width: parent.width
            height: 2
            hoverEnabled: true
            z: 1 // Place below the header
            propagateComposedEvents: true

            // Anchor to same edge as header
            anchors.top: mainLayout.reverseLayout ? undefined : parent.top
            anchors.bottom: mainLayout.reverseLayout ? parent.bottom : undefined

            onEntered: {
                headerRoot.headerVisible = true;
                hideTimer.stop();
            }
            onExited: {
                if (!headerRoot.isInteracting)
                    hideTimer.restart();
            }
            // Pass mouse events to child components
            onClicked: event => event.accepted = false
            onPressed: event => event.accepted = false
            onReleased: event => event.accepted = false
            onDoubleClicked: event => event.accepted = false
            onPositionChanged: event => event.accepted = false
            onPressAndHold: event => event.accepted = false
        }

        // WebView loader that manages the web content
        // Fills the entire Item; top/bottom margin tracks the header height so the
        // webview smoothly gains/loses space as the header animates in/out.
        Loader {
            id: webviewLoader

            // Improved the loading of the WebView & Added Error Handling
            active: root.expanded || item !== null || plasmoid.configuration.loadOnStartup
            asynchronous: true
            source: "WebView.qml"
            anchors.fill: parent
            anchors.topMargin: mainLayout.reverseLayout ? 0 : headerRoot.height
            anchors.bottomMargin: mainLayout.reverseLayout ? headerRoot.height : 0

            // Add status handling
            onStatusChanged: {
                if (status === Loader.Error) {
                    console.error("Failed to load WebView.qml");
                }
            }
        }

        // Monitor plasmoid expansion state
        Connections {
            // Activate WebView when plasmoid is expanded
            function onExpandedChanged() {
                if (root.expanded)
                    webviewLoader.active = true;
            }

            target: root
        }
    }
}
