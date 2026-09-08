import QtQuick
import qs.Commons
import qs.Ui

Column {
    id: root
    required property var service
    signal focusItem(var item)
    spacing: Style.space(12)
    component Label: Text {
        color: Color.foreground; font.family: Style.font.family; font.pixelSize: Style.font.body
        wrapMode: Text.WordWrap; textFormat: Text.PlainText
    }
    Label {
        width: parent.width
        text: "Your little sanctuary"
        font.bold: true
    }
    Label {
        width: parent.width
        text: (root.service ? root.service.completedBreaks : 0) + " completed breaks. New friends arrive as you rest. No streaks to lose."
        font.pixelSize: Style.font.bodySmall; opacity: 0.7
    }
    Repeater {
        model: [
            {catId: 0, personality: "Sleepy · expert napper", threshold: 0},
            {catId: 1, personality: "Curious · gentle explorer", threshold: 1},
            {catId: 2, personality: "Playful · little zoomies", threshold: 3},
            {catId: 3, personality: "Shy · quiet company", threshold: 6}
        ]
        delegate: Column {
            id: card
            required property var modelData
            readonly property bool unlocked: !!root.service && root.service.isUnlocked(modelData.catId)
            width: root.width; spacing: Style.space(6)
            PanelSeparator { width: parent.width }
            Row {
                width: parent.width; spacing: Style.space(8)
                CatSprite { width: Style.space(76); height: Style.space(70); variant: card.modelData.catId; activity: "loaf"; reducedMotion: true; opacity: card.unlocked ? 1 : 0.35 }
                Column {
                    width: Math.max(30, parent.width - Style.space(84)); spacing: Style.space(5)
                    Label { width: parent.width; text: root.service ? root.service.catName(card.modelData.catId) : "Cat"; font.bold: true }
                    Label { width: parent.width; text: card.modelData.personality; font.pixelSize: Style.font.bodySmall; opacity: 0.7 }
                    Label { width: parent.width; visible: !card.unlocked; text: "Arrives after " + card.modelData.threshold + " completed breaks"; font.pixelSize: Style.font.bodySmall }
                }
            }
            Flow {
                width: parent.width; spacing: Style.space(6); visible: card.unlocked
                Rectangle {
                    width: Math.min(Style.space(145), root.width); height: Style.space(34)
                    color: "transparent"; radius: Style.cornerRadius
                    border.width: 1; border.color: nameInput.activeFocus ? Color.accent : Color.foreground
                    TextInput {
                        id: nameInput
                        anchors.fill: parent; anchors.margins: Style.space(6)
                        text: root.service ? root.service.catName(card.modelData.catId) : ""
                        color: Color.foreground; selectionColor: Color.accent
                        font.family: Style.font.family; font.pixelSize: Style.font.body
                        verticalAlignment: TextInput.AlignVCenter
                        activeFocusOnTab: true; selectByMouse: true; maximumLength: 24; clip: true
                        Accessible.name: "Name for " + (root.service ? root.service.catName(card.modelData.catId) : "cat")
                        onEditingFinished: if (root.service) root.service.renameCat(card.modelData.catId, text)
                        onActiveFocusChanged: if (activeFocus) Qt.callLater(function() { root.focusItem(nameInput); })
                        Keys.onReturnPressed: { root.service.renameCat(card.modelData.catId, text); focus = false; }
                    }
                }
                Button {
                    text: root.service && root.service.favorites.indexOf(card.modelData.catId) >= 0 ? "★ Favorite" : "☆ Favorite"
                    selected: !!root.service && root.service.favorites.indexOf(card.modelData.catId) >= 0
                    focusable: true; bordered: true
                    onClicked: root.service.toggleFavorite(card.modelData.catId)
                }
            }
        }
    }
    Label { width: parent.width; text: "Favorites visit during breaks. Leave favorites empty for visits from any unlocked cat. Names save when you leave the field."; font.pixelSize: Style.font.bodySmall; opacity: 0.7 }
}
