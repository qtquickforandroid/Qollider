import QtQuick
import QtQuick3D

Node {
    id: racket

    // Textures

    // Materials — dark steel / gunmetal

    // Racket mesh parts - wrapped in Node with scale and rotation
    Node {
        scale: Qt.vector3d(200, 200, 200)
        // Rotate face from +Y (glTF default) to +Z (toward camera), then 180° around Z
        // so the face extends toward +Y (palm/fingers) and the handle drops toward -Y (elbow).
        eulerRotation: Qt.vector3d(-90, 0, 0)
        position: Qt.vector3d(0, 0, 0)

        Model {
            source: "pingpong_assets/meshes/raquette_001_Strap_002_0_mesh.mesh"
            materials: [strap_material]
        }
        Model {
            source: "pingpong_assets/meshes/raquette_001_Handle_002_0_mesh.mesh"
            materials: [handle_material]
        }
        Model {
            source: "pingpong_assets/meshes/raquette_001_Cover_002_0_mesh.mesh"
            materials: [cover_material]
        }
        Model {
            source: "pingpong_assets/meshes/raquette_001_Grip_002_0_mesh.mesh"
            materials: [grip_material]
        }
    }

    Node {
        id: __materialLibrary__

        Texture {
            id: handle_baseColor
            generateMipmaps: true
            mipFilter: Texture.Linear
            source: "pingpong_assets/maps/Handle.002_baseColor.png"
            objectName: "handle_baseColor"
        }

        Texture {
            id: handle_metallicRoughness
            generateMipmaps: true
            mipFilter: Texture.Linear
            source: "pingpong_assets/maps/Handle.002_metallicRoughness.png"
            objectName: "handle_metallicRoughness"
        }

        Texture {
            id: handle_normal
            generateMipmaps: true
            mipFilter: Texture.Linear
            source: "pingpong_assets/maps/Handle.002_normal.png"
            objectName: "handle_normal"
        }

        Texture {
            id: cover_baseColor
            generateMipmaps: true
            mipFilter: Texture.Linear
            source: "pingpong_assets/maps/Cover.002_baseColor.png"
            objectName: "cover_baseColor"
        }

        Texture {
            id: cover_metallicRoughness
            generateMipmaps: true
            mipFilter: Texture.Linear
            source: "pingpong_assets/maps/Cover.002_metallicRoughness.png"
            objectName: "cover_metallicRoughness"
        }

        Texture {
            id: cover_normal
            generateMipmaps: true
            mipFilter: Texture.Linear
            source: "pingpong_assets/maps/Cover.002_normal.png"
            objectName: "cover_normal"
        }

        Texture {
            id: grip_baseColor
            generateMipmaps: true
            mipFilter: Texture.Linear
            source: "pingpong_assets/maps/Grip.002_baseColor.png"
            objectName: "grip_baseColor"
        }

        Texture {
            id: grip_metallicRoughness
            generateMipmaps: true
            mipFilter: Texture.Linear
            source: "pingpong_assets/maps/Grip.002_metallicRoughness.png"
            objectName: "grip_metallicRoughness"
        }

        Texture {
            id: grip_normal
            generateMipmaps: true
            mipFilter: Texture.Linear
            source: "pingpong_assets/maps/Grip.002_normal.png"
            objectName: "grip_normal"
        }

        Texture {
            id: strap_baseColor
            generateMipmaps: true
            mipFilter: Texture.Linear
            source: "pingpong_assets/maps/Strap.002_baseColor.png"
            objectName: "strap_baseColor"
        }

        Texture {
            id: strap_metallicRoughness
            generateMipmaps: true
            mipFilter: Texture.Linear
            source: "pingpong_assets/maps/Strap.002_metallicRoughness.png"
            objectName: "strap_metallicRoughness"
        }

        PrincipledMaterial {
            id: handle_material
            objectName: "handle_material"
            baseColor: Qt.rgba(0.690, 0.722, 0.784, 1)
            metalness: 1.0
            roughness: 0.3
            normalMap: handle_normal
            cullMode: PrincipledMaterial.NoCulling
        }

        PrincipledMaterial {
            id: cover_material
            objectName: "cover_material"
            baseColor: Qt.rgba(0.784, 0.816, 0.863, 1)
            metalness: 1.0
            roughness: 0.1
            opacity: 0.20
            normalMap: cover_normal
            cullMode: PrincipledMaterial.NoCulling
        }

        PrincipledMaterial {
            id: grip_material
            objectName: "grip_material"
            baseColor: Qt.rgba(0.565, 0.604, 0.659, 1)
            metalness: 0.8
            roughness: 0.5
            normalMap: grip_normal
            cullMode: PrincipledMaterial.NoCulling
        }

        PrincipledMaterial {
            id: strap_material
            objectName: "strap_material"
            baseColor: Qt.rgba(0.722, 0.753, 0.800, 1)
            metalness: 1.0
            roughness: 0.18
            cullMode: PrincipledMaterial.NoCulling
        }
    }
}

/*##^##
Designer {
    D{i:0;cameraSpeed3d:25;cameraSpeed3dMultiplier:1}
}
##^##*/
