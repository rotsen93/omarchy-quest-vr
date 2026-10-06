import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

Panel {
  id: root
  moduleName: "quest-vr-link"
  ipcTarget: "quest-vr-link"

  property string connectionMode: "auto"
  property string transport: "none"
  property bool questUsb: false
  property bool questWifi: false
  property bool streaming: false
  property bool ultrawide: false
  property bool gnirehtetActive: false
  property string batteryLevel: "--"

  readonly property string icon: "󰄛"
  readonly property color statusColor: streaming ? Color.accent : (transport !== "none" ? Color.accent : root.bar.foreground)

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
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        try {
          var raw = String(text || "").trim()
          if (!raw) return
          var data = JSON.parse(raw)
          root.connectionMode = data.mode
          root.transport = data.transport
          root.questUsb = data.quest_usb
          root.questWifi = data.quest_wifi
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

  function runAction(action, param) {
    var cmd = [Qt.resolvedUrl("quest_ctl").toString().replace(/^file:\/\//, ""), action]
    if (param !== undefined) cmd.push(param)
    actionProc.command = cmd
    actionProc.running = true
    Qt.callLater(function() { statusProc.running = true })
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    active: root.streaming
    useActiveColor: true
    activeColor: Color.accent
    iconComponent: Component {
      Item {
        QuestIcon {
          anchors.centerIn: parent
          iconSize: Style.bar.iconCanvas
          color: root.statusColor
          active: root.streaming
        }
      }
    }
    tooltipText: root.streaming ? "Quest 3: Transmitiendo (" + root.batteryLevel + "% · " + root.transport + ")" : (root.transport !== "none" ? "Quest 3 conectado (" + root.batteryLevel + "% · " + root.transport + ")" : "Quest 3 desconectado")
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
    contentWidth: panel.fittedContentWidth(Style.space(330))
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

          QuestIcon {
            iconSize: Style.font.display
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
              text: root.streaming ? "Transmitiendo en vivo (" + root.transport + ")" : (root.transport !== "none" ? "Conectado (" + root.transport + ")" : "No detectado")
              font.pixelSize: Style.font.caption
              color: root.streaming ? Color.accent : (root.transport !== "none" ? Color.accent : Color.muted)
            }
          }
        }

        PanelSeparator { foreground: root.bar.foreground }

        // Telemetry: Battery & Active Link
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
                text: "Enlace Activo"
                font.pixelSize: Style.font.caption
                color: Color.muted
                anchors.horizontalCenter: parent.horizontalCenter
              }
              Text {
                text: root.transport === "cable" ? "Cable USB" : (root.transport === "wifi" ? "Wi-Fi LAN" : "Ninguno")
                font.pixelSize: Style.font.body
                font.weight: Font.Bold
                color: root.transport !== "none" ? Color.accent : Color.urgent
                anchors.horizontalCenter: parent.horizontalCenter
              }
            }
          }
        }

        PanelSeparator { foreground: root.bar.foreground }

        // Mode Switcher (Auto / Cable / Wi-Fi)
        Column {
          width: parent.width
          spacing: Style.space(6)

          Text {
            text: "Modo de conexión:"
            font.pixelSize: Style.font.caption
            color: Color.muted
          }

          Row {
            width: parent.width
            spacing: Style.space(6)

            Button {
              width: (parent.width - Style.space(12)) / 3
              bordered: true
              selected: root.connectionMode === "auto"
              text: "Auto"
              onClicked: root.runAction("set_mode", "auto")
            }

            Button {
              width: (parent.width - Style.space(12)) / 3
              bordered: true
              selected: root.connectionMode === "cable"
              text: "Cable"
              onClicked: root.runAction("set_mode", "cable")
            }

            Button {
              width: (parent.width - Style.space(12)) / 3
              bordered: true
              selected: root.connectionMode === "wifi"
              text: "Wi-Fi"
              onClicked: root.runAction("set_mode", "wifi")
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
            enabled: root.questUsb
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
            enabled: root.questUsb
            text: "  󰖟   Abrir Spatial HUD"
            onClicked: {
              root.runAction("launch_hud")
              root.close()
            }
          }

          Button {
            width: parent.width
            leftAlign: true
            bordered: true
            enabled: root.questUsb
            text: "  󰁝   Instalar Apps en el Visor"
            onClicked: {
              root.runAction("install_headset")
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
