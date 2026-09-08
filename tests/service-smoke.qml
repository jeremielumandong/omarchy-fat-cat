import QtQuick
import Quickshell
ShellRoot {
    id: root
    property string stage: Quickshell.env("FAT_CAT_TEST_STAGE")
    property string expectedPhase: stage === "break" ? "break" : "focus"
    property int before: 0
    QtObject {
        id: host
        property var shellConfig: ({bar: {layout: {right: [{id: "arkane.fat-cat", reducedMotion: true, blockingBreak: false, selectedMonitor: "missing-monitor", customSetting: "preserve"}]}}})
        function updateEntryInline(id, entry) {
            shellConfig = {bar: {layout: {right: [entry]}}};
        }
    }
    Service {
        id: service
        shell: host
        statePath: Qt.resolvedUrl("./state.json").toString().replace("file://", "")
    }
    function check(condition, reason) { if (!condition) throw new Error(reason); }
    Timer {
        interval: 200; running: service.ready
        onTriggered: {
            check(service.phase === root.expectedPhase, "restored phase lost");
            check(service.paused === (root.stage === "paused"), "restored pause lost");
            check(service.focusMinutes === 42 && service.breakMinutes === 7, "absent preferences overwrite restored intervals");
            root.before = service.secondsLeft;
            service.showPreview();
            check(service.previewing && !service.blockInput, "preview blocks input");
            check(service.phase === root.expectedPhase && service.secondsLeft === root.before, "preview changed active timer");
            check(service.completedBreaks === 1 && service.unlockedCats.length === 2, "preview awarded progress");
            service.dismissOverlay();
            check(service.phase === root.expectedPhase && !service.previewing, "dismissing preview skips real break");
            service.renameCat(0, "  Toast\n  ");
            service.toggleFavorite(1);
            check(service.catName(0) === "Toast" && service.favorites[0] === 1, "name/favorite update failed");
            check(service.reducedMotion && !service.blockingBreak && service.selectedMonitor === "missing-monitor", "collection edit reset visual preferences");
            check(host.shellConfig.bar.layout.right[0].customSetting === "preserve", "collection edit dropped unknown setting");
            check(service.focusMinutes === 42 && service.breakMinutes === 7, "collection edit reset intervals");
            check(service.overlayScreens.length === Math.min(1, Quickshell.screens.length), "missing monitor fallback failed");
            service.renameCat(3, "Locked"); service.toggleFavorite(3);
            check(service.catName(3) !== "Locked" && service.favorites.indexOf(3) < 0, "locked cat edited");
            service.showPreview(); service.previewDeadline = Date.now() - 1;
            finish.start();
        }
    }
    Timer {
        id: finish; interval: 500
        onTriggered: {
            check(!service.previewing, "preview did not expire");
            check(service.phase === root.expectedPhase && service.paused === (root.stage === "paused"), "preview expiry mutated session");
            check(service.completedBreaks === 1 && service.unlockedCats.length === 2, "preview expiry awarded progress");
            check(!service.persistenceError, "save failed");
            console.log("PASS: safe preview, restored preferences, collection merge, and monitor fallback", root.stage);
            Qt.quit();
        }
    }
}
