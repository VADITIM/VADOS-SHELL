import QtQuick

Scale {
    property bool isMirrored: false
    property real axis: 0

    origin.x: axis
    xScale: isMirrored ? -1 : 1
}
