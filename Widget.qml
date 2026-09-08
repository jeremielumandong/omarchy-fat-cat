import QtQuick
import QtQuick.Window
import Quickshell
import qs.Commons
import qs.Ui

BarWidget {
    id: root
    moduleName: "arkane.fat-cat"
    readonly property var service: bar && bar.shell ? bar.shell.serviceFor(moduleName) : null
    property bool opened: false
    property bool popoutSwitchClosing: false
    property int tab: 0
    property string draftFocus: "25"
    property string draftBreak: "5"
    property string draftLong: "15"
    property string draftEvery: "4"
    property bool draftMotion: false
    property bool draftBlocking: true
    property string draftMonitor: ""
    property string saveMessage: ""
    readonly property bool validDurations: validNumber(draftFocus, 180) && validNumber(draftBreak, 180)
        && validNumber(draftLong, 180) && validNumber(draftEvery, 12) && Number(draftEvery) >= 2
    function validNumber(value, max) { return /^\d+$/.test(value) && Number(value) >= 1 && Number(value) <= max; }
    function syncPreferences() { if (service && service.ready) service.setPreferences(settings || {}); }
    function open() {
        if (!service || !service.ready) return;
        draftFocus = String(service.focusMinutes); draftBreak = String(service.breakMinutes);
        draftLong = String(service.longBreakMinutes); draftEvery = String(service.longBreakEvery);
        draftMotion = service.reducedMotion; draftBlocking = service.blockingBreak;
        draftMonitor = service.selectedMonitor; saveMessage = ""; opened = true;
    }
    function close() { opened = false; }
    function closeForPopoutSwitch() {
        popoutSwitchClosing = true; close();
        Qt.callLater(function() { root.popoutSwitchClosing = false; });
    }
    function save() {
        if (!validDurations || !bar || !bar.shell || !service || !service.ready) return;
        var entry = Object.assign({}, settings || {}, {id: moduleName,
            focusMinutes: Number(draftFocus), breakMinutes: Number(draftBreak),
            longBreakMinutes: Number(draftLong), longBreakEvery: Number(draftEvery),
            reducedMotion: draftMotion, blockingBreak: draftBlocking, selectedMonitor: draftMonitor,
            favorites: service.favorites, catNames: service.catNames});
        bar.shell.updateEntryInline(moduleName, entry);
        settings = entry;
        service.setPreferences(entry);
        saveMessage = "Saved · intervals apply to the next session.";
    }
    onSettingsChanged: syncPreferences()
    onServiceChanged: syncPreferences()
    Component.onCompleted: syncPreferences()
    Connections { target: root.service; function onReadyChanged() { root.syncPreferences(); } }
    implicitWidth: button.implicitWidth
    implicitHeight: button.implicitHeight
    WidgetButton {
        id: button
        anchors.fill: parent
        bar: root.bar
        text: root.service && root.service.phase !== "idle"
            ? "󰄛 " + (root.service.paused ? "Ⅱ " : "") + root.service.countdown : "󰄛 Pomodoro"
        labelVisible: true
        onPressed: function(b) {
            if (b === Qt.RightButton) { root.close(); if (root.service && root.service.ready) root.service.showPreview(); }
            else if (root.opened) root.close(); else root.open();
        }
    }
    component Label: Text {
        color: Color.foreground
        font.family: Style.font.family
        font.pixelSize: Style.font.body
        wrapMode: Text.WordWrap
        textFormat: Text.PlainText
    }
    component IntervalField: Row {
        id: interval
        required property string label
        required property string value
        property int maximum: 180
        property int minimum: 1
        property string unit: "min"
        signal edited(string value)
        width: parent.width
        spacing: Style.space(8)
        Label { text: interval.label; width: Math.max(45, parent.width - Style.space(120)); anchors.verticalCenter: parent.verticalCenter }
        Rectangle {
            width: Style.space(65); height: Style.space(34)
            color: "transparent"; radius: Style.cornerRadius
            border.width: 1; border.color: input.activeFocus ? Color.accent : Color.foreground
            TextInput {
                id: input
                anchors.fill: parent; anchors.margins: Style.space(5)
                text: interval.value; color: Color.foreground; selectionColor: Color.accent
                font.family: Style.font.family; font.pixelSize: Style.font.body
                horizontalAlignment: TextInput.AlignHCenter; verticalAlignment: TextInput.AlignVCenter
                selectByMouse: true; activeFocusOnTab: true; maximumLength: 3
                Accessible.name: interval.label
                validator: IntValidator { bottom: interval.minimum; top: interval.maximum }
                onTextEdited: interval.edited(text)
                onActiveFocusChanged: if (activeFocus) Qt.callLater(function() { scroll.ensureVisible(input); })
                Keys.onReturnPressed: root.save()
            }
        }
        Label { text: interval.unit; anchors.verticalCenter: parent.verticalCenter }
    }
    KeyboardPanel {
        id: panel
        anchorItem: button; owner: root; bar: root.bar; open: root.opened
        focusTarget: scroll
        contentWidth: panel.fittedContentWidth(Style.space(390))
        contentHeight: panel.fittedContentHeight(content.implicitHeight, Style.space(730))
        Flickable {
            id: scroll
        Connections {
            target: scroll.Window.window
            function onActiveFocusItemChanged() {
                var item = scroll.Window.window ? scroll.Window.window.activeFocusItem : null;
                for (var ancestor = item; ancestor; ancestor = ancestor.parent) {
                    if (ancestor === content) { Qt.callLater(function() { scroll.ensureVisible(item); }); break; }
                }
            }
        }
            anchors.fill: parent
            contentWidth: width; contentHeight: content.implicitHeight
            clip: true; boundsBehavior: Flickable.StopAtBounds; flickableDirection: Flickable.VerticalFlick
            focus: true
            function ensureVisible(item) {
                var p = item.mapToItem(content, 0, 0);
                if (p.y < contentY) contentY = p.y;
                else if (p.y + item.height > contentY + height) contentY = Math.min(Math.max(0, contentHeight - height), p.y + item.height - height);
            }
            Keys.onEscapePressed: root.close()
            Keys.onPressed: event => {
                if (event.key === Qt.Key_PageDown) { contentY = Math.min(Math.max(0, contentHeight - height), contentY + height * 0.8); event.accepted = true; }
                else if (event.key === Qt.Key_PageUp) { contentY = Math.max(0, contentY - height * 0.8); event.accepted = true; }
            }
            Column {
                id: content
                width: scroll.width
                spacing: Style.space(12)
                Label { width: parent.width; text: "Fat Cat Pomodoro"; font.bold: true; font.pixelSize: Style.font.body * 1.25 }
                Row {
                    spacing: Style.space(8)
                    Button { text: "Timer"; selected: root.tab === 0; focusable: true; onClicked: { root.tab = 0; scroll.contentY = 0; } }
                    Button { text: "Cats"; selected: root.tab === 1; focusable: true; onClicked: { root.tab = 1; scroll.contentY = 0; } }
                }
                Column {
                    visible: root.tab === 0
                    width: parent.width; spacing: Style.space(12)
                    Label {
                        width: parent.width
                        text: !root.service || !root.service.ready ? "Loading your sanctuary…" : root.service.phase === "idle"
                            ? "Ready when you are." : (root.service.paused ? "Paused · " : root.service.phase === "focus" ? "Focus · " : "Break · ") + root.service.countdown
                        font.bold: true
                    }
                    Flow {
                        width: parent.width; spacing: Style.space(6)
                        Button {
                            text: root.service && root.service.phase !== "idle" ? (root.service.paused ? "Resume" : "Pause") : "Start focus"
                            bordered: true; focusable: true; enabled: !!root.service && root.service.ready
                            onClicked: { if (root.service.phase === "idle") root.service.start(); else if (root.service.paused) root.service.resume(); else root.service.pause(); }
                        }
                        Button { text: "Stop"; focusable: true; visible: !!root.service && root.service.phase !== "idle"; onClicked: root.service.stop() }
                        Button { text: "Preview cats"; focusable: true; enabled: !!root.service && root.service.ready; onClicked: { root.close(); root.service.showPreview(); } }
                    }
                    PanelSeparator { width: parent.width }
                    IntervalField { label: "Focus"; value: root.draftFocus; onEdited: value => root.draftFocus = value }
                    IntervalField { label: "Short break"; value: root.draftBreak; onEdited: value => root.draftBreak = value }
                    IntervalField { label: "Long break"; value: root.draftLong; onEdited: value => root.draftLong = value }
                    IntervalField { label: "Long break every"; value: root.draftEvery; minimum: 2; maximum: 12; unit: "sets"; onEdited: value => root.draftEvery = value }
                    Label { width: parent.width; text: "Intervals: 1–180 minutes. Long break every 2–12 focus sessions."; opacity: 0.7; font.pixelSize: Style.font.bodySmall }
                    Flow {
                        width: parent.width; spacing: Style.space(6)
                        Button { text: root.draftBlocking ? "Blocking break: on" : "Blocking break: off"; selected: root.draftBlocking; focusable: true; bordered: true; onClicked: root.draftBlocking = !root.draftBlocking }
                        Button { text: root.draftMotion ? "Reduced motion: on" : "Reduced motion: off"; selected: root.draftMotion; focusable: true; bordered: true; onClicked: root.draftMotion = !root.draftMotion }
                    }
                    Label { width: parent.width; text: root.draftBlocking ? "A blocking break covers your work. You can always dismiss it." : "A gentle reminder lets you keep using your desktop."; opacity: 0.7; font.pixelSize: Style.font.bodySmall }
                    Label { width: parent.width; text: "Show cats on" }
                    Flow {
                        width: parent.width; spacing: Style.space(6)
                        Button { text: "All monitors"; selected: root.draftMonitor === ""; focusable: true; onClicked: root.draftMonitor = "" }
                        Repeater {
                            model: Quickshell.screens
                            Button {
                                required property var modelData
                                text: modelData.name; selected: root.draftMonitor === modelData.name; focusable: true
                                onClicked: root.draftMonitor = modelData.name
                            }
                        }
                    }
                    Label { width: parent.width; visible: root.draftMonitor !== ""; text: "If this monitor is disconnected, cats use the first available monitor."; opacity: 0.7; font.pixelSize: Style.font.bodySmall }
                    Label { width: parent.width; visible: !root.validDurations; text: "Enter valid intervals before saving."; color: Color.accent }
                    Flow {
                        width: parent.width; spacing: Style.space(6)
                        Button { text: "Save settings"; bordered: true; focusable: true; enabled: root.validDurations && !!root.service && root.service.ready; opacity: enabled ? 1 : 0.4; onClicked: root.save() }
                        Button { text: "Close"; focusable: true; onClicked: root.close() }
                    }
                    Label { width: parent.width; visible: root.saveMessage !== ""; text: root.saveMessage; font.pixelSize: Style.font.bodySmall }
                }
                CollectionPanel { visible: root.tab === 1; width: parent.width; service: root.service; onFocusItem: item => scroll.ensureVisible(item) }
                Label { width: parent.width; visible: !!root.service && root.service.persistenceError !== ""; text: root.service ? root.service.persistenceError : ""; color: Color.accent; font.pixelSize: Style.font.bodySmall }
            }
        }
    }
}
