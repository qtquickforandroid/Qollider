import QtQuick

Rectangle {
    id: mainMenuScreen

    signal playRequested

    property bool showHighScores: false
    property string highScoreData: ""

    anchors.fill: parent
    color: Qt.rgba(0, 0, 0, 0.92)

    // Main menu
    Column {
        visible: !mainMenuScreen.showHighScores
        anchors.centerIn: parent
        spacing: 24

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "QOLLIDER"
            color: Qt.rgba(0.816, 0.847, 0.910, 1)
            font.pointSize: 70
            font.bold: true
            font.family: "monospace"
            style: Text.Outline
            styleColor: Qt.rgba(0.102, 0.110, 0.133, 1)
        }

        Item { width: 1; height: 40 }

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 280; height: 64
            radius: 8
            color: playArea.pressed ? Qt.rgba(0.227, 0.239, 0.271, 1) : Qt.rgba(0.118, 0.125, 0.157, 1)
            border.color: Qt.rgba(0.353, 0.376, 0.439, 1)
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: "PLAY GAME"
                color: Qt.rgba(0.753, 0.784, 0.831, 1)
                font.pointSize: 22
                font.bold: true
                font.family: "monospace"
            }

            MouseArea {
                id: playArea
                anchors.fill: parent
                onClicked: mainMenuScreen.playRequested()
            }
        }

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 280; height: 64
            radius: 8
            color: highScoresArea.pressed ? Qt.rgba(0.227, 0.239, 0.271, 1) : Qt.rgba(0.118, 0.125, 0.157, 1)
            border.color: Qt.rgba(0.353, 0.376, 0.439, 1)
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: "HIGH SCORES"
                color: Qt.rgba(0.753, 0.784, 0.831, 1)
                font.pointSize: 22
                font.bold: true
                font.family: "monospace"
            }

            MouseArea {
                id: highScoresArea
                anchors.fill: parent
                onClicked: mainMenuScreen.showHighScores = true
            }
        }
    }

    // High scores sub-screen
    Column {
        visible: mainMenuScreen.showHighScores
        anchors.centerIn: parent
        spacing: 16

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "HIGH SCORES"
            color: Qt.rgba(0.816, 0.847, 0.910, 1)
            font.pointSize: 50
            font.bold: true
            font.family: "monospace"
            style: Text.Outline
            styleColor: Qt.rgba(0.102, 0.110, 0.133, 1)
        }

        Item { width: 1; height: 24 }

        // Score rows
        Repeater {
            model: mainMenuScreen.highScoreData.length > 0
                   ? mainMenuScreen.highScoreData.split(";").filter(e => e.length > 0)
                   : []
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 16

                Text {
                    text: (index + 1).toString().padStart(2, " ") + "."
                    color: Qt.rgba(0.353, 0.408, 0.439, 1)
                    font.pointSize: 22
                    font.family: "monospace"
                    width: 60
                    horizontalAlignment: Text.AlignRight
                }
                Text {
                    text: modelData.split("|")[0] || "?"
                    color: Qt.rgba(0.816, 0.847, 0.910, 1)
                    font.pointSize: 22
                    font.family: "monospace"
                    width: 220
                }
                Text {
                    text: parseInt(modelData.split("|")[1] || "0").toString().padStart(3, "0")
                    color: Qt.rgba(0.502, 0.784, 0.831, 1)
                    font.pointSize: 22
                    font.family: "monospace"
                    width: 70
                    horizontalAlignment: Text.AlignRight
                }
            }
        }

        // Empty state
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: mainMenuScreen.highScoreData.length === 0
            text: "no scores yet"
            color: Qt.rgba(0.227, 0.282, 0.345, 1)
            font.pointSize: 26
            font.family: "monospace"
        }

        Item { width: 1; height: 32 }

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 200; height: 56
            radius: 8
            color: backArea.pressed ? Qt.rgba(0.227, 0.239, 0.271, 1) : Qt.rgba(0.118, 0.125, 0.157, 1)
            border.color: Qt.rgba(0.353, 0.376, 0.439, 1)
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: "BACK"
                color: Qt.rgba(0.753, 0.784, 0.831, 1)
                font.pointSize: 20
                font.bold: true
                font.family: "monospace"
            }

            MouseArea {
                id: backArea
                anchors.fill: parent
                onClicked: mainMenuScreen.showHighScores = false
            }
        }
    }
}
