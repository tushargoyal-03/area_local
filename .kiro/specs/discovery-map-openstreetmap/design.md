# Discovery Map (OpenStreetMap) Bugfix Design

## Overview

The Nearby Discovery screen (`lib/src/features/nearby_discovery/presentation/pages/nearby_discovery_screen.dart`) currently renders a static, gradient-filled placeholder `Container` (`height: 160.h`) where a map is supposed to appear, and the "Center on me" button inside it has an empty `onPressed: () {}` callback. No real map is ever shown, neighbors are never plotted geographically, and the recenter control is inert.

This fix replaces the placeholder with a real, OpenStreetMap-backed map rendered through the `flutter_map` package using OpenStreetMap raster tile layers (`latlong2` supplies the `LatLng` type). To satisfy the requirement that "the same OpenStreetMap-backed map must be used wherever a map is required," the map is extracted into a reusable shared widget (`AppMap`) under `lib/src/shared/widgets/`, exported through the existing `widgets.dart` barrel. The discovery screen consumes `AppMap`, centering it on the user's resolved location (with the existing New Delhi fallback at `lng 77.2090, lat 28.6139`), plotting nearby neighbors that have valid coordinates as markers, and wiring the "Center on me" button to a `MapController` to recenter on the user.

The fix is deliberately additive and scoped to the map area and dependency list. All existing discovery behavior — location resolution, bloc dispatch, tab content, the "Say hi" flow, and loading/empty states — is preserved unchanged.

A noted complication: `NearbyDiscoveryState.neighbors` is a `List<dynamic>` of maps with the keys currently consumed by the UI (`userId`, `displayName`, `distanceInKm`, `lookingFor`). The neighbor payload originates from the backend `users/nearby` endpoint via `UsersService.getNearbyUsers`, which returns the raw `data` list untouched. There is no confirmation in the client code that each neighbor carries coordinates. The design therefore treats neighbor coordinates as optional: markers are plotted only for neighbors that expose parseable coordinates, and neighbors without coordinates are skipped without error (the People list below is unaffected). This keeps the fix robust whether or not the backend includes `location`/`coordinates` per neighbor.

## Glossary

- **Bug_Condition (C)**: The condition that triggers the bug — the discovery screen needs to display a map (a location is resolved, or the fallback is in effect), but the map area renders the placeholder gradient `Container` instead of an actual map, and the "Center on me" control does nothing.
- **Property (P)**: The desired behavior — an OpenStreetMap-backed map is rendered in the map area, centered on the resolved (or fallback) location, with each coordinate-bearing neighbor plotted as a marker and a functional "Center on me" recenter control.
- **Preservation**: Existing discovery behavior unrelated to map rendering (location resolution, bloc dispatch, tab content, "Say hi", loading/empty states) that must remain unchanged by the fix.
- **AppMap**: The new reusable shared widget (`lib/src/shared/widgets/app_map.dart`) that wraps `flutter_map`'s `FlutterMap`, the OpenStreetMap `TileLayer`, a `MarkerLayer`, and the attribution layer. It is the single map component used wherever a map is required.
- **flutter_map**: The pub.dev mapping package that renders Leaflet-style tile maps in pure Flutter. Configured here with OpenStreetMap raster tiles.
- **latlong2**: The companion package providing the `LatLng` type used by `flutter_map` for coordinates.
- **MapController**: The `flutter_map` controller used to imperatively move/recenter the map; backs the "Center on me" button.
- **userAgentPackageName**: The `TileLayer` parameter required by OpenStreetMap's tile usage policy to identify the requesting application.
- **getCurrentPosition**: `LocationService.instance.getCurrentPosition()` in `lib/src/services/location_service.dart`; returns `FutureEither<Position>` and is the source of the user's location.
- **neighbors**: `NearbyDiscoveryState.neighbors` (`List<dynamic>`) in `lib/src/features/nearby_discovery/presentation/providers/nearby_discovery_bloc.dart`; maps with keys `userId`, `displayName`, `distanceInKm`, `lookingFor`, and (optionally, backend-dependent) coordinates.

## Bug Details

### Bug Condition

