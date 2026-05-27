import QtQuick3D
import QtQuick3D.Physics
import QtQuick

DynamicRigidBody {
    id: ball

    physicsMaterial.restitution: 1
    physicsMaterial.staticFriction: 0.0
    physicsMaterial.dynamicFriction: 0.0
    sendContactReports: true

    property real glowPulse: 1.0

    SequentialAnimation on glowPulse {
        loops: Animation.Infinite
        NumberAnimation { to: 2.2; duration: 600;  easing.type: Easing.InOutSine }
        NumberAnimation { to: 0.6; duration: 900;  easing.type: Easing.InOutSine }
        NumberAnimation { to: 1.8; duration: 400;  easing.type: Easing.InOutSine }
        NumberAnimation { to: 0.3; duration: 1400; easing.type: Easing.InOutSine }
        NumberAnimation { to: 1.4; duration: 700;  easing.type: Easing.InOutSine }
    }

    collisionShapes: SphereShape {
        diameter: 100
    }

    // Core orb — silver/deep grey
    Model {
        source: "#Sphere"
        scale: Qt.vector3d(0.8, 0.8, 0.8)
        materials: PrincipledMaterial {
            baseColor: Qt.rgba(0.478, 0.502, 0.533, 1)
            metalness: 1.0
            roughness: 0.45
        }
    }

    // Glow layer 1 — tight green halo
    Model {
        source: "#Sphere"
        scale: Qt.vector3d(1.1 + ball.glowPulse * 0.05, 1.1 + ball.glowPulse * 0.05, 1.1 + ball.glowPulse * 0.05)
        materials: PrincipledMaterial {
            baseColor: Qt.rgba(0, 0.05, 0, 0.3)
            emissiveFactor: Qt.vector3d(0.0, 0.18 * ball.glowPulse, 0.03 * ball.glowPulse)
            alphaMode: PrincipledMaterial.Blend
            opacity: 0.15
            cullMode: PrincipledMaterial.NoCulling
        }
    }

    // Glow layer 2
    Model {
        source: "#Sphere"
        scale: Qt.vector3d(1.4 + ball.glowPulse * 0.1, 1.4 + ball.glowPulse * 0.1, 1.4 + ball.glowPulse * 0.1)
        materials: PrincipledMaterial {
            baseColor: Qt.rgba(0, 0.05, 0, 0.3)
            emissiveFactor: Qt.vector3d(0.0, 0.22 * ball.glowPulse, 0.04 * ball.glowPulse)
            alphaMode: PrincipledMaterial.Blend
            opacity: 0.2
            cullMode: PrincipledMaterial.NoCulling
        }
    }

    // Glow layer 3 — outer haze
    Model {
        source: "#Sphere"
        scale: Qt.vector3d(1.9 + ball.glowPulse * 0.15, 1.9 + ball.glowPulse * 0.15, 1.9 + ball.glowPulse * 0.15)
        materials: PrincipledMaterial {
            baseColor: Qt.rgba(0, 0.02, 0, 0.1)
            emissiveFactor: Qt.vector3d(0.0, 0.3 * ball.glowPulse, 0.05 * ball.glowPulse)
            alphaMode: PrincipledMaterial.Blend
            opacity: 0.28
            cullMode: PrincipledMaterial.NoCulling
        }
    }

    PointLight {
        color: Qt.rgba(0.05, 0.9, 0.2, 1.0)
        constantFade: 0.05
        brightness: ball.glowPulse * 12
    }
}
