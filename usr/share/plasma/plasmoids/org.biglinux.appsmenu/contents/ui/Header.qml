/*
 *    Copyright 2014  Sebastian Kügler <sebas@kde.org>
 *    SPDX-FileCopyrightText: (C) 2020 Carl Schwan <carl@carlschwan.eu>
 *    Copyright (C) 2021 by Mikel Johnson <mikel5764@gmail.com>
 *
 *    This program is free software; you can redistribute it and/or modify
 *    it under the terms of the GNU General Public License as published by
 *    the Free Software Foundation; either version 2 of the License, or
 *    (at your option) any later version.
 *
 *    This program is distributed in the hope that it will be useful,
 *    but WITHOUT ANY WARRANTY; without even the implied warranty of
 *    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *    GNU General Public License for more details.
 *
 *    You should have received a copy of the GNU General Public License along
 *    with this program; if not, write to the Free Software Foundation, Inc.,
 *    51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
 */

import QtQuick 2.12
import QtQuick.Layouts 1.12
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 3.0 as PlasmaComponents
import org.kde.plasma.extras 2.0 as PlasmaExtras
import org.kde.kcoreaddons 1.0 as KCoreAddons
import org.kde.plasma.private.kicker 0.1 as Kicker //for Leave Buttons
// While using Kirigami in applets is normally a no, we
// use Avatar, which doesn't need to read the colour scheme
// at all to function, so there won't be any oddities with colours.
import org.kde.kirigami 2.13 as Kirigami
import org.kde.kquickcontrolsaddons 2.0 as KQuickAddons

PlasmaExtras.PlasmoidHeading {
    id: header

    implicitHeight: Math.round(PlasmaCore.Units.gridUnit * 2.5)
    rightPadding: rightInset

    property alias query: queryField.text
    property Item input: queryField
    property Item configureButton: configureButton
    property Item avatar: avatarButton

    KCoreAddons.KUser {
        id: kuser
    }

    RowLayout {
        id: nameAndIcon
        anchors.left: parent.left
        anchors.leftMargin: PlasmaCore.Units.gridUnit + header.leftInset + PlasmaCore.Units.devicePixelRatio //border width
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.rightMargin: PlasmaCore.Units.gridUnit - PlasmaCore.Units.devicePixelRatio - PlasmaCore.Units.smallSpacing //separator width
        
        // looks visually balanced that way
        spacing: Math.round(PlasmaCore.Units.smallSpacing * 2.5)
        
        PlasmaComponents.TextField {
            id: queryField

            Layout.fillWidth: true

            placeholderText: i18n("Search...")
            clearButtonShown: true

            Accessible.editable: true
            Accessible.searchEdit: true

            onTextChanged: {
                if (root.state != "Search") {
                    root.previousState = root.state;
                    root.state = "Search";
                }
                if (text == "") {
                    root.state = root.previousState;
                }
            }
        }

        Repeater {
            model: systemFavorites

            PlasmaComponents.ToolButton {
                // so that it lets the buttons elide...
                Layout.fillWidth: true
                // ... but does not make the buttons grow
                Layout.maximumWidth: implicitWidth
                text: model.display
                icon.name: model.decoration
                onClicked: {
                    systemFavorites.trigger(index, "", "")
                }
            }
        }
    }

    Instantiator {
        model: Kicker.SystemModel {
            id: systemModel
            favoritesModel: globalFavorites
        }
        delegate: PlasmaComponents.MenuItem {
            text: model.display
            visible: !String(plasmoid.configuration.systemFavorites).includes(model.favoriteId)

            onClicked: systemModel.trigger(index, "", "")
        }
    }
    
    //TODO: Figure out keyboard hotkeys for this later - refer to LeaveButtons.qml
    Keys.onPressed: {
        // On tab focus on left pane (or search when searching)
        if (event.key == Qt.Key_Tab) {
            navigationMethod.state = "keyboard"
            // There's no left panel when we search
            if (root.state == "Search") {
                keyboardNavigation.state = "RightColumn"
                root.currentContentView.forceActiveFocus()
            } else if (mainTabGroup.state == "top") {
                applicationButton.forceActiveFocus(Qt.TabFocusReason)
            } else {
                keyboardNavigation.state = "LeftColumn"
                root.currentView.forceActiveFocus()
            }
            event.accepted = true;
            return;
        }
    }
}
