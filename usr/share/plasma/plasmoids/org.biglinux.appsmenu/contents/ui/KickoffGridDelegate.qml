/*
    SPDX-FileCopyrightText: 2011 Martin *Gräßlin <mgraesslin@kde.org>
    SPDX-FileCopyrightText: 2012 Gregor Taetzner <gregor@freenet.de>
    SPDX-FileCopyrightText: 2014 Sebastian Kügler <sebas@kde.org>
    SPDX-FileCopyrightText: 2015-2018 Eike Hein <hein@kde.org>
    SPDX-FileCopyrightText: 2021 Mikel Johnson <mikel5764@gmail.com>
    SPDX-FileCopyrightText: 2021 Noah Davis <noahadvs@gmail.com>
    SPDX-FileCopyrightText: 2022 Nate Graham <nate@kde.org>

    SPDX-License-Identifier: GPL-2.0-or-later
 */
import QtQuick 2.15
import QtQml 2.15
import QtQuick.Layouts 1.15
import org.kde.plasma.components 3.0 as PC3
import org.kde.kirigami 2.20 as Kirigami

AbstractKickoffItemDelegate {
    id: root

    // Use fixed values instead of margins reference to reduce property bindings
    leftPadding: 6  // Hardcoded value based on typical KickoffSingleton.listItemMetrics.margins.left
    rightPadding: 6 // Hardcoded value based on typical KickoffSingleton.listItemMetrics.margins.right
    topPadding: Kirigami.Units.smallSpacing * 2
    bottomPadding: Kirigami.Units.smallSpacing * 2

    icon.width: Kirigami.Units.iconSizes.large
    icon.height: Kirigami.Units.iconSizes.large

    // Only update when label actually changes instead of constantly evaluating
    property bool _labelWasTruncated: false
    onTextChanged: {
        // Defer evaluation until layout is complete
        Qt.callLater(function() {
            _labelWasTruncated = label.truncated;
            labelTruncated = _labelWasTruncated;
        });
    }
    
    // Fixed to false instead of binding
    descriptionVisible: false

    dragIconItem: iconItem

    // Cache the icon source to avoid recomputing it on every render
    property string _cachedIconSource: ""
    Component.onCompleted: {
        updateIconSource();
    }
    onDecorationChanged: updateIconSource()
    onIconChanged: updateIconSource()
    
    function updateIconSource() {
        _cachedIconSource = root.decoration || root.icon.name || root.icon.source;
    }

    contentItem: Item {
        implicitHeight: iconItem.height + label.height + root.spacing
        
        Kirigami.Icon {
            id: iconItem
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            width: root.icon.width
            height: root.icon.height
            
            animated: false
            selected: root.iconAndLabelsShouldlookSelected
            source: root._cachedIconSource
        }

        PC3.Label {
            id: label
            anchors.top: iconItem.bottom
            anchors.topMargin: root.spacing
            anchors.left: parent.left
            anchors.right: parent.right
            height: implicitHeight * (lineCount === 1 ? 2 : 1)
            
            text: root.text
            textFormat: Text.PlainText
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignTop
            maximumLineCount: 2
            wrapMode: Text.Wrap
            color: root.iconAndLabelsShouldlookSelected ? Kirigami.Theme.highlightedTextColor : Kirigami.Theme.textColor
        }
    }
}
