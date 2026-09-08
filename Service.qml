import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Item {
    id: root
    property var shell: null
    property var manifest: null
    property alias statePath: engine.statePath
    readonly property string version: "2.0.0"
    readonly property bool ready: engine.ready
    readonly property string persistenceError: engine.persistenceError
    readonly property string phase: engine.phase
    readonly property bool paused: engine.paused
    readonly property int secondsLeft: engine.secondsLeft
    readonly property string countdown: engine.countdown
    readonly property int focusMinutes: engine.focusMinutes
    readonly property int breakMinutes: engine.breakMinutes
    readonly property int longBreakMinutes: engine.longBreakMinutes
    readonly property int longBreakEvery: engine.longBreakEvery
    readonly property int completedFocus: engine.completedFocus
    readonly property int completedBreaks: engine.completedBreaks
    property bool previewing: false
    property int previewSeconds: 15
    property double previewDeadline: 0
    property bool reducedMotion: false
    property bool blockingBreak: true
    property string selectedMonitor: ""
    property var favorites: []
    property var catNames: ({})
    readonly property var unlockedCats: [0, 1, 2, 3].filter(function(id) { return root.completedBreaks >= [0, 1, 3, 6][id]; })
    readonly property bool overlayVisible: ready && (previewing || (phase === "break" && !paused))
    readonly property bool blockInput: overlayVisible && blockingBreak && !previewing
    readonly property var overlayScreens: {
        const screens = Quickshell.screens;
        if (!selectedMonitor) return screens;
        const matches = screens.filter(function(s) { return s.name === root.selectedMonitor; });
        return matches.length ? matches : screens.slice(0, 1);
    }
    readonly property string displayCountdown: previewing ? "00:" + String(previewSeconds).padStart(2, "0") : countdown
    function catName(id) { return catNames[id] || ["Mochi", "Miso", "Patches", "Pepper"][id] || "Cat"; }
    function isUnlocked(id) { return unlockedCats.indexOf(id) >= 0; }
    function setPreferences(entry) {
        if (!entry || typeof entry !== "object") return;
        if (ready) configureDurations(entry.focusMinutes === undefined ? focusMinutes : entry.focusMinutes,
            entry.breakMinutes === undefined ? breakMinutes : entry.breakMinutes,
            entry.longBreakMinutes === undefined ? longBreakMinutes : entry.longBreakMinutes,
            entry.longBreakEvery === undefined ? longBreakEvery : entry.longBreakEvery);
        reducedMotion = entry.reducedMotion === true;
        blockingBreak = entry.blockingBreak !== false;
        selectedMonitor = typeof entry.selectedMonitor === "string" ? entry.selectedMonitor : "";
        favorites = Array.isArray(entry.favorites) ? entry.favorites.filter(function(id, i, a) { return Number.isInteger(id) && id >= 0 && id < 4 && a.indexOf(id) === i; }) : [];
        const names = {};
        for (let id = 0; id < 4; ++id) {
            const name = entry.catNames && entry.catNames[id];
            if (typeof name === "string") {
                const clean = name.replace(/[\u0000-\u001f\u007f]/g, "").trim().slice(0, 24);
                if (clean) names[id] = clean;
            }
        }
        catNames = names;
    }
    function savedEntry() {
        const config = shell && shell.shellConfig;
        if (!config) return {};
        const layout = config.bar && config.bar.layout || {};
        for (const section of ["left", "center", "right"]) {
            for (const entry of layout[section] || []) if (entry.id === "arkane.fat-cat") return entry;
        }
        for (const entry of config.plugins || []) if (entry.id === "arkane.fat-cat") return entry;
        return {};
    }
    function savePreferences(changes) {
        const entry = Object.assign({}, savedEntry(), changes, {id: "arkane.fat-cat"});
        if (shell) shell.updateEntryInline("arkane.fat-cat", entry);
        setPreferences(entry);
    }
    function renameCat(id, name) {
        if (!isUnlocked(id) || typeof name !== "string") return;
        const clean = name.replace(/[\u0000-\u001f\u007f]/g, "").trim().slice(0, 24);
        if (!clean || clean === catName(id)) return;
        const names = Object.assign({}, catNames); names[id] = clean;
        savePreferences({catNames: names});
    }
    function toggleFavorite(id) {
        if (!isUnlocked(id)) return;
        const next = favorites.slice(); const index = next.indexOf(id);
        if (index < 0) next.push(id); else next.splice(index, 1);
        savePreferences({favorites: next});
    }
    function configureDurations(focus, rest, longRest, every) { engine.configure(focus, rest, longRest, every); }
    function start() { closePreview(); engine.start(); }
    function stop() { closePreview(); engine.stop(); }
    function pause() { closePreview(); engine.pause(); }
    function resume() { closePreview(); engine.resume(); }
    function skipBreak() { closePreview(); engine.skipBreak(); }
    function showPreview() { if (!ready) return; previewSeconds = 15; previewDeadline = Date.now() + 15000; previewing = true; }
    function closePreview() { previewing = false; }
    function dismissOverlay() { if (previewing) closePreview(); else skipBreak(); }
    onPhaseChanged: if (phase === "break") closePreview()
    onReadyChanged: if (ready && shell) setPreferences(savedEntry())
    onShellChanged: if (ready && shell) setPreferences(savedEntry())
    TimerEngine { id: engine }
    Timer {
        interval: 200; repeat: true; running: root.previewing
        onTriggered: {
            root.previewSeconds = Math.max(0, Math.ceil((root.previewDeadline - Date.now()) / 1000));
            if (root.previewSeconds === 0) root.closePreview();
        }
    }
    IpcHandler {
        target: "fat-cat"
        function start(): void { root.start(); }
        function stop(): void { root.stop(); }
        function pause(): void { root.pause(); }
        function resume(): void { root.resume(); }
        function preview(): void { root.showPreview(); }
        function dismiss(): void { root.dismissOverlay(); }
        function configure(focus: string, rest: string): void {
            const f = Number(focus), b = Number(rest);
            if (!Number.isInteger(f) || !Number.isInteger(b) || f < 1 || f > 180 || b < 1 || b > 180) return;
            root.savePreferences({focusMinutes: f, breakMinutes: b});
        }
        function status(): string {
            return JSON.stringify({version: root.version, ready: root.ready, phase: root.phase, paused: root.paused,
                remaining: root.secondsLeft, preview: root.previewing, completedBreaks: root.completedBreaks,
                persistenceError: root.persistenceError});
        }
    }
    Variants {
        model: root.overlayScreens
        PanelWindow {
            id: overlay
            required property var modelData
            screen: modelData
            visible: root.overlayVisible
            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.namespace: "fat-cat-break"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: root.blockInput ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.OnDemand
            color: "transparent"
            mask: Region { item: root.blockInput ? scene : scene.cardItem }
            BreakScene { id: scene; anchors.fill: parent; service: root }
        }
    }
}
