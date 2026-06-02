# Bugfix Requirements Document

## Introduction

The Nearby Discovery screen (`nearby_discovery_screen.dart`) is supposed to show a map of the user's surroundings with nearby neighbors/activities plotted on it. Instead, the map area renders a static placeholder gradient `Container` (height `160.h`) labeled "Map / Discovery Card", and the "Center on me" button inside it has an empty `onPressed: () {}` handler that does nothing.

As a result, users never see an actual map anywhere a map is required in the discovery flow, they cannot visualize where nearby neighbors are relative to themselves, and the "Center on me" control is non-functional.

This fix replaces the placeholder with a real OpenStreetMap-backed map (rendered via the `flutter_map` package using OpenStreetMap tile layers), centers it on the user's resolved current location, plots nearby neighbors as markers, and wires up the "Center on me" button to recenter the map on the user. The same OpenStreetMap-backed map must be used wherever a map is required to be shown.

The bug condition is triggered whenever the discovery screen needs to display a map: the location is already resolved (via Geolocator, with the existing New Delhi fallback at `lng 77.2090, lat 28.6139`), but no real map is rendered.

## Bug Analysis

### Current Behavior (Defect)

When the user opens the Nearby Discovery screen, the area reserved for the map does not display a map and the map control does not work.

1.1 WHEN the Nearby Discovery screen is displayed THEN the system renders a static placeholder gradient `Container` in the map area instead of an actual map

1.2 WHEN the user's current location has been resolved (or the fallback location is used) THEN the system does NOT display any map centered on that location

1.3 WHEN nearby neighbors are loaded into `NearbyDiscoveryState` THEN the system does NOT plot any neighbor positions on a map

1.4 WHEN the user taps the "Center on me" button THEN the system does nothing because `onPressed` is an empty callback

1.5 WHEN any other screen in the discovery flow requires a map to be shown THEN the system does NOT render an OpenStreetMap-backed map

### Expected Behavior (Correct)

When the user opens the Nearby Discovery screen, a real OpenStreetMap map is shown, centered on the user, with neighbors plotted and a working recenter control.

2.1 WHEN the Nearby Discovery screen is displayed THEN the system SHALL render an OpenStreetMap-backed map (via `flutter_map` with OpenStreetMap tile layers) in the map area instead of the placeholder gradient

2.2 WHEN the user's current location has been resolved (or the fallback location is used) THEN the system SHALL center the map on that location

2.3 WHEN nearby neighbors are loaded into `NearbyDiscoveryState` THEN the system SHALL plot each neighbor that has valid coordinates as a marker on the map

2.4 WHEN the user taps the "Center on me" button THEN the system SHALL recenter the map on the user's current location

2.5 WHEN any other screen in the discovery flow requires a map to be shown THEN the system SHALL render an OpenStreetMap-backed map using the same approach

### Unchanged Behavior (Regression Prevention)

Existing discovery behavior unrelated to map rendering must continue to work exactly as before.

3.1 WHEN the Nearby Discovery screen loads THEN the system SHALL CONTINUE TO resolve the user's location via `LocationService.getCurrentPosition()` and fall back to New Delhi (`lng 77.2090, lat 28.6139`) when location resolution fails

3.2 WHEN the location is resolved THEN the system SHALL CONTINUE TO dispatch `LoadNearbyNeighbors(lng, lat)` to `NearbyDiscoveryBloc` (and the existing `LoadNearbyPostsRequested` / `LoadNearbyPromotions` events)

3.3 WHEN a filter tab (People, Activities, Business, Events, Society) is selected THEN the system SHALL CONTINUE TO display the corresponding list content below the map area

3.4 WHEN the People list is shown and the user taps "Say hi" on a neighbor THEN the system SHALL CONTINUE TO dispatch `SayHiToNeighbor` and show the existing toast feedback

3.5 WHEN neighbors, activities, or promotions are loading or empty THEN the system SHALL CONTINUE TO show the existing loading indicators and empty-state messages
