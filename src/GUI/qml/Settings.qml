import QtQuick 2.4
import FlightGear.Launcher 1.0
import "."

Item {
    Rectangle {
        // search 'dimming' rectangle
        visible: _launcher.isSearchActive
        anchors.fill: parent
        color: "#7f7f7f"
    }

    Binding {
        target: _launcher
        property: "settingsSummary"
        value: generalSettings.summary().concat(mpSettings.summary(),
                                                downloadSettings.summary(),
                                                windowSettings.summary(),
                                                renderSection.summary());
    }

    Connections {
        target: _launcher
        onRequestSaveState: {
            mpSettings.saveState();
            downloadSettings.saveState();
            generalSettings.saveState();
            renderSection.saveState();
            extraArgsSection.saveState();
            windowSettings.saveState();
        }
    }

    Flickable {
        id: settingsFlick
        contentHeight: sectionColumn.childrenRect.height
        flickableDirection: Flickable.VerticalFlick
        height: parent.height
        width: parent.width - scrollbar.width

        Column
        {
            id: sectionColumn
            width: parent.width

            Item {
                // top margin
                width: parent.width
                height: Style.margin
            }

            Item {
                id: header
                width: parent.width
                height: headerText.height

                Text {
                    id: headerText
                    text: qsTr("Settings")
                    font.pixelSize: Style.strutSize / 2
                    anchors.left: parent.left
                    anchors.leftMargin: Style.inset
                }

                SearchButton {
                    id: search
                    width: Style.strutSize * 4
                    anchors.right: parent.right
                    anchors.rightMargin: Style.margin
                    anchors.verticalCenter: parent.verticalCenter
                    autoSubmitTimeout: 250
                    onSearch: {
                        _launcher.settingsSearchTerm = term
                    }
                }
            }

            Item {
                // below header margin
                width: parent.width
                height: Style.margin
            }

            Section {
                id: generalSettings
                title: qsTr("General")
                settingGroup: "general"

                function summary()
                {
                    var result = [];
                    if (startPaused.checked) result.push("paused");
                    if (!showConsoleWin.hidden && showConsoleWin.checked) result.push("console");
                    return result;
                }

                contents: [
                    SettingCheckbox {
                        id: startPaused
                        label: qsTr("Start paused")
                        description: qsTr("Automatically pause the simulator when launching. This is useful "
                            + "when starting in the air.")
                        keywords: ["pause", "freeze"]
                        option: "freeze"
                        setting: "start-paused"
                    },

                    SettingCheckbox {
                        id: autoCoordination
                        label: qsTr("Enable auto-coordination")
                        description: qsTr("When flying with the mouse, or a joystick lacking a rudder axis, "
                            + "it's difficult to manually coordinate aileron and rudder movements during "
                            + "turn. This option automatically commands the rudder to maintain zero "
                            + "slip angle when banking");
                        advanced: true
                        keywords: ["input", "mouse", "control", "rudder"]
                        option: "auto-coordination"
                        setting: "auto-coordination"
                    },

                    SettingCheckbox {
                        id: showConsoleWin
                        label: qsTr("Show debugging console")
                        description: qsTr("Open a console window showing debug output from the application.")
                        advanced: true
                        hidden: _osName !== "win"
                        keywords: ["console", "terminal", "log", "debug"]
                        setting: "console"
                    }
                ]

                onApply: {
                    if (!showConsoleWin.hidden && showConsoleWin.checked) _config.setArg("console")
                }
            }

            Section {
                id: mpSettings
                title: qsTr("Multi-player")
                settingGroup: "mp"

                readonly property int defaultMPPort: 5000

                function summary()
                {
                    var result = [];
                    if (enableMP.checked) result.push("multi-player");
                    return result;
                }

                contents: [
                    SettingCheckbox {
                        id: enableMP
                        label: qsTr("Connect to the multi-player network")
                        description: qsTr("FlightGear supporters maintain a network of servers to enable global multi-user "
                                          + "flight. This requires a moderately fast Internet connection to be usable. Your aircraft "
                                          + "will be visible to other users online, and you will see their aircraft.")
                        keywords: ["network", "mp", "multiplay","online"]
                        setting: "enabled"

                        onValueChanged: {
                            if (value) {
                                console.info("MP enabled, doing refresh")
                                _launcher.queryMPServers();
                            }
                        }
                    },

                    SettingLineEdit {
                        id: callSign
                        enabled: enableMP.checked
                        label: qsTr("Callsign")
                        description: qsTr("Enter a callsign you will use online. This is visible to all users and is " +
                                          "how ATC services and other pilots will refer to you. " +
                                          "(Maximum of seven characters permitted)")
                        placeholder: "D-FGFS"
                        suggestedWidthString: "MMMMMMMMMMM"
                        keywords: ["callsign", "handle", "name"]

                        // between one and seven alphanumerics, underscores and/or hypens
                        // spaces not permitted
                        validation: RegExpValidator { regExp: /[\w-]{1,7}/ }
                        setting: "callsign"
                    },

                    SettingsComboBox {
                        id: mpServer
                        label: qsTr("Server")
                        enabled: enableMP.checked
                        description: qsTr("Select a server close to you for better responsiveness and reduced lag when flying online.")
                        choices: _launcher.mpServersModel

                        readonly property bool currentIsCustom: (_launcher.mpServersModel.serverForIndex(selectedIndex) == "__custom__")
                        property string __savedServer;

                        keywords: ["server", "hostname"]
                        setting: "server"

                        // following three elements are to deal with the irregular way we save the
                        // MP server state, because the index is unstable, and the time to query online servers
                        // is determined by the MPServersModel. So we let that code do the state
                        // restoration, and emit a signal we handler here, when it wants to update the UI.
                        function saveState()
                        {
                            // these values match the code in MPServersModel.cpp, sorry for that
                            // nastyness
                            _config.setValueForKey("mpSettings", "mp-server", _launcher.mpServersModel.serverForIndex(selectedIndex) );
                        }

                        function restoreState()
                        {
                            // no-op, this is triggered by MPServersModel::restoreMPServerSelection
                        }

                        Connections
                        {
                            target: _launcher.mpServersModel
                            onRestoreIndex: { mpServer.selectedIndex = index }
                        }
                    },

                    SettingLineEdit {
                        id: mpCustomServer
                        enabled: enableMP.checked
                        label: qsTr("Custom server")
                        hidden: !mpServer.currentIsCustom
                        description: qsTr("Enter a server hostname or IP address, and optionally a port number. (Default port is 5000) For example 'localhost:5001'")
                        placeholder: "localhost:5001"
                        suggestedWidthString: "MMMMMMMMMMMMMMMMMMMMMMMMMMMMM"
                        setting: "custom-server"
                    }
                ]

                onApply: {
                    if (enableMP.checked) {
                        if (mpServer.currentIsCustom) {
                            var pieces = mpCustomServer.value.split(':')
                            var port = defaultMPPort;
                            if (pieces.length > 1) {
                                port = pieces[1];
                            }

                            _config.setProperty("/sim/multiplay/txhost", pieces[0]);
                            _config.setProperty("/sim/multiplay/txport", port);
                        } else {
                            var sel = mpServer.selectedIndex
                            var host = _mpServers.serverForIndex(sel);
                            console.log("MP host is " + host)
                            if (host.length > 0) {
                                _config.setProperty("/sim/multiplay/txhost", host);
                            }

                            var port = _mpServers.portForIndex(sel);
                            if (port == 0) {
                                port = defaultMPPort;
                            }

                            _config.setProperty("/sim/multiplay/txport", port);
                        }

                        if (callSign.value.length > 0) {
                            _config.setArg("callsign", callSign.value)
                        }
                    }
                }
            }

            Section {
                id: downloadSettings
                title: qsTr("Downloads")
                width: parent.width
                settingGroup: "downloads"

                function summary()
                {
                    var result = [];
                    if (terrasync.checked) result.push("scenery downloads");
                    return result;
                }

                contents: [
                    SettingCheckbox {
                        id: terrasync
                        label: "Download scenery automatically"
                        description: "FlightGear can automatically download scenery as needed, and check for updates to "
                            + "the scenery. If you disable this option, you will need to download & install scenery "
                            + "using an alternative method."
                        keywords: ["terrasync", "download", "scenery"]
                        option: "terrasync"
                        setting: "terrasync"
                    },


                    SettingPathChooser {
                        id: downloadDir
                        label: qsTr("Download location")
                        description: qsTr("FlightGear stores downloaded files (scenery and aircraft) in this location. "
                                     + "Depending on your settings, it may grow to a considerable size (many gigabytes). "
                                     + "If you change the download location, files will need to be downloaded again.")
                        advanced: true
                        chooseDirectory: true
                        defaultPath: _config.defaultDownloadDir
                        dialogPrompt: qsTr("Choose a location to store download files.")
                        setting: "download-dir"

                        // we disable this UI if the user passes --download-dir when starting the
                        // launcher, otherwise we coudld end up in a complete mess
                        enabled: _config.enableDownloadDirUI

                        keywords: ["download", "storage", "disk"]

                        onPathChanged: {
                            // lots of special work needs to be done immediately that this
                            // value is changed.
                            _launcher.downloadDirChanged(path);
                        }
                    }
                ]

                onApply: {
                    // note we do /not/ apply the downloadDir setting here, since it's
                    // only permitted to occurr once, and we set it via other means;
                    // on startup via runLauncherDialog, and if it changes, via
                    // LauncherMainWindow::downloadDirChanged
                }

                summary: terrasync.checked ? "scenery downloads;" : ""
            }

            Section {
                id: windowSettings
                title: qsTr("View & Window")
                width: parent.width
                settingGroup: "window"

                function summary()
                {
                    var result = [];
                    if (fullscreen.checked) result.push("full-screen");
                    return result;
                }

                contents: [
                    SettingCheckbox {
                        id: fullscreen
                        label: qsTr("Start full-screen")
                        description: qsTr("Start the simulator in full-screen mode.");
                        setting: "fullscreen"
                        option: "fullscreen"
                    },

                    SettingsComboBox {
                        id: windowSize
                        enabled: !fullscreen.checked
                        label: qsTr("Window size")
                        description: qsTr("Select the initial size of the window (this has no effect in full-screen mode).")
                        advanced: true
                        choices: ["640x480", "800x600", "1024x768", "1920x1080", "2560x1600", qsTr("Custom Size") ]
                        defaultIndex: 2
                        readonly property bool isDefault: selectedIndex == defaultIndex
                        readonly property bool isCustom: selectedIndex == 5
                        keywords: ["window", "geometry", "size", "resolution"]
                        setting: "window-size"
                    },

                    SettingLineEdit {
                        id: customWindowSize
                        hidden: !windowSize.isCustom
                        label: qsTr("Custom size")
                        advanced: true
                        description: qsTr("Enter a custom window size in the form 'WWWWW x HHHHH', for example '1280 x 900'")
                        validation: RegExpValidator { regExp: /[\d]{1,7}[\s]*x[\s]*[\d]{1,7}$/ }
                        setting: "custom-size"
                        suggestedWidthString: "0000000 x 0000000"

                    }

                ]

                onApply: {
                    if (windowSize.isCustom) {
                        _config.setArg("geometry", customWindowSize.value);
                    } else if (!windowSize.isDefault) {
                        _config.setArg("geometry", windowSize.choices[windowSize.selectedIndex]);
                    }
                }
            }

            Section {
                id: renderSection
                title: qsTr("Rendering")
                width: parent.width
                settingGroup: "render"

                readonly property bool rembrandt: (renderer.selectedIndex == 2)
                readonly property bool alsEnabled: (renderer.selectedIndex == 1)
                readonly property bool msaaEnabled: !rembrandt && (msaa.selectedIndex > 0)

                function summary()
                {
                    var result = [];
                    if (rembrandt) result.push("Rembrandt");
                    else if (alsEnabled) result.push("ALS");
                    if (msaaEnabled) result.push("anti-aliasing");
                    return result;
                }

                contents: [
                    SettingsComboBox {
                        id: renderer
                        label: qsTr("Renderer")
                        choices: [qsTr("Default"),
                            qsTr("Atmospheric Light Scattering"),
                            qsTr("Rembrandt")]
                        description: descriptions[selectedIndex]
                        defaultIndex: 0
                        setting: "renderer"

                        readonly property var descriptions: [
                            qsTr("The default renderer provides standard visuals with maximum compatibility."),
                            qsTr("The ALS renderer uses a sophisticated physical atmospheric model and several " +
                            "other effects to give realistic rendering of large distances."),
                            qsTr("Rembrandt is a configurable multi-pass renderer which supports shadow-maps, cinematic " +
                            "effects and more. However, not all aircraft appear correctly and performance will " +
                            "depend greatly on your system hardware.")
                        ]

                        keywords: ["als", "rembrandt", "render", "shadow"]
                    },

                    SettingsComboBox {
                        id: msaa
                        label: qsTr("Anti-aliasing")
                        setting: "aa"
                        description: renderSection.rembrandt? qsTr("Anti-aliasing is disabled when Rembrandt is enabled.")
                             : qsTr("Anti-aliasing improves the appearance of high-contrast edges and lines. " +
                            "This is especially noticeable on sloping or diagonal edges. " +
                            "Higher settings can reduce performance.")
                        keywords: ["msaa", "anti", "aliasing", "multi", "sample"]
                        choices: [qsTr("Off"), "2x", "4x"]
                        enabled: !renderSection.rembrandt
                        property var data: [0, 2, 4];
                        defaultIndex: 0
                    }

                ]

                onApply: {
                    if (msaaEnabled) {
                        _config.setProperty("/sim/rendering/multi-sample-buffers", 1)
                        _config.setProperty("/sim/rendering/multi-samples", msaa.data[msaa.selectedIndex])
                    }

                    _config.setEnableDisableOption("rembrandt",  rembrandt);

                    if (alsEnabled) {
                        _config.setProperty("/sim/rendering/shaders/skydome", true);
                    }
                }
            }

            Section {
                id: extraArgsSection
                title: qsTr("Additional Settings")
                settingGroup: "extraArgs"
                width: parent.width
                contents: [
                    SettingExtraArguments {
                        id: extraArgs
                        keywords: ["property", "extra", "command", "argument"]
                        setting: "extra-args"
                    }
                ]
            }
        } // of Column
    } // of Flickable

    Scrollbar {
        id: scrollbar
        anchors.right: parent.right
        height: settingsFlick.height
        flickable: settingsFlick
        visible: settingsFlick.contentHeight > settingsFlick.height
    }
}
