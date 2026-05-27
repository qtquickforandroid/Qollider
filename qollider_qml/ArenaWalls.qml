import QtQuick3D
import QtQuick3D.Physics

Node {
    property real wallRestitution: 1
    property real arenaWidth: 750
    property real arenaHeight: 600
    property real arenaDepth: 200

    // Front visual frame sits at the racket plane — defines the visible playfield box
    readonly property real _frontZ: 600
    readonly property real _depthSpan: _frontZ + arenaDepth          // 800
    readonly property real _depthMid:  (_frontZ - arenaDepth) * 0.5  // 200

    property string wallTexture: "arena_assets/maps/Texturelabs_Paper_198L.jpg"
    property real wallOpacity: 0.2

    signal ballMissed

    component WallMaterial: PrincipledMaterial {
        baseColorMap: Texture {
            source: wallTexture
            generateMipmaps: true
            mipFilter: Texture.Linear
            scaleU: 1
            scaleV: 1
        }
        roughness: 0.8
        metalness: 0.0
        opacity: wallOpacity
        alphaMode: PrincipledMaterial.Blend
    }

    StaticRigidBody {
        id: backWall
        position: Qt.vector3d(0, 0, -arenaDepth)
        collisionShapes: PlaneShape {}
        physicsMaterial.restitution: wallRestitution
        Model {
            source: "#Cube"
            position: Qt.vector3d(0, 0, -0.5)
            scale: Qt.vector3d(arenaWidth * 2 / 100, arenaHeight * 2 / 100, 0.01)
            materials: WallMaterial {}
        }
    }

    StaticRigidBody {
        id: frontWall
        position: Qt.vector3d(0, 0, 1100)
        eulerRotation: Qt.vector3d(180, 0, 0)
        collisionShapes: PlaneShape {}
        physicsMaterial.restitution: wallRestitution
        receiveContactReports: true
        onBodyContact: ballMissed()
    }

    StaticRigidBody {
        id: leftWall
        position: Qt.vector3d(-arenaWidth, 0, _depthMid)
        eulerRotation: Qt.vector3d(0, 89, 0)
        collisionShapes: PlaneShape {}
        physicsMaterial.restitution: wallRestitution
        Model {
            source: "#Cube"
            eulerRotation: Qt.vector3d(0, -89, 0)
            scale: Qt.vector3d(0.01, arenaHeight * 2 / 100, _depthSpan / 100)
            materials: WallMaterial {}
        }
    }

    StaticRigidBody {
        id: rightWall
        position: Qt.vector3d(arenaWidth, 0, _depthMid)
        eulerRotation: Qt.vector3d(0, -89, 0)
        collisionShapes: PlaneShape {}
        physicsMaterial.restitution: wallRestitution
        Model {
            source: "#Cube"
            eulerRotation: Qt.vector3d(0, 89, 0)
            scale: Qt.vector3d(0.01, arenaHeight * 2 / 100, _depthSpan / 100)
            materials: WallMaterial {}
        }
    }

    StaticRigidBody {
        id: topWall
        position: Qt.vector3d(0, arenaHeight, _depthMid)
        eulerRotation: Qt.vector3d(89, 0, 0)
        collisionShapes: PlaneShape {}
        physicsMaterial.restitution: wallRestitution
        Model {
            source: "#Cube"
            eulerRotation: Qt.vector3d(-89, 0, 0)
            scale: Qt.vector3d(arenaWidth * 2 / 100, 0.01, _depthSpan / 100)
            materials: WallMaterial {}
        }
    }

    StaticRigidBody {
        id: bottomWall
        position: Qt.vector3d(0, -arenaHeight, _depthMid)
        eulerRotation: Qt.vector3d(-89, 0, 0)
        collisionShapes: PlaneShape {}
        physicsMaterial.restitution: wallRestitution
        Model {
            source: "#Cube"
            eulerRotation: Qt.vector3d(89, 0, 0)
            scale: Qt.vector3d(arenaWidth * 2 / 100, 0.01, _depthSpan / 100)
            materials: WallMaterial {}
        }
    }

    component WireEdge: Model {
        source: "#Sphere" // thin long egg shaped so that its rounded without the corners looking off
        materials: PrincipledMaterial {
            baseColor: Qt.rgba(0.85, 0.92, 1.0, 1) // bright cool white/blue silver
            emissiveFactor: Qt.vector3d(0.4, 0.7, 1.2)  // electric blue sparkle glow
            metalness: 1.0
            roughness: 0.02   // near-mirror = sparkly
            specularAmount: 1.0
            specularTint: 1.0
            clearcoatAmount: 1.0
            clearcoatRoughnessAmount: 0.0
            lighting: PrincipledMaterial.FragmentLighting
        }
    }

    // Back wall frame  (Z = -arenaDepth)
    WireEdge { position: Qt.vector3d(0,  arenaHeight, -arenaDepth); scale: Qt.vector3d(arenaWidth * 2 / 100, 0.10, 0.10) }
    WireEdge { position: Qt.vector3d(0, -arenaHeight, -arenaDepth); scale: Qt.vector3d(arenaWidth * 2 / 100, 0.10, 0.10) }
    WireEdge { position: Qt.vector3d(-arenaWidth, 0,  -arenaDepth); scale: Qt.vector3d(0.10, arenaHeight * 2 / 100, 0.10) }
    WireEdge { position: Qt.vector3d( arenaWidth, 0,  -arenaDepth); scale: Qt.vector3d(0.10, arenaHeight * 2 / 100, 0.10) }

    // Front frame  (Z = _frontZ, at racket plane)
    WireEdge { position: Qt.vector3d(0,  arenaHeight, _frontZ); scale: Qt.vector3d(arenaWidth * 2 / 100, 0.10, 0.10) }
    WireEdge { position: Qt.vector3d(0, -arenaHeight, _frontZ); scale: Qt.vector3d(arenaWidth * 2 / 100, 0.10, 0.10) }
    WireEdge { position: Qt.vector3d(-arenaWidth, 0,  _frontZ); scale: Qt.vector3d(0.10, arenaHeight * 2 / 100, 0.10) }
    WireEdge { position: Qt.vector3d( arenaWidth, 0,  _frontZ); scale: Qt.vector3d(0.10, arenaHeight * 2 / 100, 0.10) }

    // Corner pillars connecting back to front frame
    WireEdge { position: Qt.vector3d(-arenaWidth,  arenaHeight, _depthMid); scale: Qt.vector3d(0.10, 0.10, _depthSpan / 100) }
    WireEdge { position: Qt.vector3d( arenaWidth,  arenaHeight, _depthMid); scale: Qt.vector3d(0.10, 0.10, _depthSpan / 100) }
    WireEdge { position: Qt.vector3d(-arenaWidth, -arenaHeight, _depthMid); scale: Qt.vector3d(0.10, 0.10, _depthSpan / 100) }
    WireEdge { position: Qt.vector3d( arenaWidth, -arenaHeight, _depthMid); scale: Qt.vector3d(0.10, 0.10, _depthSpan / 100) }
}
