 /*
    SPDX-FileCopyrightText: 2020 Mikel Johnson <mikel5764@gmail.com>
    SPDX-FileCopyrightText: 2021 Kai Uwe Broulik <kde@broulik.de>

    SPDX-License-Identifier: GPL-2.0-or-later
*/
import QtQuick 2.15
import QtQuick.Layouts 1.15
import org.kde.plasma.private.kicker 0.1 as Kicker
import org.kde.plasma.components 2.0 as PC2 // for Menu + MenuItem
import org.kde.plasma.components 3.0 as PC3
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.kirigami 2.16 as Kirigami

RowLayout {
    id: root
    
    property alias leave: leaveButton
    spacing: plasmoid.rootItem.backgroundMetrics.spacing
    visible: plasmoid.configuration.showSystemButton
    Kicker.SystemModel {
        id: systemModel
        favoritesModel: plasmoid.rootItem.rootModel.systemFavoritesModel
    }
    Repeater {
        id: buttonRepeater
        
        model: systemModel
        delegate: PC3.ToolButton {
            id: buttonDelegate
            text: model.display
            icon.name: model.decoration
            // TODO: Don't generate items that will never be seen. Maybe DelegateModel can help?
            visible: String(plasmoid.configuration.systemFavorites).includes(model.favoriteId)
            onClicked: systemModel.trigger(index, "", null)
            display: PC3.AbstractButton.IconOnly;

            PC3.ToolTip.text: text
            PC3.ToolTip.delay: Kirigami.Units.toolTipDelay
            PC3.ToolTip.visible: display === PC3.AbstractButton.IconOnly && hovered

             Keys.onLeftPressed: if (activeFocus) {
             if (LayoutMirroring.enabled) {
            nextItemInFocusChain().forceActiveFocus(Qt.TabFocusReason)
            } else {
            nextItemInFocusChain(false).forceActiveFocus(Qt.BacktabFocusReason)
                }
            }
        Keys.onRightPressed: if (activeFocus) {
        if (!LayoutMirroring.enabled) {
            nextItemInFocusChain().forceActiveFocus(Qt.TabFocusReason)
        } else {
            nextItemInFocusChain(false).forceActiveFocus(Qt.BacktabFocusReason)
                }
            }
        }
    }

    PC3.ToolButton {
        id: leaveButton
        readonly property int currentId: plasmoid.configuration.primaryActions
        visible: false
        Accessible.role: Accessible.ButtonMenu
        icon.width: PlasmaCore.Units.iconSizes.smallMedium
        icon.height: PlasmaCore.Units.iconSizes.smallMedium

        display: PC3.AbstractButton.IconOnly;
        PC3.ToolTip.visible: leaveButton.hovered
        PC3.ToolTip.delay: Kirigami.Units.toolTipDelay
       Keys.onLeftPressed: if (activeFocus) {
       if (LayoutMirroring.enabled) {
            nextItemInFocusChain().forceActiveFocus(Qt.TabFocusReason)
        } else {
            nextItemInFocusChain(false).forceActiveFocus(Qt.BacktabFocusReason)
                }
            }
        Keys.onRightPressed: if (activeFocus) {
        if (!LayoutMirroring.enabled) {
            nextItemInFocusChain().forceActiveFocus(Qt.TabFocusReason)
        } else {
            nextItemInFocusChain(false).forceActiveFocus(Qt.BacktabFocusReason)
                }
            }
    }

}
