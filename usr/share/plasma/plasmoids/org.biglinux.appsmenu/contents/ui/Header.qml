/*
    SPDX-FileCopyrightText: 2014 Sebastian Kügler <sebas@kde.org>
    SPDX-FileCopyrightText: 2020 Carl Schwan <carl@carlschwan.eu>
    SPDX-FileCopyrightText: 2021 Mikel Johnson <mikel5764@gmail.com>
    SPDX-FileCopyrightText: 2021 Noah Davis <noahadvs@gmail.com>

    SPDX-License-Identifier: GPL-2.0-or-later
*/

pragma ComponentBehavior: Bound

import QtQuick 2.15
import QtQml 2.15
import QtQuick.Layouts
import QtQuick.Templates as T
import Qt5Compat.GraphicalEffects
import org.kde.plasma.components as PC3
import org.kde.plasma.extras as PlasmaExtras
import org.kde.kirigami 2.20 as Kirigami
import org.kde.kirigamiaddons.components as KirigamiComponents
import org.kde.coreaddons as KCoreAddons
import org.kde.kcmutils as KCM
import org.kde.config as KConfig
import org.kde.plasma.plasmoid

PlasmaExtras.PlasmoidHeading {
    id: root

    // Alias to access the search text externally
    property alias searchText: searchField.text
    property Item configureButton: configureButton
    property Item avatar: avatar
    property real preferredNameAndIconWidth: 0

    contentHeight: Math.max(searchField.implicitHeight, configureButton.implicitHeight)

    leftPadding: 0
    rightPadding: 0
    topPadding: Math.round((background.margins.top - background.inset.top) / 2.0)
    bottomPadding: background.margins.bottom + Math.round((background.margins.bottom - background.inset.bottom) / 2.0)

    KCoreAddons.KUser {
        id: kuser
    }

    spacing: kickoff.backgroundMetrics.spacing

    function tabSetFocus(event, invertedTarget, normalTarget) {
        const reason = event.key === Qt.Key_Tab ? Qt.TabFocusReason : Qt.BacktabFocusReason
        if (kickoff.paneSwap) {
            invertedTarget.forceActiveFocus(reason)
        } else if (normalTarget !== undefined) {
            normalTarget.forceActiveFocus(reason)
        } else {
            event.accepted = false
        }
    }

    RowLayout {
        id: nameAndIcon
        anchors.left: parent.left
        LayoutMirroring.enabled: false
        height: parent.height

        // Avatar button
        KirigamiComponents.AvatarButton {
            id: avatar
            visible: KConfig.KAuthorized.authorizeControlModule("kcm_users")

            Layout.fillHeight: true
            Layout.minimumWidth: height
            Layout.maximumWidth: height
            Layout.leftMargin: kickoff.backgroundMetrics.leftPadding

            source: kuser.faceIconUrl + "?timestamp=" + Date.now()

            Keys.onTabPressed: event => {
                tabSetFocus(event, kickoff.firstCentralPane);
            }
            Keys.onBacktabPressed: event => {
                tabSetFocus(event, nextItemInFocusChain());
            }

            // MouseArea to manage hover events
            MouseArea {
                id: avatarMouseArea
                anchors.fill: parent
                hoverEnabled: true
                z: 1

                // Change the cursor to a pointing hand when hovering
                cursorShape: Qt.PointingHandCursor

                // Handle hover enter event
                onEntered: {
                    searchField.visible = false
                    searchPlaceholder.visible = true
                    userInfo.visible = true
                    configureButton.visible = false // Hide leave buttons
                }

                // Handle hover exit event
                onExited: {
                    searchField.visible = true
                    searchPlaceholder.visible = false
                    userInfo.visible = false
                    configureButton.visible = true // Show leave buttons
                }
                onClicked: KCM.KCMLauncher.openSystemSettings("kcm_users")
            }
        }

        // User information container
        Item {
            id: userInfo
            visible: false
            Layout.fillHeight: true
            Layout.fillWidth: true
            z: 2

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 5



                Kirigami.Heading {
                    id: infoLabel
                    text: `${kuser.loginName}@${kuser.host}`
                    color: Kirigami.Theme.textColor
                    level: 5
                    textFormat: Text.PlainText
                    elide: Text.ElideRight
                    horizontalAlignment: kickoff.paneSwap ? Text.AlignRight : Text.AlignLeft
                    verticalAlignment: Text.AlignVCenter

                    Behavior on opacity {
                        NumberAnimation {
                            duration: Kirigami.Units.longDuration
                            easing.type: Easing.InOutQuad
                        }
                    }
                }
            }

            PC3.ToolTip.text: infoLabel.text
            PC3.ToolTip.delay: Kirigami.Units.toolTipDelay
            PC3.ToolTip.visible: infoLabel.truncated && containsMouse
        }
    }

    RowLayout {
        id: rowLayout
        spacing: root.spacing
        height: parent.height
        anchors {
            left: nameAndIcon.right
            right: parent.right
        }
        LayoutMirroring.enabled: false

        PlasmaExtras.SearchField {
            id: searchField
            Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
            Layout.fillWidth: true
            Layout.leftMargin: kickoff.backgroundMetrics.leftPadding + 10
            focus: true

            Binding {
                target: kickoff
                property: "searchField"
                value: searchField
                // there's only one header ever, so don't waste resources
                restoreMode: Binding.RestoreNone
            }
            Connections {
                target: kickoff
                function onExpandedChanged() {
                    if (kickoff.expanded) {
                        searchField.clear()
                    }
                }
            }
            onTextEdited: {
                searchField.forceActiveFocus(Qt.ShortcutFocusReason)
            }
            onAccepted: {
                kickoff.contentArea.currentItem.action.triggered()
                kickoff.contentArea.currentItem.forceActiveFocus(Qt.ShortcutFocusReason)
            }
            Keys.priority: Keys.AfterItem
            Keys.forwardTo: kickoff.contentArea !== null ? kickoff.contentArea.view : []
            Keys.onTabPressed: event => {
                tabSetFocus(event, nextItemInFocusChain(false));
            }
            Keys.onBacktabPressed: event => {
                tabSetFocus(event, nextItemInFocusChain());
            }
            Keys.onLeftPressed: event => {
                if (activeFocus) {
                    nextItemInFocusChain(kickoff.sideBarOnRight).forceActiveFocus(
                        Qt.application.layoutDirection === Qt.RightToLeft ? Qt.TabFocusReason : Qt.BacktabFocusReason)
                }
            }
            Keys.onRightPressed: event => {
                if (activeFocus) {
                    nextItemInFocusChain(!kickoff.sideBarOnRight).forceActiveFocus(
                        Qt.application.layoutDirection === Qt.RightToLeft ? Qt.BacktabFocusReason : Qt.TabFocusReason)
                }
            }
        }

        // Placeholder to maintain layout stability
        Item {
            id: searchPlaceholder
            visible: false
            Layout.fillWidth: true
        }

        // Leave buttons (logout buttons), hidden when hovering over avatar
        LeaveButtons {
            id: configureButton
            Layout.fillWidth: false
            Layout.leftMargin: kickoff.backgroundMetrics.leftPadding

            shouldCollapseButtons: root.contentWidth + root.spacing + buttonImplicitWidth > root.width
        }
    }
}
