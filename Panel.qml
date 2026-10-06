import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

Panel {
  id: root
  moduleName: "makiaveloh.quest-vr"
  ipcTarget: "makiaveloh.quest-vr"

  property bool questConnected: false
  property bool streaming: false
  property bool ultrawide: false
  property bool gnirehtetActive: false
  property string batteryLevel: "--"

  readonly property string icon: "󰄛"
  readonly property color statusColor: streaming ? Color.accent : (questConnected ? Color.accent : root.bar.foreground)

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  Timer {
    interval: 3500
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: statusProc.running = true
  }

  Process {
    id: statusProc
    command: [Qt.resolvedUrl("quest_ctl").toString().replace(/^file:\/\//, ""), "status"]
    stdout: SplitParser {
      onRead: function(line) {
        try {
          var data = JSON.parse(line.trim())
          root.questConnected = data.quest_connected
          root.streaming = data.streaming
          root.ultrawide = data.ultrawide
          root.gnirehtetActive = data.gnirehtet
          root.batteryLevel = data.battery
        } catch(e) {}
      }
    }
  }

  Process {
    id: actionProc
  }

  function runAction(action) {
    actionProc.command = [Qt.resolvedUrl("quest_ctl").toString().replace(/^file:\/\//, ""), action]
    actionProc.running = true
    Qt.callLater(function() { statusProc.running = true })
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.icon
    active: root.streaming
    useActiveColor: true
    activeColor: Color.accent
    tooltipText: root.streaming ? "Quest 3: Transmitiendo (" + root.batteryLevel + "%)" : (root.questConnected ? "Quest 3 conectado (" + root.batteryLevel + "%)" : "Quest 3 desconectado")
    onPressed: function(b) {
      if (b === Qt.RightButton) {
        root.runAction("toggle_ultrawide")
      } else {
        root.toggle()
      }
    }
  }

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(320))
    contentHeight: panel.fittedContentHeight(contentColumn.implicitHeight)

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }

      Column {
        id: contentColumn
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: Style.space(12)

        // Header
        Row {
          spacing: Style.space(12)
          width: parent.width

          Text {
            text: root.icon
            font.pixelSize: Style.font.display
            color: root.statusColor
            anchors.verticalCenter: parent.verticalCenter
          }

          Column {
            spacing: Style.space(2)
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - Style.space(48)

            Text {
              text: "Meta Quest 3"
              font.pixelSize: Style.font.title
              font.weight: Font.Bold
              color: root.bar.foreground
            }

            Text {
              text: root.streaming ? "Transmitiendo en vivo" : (root.questConnected ? "Conectado vía USB" : "No detectado")
              font.pixelSize: Style.font.caption
              color: root.streaming ? Color.accent : (root.questConnected ? Color.accent : Color.muted)
            }
          }
        }

        PanelSeparator { foreground: root.bar.foreground }

        // Telemetry cards
        Row {
          width: parent.width
          spacing: Style.space(10)

          Rectangle {
            width: (parent.width - Style.space(10)) / 2
            height: Style.space(52)
            radius: Style.cornerRadius
            color: Qt.rgba(255, 255, 255, 0.05)
            border.width: 1
            border.color: Qt.rgba(255, 255, 255, 0.1)

            Column {
              anchors.centerIn: parent
              spacing: Style.space(2)

              Text {
                text: "Batería Visor"
                font.pixelSize: Style.font.caption
                color: Color.muted
                anchors.horizontalCenter: parent.horizontalCenter
              }
              Text {
                text: root.batteryLevel + "%"
                font.pixelSize: Style.font.body
                font.weight: Font.Bold
                color: root.batteryLevel !== "--" ? Color.accent : Color.muted
                anchors.horizontalCenter: parent.horizontalCenter
              }
            }
          }

          Rectangle {
            width: (parent.width - Style.space(10)) / 2
            height: Style.space(52)
            radius: Style.cornerRadius
            color: Qt.rgba(255, 255, 255, 0.05)
            border.width: 1
            border.color: Qt.rgba(255, 255, 255, 0.1)

            Column {
              anchors.centerIn: parent
              spacing: Style.space(2)

              Text {
                text: "Túnel USB"
                font.pixelSize: Style.font.caption
                color: Color.muted
                anchors.horizontalCenter: parent.horizontalCenter
              }
              Text {
                text: root.gnirehtetActive ? "10.0.2.2 OK" : "Inactivo"
                font.pixelSize: Style.font.body
                font.weight: Font.Bold
                color: root.gnirehtetActive ? Color.accent : Color.urgent
                anchors.horizontalCenter: parent.horizontalCenter
              }
            }
          }
        }

        PanelSeparator { foreground: root.bar.foreground }

        // Action Buttons
        Column {
          width: parent.width
          spacing: Style.space(8)

          Button {
            width: parent.width
            leftAlign: true
            bordered: true
            text: root.ultrawide ? "  󰍹   Volver a Pantalla 16:9" : "  󰍺   Activar Ultrawide 32:9"
            onClicked: {
              root.runAction("toggle_ultrawide")
              root.close()
            }
          }

          Button {
            width: parent.width
            leftAlign: true
            bordered: true
            enabled: root.questConnected
            text: "  󰢹   Lanzar Moonlight XR"
            onClicked: {
              root.runAction("launch_moonlight")
              root.close()
            }
          }

          Button {
            width: parent.width
            leftAlign: true
            bordered: true
            enabled: root.questConnected
            text: "  󰖟   Abrir Spatial HUD (10.0.2.2:9090)"
            onClicked: {
              root.runAction("launch_hud")
              root.close()
            }
          }

          Button {
            width: parent.width
            leftAlign: true
            bordered: true
            text: "  󰑐   Reiniciar Sunshine"
            onClicked: {
              root.runAction("restart_sunshine")
              root.close()
            }
          }
        }
      }
    }
  }
}
