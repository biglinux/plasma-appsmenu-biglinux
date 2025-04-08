/*
 * SPDX-FileCopyrightText: 2021 Noah Davis <noahadvs@gmail.com>
 * SPDX-License-Identifier: LGPL-2.0-or-later
 */

import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Templates 2.15 as T
import QtQml 2.15
import org.kde.plasma.private.kicker 0.1 as Kicker
import org.kde.kirigami 2.20 as Kirigami
import org.kde.plasma.plasmoid 2.0

BasePage {
    id: root
    sideBarComponent: KickoffListView {
        id: sideBar
        focus: true // needed for Loaders
        model: kickoff.rootModel
        // needed otherwise app displayed at top-level will show a first character as group.
        section.property: ""
        delegate: KickoffListDelegate {
            width: view.availableWidth
            isCategoryListItem: true
        }
    }
    contentAreaComponent: VerticalStackView {
        id: stackView

        // Add back the property declaration
        property bool isChangingCategory: false

        // Completely remove animations by setting all transitions to null
        popEnter: null
        pushEnter: null
        popExit: null
        pushExit: null

        // Disable movement transitions by default to speed up category switching
        movementTransitionsEnabled: false

        readonly property string preferredFavoritesViewObjectName: Plasmoid.configuration.favoritesDisplay === 0 ? "favoritesGridView" : "favoritesListView"
        readonly property Component preferredFavoritesViewComponent: Plasmoid.configuration.favoritesDisplay === 0 ? favoritesGridViewComponent : favoritesListViewComponent
        readonly property string preferredAllAppsViewObjectName: Plasmoid.configuration.applicationsDisplay === 0 ? "listOfGridsView" : "applicationsListView"
        readonly property Component preferredAllAppsViewComponent: Plasmoid.configuration.applicationsDisplay === 0 ? listOfGridsViewComponent : applicationsListViewComponent

        readonly property string preferredAppsViewObjectName: Plasmoid.configuration.applicationsDisplay === 0 ? "applicationsGridView" : "applicationsListView"
        readonly property Component preferredAppsViewComponent: Plasmoid.configuration.applicationsDisplay === 0 ? applicationsGridViewComponent : applicationsListViewComponent
        // NOTE: The 0 index modelForRow isn't supposed to be used. That's just how it works.
        // But to trigger model data update, set initial value to 0
        property int appsModelRow: 0
        readonly property Kicker.AppsModel appsModel: kickoff.rootModel.modelForRow(appsModelRow)
        focus: true
        initialItem: getOrCreateView("favorites")
        
        // Store view instances to avoid recreation
        property var viewCache: ({})

        // Function to get an existing view or create one if needed
        function getOrCreateView(viewType) {
            if (viewCache[viewType]) {
                return viewCache[viewType];
            }
            
            var component, view;
            switch(viewType) {
                case "favorites":
                    component = Plasmoid.configuration.favoritesDisplay === 0 ? 
                        favoritesGridViewComponent : favoritesListViewComponent;
                    break;
                case "allApps":
                    component = Plasmoid.configuration.applicationsDisplay === 0 ? 
                        listOfGridsViewComponent : applicationsListViewComponent;
                    break;
                case "categoryApps":
                    component = Plasmoid.configuration.applicationsDisplay === 0 ? 
                        applicationsGridViewComponent : applicationsListViewComponent;
                    break;
                default:
                    component = favoritesListViewComponent;
            }
            
            view = component.createObject(stackView);
            viewCache[viewType] = view;
            return view;
        }

        Component {
            id: favoritesListViewComponent
            DropAreaListView {
                id: favoritesListView
                objectName: "favoritesListView"
                mainContentView: true
                focus: true
                model: kickoff.rootModel.favoritesModel
            }
        }

        Component {
            id: favoritesGridViewComponent
            DropAreaGridView {
                id: favoritesGridView
                objectName: "favoritesGridView"
                focus: true
                model: kickoff.rootModel.favoritesModel
            }
        }

        Component {
            id: applicationsListViewComponent

            KickoffListView {
                id: applicationsListView
                objectName: "applicationsListView"
                mainContentView: true
                model: stackView.appsModel
                section.property: model && model.description === "KICKER_ALL_MODEL" ? "group" : ""
                section.criteria: ViewSection.FirstCharacter
                hasSectionView: stackView.appsModelRow === 1

                onShowSectionViewRequested: sectionName => {
                    stackView.push(applicationsSectionViewComponent, {
                        "currentSection": sectionName,
                        "parentView": applicationsListView
                    });
                }
            }
        }

        Component {
            id: applicationsSectionViewComponent

            SectionView {
                id: sectionView
                model: stackView.appsModel.sections

                onHideSectionViewRequested: index => {
                    stackView.pop();
                    stackView.currentItem.view.positionViewAtIndex(index, ListView.Beginning);
                    stackView.currentItem.currentIndex = index;
                }
            }
        }

        Component {
            id: applicationsGridViewComponent
            KickoffGridView {
                id: applicationsGridView
                objectName: "applicationsGridView"
                model: stackView.appsModel
            }
        }

        Component {
            id: listOfGridsViewComponent

            ListOfGridsView {
                id: listOfGridsView
                objectName: "listOfGridsView"
                mainContentView: true
                gridModel: stackView.appsModel

                onShowSectionViewRequested: sectionName => {
                    stackView.push(applicationsSectionViewComponent, {
                        currentSection: sectionName,
                        parentView: listOfGridsView
                    });
                }
            }
        }

        Connections {
            target: root.sideBarItem
            function onCurrentIndexChanged() {
                // Flag that we're changing categories to disable animations
                stackView.isChangingCategory = true;
                
                // Only update row index if the condition is met.
                if (root.sideBarItem.currentIndex > 0) {
                    appsModelRow = root.sideBarItem.currentIndex
                }
                
                // Use the view cache to switch views without recreating them
                if (root.sideBarItem.currentIndex === 0) {
                    var favoritesView = getOrCreateView("favorites");
                    if (stackView.currentItem !== favoritesView) {
                        stackView.replace(favoritesView);
                    }
                } else if (root.sideBarItem.currentIndex === 1) {
                    var allAppsView = getOrCreateView("allApps");
                    if (stackView.currentItem !== allAppsView) {
                        stackView.replace(allAppsView);
                    }
                } else if (root.sideBarItem.currentIndex > 1) {
                    var categoryView = getOrCreateView("categoryApps");
                    // Update the model of the existing view instead of creating a new one
                    if (stackView.currentItem !== categoryView) {
                        stackView.replace(categoryView);
                    }
                }
                
                // Reset the flag after a short delay (to ensure animation skip completes)
                Qt.callLater(function() {
                    stackView.isChangingCategory = false;
                });
            }
        }
        Connections {
            target: kickoff
            function onExpandedChanged() {
                if (kickoff.expanded) {
                    kickoff.contentArea.currentItem.forceActiveFocus()
                }
            }
        }

        onPreferredFavoritesViewComponentChanged: {
            stackView.isChangingCategory = true;
            
            // Clear the cache to force creation of new views with updated components
            if (viewCache["favorites"]) {
                viewCache["favorites"].destroy();
                delete viewCache["favorites"];
            }
            
            if (root.sideBarItem && root.sideBarItem.currentIndex === 0) {
                stackView.replace(getOrCreateView("favorites"));
            }

            Qt.callLater(function() {
                stackView.isChangingCategory = false;
            });
        }
        onPreferredAllAppsViewComponentChanged: {
            stackView.isChangingCategory = true;
            
            if (viewCache["allApps"]) {
                viewCache["allApps"].destroy();
                delete viewCache["allApps"];
            }
            
            if (root.sideBarItem && root.sideBarItem.currentIndex === 1) {
                stackView.replace(getOrCreateView("allApps"));
            }

            Qt.callLater(function() {
                stackView.isChangingCategory = false;
            });
        }
        onPreferredAppsViewComponentChanged: {
            stackView.isChangingCategory = true;
            
            if (viewCache["categoryApps"]) {
                viewCache["categoryApps"].destroy();
                delete viewCache["categoryApps"];
            }
            
            if (root.sideBarItem && root.sideBarItem.currentIndex > 1) {
                stackView.replace(getOrCreateView("categoryApps"));
            }

            Qt.callLater(function() {
                stackView.isChangingCategory = false;
            });
        }
    }
    // NormalPage doesn't get destroyed when deactivated, so the binding uses
    // StackView.status and visible. This way the bindings are reset when
    // NormalPage is Activated again.
    Binding {
        target: kickoff
        property: "sideBar"
        value: root.sideBarItem
        when: root.T.StackView.status === T.StackView.Active && root.visible
        restoreMode: Binding.RestoreBinding
    }
    Binding {
        target: kickoff
        property: "contentArea"
        value: root.contentAreaItem.currentItem // NOT just root.contentAreaItem
        when: root.T.StackView.status === T.StackView.Active && root.visible
        restoreMode: Binding.RestoreBinding
    }
}
