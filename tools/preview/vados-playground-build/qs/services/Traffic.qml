pragma Singleton
import QtQuick
QtObject {
    property bool isActive: false
    property real download: 8.2e6
    property real upload: 0.9e6
    property var downloads: Array.from({ length: 60 }, (_, index) => 7e6 + Math.sin(index / 4) * 1.2e6 + Math.random() * 6e5)
    property var uploads: Array.from({ length: 60 }, (_, index) => 6e5 + Math.random() * 5e5)
    property int samples: 0
    property real ping: 53
    property real jitter: 19
    property bool hasPing: true
    property Timer drift: Timer {
        interval: 1000; running: true; repeat: true
        onTriggered: {
            download = Math.max(2e5, download + (Math.random() - 0.5) * 2e6)
            upload = Math.max(1e5, upload + (Math.random() - 0.5) * 3e5)
            downloads = downloads.concat([download]).slice(-60)
            uploads = uploads.concat([upload]).slice(-60)
            samples++
        }
    }
}
