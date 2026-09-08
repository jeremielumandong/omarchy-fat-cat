import QtQuick
import Quickshell

ShellRoot {
    Item {
        id: host
        width: 0
        height: 0
        CatPlayground {
            id: playground
            anchors.fill: parent
            active: true
            reducedMotion: true
            availableCats: [0, 1, 2, 3]
        }
    }
    function checkLayout() {
        const cats = playground.children.filter(child => child.objectName.indexOf("playgroundCat") === 0)
                         .sort((a, b) => a.index - b.index);
        if (cats.length !== 4) throw Error("Expected all four cats, got " + cats.length);
        for (let i = 0; i < cats.length; ++i) {
            if (cats[i].x < 0 || cats[i].x + cats[i].width > host.width + 1)
                throw Error("Cat outside resized monitor");
            if (i && cats[i].x - cats[i - 1].x < cats[i - 1].width - 1)
                throw Error("Cats overlap after geometry settles");
        }
        if (cats[3].x < host.width * .65) throw Error("Cats clumped at left edge");
    }
    Timer { interval: 100; running: true; onTriggered: { host.width = 1280; host.height = 720; } }
    Timer {
        interval: 300; running: true
        onTriggered: {
            checkLayout();
            host.width = 400;
            host.height = 300;
        }
    }
    Timer {
        interval: 500; running: true
        onTriggered: {
            checkLayout();
            console.log("PASS: Cats spread after zero-size creation and monitor resize with reduced motion");
            Qt.quit();
        }
    }
}
