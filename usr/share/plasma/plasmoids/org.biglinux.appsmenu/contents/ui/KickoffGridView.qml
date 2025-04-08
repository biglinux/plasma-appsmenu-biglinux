/*
    SPDX-FileCopyrightText: 2015 Eike Hein <hein@kde.org>
    SPDX-FileCopyrightText: 2021 Mikel Johnson <mikel5764@gmail.com>
    SPDX-FileCopyrightText: 2021 Noah Davis <noahadvs@gmail.com>

    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick 2.15
import QtQml 2.15

import org.kde.plasma.components 3.0 as PC3
import org.kde.plasma.extras as PlasmaExtras

import org.kde.ksvg 1.0 as KSvg
import org.kde.kirigami 2.20 as Kirigami

// ScrollView makes it difficult to control implicit size using the contentItem.
// Using EmptyPage instead.
EmptyPage {
    id: root
    property alias model: view.model
    property alias count: view.count
    property alias currentIndex: view.currentIndex
    property alias currentItem: view.currentItem
    property alias delegate: view.delegate
    property alias blockTargetWheel: wheelHandler.blockTargetWheel
    property alias view: view

    clip: view.height < view.contentHeight

    header: MouseArea {
        implicitHeight: KickoffSingleton.listItemMetrics.margins.top
        hoverEnabled: true
        onEntered: {
            if (containsMouse) {
                let targetIndex = view.indexAt(mouseX + view.contentX, view.contentY)
                if (targetIndex >= 0) {
                    view.currentIndex = targetIndex
                    view.forceActiveFocus(Qt.MouseFocusReason)
                }
            }
        }
    }

    footer: MouseArea {
        implicitHeight: KickoffSingleton.listItemMetrics.margins.bottom
        hoverEnabled: true
        onEntered: {
            if (containsMouse) {
                let targetIndex = view.indexAt(mouseX + view.contentX, view.height + view.contentY - 1)
                if (targetIndex >= 0) {
                    view.currentIndex = targetIndex
                    view.forceActiveFocus(Qt.MouseFocusReason)
                }
            }
        }
    }

    /* Not setting GridView as the contentItem because GridView has no way to
     * set horizontal alignment. I don't want to use leftPadding/rightPadding
     * for that because I'd have to change the implicitWidth formula and use a
     * more complicated calculation to get the correct padding.
     */
    GridView {
        id: view
        readonly property real availableWidth: width - leftMargin - rightMargin
        readonly property real availableHeight: height - topMargin - bottomMargin
        readonly property int columns: Math.floor(availableWidth / cellWidth)
        // Removed the rows property completely
        property bool movedWithKeyboard: false
        property bool movedWithWheel: false

        // NOTE: parent is the contentItem that Control subclasses automatically
        // create when no contentItem is set, but content is added.
        height: parent.height
        // There are lots of ways to try to center the content of a GridView
        // and many of them have bad visual flaws. This way works pretty well.
        // Not center aligning when there might be a scrollbar to keep click target positions consistent.
        anchors.horizontalCenter: kickoff.mayHaveGridWithScrollBar ? undefined : parent.horizontalCenter
        anchors.horizontalCenterOffset: if (kickoff.mayHaveGridWithScrollBar) {
            if (root.mirrored) {
                return verticalScrollBar.implicitWidth/2
            } else {
                return -verticalScrollBar.implicitWidth/2
            }
        } else {
            return 0
        }
        width: Math.min(parent.width, Math.floor((parent.width - leftMargin - rightMargin - (kickoff.mayHaveGridWithScrollBar ? verticalScrollBar.implicitWidth : 0)) / cellWidth) * cellWidth + leftMargin + rightMargin)

        // Remove the binding and set an initial empty value
        Accessible.description: ""
        
        // Only update description on initial load and when columns change to avoid binding loop
        Component.onCompleted: updateAccessibilityDescription()
        onColumnsChanged: updateAccessibilityDescription()
        
        // Function to update accessibility description without creating a binding
        function updateAccessibilityDescription() {
            // Calculate row count directly here instead of relying on availableHeight change
            var rowCount = Math.floor((height - topMargin - bottomMargin) / cellHeight);
            Accessible.description = i18n("Grid with %1 rows, %2 columns", rowCount, columns);
        }

        implicitWidth: {
            let w = view.cellWidth * 2 + leftMargin + rightMargin + 2
            if (kickoff.mayHaveGridWithScrollBar) {
                w += verticalScrollBar.implicitWidth
            }
            return w
        }
        implicitHeight: view.cellHeight * kickoff.minimumGridRowCount + topMargin + bottomMargin

        leftMargin: 0
        rightMargin: 0

        cellHeight: KickoffSingleton.gridCellSize
        cellWidth: KickoffSingleton.gridCellSize * 1.8

        currentIndex: count > 0 ? 0 : -1
        focus: true
        interactive: height < contentHeight
        pixelAligned: true
        reuseItems: true
        boundsBehavior: Flickable.StopAtBounds
        // default keyboard navigation doesn't allow focus reasons to be used
        // and eats up/down key events when at the beginning or end of the list.
        keyNavigationEnabled: false
        keyNavigationWraps: false

        highlightMoveDuration: 0
        highlight: PlasmaExtras.Highlight {
            // The default Z value for delegates is 1. The default Z value for the section delegate is 2.
            // The highlight gets a value of 3 while the drag is active and then goes back to the default value of 0.
            z: root.currentItem && root.currentItem.Drag.active ?
                3 : 0
            pressed: view.currentItem && view.currentItem.isPressed
            active: view.activeFocus
                || (kickoff.contentArea === root
                    && kickoff.searchField.activeFocus)
            width: view.cellWidth
            height: view.cellHeight
        }

        delegate: KickoffGridDelegate {
            id: itemDelegate
            width: view.cellWidth
            Accessible.role: Accessible.Cell
        }

        move: normalTransition
        moveDisplaced: normalTransition

        Transition {
            id: normalTransition
            NumberAnimation {
                duration: Kirigami.Units.shortDuration
                properties: "x, y"
                easing.type: Easing.OutCubic
            }
        }

        PC3.ScrollBar.vertical: PC3.ScrollBar {
            id: verticalScrollBar
            parent: root
            z: 2
            height: root.height
            anchors.right: parent.right
        }

        Kirigami.WheelHandler {
            id: wheelHandler
            target: view
            filterMouseEvents: true
            
            // Simplified wheel handling with fixed step sizes instead of calculated ones
            horizontalStepSize: 60  // Fixed value instead of calculation
            verticalStepSize: 60    // Fixed value instead of calculation

            // Simplified wheel handler that doesn't update state variables on every event
            onWheel: wheel => {
                // Only set state flags once per batch of wheel events
                if (!view.movedWithWheel) {
                    view.movedWithWheel = true
                    view.movedWithKeyboard = false
                    // Use a single restart call instead of setting variables and then restarting
                    movedWithWheelTimer.restart()
                }
            }
        }

        // Optimize connection by reducing the work done
        Connections {
            target: kickoff
            function onExpandedChanged() {
                if (kickoff.expanded) {
                    // Set index first, then position view (more efficient)
                    view.currentIndex = 0
                    // Use immediate positioning without animation
                    view.cancelFlick()
                    view.contentY = 0
                }
            }
        }

        // Combine timers to reduce overhead
        Timer {
            id: movedWithKeyboardTimer
            interval: 200
            onTriggered: {
                // Handle both states in one timer to reduce overhead
                view.movedWithKeyboard = false
                view.movedWithWheel = false
            }
        }

        // Remove redundant timer
        property alias movedWithWheelTimer: movedWithKeyboardTimer

        // Simplified focus function that doesn't require event parameter checking
        function focusCurrentItem(reason) {
            if (view.currentItem) {
                view.currentItem.forceActiveFocus(reason)
                return true
            }
            return false
        }

        // Optimize menu handling to avoid redundant checks
        Keys.onMenuPressed: event => {
            if (currentItem) {
                currentItem.forceActiveFocus(Qt.ShortcutFocusReason)
                currentItem.openActionMenu()
                event.accepted = true
            }
        }

        // Optimize keyboard navigation with simplified and cached calculations
        Keys.onPressed: event => {
            // Skip processing if there's no meaningful navigation possible
            if (count <= 1) {
                return
            }

            // Cache calculations to avoid recomputing them multiple times
            const col = currentIndex % columns
            const isRightToLeft = Qt.application.layoutDirection === Qt.RightToLeft
            const atLeft = isRightToLeft ? (col === columns - 1) : (col === 0)
            const atRight = isRightToLeft ? (col === 0) : (col === columns - 1)
            const atTop = currentIndex < columns
            const atBottom = currentIndex >= count - columns

            // Use simple flags to track what was accepted
            let accepted = true
            let reason = Qt.TabFocusReason
            let newIndex = -1

            switch (event.key) {
                // Left movement - simplified
                case Qt.Key_Left:
                case Qt.Key_H:
                    if (!atLeft && (!kickoff.searchField.activeFocus || 
                        (event.key === Qt.Key_H && event.modifiers & Qt.ControlModifier))) {
                        newIndex = currentIndex - 1
                        reason = Qt.BacktabFocusReason
                    } else {
                        accepted = false
                    }
                    break

                // Up movement - simplified
                case Qt.Key_Up:
                case Qt.Key_K:
                    if (!atTop && (event.key !== Qt.Key_K || event.modifiers & Qt.ControlModifier)) {
                        newIndex = currentIndex - columns
                        reason = Qt.BacktabFocusReason
                    } else {
                        accepted = false
                    }
                    break

                // Right movement - simplified
                case Qt.Key_Right:
                case Qt.Key_L:
                    if (!atRight && (!kickoff.searchField.activeFocus ||
                        (event.key === Qt.Key_L && event.modifiers & Qt.ControlModifier))) {
                        newIndex = currentIndex + 1
                    } else {
                        accepted = false
                    }
                    break

                // Down movement - simplified
                case Qt.Key_Down:
                case Qt.Key_J:
                    if (!atBottom && (event.key !== Qt.Key_J || event.modifiers & Qt.ControlModifier)) {
                        newIndex = currentIndex + columns
                    } else {
                        accepted = false
                    }
                    break

                // Home/End/Page navigation optimized to avoid complex calculations
                case Qt.Key_Home:
                    if (event.modifiers === Qt.ControlModifier) {
                        newIndex = 0
                        reason = Qt.BacktabFocusReason
                    } else {
                        newIndex = currentIndex - col
                        reason = Qt.BacktabFocusReason
                    }
                    break

                case Qt.Key_End:
                    if (event.modifiers === Qt.ControlModifier) {
                        newIndex = count - 1
                    } else {
                        newIndex = currentIndex + (columns - 1 - col)
                    }
                    break

                // Page navigation without complex index calculations
                case Qt.Key_PageUp:
                    if (!atTop) {
                        newIndex = Math.max(0, currentIndex - (Math.floor(height / cellHeight) * columns))
                        reason = Qt.BacktabFocusReason
                    } else {
                        accepted = false
                    }
                    break

                case Qt.Key_PageDown:
                    if (!atBottom) {
                        newIndex = Math.min(count - 1, currentIndex + (Math.floor(height / cellHeight) * columns))
                    } else {
                        accepted = false
                    }
                    break

                default:
                    accepted = false
            }

            // Apply the new index if navigation was successful
            if (accepted && newIndex >= 0) {
                currentIndex = Math.min(count - 1, Math.max(0, newIndex))
                if (currentItem) {
                    currentItem.forceActiveFocus(reason)
                    event.accepted = true
                    
                    // Update the keyboard movement state once instead of per-key
                    view.movedWithKeyboard = true
                    view.movedWithWheel = false
                    movedWithKeyboardTimer.restart()
                    
                    // Ensure the item is visible
                    view.positionViewAtIndex(currentIndex, GridView.Contain)
                }
            }
        }
    }
}
