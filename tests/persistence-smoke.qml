import QtQuick
import Quickshell
ShellRoot {
    TimerEngine {
        id: engine
        statePath: Qt.resolvedUrl("./state/session.json").toString().replace("file://", "")
        onReadyChanged: {
            if (!ready) return;
            if (Quickshell.env("FAT_CAT_TEST_STAGE") === "write") {
                configure(40, 8, 20, 3); start(); pause(); resume(); pause();
            } else {
                if (phase !== "focus" || !paused || focusMinutes !== 40 || breakMinutes !== 8 || longBreakMinutes !== 20 || longBreakEvery !== 3 || secondsLeft < 2399)
                    throw new Error("session was not restored across process restart");
                console.log("PASS: paused session and settings restored across process restart");
            }
            finish.start();
        }
    }
    Timer {
        id: finish; interval: 100; repeat: true
        onTriggered: {
            if (engine.persistenceError) throw new Error(engine.persistenceError);
            if (!engine.writeInProgress && !engine.writePending) {
                console.log("PASS: atomic snapshot writes completed");
                Qt.quit();
            }
        }
    }
}
