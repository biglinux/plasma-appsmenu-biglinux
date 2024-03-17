/*
    SPDX-FileCopyrightText: 2014 Sebastian Kügler <sebas@kde.org>
    SPDX-FileCopyrightText: 2020 Carl Schwan <carl@carlschwan.eu>
    SPDX-FileCopyrightText: 2021 Mikel Johnson <mikel5764@gmail.com>
    SPDX-FileCopyrightText: 2021 Noah Davis <noahadvs@gmail.com>

    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick 2.15
import QtQml 2.15
import QtQuick.Layouts 1.15
import QtQuick.Templates 2.15 as T
import Qt5Compat.GraphicalEffects
import org.kde.plasma.components 3.0 as PC3
import org.kde.plasma.extras 2.0 as PlasmaExtras
import org.kde.kirigami 2.20 as Kirigami
import org.kde.kirigamiaddons.components 1.0 as KirigamiComponents
import org.kde.coreaddons 1.0 as KCoreAddons
import org.kde.kcmutils as KCM
import org.kde.config as KConfig
import org.kde.plasma.plasmoid 2.0

PlasmaExtras.PlasmoidHeading {
    id: root

    property alias searchText: searchField.text
    property Item configureButton: configureButton
    property Item pinButton: pinButton
    property Item avatar: avatar
    property real preferredNameAndIconWidth: 0

    contentHeight: Math.max(searchField.implicitHeight, configureButton.implicitHeight)

    leftPadding: 0
    rightPadding: 0
    topPadding: Math.round((background.margins.top - background.inset.top) / 2.0)
    bottomPadding: background.margins.bottom + Math.round((background.margins.bottom - background.inset.bottom) / 2.0)

    leftInset: -kickoff.backgroundMetrics.leftPadding
    rightInset: -kickoff.backgroundMetrics.rightPadding
    topInset: -background.margins.top
    bottomInset: 0

    KCoreAddons.KUser {
        id: kuser
    }

    spacing: kickoff.backgroundMetrics.spacing

    function tabSetFocus(event, invertedTarget, normalTarget) {
        // Set input focus depending on whether layout order matches focus chain order
        // normalTarget is optional
        const reason = event.key == Qt.Key_Tab ? Qt.TabFocusReason : Qt.BacktabFocusReason
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
        // spacing: root.spacing
        anchors.left: parent.left
        height: parent.height

        KirigamiComponents.AvatarButton {
            id: avatar
            visible: KConfig.KAuthorized.authorizeControlModule("kcm_users")

            Layout.fillHeight: true
            Layout.minimumWidth: height
            Layout.maximumWidth: height
            Layout.leftMargin: kickoff.backgroundMetrics.leftPadding + 6

            text: `${kuser.loginName}
${kuser.host}`
            name: kuser.fullName
            source: kuser.faceIconUrl + "?timestamp=" + Date.now()

            Keys.onTabPressed: event => {
                tabSetFocus(event, kickoff.firstCentralPane);
            }
            Keys.onBacktabPressed: event => {
                tabSetFocus(event, nextItemInFocusChain());
            }
            Keys.onLeftPressed: event => {
                if (kickoff.sideBarOnRight) {
                    searchField.forceActiveFocus(Qt.application.layoutDirection == Qt.RightToLeft ? Qt.TabFocusReason : Qt.BacktabFocusReason)
                }
            }
            Keys.onRightPressed: event => {
                if (!kickoff.sideBarOnRight) {
                    searchField.forceActiveFocus(Qt.application.layoutDirection == Qt.RightToLeft ? Qt.BacktabFocusReason : Qt.TabFocusReason)
                }
            }
            Keys.onDownPressed: event => {
                if (kickoff.sideBar) {
                    kickoff.sideBar.forceActiveFocus(Qt.TabFocusReason)
                } else {
                    kickoff.contentArea.forceActiveFocus(Qt.TabFocusReason)
                }
            }

            onClicked: KCM.KCMLauncher.openSystemSettings("kcm_users")
        }

        // MouseArea {
        //     id: nameAndInfoMouseArea
        //     hoverEnabled: true

        //     Layout.fillHeight: true
        //     Layout.fillWidth: true

        //     // Kirigami.Heading {
        //     //     id: nameLabel
        //     //     anchors.fill: parent
        //     //     opacity: parent.containsMouse ? 0 : 1
        //     //     color: Kirigami.Theme.textColor
        //     //     level: 4
        //     //     text: kuser.fullName
        //     //     elide: Text.ElideRight
        //     //     horizontalAlignment: kickoff.paneSwap ? Text.AlignRight : Text.AlignLeft
        //     //     verticalAlignment: Text.AlignVCenter

        //     //     Behavior on opacity {
        //     //         NumberAnimation {
        //     //             duration: Kirigami.Units.longDuration
        //     //             easing.type: Easing.InOutQuad
        //     //         }
        //     //     }
        //     // }

        //     // Kirigami.Heading {
        //     //     id: infoLabel
        //     //     anchors.fill: parent
        //     //     level: 5
        //     //     opacity: parent.containsMouse ? 1 : 0
        //     //     color: Kirigami.Theme.textColor
        //     //     text: kuser.os !== "" ? `${kuser.loginName}@${kuser.host} (${kuser.os})` : `${kuser.loginName}@${kuser.host}`
        //     //     elide: Text.ElideRight
        //     //     horizontalAlignment: kickoff.paneSwap ? Text.AlignRight : Text.AlignLeft
        //     //     verticalAlignment: Text.AlignVCenter

        //     //     Behavior on opacity {
        //     //         NumberAnimation {
        //     //             duration: Kirigami.Units.longDuration
        //     //             easing.type: Easing.InOutQuad
        //     //         }
        //     //     }
        //     // }

        //     PC3.ToolTip.text: infoLabel.text
        //     PC3.ToolTip.delay: Kirigami.Units.toolTipDelay
        //     PC3.ToolTip.visible: infoLabel.truncated && containsMouse
        // }
    }
    
    RowLayout {
        id: rowLayout
        spacing: root.spacing
        height: parent.height
        anchors {
            left: nameAndIcon.right
            right: parent.right
        }
        LayoutMirroring.enabled: kickoff.sideBarOnRight
        Keys.onDownPressed: event => {
            kickoff.contentArea.forceActiveFocus(Qt.TabFocusReason);
        }

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

            LeaveButtons {
            id: configureButton // from footer id: leaveButtons

            Layout.alignment: Qt.AlignRight
            Layout.fillWidth: false
            Layout.leftMargin: kickoff.backgroundMetrics.leftPadding

        anchors {
            right: parent.right
            top: parent.top
            bottom: parent.bottom
            leftMargin: root.spacing
        }
        shouldCollapseButtons: root.contentWidth + root.spacing + buttonImplicitWidth > root.width
        Keys.onUpPressed: event => {
            kickoff.lastCentralPane.forceActiveFocus(Qt.BacktabFocusReason);
        }
    }



    }
}
