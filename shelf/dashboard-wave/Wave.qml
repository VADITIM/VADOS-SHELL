import QtQuick
import QtQuick.Shapes

Shape {
    id: wave

    property real edge: 0
    property real root: 0
    property real front: 0
    property real ceiling: 0
    property real floor: 0
    property real corner: 0
    property real fillet: 0
    property real crest: 0
    property real ripple: 0
    property real wavelength: 280
    property real phase: 0
    readonly property int segments: 24

    anchors.fill: parent
    visible: front - root > 0.5

    function outline() {
        const span = Math.max(0, front - root)
        const height = Math.max(0, floor - ceiling)
        const radius = Math.min(corner, height / 2, span)
        const flare = Math.max(0, Math.min(fillet, span - radius))
        const run = Math.max(1, span - flare - radius)
        const number = 2 * Math.PI / wavelength
        const points = []
        const lift = (pointX, offset) => {
            const share = Math.max(0, Math.min(1, (pointX - root - flare) / run))
            return ripple * Math.sin(Math.PI * share) * Math.sin(number * (pointX - root) - phase + offset)
        }
        const arc = (centerX, centerY, from, to) => {
            for (let step = 0; step <= segments / 2; step++) {
                const angle = from + (to - from) * step / (segments / 2)
                points.push(Qt.point(centerX + Math.cos(angle) * radius, centerY + Math.sin(angle) * radius))
            }
        }
        const fold = (centerX, centerY, from, to) => {
            for (let step = 0; step <= segments / 3; step++) {
                const angle = from + (to - from) * step / (segments / 3)
                points.push(Qt.point(centerX + Math.cos(angle) * flare, centerY + Math.sin(angle) * flare))
            }
        }

        points.push(Qt.point(edge, ceiling - flare))
        fold(root + flare, ceiling - flare, Math.PI, Math.PI / 2)
        for (let step = 1; step < segments; step++) {
            const pointX = root + flare + run * step / segments
            points.push(Qt.point(pointX, ceiling - lift(pointX, 0)))
        }
        arc(front - radius, ceiling + radius, -Math.PI / 2, 0)
        const side = Math.max(0, height - radius * 2)
        for (let step = 1; step < segments; step++) {
            const share = step / segments
            const pointY = ceiling + radius + side * share
            points.push(Qt.point(front + ripple * 0.4 * Math.sin(number * pointY - phase), pointY))
        }
        arc(front - radius, floor - radius, 0, Math.PI / 2)
        for (let step = segments - 1; step > 0; step--) {
            const pointX = root + flare + run * step / segments
            points.push(Qt.point(pointX, floor + lift(pointX, Math.PI * 0.6)))
        }
        fold(root + flare, floor + flare, -Math.PI / 2, -Math.PI)
        const bulged = points.map(point => {
            const reach = Math.max(0, (point.x - root) / Math.max(1, span))
            const share = Math.max(0, Math.min(1, (point.y - ceiling) / Math.max(1, height)))
            return Qt.point(point.x + crest * Math.sin(Math.PI * share) * reach * reach * reach, point.y)
        })
        bulged.push(Qt.point(edge, floor + flare))
        bulged.push(Qt.point(edge, ceiling - flare))
        return bulged
    }

    ShapePath {
        fillColor: "white"
        strokeColor: "transparent"
        strokeWidth: 0

        PathPolyline {
            path: wave.outline()
        }
    }
}
