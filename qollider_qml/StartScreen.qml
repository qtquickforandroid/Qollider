import QtQuick

Rectangle {
    id: startScreen

    property bool handInZone: false
    property real holdProgress: 0.0
    property real zoneVisualRadius: 0.12
    property string moveDiff: ""
    property bool handDetected: false

    anchors.fill: parent
    color: Qt.rgba(0, 0, 0, 0.85)

    readonly property var liveHand: {
        if (!handDetected || moveDiff.length === 0) return null
        let p = moveDiff.split(",")
        if (p.length < 4) return null
        let wx = 1.0 - parseFloat(p[0])
        let wy = 1.0 - parseFloat(p[1])
        let dwx = parseFloat(p[2]) - parseFloat(p[0])
        let dwy = parseFloat(p[3]) - parseFloat(p[1])
        return {wx, wy, handSize: Math.sqrt(dwx * dwx + dwy * dwy)}
    }

    // Faint ghost at the ideal hand placement position
    Image {
        source: "ui_assets/black-hand.svg"
        width: parent.width * 0.2
        height: width * (869.7 / 846.1)
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        opacity: 0.12
    }

    // Ghost hand that tracks the user's hand position
    Image {
        id: trackingGhost
        source: "ui_assets/black-hand.svg"
        visible: startScreen.handDetected && startScreen.liveHand !== null

        // Derive image size from the wrist-to-middle-finger viewport distance
        property real palmLen: startScreen.liveHand
            ? startScreen.liveHand.handSize * parent.height
            : 0
        height: palmLen > 10 ? palmLen / 0.72 : 0
        width: height * (846.1 / 869.7)

        // Align the wrist point (~85% from top of image) to the tracked wrist
        x: startScreen.liveHand ? startScreen.liveHand.wx * parent.width  - width  * 0.50 : 0
        y: startScreen.liveHand ? startScreen.liveHand.wy * parent.height - height * 0.85 : 0

        opacity: startScreen.handInZone ? 0.72 : 0.46
        Behavior on opacity { NumberAnimation { duration: 150 } }
    }

    // Monitoring circle
    Item {
        anchors.centerIn: parent
        width: parent.width * startScreen.zoneVisualRadius * 2.0
        height: width

        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: "transparent"
            border.color: startScreen.handInZone
                ? Qt.rgba(0.502, 0.784, 0.831, 1)
                : Qt.rgba(0.227, 0.251, 0.314, 1)
            border.width: 4
        }

        Rectangle {
            anchors.centerIn: parent
            width: parent.width * startScreen.holdProgress
            height: parent.height * startScreen.holdProgress
            radius: width / 2
            color: Qt.rgba(0.2, 0.6, 0.7, 0.25)
        }
    }

    // Depth / distance guide — right edge
    Column {
        anchors.right: parent.right
        anchors.rightMargin: 30
        anchors.verticalCenterOffset: 1
        anchors.verticalCenter: parent.verticalCenter
        spacing: 25


        readonly property real hs: startScreen.liveHand ? startScreen.liveHand.handSize : 0
        readonly property bool tooClose: hs > 0.30
        readonly property bool tooFar:   hs > 0.001 && hs < 0.08
        width: 175

        Text {
            text: "Step\nback"
            color: parent.tooClose ? Qt.rgba(1.0, 0.75, 0.30, 0.9) : Qt.rgba(0.35, 0.40, 0.50, 0.40)
            font.pointSize: 40
            font.family: "monospace"
        }

        Text {
            text: "Come\ncloser"
            color: parent.tooFar ? Qt.rgba(1.0, 0.75, 0.30, 0.9) : Qt.rgba(0.35, 0.40, 0.50, 0.40)
            font.pointSize: 40
            font.family: "monospace"
        }
    }
}