The bug manifests whenever the Nearby Discovery screen needs to display a map. The user's location is already resolved through `LocationService.getCurrentPosition()` (or the New Delhi fallback `lng 77.2090, lat 28.6139` is in effect), but the map area renders a placeholder gradient `Container` rather than an actual map. The `NearbyDiscoveryScreen` widget is failing to render a map, failing to center it on the resolved location, failing to plot neighbor markers, and failing to make the "Center on me" button recenter the map (its `onPressed` is an empty closure).

**Formal Specification:**
```
FUNCTION isBugCondition(input)
  INPUT: input of type DiscoveryMapRender
         { resolvedCenter: {lng, lat},      // from Geolocator or New Delhi fallback
           neighbors: List<NeighborData>,    // current NearbyDiscoveryState.neighbors
           centerOnMePressed: boolean }      // user tapped "Center on me"
  OUTPUT: boolean

  // A map is always required on this screen, and a center is always available
  // (real location or fallback), so the precondition always holds here.
  mapIsRequired := true
  centerAvailable := input.resolvedCenter != null

  RETURN mapIsRequired
         AND centerAvailable
         AND ( NOT realMapRendered()                       // placeholder shown instead of OSM map
               OR NOT mapCenteredOn(input.resolvedCenter)  // map not centered on resolved/fallback location
               OR NOT neighborMarkersPlotted(input.neighbors WHERE hasValidCoordinates)
               OR ( input.centerOnMePressed AND NOT mapRecenteredOnUser() ) )
END FUNCTION
```

### Examples

- **Map area on open** — Expected: an OpenStreetMap map fills the map card. Actual: a gradient `Container` with no tiles is shown.
- **Centering on resolved location** — Expected: with a real position resolved, the map is centered on the user's coordinates. Actual: no map exists to center.
- **Centering on fallback** — Expected: when Geolocator fails, the map centers on New Delhi (`lng 77.2090, lat 28.6139`). Actual: no map exists to center.
- **Neighbor markers** — Expected: each neighbor with valid coordinates appears as a marker at its position. Actual: no markers are rendered because there is no map.
- **"Center on me" tap** — Expected: tapping recenters the map on the user. Actual: nothing happens (`onPressed: () {}`).
- **Edge case: neighbor without coordinates** — Expected: the neighbor is simply not plotted (and still appears in the People list); no crash. Actual: not applicable today because no map renders at all.

## Expected Behavior

### Preservation Requirements

**Unchanged Behaviors:**
- Location resolution must continue to use `LocationService.instance.getCurrentPosition()` in `initState` → `_loadNeighbors`, including the New Delhi fallback (`lng 77.2090, lat 28.6139`) when resolution fails.
- Bloc dispatch must continue unchanged: `LoadNearbyNeighbors(lng, lat)` to `NearbyDiscoveryBloc`, plus `LoadNearbyPostsRequested(lng, lat)` to `PostsBloc` and `LoadNearbyPromotions(lng, lat)` to `BusinessBloc`.
- Tab/chip selection (People, Activities, Business, Events, Society) must continue to switch the list content rendered below the map area exactly as before.
- The People list and the "Say hi" flow (`SayHiToNeighbor` dispatch and toast feedback) must continue to work unchanged.
- Loading indicators and empty-state messages for neighbors, activities, and promotions must continue to display as they do today.
- The app bar, filter chip styling, and overall screen layout/scroll behavior must remain visually and behaviorally unchanged outside the map card.

**Scope:**
All inputs and interactions that do NOT involve rendering or interacting with the map should be completely unaffected by this fix. This includes:
- The location-resolution and bloc-dispatch sequence in `_loadNeighbors`.
- Tab switching and list rendering (`_buildPeopleList`, `_buildActivitiesList`, `_buildBusinessList`).
- The "Say hi" button behavior on neighbor cards.
- All loading/error/empty states across the three blocs.

**Note:** The desired correct map behavior is defined in the Correctness Properties section (Property 1). This section focuses on what must NOT change.

## Hypothesized Root Cause

The defect is not a logic error in an existing map; it is a missing implementation. Based on the bug description and code review, the contributing causes are:

1. **Placeholder never replaced**: The map card is a hardcoded gradient `Container` (`height: 160.h`) that was scaffolded as a visual stand-in and never wired to a real map library.

