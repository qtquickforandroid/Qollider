import QtQuick

Rectangle {
    id: gameOverScreen

    property int score: 0
    property bool hasSaved: false

    signal retryRequested
    signal scoreSaved(string name)

    anchors.fill: parent
    color: Qt.rgba(0, 0, 0, 1)

    onScoreSaved: (name) => { hasSaved = true }
    onVisibleChanged: {
        if (!visible) {
            hasSaved = false
            nameInput.text = ""
        }
    }

    Column {
        anchors.centerIn: parent
        spacing: 28

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "GAME OVER"
            color: Qt.rgba(0.816, 0.847, 0.910, 1)
            font.pointSize: 70
            font.bold: true
            font.family: "monospace"
            style: Text.Outline
            styleColor: Qt.rgba(0.102, 0.110, 0.133, 1)
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "score  " + gameOverScreen.score.toString().padStart(3, "0")
            color: Qt.rgba(0.416, 0.471, 0.533, 1)
            font.pointSize: 50
            font.family: "monospace"
        }

        Item { width: 1; height: 12 }

        // Name input
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 400
            height: 72
            radius: 8
            color: Qt.rgba(0.118, 0.125, 0.157, 1)
            border.color: nameInput.activeFocus ? Qt.rgba(0.502, 0.784, 0.831, 1) : Qt.rgba(0.353, 0.376, 0.439, 1)
            border.width: 2
            visible: !gameOverScreen.hasSaved

            Text {
                anchors.centerIn: parent
                visible: nameInput.text.length === 0
                text: "enter name"
                color: Qt.rgba(0.227, 0.282, 0.345, 1)
                font.pointSize: 22
                font.family: "monospace"
            }

            TextInput {
                id: nameInput
                anchors.centerIn: parent
                width: parent.width - 40
                color: Qt.rgba(0.816, 0.847, 0.910, 1)
                font.pointSize: 22
                font.family: "monospace"
                maximumLength: 12
                horizontalAlignment: TextInput.AlignHCenter
            }
        }

        // Save button
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 280
            height: 64
            radius: 8
            color: saveArea.pressed ? Qt.rgba(0.227, 0.239, 0.271, 1) : Qt.rgba(0.118, 0.125, 0.157, 1)
            border.color: Qt.rgba(0.353, 0.376, 0.439, 1)
            border.width: 1
            visible: !gameOverScreen.hasSaved
            opacity: nameInput.text.trim().length > 0 ? 1.0 : 0.35

            Text {
                anchors.centerIn: parent
                text: "SAVE SCORE"
                color: Qt.rgba(0.753, 0.784, 0.831, 1)
                font.pointSize: 20
                font.bold: true
                font.family: "monospace"
            }

            MouseArea {
                id: saveArea
                anchors.fill: parent
                enabled: nameInput.text.trim().length > 0
                onClicked: gameOverScreen.scoreSaved(nameInput.text.trim())
            }
        }

        // Saved confirmation
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: gameOverScreen.hasSaved
            text: "score saved!"
            color: Qt.rgba(0.502, 0.784, 0.831, 1)
            font.pointSize: 22
            font.family: "monospace"
        }

        Item { width: 1; height: 8 }

        // Play Again button
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 220
            height: 64
            radius: 8
            color: retryArea.pressed ? Qt.rgba(0.227, 0.239, 0.271, 1) : Qt.rgba(0.118, 0.125, 0.157, 1)
            border.color: Qt.rgba(0.353, 0.376, 0.439, 1)
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: "PLAY AGAIN"
                color: Qt.rgba(0.753, 0.784, 0.831, 1)
                font.pointSize: 20
                font.bold: true
                font.family: "monospace"
            }

            MouseArea {
                id: retryArea
                anchors.fill: parent
                onClicked: gameOverScreen.retryRequested()
            }
        }
    }
}
