import QtQuick 2.6
import Sailfish.Silica 1.0
import ".."

Page {
    function randomIndices(a, count) {
        var indices = []
        for (var i = 0; i < count - 1; ++i) {
            indices[i] = Math.floor(Math.random() * dataModel.count)
            if (indices[i] === a)
                --i
        }
        indices.splice(Math.floor(Math.random() * (indices.length + 1)), 0, a)
        return indices
    }

    SilicaListView {
        anchors.fill: parent

        model: Data { id: dataModel }

        delegate: BackgroundItem {
            id: item
            height: Theme.itemSizeLarge
            contentHeight: Theme.itemSizeLarge
            width: ListView.view.width

            Row {
                spacing: Theme.paddingMedium

                Image {
                    source: "../../assets/flags/" + flag
                    sourceSize.height: Theme.itemSizeMedium
                }

                Label {
                    anchors.verticalCenter: parent.verticalCenter
                    font.pixelSize: Theme.fontSizeLarge
                    text: name
                    truncationMode: TruncationMode.Fade
                    width: item.width - x - Theme.horizontalPageMargin
                }
            }

            onClicked: pageStack.push(Qt.resolvedUrl("Flag.qml"), { index: index, model: dataModel })
        }

        PullDownMenu {
            MenuItem {
                text: "Quiz me!"
                onClicked: {
                    var index = Math.floor(Math.random() * dataModel.count)
                    var indices = randomIndices(index, 4)
                    pageStack.push(Qt.resolvedUrl("Quiz.qml"), { index: index, indices: indices, model: dataModel })
                }
            }
        }

        VerticalScrollDecorator { }
    }
}