/*
 * SPDX-FileCopyrightText: 2021 Noah Davis <noahadvs@gmail.com>
 * SPDX-License-Identifier: LGPL-2.0-or-later
*/

import QtQuick 2.15
import QtQuick.Templates 2.15 as T
import QtQml 2.15
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 3.0 as PC3

EmptyPage {
    id: root
 
    property real preferredSideBarWidth: 200

    contentItem: HorizontalStackView {
        id: stackView
        focus: true
        reverseTransitions: currentIndex === 1
        initialItem: ApplicationsPage {
            id: applicationsPage
            preferredSideBarWidth: root.preferredSideBarWidth + plasmoid.rootItem.backgroundMetrics.leftPadding
        }
        }
        // Eat down events to prevent them from reaching the contentArea or searchField
        Keys.onDownPressed: {}
    }
