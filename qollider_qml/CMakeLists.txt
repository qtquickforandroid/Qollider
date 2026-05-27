cmake_minimum_required(VERSION 3.14)
project(qollider LANGUAGES CXX)

set(CMAKE_AUTOMOC ON)

find_package(Qt6 REQUIRED COMPONENTS Core Gui Quick Quick3D Quick3DPhysics Svg)

qt_add_executable(${PROJECT_NAME}
    main.cpp
)

set_target_properties(${PROJECT_NAME} PROPERTIES
    WIN32_EXECUTABLE TRUE
    MACOSX_BUNDLE TRUE
)

target_link_libraries(${PROJECT_NAME} PUBLIC
    Qt::Core
    Qt::Gui
    Qt::Quick
    Qt::Quick3D
    Qt::Quick3DPhysics
    Qt::Svg
)

file(GLOB PINGPONG_MESHES RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} "pingpong_assets/meshes/*.mesh")
file(GLOB PINGPONG_MAPS RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} "pingpong_assets/maps/*.png")
file(GLOB SKYBOX_MESHES RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} "skybox_assets/meshes/*.mesh")
file(GLOB SKYBOX_MAPS RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} "skybox_assets/maps/*.jpeg")
file(GLOB ARENA_MAPS RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} "arena_assets/maps/*.jpg")
file(GLOB UI_ASSETS RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} "ui_assets/*.svg")

qt_add_qml_module(${PROJECT_NAME}
    URI qollider_qml
    VERSION 1.0
    QML_FILES
        Main.qml
        Racket.qml
        ArenaWalls.qml
        GlowBall.qml
        RacketBody.qml
        StartScreen.qml
        GameOverScreen.qml
        MainMenuScreen.qml
    RESOURCES
    ${PINGPONG_MESHES}
    ${PINGPONG_MAPS}
    ${SKYBOX_MESHES}
    ${SKYBOX_MAPS}
    ${ARENA_MAPS}
    ${UI_ASSETS}
)

install(TARGETS ${PROJECT_NAME}
    BUNDLE DESTINATION .
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
)
