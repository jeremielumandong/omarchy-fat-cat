import QtQuick
import Quickshell
import Quickshell.Io
import "SessionModel.js" as Session

Item {
    id: root
    property string statePath: (Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state") + "/omarchy/fat-cat-session.json"
    property bool fileEnabled: false
    property var session: Session.initial()
    property double now: Date.now()
    property bool ready: false
    property string persistenceError: ""
    readonly property string phase: session.phase
    readonly property bool paused: session.paused
    readonly property int secondsLeft: Session.remaining(session, now)
    readonly property string countdown: Session.format(secondsLeft)
    readonly property int focusMinutes: session.focusMinutes
    readonly property int breakMinutes: session.breakMinutes
    readonly property int longBreakMinutes: session.longBreakMinutes
    readonly property int longBreakEvery: session.longBreakEvery
    readonly property int completedFocus: session.completedFocus
    readonly property int completedBreaks: session.completedBreaks
    signal breakCompleted(int total)

    property bool writeInProgress: false
    property bool writePending: false
    property string lastPayload: ""
    function persist() {
        if (!ready || !fileEnabled) return;
        writePending = true;
        if (!writeInProgress) saveDelay.restart();
    }
    function writeLatest() {
        if (writeInProgress || !writePending) return;
        writePending = false;
        var payload = JSON.stringify(session) + "\n";
        if (payload === lastPayload) return;
        lastPayload = payload;
        writeInProgress = true;
        stateFile.setText(payload);
    }
    function apply(next) {
        if (!ready || next === session) return;
        var previousBreaks = completedBreaks;
        session = next;
        persist();
        if (completedBreaks > previousBreaks) breakCompleted(completedBreaks);
    }
    function initialize(text) {
        if (ready || !fileEnabled) return;
        now = Date.now();
        lastPayload = text;
        session = Session.restore(text, now);
        ready = true;
        // Repair missing/invalid snapshots and persist a single overdue transition.
        persist();
    }
    function start() { now = Date.now(); apply(Session.start(session, now)); }
    function stop() { apply(Session.stop(session)); }
    function pause() { now = Date.now(); apply(Session.pause(session, now)); }
    function resume() { now = Date.now(); apply(Session.resume(session, now)); }
    function skipBreak() { now = Date.now(); apply(Session.skipBreak(session, now)); }
    function configure(focus, rest, longRest, every) { apply(Session.configure(session, focus, rest, longRest, every)); }
    function tick() { if (!ready) return; now = Date.now(); apply(Session.tick(session, now)); }

    Process {
        id: createStateDirectory
        command: ["mkdir", "-p", "--", root.statePath.substring(0, root.statePath.lastIndexOf("/"))]
        onExited: (exitCode) => {
            if (exitCode === 0) root.fileEnabled = true;
            else {
                root.persistenceError = "Session directory could not be created.";
                root.ready = true;
            }
        }
    }
    Component.onCompleted: createStateDirectory.running = true
    FileView {
        id: stateFile
        path: root.fileEnabled ? root.statePath : ""
        preload: true
        atomicWrites: true
        watchChanges: false
        printErrors: false
        onLoaded: root.initialize(text())
        onLoadFailed: root.initialize("")
        onSaveFailed: {
            root.writeInProgress = false;
            root.lastPayload = "";
            root.persistenceError = "Session could not be saved. Check the state directory permissions.";
            if (root.writePending) saveDelay.restart();
        }
        onSaved: {
            root.writeInProgress = false;
            root.persistenceError = "";
            if (root.writePending) saveDelay.restart();
        }
    }
    Timer { id: saveDelay; interval: 25; onTriggered: root.writeLatest() }
    Timer {
        interval: 250
        running: root.ready && root.phase !== "idle" && !root.paused
        repeat: true
        onTriggered: root.tick()
    }
}
