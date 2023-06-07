/*
    SPDX-FileCopyrightText: 2011 Martin Gräßlin <mgraesslin@kde.org>
    SPDX-FileCopyrightText: 2012 Marco Martin <mart@kde.org>
    SPDX-FileCopyrightText: 2015-2018 Eike Hein <hein@kde.org>
    SPDX-FileCopyrightText: 2021 Mikel Johnson <mikel5764@gmail.com>
    SPDX-FileCopyrightText: 2021 Noah Davis <noahadvs@gmail.com>
    SPDX-FileCopyrightText: 2023 Douglas Guimarães <dg2003gh@gmail.com>

    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Templates 2.15 as T
import QtQml 2.15
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 3.0 as PC3
import org.kde.plasma.private.kicker 0.1 as Kicker

FocusScope {
    id: root
    property real preferredSideBarWidth: implicitSideBarWidth
    property real preferredSideBarHeight: implicitSideBarHeight

    property alias sideBarComponent: sideBarLoader.sourceComponent
    property alias sideBarItem: sideBarLoader.item
    property alias contentAreaComponent: contentAreaLoader.sourceComponent
    property alias contentAreaItem: contentAreaLoader.item

    property alias implicitSideBarWidth: sideBarLoader.implicitWidth
    property alias implicitSideBarHeight: sideBarLoader.implicitHeight

    implicitWidth: root.preferredSideBarWidth + separator.implicitWidth + contentAreaLoader.implicitWidth
    implicitHeight: Math.max(root.preferredSideBarHeight, contentAreaLoader.implicitHeight)
    
    Kicker.TriangleMouseFilter {
        id: sideBarFilter
        
        anchors {
            top: parent.top
            bottom: parent.bottom
        }
        
        states: [
             State {
                name: "reanchorToLeft" ; when: plasmoid.configuration.sidebarOnRight == false

                AnchorChanges {
                    target: sideBarFilter
                    anchors {
                        right: undefined
                        left: parent.left
                    }
                }
            },
            
            State {
                name: "reanchorToRight" ; when: plasmoid.configuration.sidebarOnRight == true

                AnchorChanges {
                    target: sideBarFilter
                    anchors {
                        right: parent.right
                        left: undefined
                    }
                }
            }
        ]
        
        implicitWidth: root.preferredSideBarWidth
        implicitHeight: root.preferredSideBarHeight
        edge: LayoutMirroring.enabled ? Qt.LeftEdge : Qt.RightEdge
        Loader {
            id: sideBarLoader
            anchors.fill: parent
            // backtab is implicitly set by the last button in Header.qml
            KeyNavigation.tab: root.contentAreaItem
            KeyNavigation.right: contentAreaLoader
            Keys.onUpPressed: plasmoid.rootItem.header.nextItemInFocusChain().forceActiveFocus(Qt.BacktabFocusReason)
            Keys.onDownPressed: plasmoid.rootItem.footer.tabBar.forceActiveFocus(Qt.TabFocusReason)
        }
    }
    PlasmaCore.SvgItem {
        id: separator
        visible: plasmoid.configuration.showSeparator
        anchors {
            top: parent.top
            bottom: parent.bottom
        }
        
        states: [
             State {
                name: "reanchorToLeft" ; when: plasmoid.configuration.sidebarOnRight == false

                AnchorChanges {
                    target: separator
                    anchors {
                        right: undefined
                        left: sideBarFilter.right
                    }
                }
            },
            
            State {
                name: "reanchorToRight" ; when: plasmoid.configuration.sidebarOnRight == true

                AnchorChanges {
                    target: separator
                    anchors {
                        right: sideBarFilter.left
                        left: undefined
                    }
                }
            }
        ]
        implicitWidth: naturalSize.width
        implicitHeight: implicitWidth
        elementId: "vertical-line"
        svg: KickoffSingleton.lineSvg
    }
    Loader {
        id: contentAreaLoader
        focus: true
        anchors {
            top: parent.top
            bottom: parent.bottom
        }
        
        states: [
             State {
                name: "reanchorToLeft" ; when: plasmoid.configuration.sidebarOnRight == false

                AnchorChanges {
                    target: contentAreaLoader
                    anchors {
                        right: parent.right
                        left: separator.left
                    }
                }
            },
            
            State {
                name: "reanchorToRight" ; when: plasmoid.configuration.sidebarOnRight == true

                AnchorChanges {
                    target: contentAreaLoader
                    anchors {
                        right: separator.right
                        left: parent.left
                    }
                }
            }
        ]
        KeyNavigation.backtab: root.sideBarItem
        KeyNavigation.left: sideBarLoader
        Keys.onUpPressed: plasmoid.rootItem.searchField.forceActiveFocus(Qt.BacktabFocusReason)
        Keys.onDownPressed: plasmoid.rootItem.footer.leaveButtons.nextItemInFocusChain().forceActiveFocus(Qt.TabFocusReason)
    }
    
}
