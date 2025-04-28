# TrackAsia App Structure

## Overview
This document outlines the organization of the TrackAsia demo iOS app code. The app has been refactored to follow a more modular, maintainable structure using SwiftUI best practices.

## Directory Structure

### Models
- **SearchAddressModel.swift** - Model for address search results
- **Toast.swift** - Model for toast notifications

### ViewModels
- **ContentViewModel.swift** - Main view model for ContentView
- **ContentViewCountrySettings.swift** - View model for country settings

### Views
- **ContentView.swift** - Main container view that orchestrates all other views

#### Components
- **AddressSearchView.swift** - Reusable component for address search input
- **BottomBarView.swift** - Tab bar at the bottom of the screen
- **TopBarView.swift** - Navigation bar at the top of the screen

#### Tabs (one view per tab)
- **MapSinglePointView.swift** - UI for Single Point tab
- **MapWayPointView.swift** - UI for Multi-Point tab
- **MapClusterView.swift** - UI for Clusters tab
- **MapAnimationView.swift** - UI for Animation tab
- **MapFeatureView.swift** - UI for Features tab
- **MapCompareView.swift** - UI for Compare tab

- **MapContainer.swift** - UIViewRepresentable wrapper for TrackAsia map

## Key Design Patterns

1. **MVVM Architecture** - Separation of UI (Views), business logic (ViewModels), and data (Models)
2. **Composition** - Complex UI broken into smaller, reusable components
3. **Dependency Injection** - ViewModels passed down to views that need them
4. **State Management** - Using @StateObject, @ObservedObject, and @Binding appropriately
5. **TabViewPattern** - Custom implementation for better control of map state

## Benefits of This Structure

1. **Maintainability** - Smaller, focused files are easier to understand and modify
2. **Reusability** - Components can be reused across the app
3. **Testability** - Separated concerns make unit testing easier
4. **Scalability** - New features can be added without modifying existing code
5. **Collaboration** - Multiple developers can work on different views simultaneously 