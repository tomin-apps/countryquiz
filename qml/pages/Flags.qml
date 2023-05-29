import QtQuick 2.6
import Sailfish.Silica 1.0
import ".."

Page {
    id: flagsPage

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

        VerticalScrollDecorator { }
    }
}