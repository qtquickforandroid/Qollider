// Copyright (C) 2022 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR BSD-3-Clause

import QtQuick
import QtQuick3D
import QtQuick3D.Physics

Item {
    id: root
    anchors.fill: parent

    // --- Hand Tracking Inputs ---
    property string moveDiff : ""
    property string handRotation : "0,0,0"
    readonly property var parsedRotation: {
        var p = handRotation.split(",")
        return p.length === 3 ? [parseFloat(p[0]), parseFloat(p[1]), parseFloat(p[2])] : [0.0, 0.0, 0.0]
    }

    property bool inMenu: true

    property bool gameStarted: false

    // --- High Scores ---
    property string saveScoreRequest: ""
    property string highScoreData: ""

    property bool startHandDetected: false
    property bool gameOver: false
    property real holdProgress: 0.0
    property bool handInZone: false

    property int score: 0
    property int lives: 3
    property bool ballLostThisRound: false
    property bool racketHitActive: false
    property int stuckTicks: 0

    readonly property real zoneX: 0.5
    readonly property real zoneY: 0.5
    readonly property real zoneRadius: 0.30
    readonly property real zoneVisualRadius: 0.12

    readonly property vector3d ballOrigin: Qt.vector3d(0, 0, 300)

    // --- Physics Tuning ---
    property real wallRestitution: 1
    property real ballRestitution: 1
    property real ballLaunchForce: 300000
    property real racketHitForce: 30000
    property real arenaHeight: 600
    property real arenaWidth: 750
    property real ballSpeedMultiplier: 1.0
    property real speedBoostPerHit: 0.07
    property real arenaDepth: 200
    // Racket mesh height in world units — used to normalise hand-size → racket scale
    readonly property real racketWorldHeight: 145.0
    // 312 ticks × 16ms ≈ 5 seconds before a stuck ball is reset
    readonly property int stuckBallTimeoutTicks: 312

    function resetBall() {
        // Set guard before teleporting so any queued frontWall contact events are
        // blocked until resetGuardTimer clears it 200ms later.
        root.ballLostThisRound = true
        root.racketHitActive = false
        root.stuckTicks = 0
        ball.reset(root.ballOrigin, Qt.quaternion(1, 0, 0, 0))
        ballLauncher.restart()
        resetGuardTimer.restart()
    }

    function handleBallMissed() {
        if (root.ballLostThisRound) return
        root.ballSpeedMultiplier = 1.0
        root.lives--
        if (root.lives <= 0) root.gameOver = true
        else root.resetBall()
    }

    // --- Hand Position → Racket Movement ---
    readonly property real scaleAlpha: 0.45

    Timer {
        id: resetGuardTimer
        interval: 200
        repeat: false
        onTriggered: root.ballLostThisRound = false
    }

    Timer {
        id: holdTimer
        interval: 50
        running: !root.inMenu && !root.gameStarted && root.handInZone
        repeat: true
        onTriggered: {
            root.holdProgress = Math.min(1.0, root.holdProgress + 0.05 / 3.0)
            if (root.holdProgress >= 1.0) root.gameStarted = true
        }
    }

    Timer {
        id: fingerRecognizer
        interval: 500
        running: !root.inMenu && !root.gameStarted
        repeat: true
        onTriggered: { root.handInZone = false; root.holdProgress = 0.0; root.startHandDetected = false }
    }

    onHandInZoneChanged: { if (!handInZone) holdProgress = 0.0 }

    onMoveDiffChanged: {
        fingerRecognizer.restart()

        let parts = moveDiff.split(",")
        if (parts.length < 4) return
        if (!root.gameStarted) root.startHandDetected = true

        let wristX  = 1.0 - parseFloat(parts[0])
        let wristY  = 1.0 - parseFloat(parts[1])
        let middleX = 1.0 - parseFloat(parts[2])
        let middleY = 1.0 - parseFloat(parts[3])

        if (!root.gameStarted) {
            let ddx = wristX - zoneX
            let ddy = wristY - zoneY
            root.handInZone = Math.sqrt(ddx * ddx + ddy * ddy) <= zoneRadius
        }

        if (!root.gameStarted || root.gameOver) return

        let currentVpPos = camera.mapToViewport(rack.kinematicPosition)
        let wrist3D  = camera.mapFromViewport(Qt.vector3d(wristX,  wristY,  currentVpPos.z))
        let middle3D = camera.mapFromViewport(Qt.vector3d(middleX, middleY, currentVpPos.z))

        rack.kinematicPosition = Qt.vector3d(wrist3D.x, wrist3D.y, rack.kinematicPosition.z)

        let handHeight = Math.sqrt(
            Math.pow(middle3D.x - wrist3D.x, 2) +
            Math.pow(middle3D.y - wrist3D.y, 2)
        )
        let targetScale = handHeight / racketWorldHeight
        rack.racketScaleY = rack.racketScaleY + scaleAlpha * (targetScale - rack.racketScaleY)
    }

    // --- Physics World ---
    PhysicsWorld {
        scene: viewport.scene
        gravity: Qt.vector3d(0, 0, -25)
        running: !root.gameOver
    }

    View3D {
        id: viewport
        anchors.fill: parent

        environment: SceneEnvironment {
            backgroundMode: SceneEnvironment.SkyBox
            lightProbe: Texture {
                source: "skybox_assets/maps/Scene_-_Root_diffuse.jpeg"
                generateMipmaps: true
                mipFilter: Texture.Linear
            }
            probeExposure: 3.0
        }

        // --- HUD ---
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 16
            text: root.score.toString().padStart(3, "0")
            color: Qt.rgba(0.816, 0.847, 0.910, 1)
            font.pointSize: 48
            font.bold: true
            font.family: "monospace"
            style: Text.Outline
            styleColor: Qt.rgba(0.102, 0.110, 0.133, 1)
        }
        Row {
        // ---  lives/attempt counter ---
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.margins: 30
            anchors.topMargin: 50
            anchors.leftMargin: 150
            spacing: 15
            Repeater {
                model: 3
                Item {
                    width: 60; height: 60
                    Rectangle {
                        anchors.centerIn: parent
                        width: 36; height: 36; radius: 18
                        color: Qt.rgba(0, 0.05, 0, 0.3)
                        scale: 1.4
                    }
                    Rectangle {
                        anchors.centerIn: parent
                        width: 28; height: 28; radius: 14
                        color: index < root.lives ? Qt.rgba(0.478, 0.502, 0.533, 1) : Qt.rgba(0, 0, 0, 0)
                        border.color: index < root.lives ? Qt.rgba(0, 0.05, 0, 0.3) : Qt.rgba(0.314, 0.376, 0.627, 1)
                        border.width: 3
                        // top highlight shimmer — only on active lives
                        Rectangle {
                            visible: index < root.lives
                            x: 6; y: 4
                            width: 7; height: 5; radius: 3
                            color: Qt.rgba(0, 0.02, 0, 0.1)
                        }
                    }
                }
            }
        }

        // --- Camera ---
        PerspectiveCamera {
            id: camera
            position: Qt.vector3d(0, 0, 1200)
            eulerRotation: Qt.vector3d(0, 0, 0)
            clipFar: 100000
            clipNear: 10
            fieldOfView: 60
        }

        // --- Lighting ---
        Repeater3D {
            model: 5
            PointLight {
                position.z: 800 - (index * 700)
                color: Qt.rgba(0.85, 0.9, 1.0, 1.0)
                constantFade: 0.2
                brightness: 5
                shadowFactor: 50
            }
        }

        PointLight {
            position.z: 1800
            color: Qt.rgba(0.9, 0.95, 1.0, 1.0)
            constantFade: 0.01
            castsShadow: true
            brightness: 8
        }

        DirectionalLight {
            eulerRotation: Qt.vector3d(-20, 0, 0)
            color: Qt.rgba(1.0, 0.98, 0.95, 1.0)
            brightness: 2.5
        }

        PointLight {
            position: Qt.vector3d(0, 200, 900)
            color: Qt.rgba(0.95, 0.97, 1.0, 1.0)
            constantFade: 0.005
            brightness: 12
        }

        // --- Arena ---
        ArenaWalls {
            x: 0
            y: 0
            z: 0
            wallRestitution: root.wallRestitution
            arenaWidth: root.arenaWidth
            arenaHeight: root.arenaHeight
            arenaDepth: root.arenaDepth
            onBallMissed: { root.handleBallMissed() }
        }

        // --- Racket ---
        RacketBody {
            id: rack
            ballBody: ball
            position: Qt.vector3d(0, 0, 600)
            kinematicPosition: Qt.vector3d(0, 0, 600)
            physicsMaterial.restitution: root.ballRestitution

            pitch: root.parsedRotation[0]
            yaw:   root.parsedRotation[1]
            roll:  root.parsedRotation[2]

            onBallHit: {
                if (root.racketHitActive) return
                root.racketHitActive = true

                let pitchRad = rack.pitch * Math.PI / 180
                let yawRad   = rack.yaw   * Math.PI / 180

                let nx = -Math.cos(pitchRad) * Math.sin(yawRad)
                let ny =  Math.sin(pitchRad)
                let nz = -Math.cos(pitchRad) * Math.cos(yawRad)

                root.score++
                if (root.score % 5 === 0) root.ballSpeedMultiplier += root.speedBoostPerHit
                let speed = racketHitForce + root.ballLaunchForce * root.ballSpeedMultiplier
                ball.applyCentralImpulse(Qt.vector3d(nx * speed, ny * speed, nz * speed))
            }
        }

        // --- Ball ---
        Timer {
            id: ballLauncher
            interval: 2000
            running: root.gameStarted && !root.gameOver
            repeat: false
            onTriggered: ball.applyCentralImpulse(Qt.vector3d(0, 0, root.ballLaunchForce *
                                                                    root.ballSpeedMultiplier))
        }

        // Fallback: catch tunnelling + ball stuck between side/top/bottom walls
        Timer {
            interval: 16
            running: root.gameStarted && !root.gameOver
            repeat: true
            onTriggered: {
                let z = ball.position.z
                if (z > 650) {
                    root.stuckTicks = 0
                    root.handleBallMissed()
                } else if (z > 250) {
                    root.stuckTicks = 0
                } else {
                    root.stuckTicks++
                    if (root.stuckTicks > root.stuckBallTimeoutTicks)
                        root.resetBall()
                }
                // Reset hit guard once ball has bounced well clear of racket
                if (root.racketHitActive && z < 500)
                    root.racketHitActive = false
            }
        }

        GlowBall {
            id: ball
            position: root.ballOrigin
            physicsMaterial.restitution: root.ballRestitution
        }
    }

    // --- Start Screen ---
    StartScreen {
        visible: !root.inMenu && !root.gameStarted
        handInZone: root.handInZone
        holdProgress: root.holdProgress
        zoneVisualRadius: root.zoneVisualRadius
        moveDiff: root.moveDiff
        handDetected: root.startHandDetected
    }

    // --- Main Menu ---
    MainMenuScreen {
        visible: root.inMenu
        highScoreData: root.highScoreData
        onPlayRequested: { root.inMenu = false }
    }

    // --- Game Over Screen ---
    GameOverScreen {
        visible: root.gameOver
        score: root.score
        onScoreSaved: (name) => { root.saveScoreRequest = name + "|" + root.score }
        onRetryRequested: {
            root.score = 0
            root.lives = 3
            root.gameOver = false
            root.gameStarted = false
            root.holdProgress = 0.0
            root.ballLostThisRound = false
            root.racketHitActive = false
            root.stuckTicks = 0
            root.ballSpeedMultiplier = 1.0
            ball.reset(root.ballOrigin, Qt.quaternion(1, 0, 0, 0))
            root.inMenu = true
        }
    }

    Item {
        id: __materialLibrary__
    }
}

/*##^##
Designer {
    D{i:0}D{i:5;cameraSpeed3d:25;cameraSpeed3dMultiplier:1}
}
##^##*/
