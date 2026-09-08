import QtQuick
import qs.Commons
import qs.Ui

Item {
    id: root
    required property var service
    property alias cardItem: card
    focus: true
    Keys.onEscapePressed: service.dismissOverlay()
    MouseArea { anchors.fill: parent; enabled: root.service.blockInput }
    CatPlayground {
        anchors.fill: parent
        active: root.service.overlayVisible
        reducedMotion: root.service.reducedMotion
        availableCats: root.service.previewing ? [0, 1, 2, 3] : root.service.unlockedCats
        favorites: root.service.previewing ? [] : root.service.favorites
        catNames: root.service.catNames
    }
    Rectangle {
        id: card
        anchors.horizontalCenter: parent.horizontalCenter
        y: Math.max(Style.space(12), root.height * 0.09)
        width: Math.min(Style.space(460), root.width - Style.space(24))
        height: Math.min(root.height - y - Style.space(12), content.implicitHeight + Style.space(36))
        radius: Style.cornerRadius
        color: Color.popups.background
        border.color: Color.popups.border
        Flickable {
            anchors.fill: parent; anchors.margins: Style.space(18)
            contentWidth: width; contentHeight: content.implicitHeight
            clip: true; boundsBehavior: Flickable.StopAtBounds
            Column {
                id: content
                width: parent.width
                spacing: Style.space(12)
                Text {
                    width: parent.width; horizontalAlignment: Text.AlignHCenter
                    text: root.service.previewing ? "MEET YOUR CATS" : "CAT BREAK"
                    color: Color.accent; font.family: Style.font.family; font.pixelSize: Style.font.body
                    font.letterSpacing: 2
                }
                Text {
                    width: parent.width; horizontalAlignment: Text.AlignHCenter
                    text: root.service.displayCountdown
                    color: Color.popups.text; font.family: Style.font.family
                    font.pixelSize: Math.min(Style.space(64), root.height * 0.13); font.bold: true
                    Accessible.name: "Time remaining " + text
                }
                Text {
                    width: parent.width; horizontalAlignment: Text.AlignHCenter; wrapMode: Text.WordWrap
                    text: root.service.previewing ? "A short visit. Your timer keeps its place."
                        : "Stretch your legs. The cats are stretching theirs."
                    color: Color.popups.text; font.family: Style.font.family; font.pixelSize: Style.font.body
                }
                Flow {
                    width: parent.width; spacing: Style.space(8)
                    Button {
                        text: root.service.previewing ? "Close preview" : "Skip break"
                        bordered: true; focusable: true
                        onClicked: root.service.dismissOverlay()
                    }
                    Button {
                        visible: !root.service.previewing
                        text: "Pause timer"; bordered: true; focusable: true
                        onClicked: root.service.pause()
                    }
                }
                Text {
                    width: parent.width; horizontalAlignment: Text.AlignHCenter; wrapMode: Text.WordWrap
                    text: root.service.previewing ? "Preview closes automatically · No progress is earned"
                        : "Esc to skip · Your next focus session starts after this break"
                    color: Color.popups.text; opacity: 0.7; font.family: Style.font.family; font.pixelSize: Style.font.bodySmall
                }
            }
        }
    }
}
