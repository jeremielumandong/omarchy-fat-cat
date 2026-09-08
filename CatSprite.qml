import QtQuick

Item {
    id: root
    property int variant: 0
    property bool walking: false
    property string activity: walking ? "walk" : "loaf"
    property bool facingLeft: false
    property bool reducedMotion: false
    property int frame: 0
    readonly property var activities: ["walk", "stretch", "groom", "yawn", "loaf", "sleep"]
    readonly property int row: Math.max(0, activities.indexOf(activity))
    readonly property var coats: ["orange", "gray", "calico", "tuxedo"]
    implicitWidth: 176
    implicitHeight: 176
    onActivityChanged: frame = 0
    onReducedMotionChanged: frame = 0
    Item {
        anchors.fill: parent
        clip: true
        transform: Scale { origin.x: root.width / 2; xScale: root.facingLeft ? -1 : 1 }
        Image {
            source: Qt.resolvedUrl("assets/cat-" + root.coats[Math.max(0, Math.min(3, root.variant))] + ".png")
            width: root.width * 4
            height: root.height * 6
            x: -root.frame * root.width
            y: -root.row * root.height
            smooth: false
            mipmap: false
            cache: true
            asynchronous: true
        }
    }
    Timer {
        interval: [150, 300, 250, 420, 900, 1300][root.row]
        repeat: true
        running: root.visible && !root.reducedMotion
        onTriggered: root.frame = (root.frame + 1) % 4
    }
}
