import QtQuick
import qs.Commons

Item {
  id: root

  property real iconSize: Style.font.icon
  property color color: Color.foreground
  property bool active: false

  width: iconSize
  height: iconSize
  implicitWidth: iconSize
  implicitHeight: iconSize

  // Luminance calculation to dynamically choose white or black icon
  readonly property real bgLuminance: {
    var c = Color.background
    return 0.299 * c.r + 0.587 * c.g + 0.114 * c.b
  }

  // Adaptive theme icon: white on dark backgrounds, black on light backgrounds
  readonly property string iconSource: bgLuminance >= 0.5
    ? Qt.resolvedUrl("assets/meta-quest-light.png")
    : Qt.resolvedUrl("assets/meta-quest-dark.png")

  Image {
    id: img
    anchors.fill: parent
    source: root.iconSource
    sourceSize.width: root.iconSize * Screen.devicePixelRatio
    sourceSize.height: root.iconSize * Screen.devicePixelRatio
    fillMode: Image.PreserveAspectFit
    smooth: true
    opacity: root.active ? 1.0 : 0.8
  }

  // Accent ring / dot when streaming
  Rectangle {
    visible: root.active
    width: Math.max(5, root.iconSize * 0.3)
    height: width
    radius: width / 2
    color: Color.accent
    anchors.right: parent.right
    anchors.bottom: parent.bottom
  }
}
