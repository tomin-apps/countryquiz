import QtQuick 2.6
import Sailfish.Silica 1.0
import ".."

Page {
    property alias index: view.currentIndex
    property alias model: view.model

    PageHeader { id: header }

    PagedView {
        id: view
        anchors {
            left: parent.left
            top: header.bottom
        }
        height: parent.height / 2
        width: parent.width

        delegate: Column {
            spacing: Theme.paddingLarge
            width: PagedView.contentWidth

            Image {
                anchors.horizontalCenter: parent.horizontalCenter
                source: "../../assets/flags/" + model.flag
                sourceSize.width: parent.width - 2*Theme.horizontalPageMargin
            }

            Label {
                anchors.horizontalCenter: parent.horizontalCenter
                color: Theme.highlightColor
                font.pixelSize: Theme.fontSizeExtraLarge
                horizontalAlignment: Text.AlignHCenter
                text: model.name
                width: parent.width - 2*Theme.horizontalPageMargin
                wrapMode: Text.Wrap
            }
        }
    }
}