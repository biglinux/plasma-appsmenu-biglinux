/*
    SPDX-FileCopyrightText: 2013 David Edmundson <davidedmundson@kde.org>
    SPDX-FileCopyrightText: 2021 Mikel Johnson <mikel5764@gmail.com>
    SPDX-FileCopyrightText: 2022 Nate Graham <nate@kde.org>

    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick 2.15
import QtQuick.Layouts 1.1
import QtQuick.Controls 2.5

import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.kquickcontrolsaddons 2.0 as KQuickAddons
import org.kde.kirigami 2.15 as Kirigami
import org.kde.plasma.extras 2.0 as PlasmaExtras

ColumnLayout {

    property string cfg_menuLabel: menuLabel.text
    property string cfg_icon: plasmoid.configuration.icon
    property alias cfg_alphaSort: alphaSort.checked
    property alias cfg_showPinButton: showPinButton.checked
    property alias cfg_showSystemCategory: showPowercategory.checked
    property alias cfg_showSystemButton: showPowerButton.checked
    property alias cfg_showAllAppsCategory: showAllAppscategory.checked
    property alias cfg_showCategoryIcons: showCategoryIcons.checked
    property alias cfg_showFavoritesCategory: showFavoritesCategory.checked
    //property alias cfg_showRecentAppsCategory: showRecentAppsCategory.checked
    //property alias cfg_showRecentDocsCategory: showRecentDocsCategory.checked
    property alias cfg_showFullscreenButton: showFullScreenButton.checked
    property alias cfg_showSettingsButton: showSettingsButton.checked
    property alias cfg_compactMode: compactModeCheckbox.checked
    property alias cfg_showAppsdescription: showAppsdescription.checked 
    property int cfg_favoritesDisplay: plasmoid.configuration.favoritesDisplay
    property int cfg_applicationsDisplay: plasmoid.configuration.applicationsDisplay
    property int cfg_systemDisplay: plasmoid.configuration.systemDisplay
    property var cfg_systemFavorites: String(plasmoid.configuration.systemFavorites)
    property int cfg_primaryActions: plasmoid.configuration.primaryActions
    //property alias cfg_menuPosition: menuPosition.currentIndex
    
    Kirigami.FormLayout {
        Button {
            id: iconButton

            Kirigami.FormData.label: i18n("Icon:")

            implicitWidth: previewFrame.width + PlasmaCore.Units.smallSpacing * 2
            implicitHeight: previewFrame.height + PlasmaCore.Units.smallSpacing * 2

            KQuickAddons.IconDialog {
                id: iconDialog
                onIconNameChanged: cfg_icon = iconName || "start-here-kde"
            }

            onPressed: iconMenu.opened ? iconMenu.close() : iconMenu.open()

            PlasmaCore.FrameSvgItem {
                id: previewFrame
                anchors.centerIn: parent
                imagePath: plasmoid.formFactor === PlasmaCore.Types.Vertical || plasmoid.formFactor === PlasmaCore.Types.Horizontal
                        ? "widgets/panel-background" : "widgets/background"
                width: PlasmaCore.Units.iconSizes.large + fixedMargins.left + fixedMargins.right
                height: PlasmaCore.Units.iconSizes.large + fixedMargins.top + fixedMargins.bottom

                PlasmaCore.IconItem {
                    anchors.centerIn: parent
                    width: PlasmaCore.Units.iconSizes.large
                    height: width
                    source: plasmoid.formFactor !== PlasmaCore.Types.Vertical ? cfg_icon : cfg_icon ? cfg_icon : "start-here-kde"
                }
            }

            Menu {
                id: iconMenu

                // Appear below the button
                y: +parent.height

                MenuItem {
                    text: i18nc("@item:inmenu Open icon chooser dialog", "Choose…")
                    icon.name: "document-open-folder"
                    onClicked: iconDialog.open()
                }
                MenuItem {
                    text: i18nc("@item:inmenu Reset icon to default", "Reset to default icon")
                    icon.name: "edit-clear"
                    enabled: cfg_icon != "start-here-kde"
                    onClicked: cfg_icon = "start-here-kde"
                }
                MenuItem {
                    text: i18nc("@action:inmenu", "Remove icon")
                    icon.name: "delete"
                    enabled: !!cfg_icon && menuLabel.text && plasmoid.formFactor !== PlasmaCore.Types.Vertical
                    onClicked: cfg_icon = ""
                }
            }
        }

        Kirigami.ActionTextField {
            id: menuLabel
            enabled: plasmoid.formFactor !== PlasmaCore.Types.Vertical
            Kirigami.FormData.label: i18nc("@label:textbox", "Text label:")
            text: plasmoid.configuration.menuLabel
            placeholderText: i18nc("@info:placeholder", "Type here to add a text label")
            onTextEdited: {
                cfg_menuLabel = menuLabel.text
                
                // This is to make sure that we always have a icon if there is no text.
                // If the user remove the icon and remove the text, without this, we'll have no icon and no text.
                // This is to force the icon to be there.
                if (!menuLabel.text) {
                    cfg_icon = cfg_icon || "start-here-kde"
                }
            }
            rightActions: [
                Action {
                    icon.name: "edit-clear"
                    enabled: menuLabel.text !== ""
                    onTriggered: {
                        menuLabel.clear()
                        cfg_menuLabel = ''
                        cfg_icon = cfg_icon || "start-here-kde"
                    }
                }
            ]
        }

        Label {
            Layout.fillWidth: true
            Layout.maximumWidth: Kirigami.Units.gridUnit * 25
            visible: plasmoid.formFactor === PlasmaCore.Types.Vertical
            text: i18nc("@info", "A text label cannot be set when the Panel is vertical.")
            wrapMode: Text.Wrap
            font: Kirigami.Theme.smallFont
        }

        Item {
            Kirigami.FormData.isSection: true
        }
      
       /* ComboBox {
        id: menuPosition

        Kirigami.FormData.label: i18n("Menu Position:")

        model: [i18n("Left"), i18n("Center"), i18n("Right")]
        onActivated: cfg_menuPosition = currentIndex
        
        
    }*/
        Item {
            Kirigami.FormData.isSection: true
        }
        
        RadioButton {
            id: showFavoritesInGrid
            Kirigami.FormData.label: i18n("Show favorites:")
            text: i18nc("Part of a sentence: 'Show favorites in a grid'", "In a grid")
            ButtonGroup.group: favoritesDisplayGroup
            property int index: 0
            checked: plasmoid.configuration.favoritesDisplay == index
        }

        RadioButton {
            id: showFavoritesInList
            text: i18nc("Part of a sentence: 'Show favorites in a list'", "In a list")
            ButtonGroup.group: favoritesDisplayGroup
            property int index: 1
            checked: plasmoid.configuration.favoritesDisplay == index
        }
        
        Item {
            Kirigami.FormData.isSection: true
        }
        
        RadioButton {
            id: showAppsInGrid
            Kirigami.FormData.label: i18n("Show other applications:")
            text: i18nc("Part of a sentence: 'Show other applications in a grid'", "In a grid")
            ButtonGroup.group: applicationsDisplayGroup
            property int index: 0
            checked: plasmoid.configuration.applicationsDisplay == index
        }

        RadioButton {
            id: showAppsInList
            text: i18nc("Part of a sentence: 'Show other applications in a list'", "In a list")
            ButtonGroup.group: applicationsDisplayGroup
            property int index: 1
            checked: plasmoid.configuration.applicationsDisplay == index
        }
        
        Item {
            Kirigami.FormData.isSection: true
        }
        
        RadioButton {
            id: showSystemInGrid
            Kirigami.FormData.label: i18n("Show system actions:")
            text: i18nc("Part of a sentence: 'Show system actions in a grid'", "In a grid")
            ButtonGroup.group: systemDisplayGroup
            property int index: 0
            checked: plasmoid.configuration.systemDisplay == index
        }

        RadioButton {
            id: showSystemInList
            text: i18nc("Part of a sentence: 'Show system actions in a list'", "In a list")
            ButtonGroup.group: systemDisplayGroup
            property int index: 1
            checked: plasmoid.configuration.systemDisplay == index
        }
        
        Item {
            Kirigami.FormData.isSection: true
        }

        RadioButton {
            id: powerActionsButton
            Kirigami.FormData.label: i18n("Show buttons for:")
            text: i18n("Power")
            ButtonGroup.group: radioGroup
            property string actions: "suspend,hibernate,reboot,shutdown"
            property int index: 0
            checked: plasmoid.configuration.primaryActions == index
        }

        RadioButton {
            id: sessionActionsButton
            text: i18n("Session")
            ButtonGroup.group: radioGroup
            property string actions: "lock-screen,logout,save-session"
            property int index: 1
            checked: plasmoid.configuration.primaryActions == index
        }
        
        RadioButton {
            id: shutdownButton
            text: i18n("Shutdown")
            ButtonGroup.group: radioGroup
            property string actions: "shutdown"
            property int index: 2
            checked: plasmoid.configuration.primaryActions == index
        }
        
        RadioButton {
            id: allActionsButton
            text: i18n("Power and session")
            ButtonGroup.group: radioGroup
            property string actions: "lock-screen,logout,save-session,switch-user,suspend,hibernate,reboot,shutdown"
            property int index: 3
            checked: plasmoid.configuration.primaryActions == index
        }
        
        Item {
            Kirigami.FormData.isSection: true
        }
        
        CheckBox {
            id: alphaSort
            Kirigami.FormData.label: i18nc("General options", "General:")
            text: i18n("Always sort applications alphabetically")
        }

        CheckBox {
            id: compactModeCheckbox
            text: i18n("Use compact categories style")
            checked: Kirigami.Settings.tabletMode ? true : plasmoid.configuration.compactMode
            enabled: !Kirigami.Settings.tabletMode
        }
        Label {
            visible: Kirigami.Settings.tabletMode
            text: i18nc("@info:usagetip under a checkbox when Touch Mode is on", "Automatically disabled when in Touch Mode")
            Layout.fillWidth: true
            wrapMode: Text.Wrap
            font: Kirigami.Theme.smallFont
        }

        CheckBox {
            id: showFavoritesCategory
            text: i18n("Show favorites category")
        }
        CheckBox {
            id: showAllAppscategory
            text: i18n("Show all apps category")
        }
        CheckBox {
            id: showCategoryIcons
            text: i18n("Show categories icons")
        }
        CheckBox {
            id: showAppsdescription
            text: i18n("Show apps description")
        }
        CheckBox {
            id: showSettingsButton
            text: i18n("Show menu settings button")
        }
        /*CheckBox {
            id: showRecentAppsCategory
            text: i18n("Show Recent applications category")
        } 
         CheckBox {
            id: showRecentDocsCategory
            text: i18n("Show Recent documents category")
        }*/
        CheckBox {
            id: showPinButton
            text: i18n("Show pin button")
        }
        CheckBox {
            id: showFullScreenButton
            text: i18n("Show fullscreen button")
            
        }
       
       CheckBox {
            id: showPowercategory
            text: i18n("Show power/session category")
        } 
       
        CheckBox {
            id: showPowerButton
            text: i18n("Show power/session button")
        }
        
        Button {
            enabled: KQuickAddons.KCMShell.authorize("kcm_plasmasearch.desktop").length > 0
            icon.name: "settings-configure"
            text: i18nc("@action:button", "Configure Enabled Search Plugins…")
            onClicked: KQuickAddons.KCMShell.openSystemSettings("kcm_plasmasearch")
        }

    ButtonGroup {
        id: favoritesDisplayGroup
        onCheckedButtonChanged: {
            if (checkedButton) {
                cfg_favoritesDisplay = checkedButton.index
            }
        }
    }

    ButtonGroup {
        id: applicationsDisplayGroup
        onCheckedButtonChanged: {
            if (checkedButton) {
                cfg_applicationsDisplay = checkedButton.index
            }
        }
    }
    
    ButtonGroup {
        id: systemDisplayGroup
        onCheckedButtonChanged: {
            if (checkedButton) {
                cfg_systemDisplay = checkedButton.index
            }
        }
    }


    ButtonGroup {
        id: radioGroup
        onCheckedButtonChanged: {
            if (checkedButton) {
                cfg_primaryActions = checkedButton.index
                cfg_systemFavorites = checkedButton.actions
            }
        }
    }

    Item {
        Layout.fillHeight: true
    }
  }
}
