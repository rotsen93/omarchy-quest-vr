import QtQuick
import Quickshell.Io

Item {
  Process {
    command: ["/bin/bash", Qt.resolvedUrl("migrate-legacy-terminal.sh").toString().replace(/^file:\/\//, "")]
    running: true
    stderr: StdioCollector {
      onStreamFinished: {
        if (text.trim())
          console.warn("Quest VR Link terminal migration: " + text.trim())
      }
    }
  }
}