2. **No mapping dependency present**: `pubspec.yaml` includes `geolocator: ^14.0.2` but neither `flutter_map` nor `latlong2`, so there is no map widget available to render tiles.

3. **Inert recenter control**: The "Center on me" `ElevatedButton.icon` has `onPressed: () {}` and there is no `MapController` to drive a recenter, so the control cannot do anything.

4. **No map-facing access to the resolved center**: The resolved/fallback coordinates are used only to dispatch bloc events inside `_loadNeighbors`; they are not retained in widget state for use as a map center, so even a map widget would have nothing to center on.

5. **Neighbor coordinates not surfaced for plotting**: `NearbyDiscoveryState.neighbors` is a `List<dynamic>` consumed only for list rendering (`displayName`, `distanceInKm`, `lookingFor`, `userId`). Whether each neighbor carries coordinates from the `users/nearby` backend response is unconfirmed in the client, so marker plotting must defensively parse optional coordinates.

## Correctness Properties

Property 1: Bug Condition - OpenStreetMap Map Renders, Centers, Plots, and Recenters

_For any_ render of the Nearby Discovery screen where a center is available (a resolved device location or the New Delhi fallback) — i.e. where `isBugCondition` returns true on the unfixed code — the fixed screen SHALL render an OpenStreetMap-backed map (`flutter_map` with OpenStreetMap tile layers) in the map area, centered on the resolved/fallback location, with every neighbor that has valid coordinates plotted as a marker, and SHALL recenter the map on the user's location when the "Center on me" button is tapped.

**Validates: Requirements 2.1, 2.2, 2.3, 2.4, 2.5**

Property 2: Preservation - Non-Map Discovery Behavior

_For any_ interaction that does NOT involve rendering or interacting with the map (location resolution and fallback, bloc dispatch of `LoadNearbyNeighbors`/`LoadNearbyPostsRequested`/`LoadNearbyPromotions`, tab switching and list content, the "Say hi" flow, and loading/empty states) — i.e. where `isBugCondition` returns false — the fixed code SHALL produce exactly the same behavior as the original code, preserving all existing discovery functionality.

**Validates: Requirements 3.1, 3.2, 3.3, 3.4, 3.5**

## Fix Implementation

### Changes Required

Assuming the root cause analysis is correct, the fix adds the mapping dependencies, introduces a reusable map widget, and wires the discovery screen to it.

**File**: `pubspec.yaml`

1. **Add mapping dependencies**: Add `flutter_map` and `latlong2` under `dependencies` (alongside the existing `geolocator: ^14.0.2`), pinned to current, mutually compatible versions. Run `flutter pub get` to resolve. Verify the resolved `flutter_map` version supports the project SDK constraint (`>=3.5.0 <4.0.0`).

**File**: `lib/src/imports/packages_imports.dart`

2. **Export mapping packages via the barrel**: Add `export 'package:flutter_map/flutter_map.dart';` and `export 'package:latlong2/latlong.dart';` so features consume them through the existing `packages_imports.dart` barrel, matching project convention. (Guard for symbol collisions with a `hide` clause if any export conflicts surface during analysis.)

**File**: `lib/src/shared/widgets/app_map.dart` (new)

3. **Create the reusable `AppMap` widget**: A `StatelessWidget` (or thin `StatefulWidget` if it owns its own controller) that wraps `FlutterMap` and accepts:
   - `center` (`LatLng`) — required initial center.
   - `markers` (`List<Marker>`) — points to plot (default empty).
   - `controller` (`MapController?`) — optional external controller for recentering.
   - `initialZoom` (`double`, default e.g. `14`), `height` (optional), and `borderRadius` (default to match the current `28.r` card rounding).
   Internally it composes:
   - `MapOptions(initialCenter: center, initialZoom: initialZoom)`.
   - `TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: '<app id>')` — see Tile Usage Policy below.
   - `MarkerLayer(markers: markers)`.
   - An attribution layer crediting "OpenStreetMap contributors" with a tappable link to the OSM copyright page.
   The widget is wrapped with `ClipRRect`/rounded `BorderRadius` so it visually matches the prior card, and theming uses `flutter_screenutil` (`.r`, `.h`) consistent with existing widgets.

**File**: `lib/src/shared/widgets/widgets.dart`

