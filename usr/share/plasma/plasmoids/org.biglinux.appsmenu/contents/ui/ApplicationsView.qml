/*
    Copyright (C) 2011  Martin Gräßlin <mgraesslin@kde.org>
    Copyright (C) 2012 Marco Martin <mart@kde.org>
    Copyright 2014 Sebastian Kügler <sebas@kde.org>
    Copyright (C) 2015-2018  Eike Hein <hein@kde.org>
    Copyright (C) 2016 Jonathan Liu <net147@gmail.com>
    Copyright (C) 2016 Kai Uwe Broulik <kde@privat.broulik.de>
    Copyright (C) 2021 by Mikel Johnson <mikel5764@gmail.com>

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License along
    with this program; if not, write to the Free Software Foundation, Inc.,
    51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
*/
import QtQuick 2.0
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 3.0 as PlasmaComponents3

FocusScope {
    id: appViewContainer
    property QtObject activatedSection: null
    property string rootBreadcrumbName: ""
    signal appModelChange()
    onAppModelChange: {
        if (activatedSection != null) {
            applicationsView.gridView.model = activatedSection;
        }
    }

    objectName: "ApplicationsGridView"

    property GridView gridView: applicationsView.gridView

    function keyNavLeft() { return applicationsView.keyNavLeft() }
    function keyNavRight() { return applicationsView.keyNavRight() }
    function keyNavUp() { return applicationsView.keyNavUp() }
    function keyNavDown() { return applicationsView.keyNavDown() }

    function activateCurrentIndex() {
        applicationsView.currentItem.activate();
    }

    function openContextMenu() {
        applicationsView.currentItem.openActionMenu();
    }

    function reset() {
        applicationsView.model = activatedSection;
        if (applicationsView.model == null) {
            applicationsView.currentIndex = -1
        } else {
            applicationsView.currentIndex = 0
        }
    }

    function refreshed() {
        reset();
        updatedLabelTimer.running = true;
    }

    // QQuickItem::isAncestorOf is not invokable...
    function isChildOf(item, parent) {
        if (!item || !parent) {
            return false;
        }

        if (item.parent === parent) {
            return true;
        }

        return isChildOf(item, item.parent);
    }
    DropArea {
        anchors.fill: parent
        enabled: plasmoid.immutability !== PlasmaCore.Types.SystemImmutable

        function syncTarget(drag) {
            if (applicationsView.animating) {
                return;
            }

            var pos = mapToItem(gridView.contentItem, drag.x, drag.y);
            var above = gridView.itemAt(pos.x, pos.y);

            var source = kickoff.dragSource;

            if (above && above !== source && isChildOf(source, applicationsView)) {
                applicationsView.model.moveRow(source.itemIndex, above.itemIndex);
                // itemIndex changes directly after moving,
                // we can just set the currentIndex to it then.
                applicationsView.currentIndex = source.itemIndex;
            }
        }

        onPositionChanged: syncTarget(drag)
        onEntered: syncTarget(drag)
    }

    Transition {
        id: moveTransition
        SequentialAnimation {
            PropertyAction { target: applicationsView; property: "animating"; value: true }

            NumberAnimation {
                duration: applicationsView.animationDuration
                properties: "x, y"
                easing.type: Easing.OutQuad
            }

            PropertyAction { target: applicationsView; property: "animating"; value: false }
        }
    }

    Connections {
        target: plasmoid
        function onExpandedChanged() {
            if (!plasmoid.expanded) {
                applicationsView.currentIndex = 0;
            }
        }
    }

    KickoffGridView {
        id: applicationsView

        anchors.fill: parent

        property bool animating: false
        property int animationDuration: resetAnimationDurationTimer.interval
        focus: true

        interactive: contentHeight > height

        move: moveTransition
        moveDisplaced: moveTransition

        onCountChanged: {
            animationDuration = 0;
            resetAnimationDurationTimer.start();
        }
    }

    Timer {
        id: resetAnimationDurationTimer

        // We don't want drag animation to be affected by "Animation speed" setting cause this is an active interaction (we want this enabled even for those who disabled animations)
        // In other words: it's not a passive animation it should (roughly) follow the drag
        interval: 150

        onTriggered: applicationsView.animationDuration = interval - 20
    }

    // Displays text when application list gets updated
    Timer {
        id: updatedLabelTimer
        // We want to have enough time to show that applications have been updated even for those who disabled animations
        interval: 1500
        running: false
        repeat: true

        onRunningChanged: {
            if (running) {
                updatedLabel.opacity = 1;
                applicationsView.gridView.opacity = 0.3;
            }
        }
        onTriggered: {
            updatedLabel.opacity = 0;
            applicationsView.gridView.opacity = 1;
            running = false;
        }
    }

    PlasmaComponents3.Label {
        id: updatedLabel
        text: i18n("Applications updated.")
        opacity: 0
        visible: opacity != 0
        anchors.centerIn: parent

        Behavior on opacity {
            NumberAnimation {
                duration: PlasmaCore.Units.shortDuration
                easing.type: Easing.InOutQuad
            }
        }
    }

    Component.onCompleted: {
        rootModel.cleared.connect(refreshed);
    }

}
