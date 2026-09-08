import QtQuick
import Quickshell
import qs.Commons
ShellRoot {
    QtObject {
        id: example
        property bool blockInput: false
        property bool previewing: false
        property bool overlayVisible: true
        property bool reducedMotion: false
        property var unlockedCats: [0,1,2,3]
        property var favorites: []
        property var catNames: ({})
        property string displayCountdown: "05:00"
        function dismissOverlay() { Qt.quit(); }
        function pause() { Qt.quit(); }
    }
    PanelWindow {
        visible: true
        implicitWidth: 1280; implicitHeight: 800
        Item {
            id: capture
            anchors.fill: parent
            Rectangle { anchors.fill: parent; color: Color.background }
            BreakScene { anchors.fill: parent; service: example }
        }
    }
    Timer {
        interval: 1600; running: true
        onTriggered: capture.grabToImage(function(result) {
            if (!result.saveToFile(Quickshell.env("FAT_CAT_PREVIEW_PATH"))) throw new Error("preview save failed");
            console.log("PASS: marketplace preview saved");
            Qt.quit();
        }, Qt.size(1280,800))
    }
}
