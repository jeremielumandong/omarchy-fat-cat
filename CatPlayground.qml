import QtQuick
import "CatModel.js" as Cats

Item {
    id: root
    property bool active: false
    property bool reducedMotion: false
    property var availableCats: [0]
    property var favorites: []
    property var catNames: ({})
    readonly property var selection: Cats.choices(availableCats, favorites)
    readonly property int catCount: selection.length
    clip: true

    function restart() {
        for (let i = 0; i < cats.count; ++i) {
            const cat = cats.itemAt(i);
            if (cat) cat.reset();
        }
        movement.lastTick = Date.now();
    }
    // Anchored overlay geometry may arrive after delegates and Component.onCompleted.
    // Coalesce layout changes so every cat is placed using the settled screen size.
    onWidthChanged: Qt.callLater(restart)
    onHeightChanged: Qt.callLater(restart)
    onActiveChanged: if (active) Qt.callLater(restart)
    onSelectionChanged: Qt.callLater(restart)
    Component.onCompleted: Qt.callLater(restart)

    Repeater {
        id: cats
        model: root.selection
        delegate: Item {
            id: cat
            objectName: "playgroundCat" + index
            required property int index
            required property int modelData
            property var motion: Cats.create(modelData, index, root.catCount, maxX, Math.random, width)
            readonly property real maxX: Math.max(0, root.width - width)
            readonly property real groundTop: Math.max(0, root.height * 0.55)
            readonly property real floorY: Math.max(0, root.height - height - 16)
            readonly property real baseY: Math.min(floorY, groundTop) + Math.max(0, floorY - groundTop) * motion.lane
            readonly property string catName: root.catNames[modelData] || ["Mochi", "Miso", "Patches", "Pepper"][modelData]
            width: Math.max(1, Math.min(root.width / Math.max(1, root.catCount), root.height * 0.42,
                                        Math.max(100, Math.min(208, root.width * 0.15))))
            height: width
            visible: root.active
            x: Math.max(0, Math.min(maxX, motion.x))
            y: baseY - (!root.reducedMotion && motion.hop > 0
                       ? Math.sin(Math.PI * (1 - motion.hop / 0.55)) * Math.min(24, baseY) : 0)
            z: baseY
            Accessible.name: catName + ", " + Cats.personalities[modelData].toLowerCase() + " cat"
            Accessible.role: Accessible.Graphic
            function reset() { motion = Cats.create(modelData, index, root.catCount, maxX, Math.random, width); }
            CatSprite {
                anchors.fill: parent
                variant: cat.modelData
                activity: root.reducedMotion ? "loaf" : cat.motion.activity
                facingLeft: cat.motion.direction < 0
                reducedMotion: root.reducedMotion
            }
        }
    }
    Timer {
        id: movement
        property double lastTick: 0
        interval: 33
        repeat: true
        running: root.active && root.visible && !root.reducedMotion
        onRunningChanged: lastTick = Date.now()
        onTriggered: {
            const now = Date.now();
            const dt = Math.max(0, Math.min(0.1, (now - lastTick) / 1000));
            lastTick = now;
            const peers = [];
            for (let i = 0; i < cats.count; ++i) peers.push(cats.itemAt(i).motion);
            for (let i = 0; i < cats.count; ++i) {
                const cat = cats.itemAt(i);
                cat.motion = Cats.advance(cat.motion, dt, cat.maxX, peers, cat.width);
            }
        }
    }
}
