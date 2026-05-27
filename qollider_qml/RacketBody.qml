import QtQuick3D
import QtQuick3D.Physics

DynamicRigidBody {
    id: rack

    property double pitch: 0.0
    property double yaw:   0.0
    property double roll:  0.0

    property real racketScaleY: 3.0

    signal ballHit

    property var ballBody: null

    kinematicEulerRotation: Qt.vector3d(pitch, yaw, roll)
    collisionShapes: BoxShape {
        position: Qt.vector3d(0, 43, 0)
        extents: Qt.vector3d(120, 210, 80)
    }

    receiveContactReports: true
    isKinematic: true

    onBodyContact: function(body, positions, impulses, normals) {
        if (body === ballBody) ballHit()
    }

    Racket {
        id: racketModel
        scale: Qt.vector3d(3, rack.racketScaleY, 3)
        eulerRotation: Qt.vector3d(0, 0, 0)
    }

}