4. **Export `AppMap`**: Add `export 'app_map.dart';` to the widgets barrel so it is reachable through `core_imports.dart` everywhere.

**File**: `lib/src/features/nearby_discovery/presentation/pages/nearby_discovery_screen.dart`

5. **Retain the resolved center in widget state**: Add a `LatLng _center` field initialized to the New Delhi fallback (`LatLng(28.6139, 77.2090)`). In `_loadNeighbors`, after resolving the position (or on fallback), update `_center` via `setState` so the map can center on it. Preserve the existing fold branches and all three bloc dispatches exactly as they are.

6. **Add a `MapController`**: Create `final MapController _mapController = MapController();` in state and dispose if needed.

7. **Replace the placeholder with `AppMap`**: Swap the gradient `Container` for `AppMap(center: _center, controller: _mapController, markers: _buildNeighborMarkers(state), height: 160.h)`, keeping the same height and rounded corners. The "Center on me" `ElevatedButton.icon` remains positioned as before but its `onPressed` calls `_mapController.move(_center, _mapController.camera.zoom)` (or a fixed recenter zoom) to recenter on the user.

8. **Build neighbor markers defensively**: Add a helper `_buildNeighborMarkers` that iterates `state.neighbors`, parses optional coordinates per neighbor (supporting likely shapes such as `neighbor['location']['coordinates'] == [lng, lat]` or top-level `lng`/`lat`), and produces a `Marker` only when coordinates are valid finite numbers. Neighbors without coordinates are skipped (no crash, still listed below). This isolates the unconfirmed backend coordinate shape behind one well-tested function.

9. **Keep list/tab code untouched**: `_buildPeopleList`, `_buildActivitiesList`, `_buildBusinessList`, chip rendering, the "Say hi" flow, and loading/empty states remain unchanged.

### OpenStreetMap Tile Usage Policy

OpenStreetMap's public tile servers require compliance with their [tile usage policy](https://operations.osmfoundation.org/policies/tiles/). The design satisfies this by:

- **Identifying the app**: Setting `TileLayer.userAgentPackageName` to the application identifier (`com.example.area_connect`, per `android/app/build.gradle.kts`). This MUST be updated to the real published application ID before release, since `com.example.*` is a placeholder and OSM may block unidentified/placeholder agents.
- **Attribution**: Always displaying "© OpenStreetMap contributors" via `flutter_map`'s attribution layer, with a tappable link to `https://www.openstreetmap.org/copyright`.
- **Reasonable usage**: Relying on default tile caching and avoiding bulk/pre-fetching, consistent with the policy's prohibition on heavy/automated downloading. For production-scale traffic, the `urlTemplate` should be swappable to a dedicated/commercial tile provider; centralizing tiles in `AppMap` makes that a one-line change.
- **Precedent**: The project already calls `nominatim.openstreetmap.org` with a `User-Agent` header in `LocationService.getAddressFromCoordinates`, so OSM-service compliance is an established concern in this codebase.

## Testing Strategy

### Validation Approach

The testing strategy follows a two-phase approach: first, surface counterexamples that demonstrate the bug on the unfixed code (placeholder shown, inert button, no markers), then verify the fix renders/centers/plots/recenters correctly and preserves all existing non-map behavior. Because the change is primarily a Flutter widget, tests use `flutter_test` with `WidgetTester`, pumping the screen with mocked blocs/services so behavior is deterministic.

### Exploratory Bug Condition Checking

**Goal**: Surface counterexamples that demonstrate the bug BEFORE implementing the fix. Confirm or refute the root cause analysis (missing map implementation, no dependency, inert button). If refuted, re-hypothesize.

**Test Plan**: Pump `NearbyDiscoveryScreen` with a stubbed `NearbyDiscoveryBloc`/`PostsBloc`/`BusinessBloc` and a stubbed location source, then assert on the map area. Run these against the UNFIXED code to observe failures.

**Test Cases**:
1. **No map rendered**: Assert that a `FlutterMap` widget exists in the map area (will fail on unfixed code — only a `Container` exists).
2. **Map not centered**: Assert the map's center equals the resolved/fallback `LatLng` (will fail on unfixed code — no map/center).
3. **No neighbor markers**: With neighbors that have coordinates in state, assert markers are present (will fail on unfixed code — no markers).
4. **Inert "Center on me"**: Tap the "Center on me" button and assert the map controller's `move` is invoked / camera center changes (will fail on unfixed code — `onPressed` is empty).
5. **Edge case — neighbor without coordinates**: With a neighbor lacking coordinates, assert no crash and that neighbor produces no marker (documents the defensive parsing requirement).

