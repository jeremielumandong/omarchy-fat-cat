import QtQuick
import Quickshell
ShellRoot {
    Service { id: service; shell: bar.shell; statePath: Qt.resolvedUrl("./test-session.json").toString().replace("file://", "") }
    QtObject {
        id: bar
        property QtObject shell: QtObject {
            property var shellConfig: ({bar: {layout: {left: [], center: [], right: []}}})
            function serviceFor(id) { return service; }
            function updateEntryInline(id, entry) { bar.saved = entry; }
        }
        property var saved: null
        property string position: "top"
        property bool vertical: false
        property int barSize: 30
        property bool foregroundAnimationEnabled: false
        property string fontFamily: "monospace"
        property color barForeground: "white"
        property color urgent: "red"
        property var activePopout: null
        function requestPopout(item) { activePopout = item; }
        function releasePopout(item) { activePopout = null; }
        function hideTooltip(item) {}
        function showTooltip(item, text) {}
    }
    PanelWindow {
        visible: true; implicitWidth: 400; implicitHeight: 400
        Widget { id: widget; bar: bar }
    }
    Timer {
        interval: 700; running: service.ready
        onTriggered: {
            service.start();
            const before = service.secondsLeft;
            widget.open();
            if (!widget.opened || widget.draftFocus !== "25") throw new Error("settings open failed");
            widget.draftFocus = "0";
            if (widget.validDurations) throw new Error("zero duration accepted");
            widget.draftFocus = "40";
            widget.draftEvery = "1";
            if (widget.validDurations) throw new Error("one-session long break accepted");
            widget.draftEvery = "4";
            widget.save();
            if (!bar.saved || bar.saved.focusMinutes !== 40 || bar.saved.longBreakMinutes !== 15) throw new Error("save failed");
            if (service.secondsLeft !== before) throw new Error("save reset active timer");
            service.showPreview();
            if (service.secondsLeft !== before || service.phase !== "focus") throw new Error("preview changed session");
            service.closePreview();
            widget.close();
            if (widget.opened) throw new Error("panel close failed");
            widget.open();
            widget.tab = 1;
            console.log("PASS: Widget creates with native Omarchy controls; settings validation and persistence call; active timer preserved; collection constructs; real Service preview preserves focus");
            exitTimer.start();
        }
    }
    Timer { id: exitTimer; interval: 500; onTriggered: Qt.quit() }
}
