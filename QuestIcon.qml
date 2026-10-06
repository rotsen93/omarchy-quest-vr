import QtQuick
import qs.Commons

Item {
  id: root

  property real iconSize: Style.font.icon
  property color color: Color.foreground

  width: iconSize
  height: iconSize
  implicitWidth: iconSize
  implicitHeight: iconSize

  Image {
    id: img
    anchors.fill: parent
    source: Qt.resolvedUrl("assets/meta-quest.svg")
    sourceSize.width: root.iconSize * 2
    sourceSize.height: root.iconSize * 2
    fillMode: Image.PreserveAspectFit
    smooth: true
    asynchronous: true
  }
}