**Expected Counterexamples**:
- No `FlutterMap`/`TileLayer` in the tree; only the gradient `Container`.
- Tapping "Center on me" produces no state/camera change.
- Possible causes confirmed: placeholder never replaced, dependency absent, no `MapController`, resolved center not retained.

### Fix Checking

**Goal**: Verify that for all inputs where the bug condition holds, the fixed screen produces the expected behavior (map rendered, centered, neighbors plotted, recenter works).

**Pseudocode:**
```
FOR ALL input WHERE isBugCondition(input) DO
  result := renderDiscoveryScreen_fixed(input)
  ASSERT realMapRendered(result)
  ASSERT mapCenteredOn(result, input.resolvedCenter)
  ASSERT markersMatch(result, input.neighbors WHERE hasValidCoordinates)
  IF input.centerOnMePressed THEN
    ASSERT mapRecenteredOnUser(result)
  END IF
END FOR
```

### Preservation Checking

**Goal**: Verify that for all inputs where the bug condition does NOT hold (non-map interactions), the fixed screen produces the same result as the original.

**Pseudocode:**
```
FOR ALL input WHERE NOT isBugCondition(input) DO
  ASSERT discoveryBehavior_original(input) = discoveryBehavior_fixed(input)
END FOR
```

**Testing Approach**: Property-based testing is recommended for preservation checking because:
- It generates many neighbor/tab/state combinations automatically across the input domain.
- It catches edge cases (empty neighbors, neighbors missing keys, every tab index) that hand-written cases might miss.
- It provides strong guarantees that list rendering, dispatch, and state handling are unchanged for all non-map inputs.

**Test Plan**: Observe behavior on UNFIXED code for location resolution, bloc dispatch, tab switching, "Say hi", and loading/empty states; capture that behavior, then assert it still holds after the fix.

**Test Cases**:
1. **Location + dispatch preservation**: Observe that `_loadNeighbors` dispatches `LoadNearbyNeighbors`/`LoadNearbyPostsRequested`/`LoadNearbyPromotions` with resolved coordinates (and fallback New Delhi on failure) on unfixed code; assert identical dispatch after the fix.
2. **Tab content preservation**: Observe that each chip index renders its corresponding list/"Coming soon" content; assert unchanged after the fix.
3. **"Say hi" preservation**: Observe that tapping "Say hi" dispatches `SayHiToNeighbor(userId)`; assert unchanged after the fix.
4. **Loading/empty-state preservation**: Observe loading indicators and empty-state messages for each bloc; assert unchanged after the fix.

### Unit Tests

- `_buildNeighborMarkers` (or equivalent coordinate parser): valid `[lng, lat]` produces a marker; missing/invalid/non-finite coordinates produce none; mixed lists produce only valid markers.
- Center selection: resolved position yields its `LatLng`; resolution failure yields the New Delhi fallback `LatLng(28.6139, 77.2090)`.
- `AppMap` configuration: renders a `TileLayer` with the OSM `urlTemplate`, a non-empty `userAgentPackageName`, and an attribution layer.

### Property-Based Tests

- Generate random neighbor lists (with/without coordinates, varying validity) and assert the number of plotted markers equals the count of neighbors with valid coordinates (Property 1, plotting).
- Generate random non-map interaction sequences (tab indices, neighbor lists, loading/empty states) and assert list/dispatch/say-hi behavior matches the original (Property 2, preservation).
- Generate random resolved centers and assert the rendered map center equals the provided center (Property 1, centering).

### Integration Tests

- Full screen flow: resolve a (mocked) location → map renders centered on it → neighbors with coordinates appear as markers → tapping "Center on me" recenters the map.
- Fallback flow: location resolution fails → map renders centered on New Delhi → discovery lists still load.
- Reusability check: mount `AppMap` standalone with a given center and markers (the "used wherever a map is required" path) and verify it renders an OSM-backed, attributed map independent of the discovery screen.
