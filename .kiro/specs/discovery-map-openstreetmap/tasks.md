# Implementation Plan

## Overview

This plan follows the exploratory bug-condition methodology from the design's Testing Strategy:
explore the bug first (Property 1: Bug Condition), lock in existing behavior (Property 2:
Preservation), then apply the fix and re-run both properties to confirm the bug is resolved
without regressions.

The bug: the Nearby Discovery screen renders a static gradient `Container` placeholder where a
map belongs, and the "Center on me" button has an empty `onPressed`. The fix adds
`flutter_map` + `latlong2`, introduces a reusable `AppMap` widget backed by OpenStreetMap
tiles, and wires `NearbyDiscoveryScreen` to render/center/plot/recenter — preserving all
existing non-map discovery behavior.

> **Testing setup**: Tests use `flutter_test` with `WidgetTester`, pumping
> `NearbyDiscoveryScreen` with stubbed `NearbyDiscoveryBloc` / `PostsBloc` / `BusinessBloc`
> and a stubbed location source so behavior is deterministic. The project has no
> property-based testing package installed. Implement the "property" tests as
> generated-input loops (e.g. `dart:math` `Random` driving many neighbor lists, centers,
> tab indices, and state combinations) inside `flutter_test`; optionally add the `glados`
> dev dependency if a dedicated PBT harness is preferred. Either way keep the
> `**Property N:**` headers so hover status works.

## Task Dependency Graph

Tasks 1 and 2 are independent and both run first against the UNFIXED code. The fix (Task 3
and its sub-tasks) depends on both. Re-running the same tests (3.4, 3.5) depends on the fix
landing. Task 4 is the final gate.

```json
{
  "waves": [
    {
      "wave": 1,
      "tasks": ["1", "2"],
      "description": "Author and run the bug-condition exploration test (fails) and the preservation tests (pass) against the UNFIXED code. Independent of each other."
    },
    {
      "wave": 2,
      "tasks": ["3.1", "3.2", "3.3"],
      "description": "Apply the fix: barrel exports, then the reusable AppMap widget, then wire NearbyDiscoveryScreen. Sequential within the wave (3.1 -> 3.2 -> 3.3). Depends on wave 1."
    },
    {
      "wave": 3,
      "tasks": ["3.4", "3.5"],
      "description": "Re-run the SAME tests from tasks 1 and 2. Property 1 must now PASS; Property 2 must still PASS. Depends on wave 2."
    },
    {
      "wave": 4,
      "tasks": ["4"],
      "description": "Checkpoint: full suite + analyzer green. Depends on wave 3."
    }
  ]
}
```

## Tasks

- [ ] 1. Write bug condition exploration test
  - **Property 1: Bug Condition** - OpenStreetMap Map Renders, Centers, Plots, and Recenters
  - **CRITICAL**: This test MUST FAIL on unfixed code - failure confirms the bug exists
  - **DO NOT attempt to fix the test or the screen code when it fails**
  - **NOTE**: This test encodes the expected behavior - it will validate the fix when it passes after implementation
  - **GOAL**: Surface counterexamples that demonstrate the bug exists (placeholder gradient `Container` shown, no `FlutterMap`/`TileLayer`, no markers, inert "Center on me")
  - **Test scaffolding**: Add `flutter_map` and `latlong2` to `pubspec.yaml` under `dependencies` (alongside `geolocator: ^14.0.2`) and run `flutter pub get`, so the test can reference the `FlutterMap` type. The screen itself stays UNFIXED, so the test still fails.
  - **Scoped PBT approach**: For the deterministic render assertions, scope to concrete cases (resolved center = `LatLng(28.6139, 77.2090)` New Delhi fallback, and a real resolved center). For the plotting assertion, generate random neighbor lists (mix of with/without valid coordinates) and assert the number of plotted markers equals the count of neighbors with valid finite coordinates.
  - Pump `NearbyDiscoveryScreen` with stubbed `NearbyDiscoveryBloc` / `PostsBloc` / `BusinessBloc` and a stubbed location source (per design "Exploratory Bug Condition Checking" test plan)
  - Bug condition (from `isBugCondition` in design): a center is available (resolved location or New Delhi fallback) yet the map area renders the placeholder gradient `Container` instead of an OSM map
  - Assert expected behavior (from `expectedBehavior` / design Test Cases), each will FAIL on unfixed code:
    - `find.byType(FlutterMap)` finds the map widget in the map area (Req 2.1)
    - the map's center equals the resolved/fallback `LatLng` (Req 2.2)
    - with neighbors that have coordinates in state, markers are present and count matches valid-coordinate neighbors (Req 2.3)
    - tapping "Center on me" invokes `MapController.move` / changes the camera center (Req 2.4)
    - edge case: a neighbor lacking coordinates produces no marker and no crash (Req 2.3 defensive parsing)
  - Run test on UNFIXED code
  - **EXPECTED OUTCOME**: Test FAILS (this is correct - it proves the bug exists)
  - Document counterexamples found (e.g. "only a gradient `Container` present, no `FlutterMap`"; "tapping 'Center on me' produces no camera change because `onPressed: () {}`")
  - Mark task complete when the test is written, run, and the failure is documented
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5_

- [ ] 2. Write preservation property tests (BEFORE implementing fix)
  - **Property 2: Preservation** - Non-Map Discovery Behavior
  - **IMPORTANT**: Follow observation-first methodology - observe the UNFIXED code, record actual behavior, then assert it
  - Observe on UNFIXED code and capture (per design "Preservation Checking" test plan):
    - `_loadNeighbors` dispatches `LoadNearbyNeighbors(lng, lat)` to `NearbyDiscoveryBloc`, plus `LoadNearbyPostsRequested(lng, lat)` to `PostsBloc` and `LoadNearbyPromotions(lng, lat)` to `BusinessBloc` with the resolved coordinates (Req 3.2)
    - on location-resolution failure, the same dispatch occurs with the New Delhi fallback `lng 77.2090, lat 28.6139` (Req 3.1)
    - each chip index (People, Activities, Business, Events, Society) renders its corresponding list / "Coming soon..." content (Req 3.3)
    - tapping "Say hi" on a neighbor dispatches `SayHiToNeighbor(userId)` and shows the existing toast (Req 3.4)
    - loading indicators and empty-state messages for neighbors, activities, and promotions display as today (Req 3.5)
  - Write property-based tests capturing these observed patterns: generate random non-map interaction sequences (tab indices, neighbor lists with/without keys, loading/empty states) and assert list/dispatch/say-hi behavior matches the observed original behavior across the input domain (cases where `isBugCondition` returns false)
  - Property-based generation catches edge cases (empty neighbors, neighbors missing keys, every tab index) that hand-written cases might miss
  - Run tests on UNFIXED code
  - **EXPECTED OUTCOME**: Tests PASS (this confirms the baseline behavior to preserve)
  - Mark task complete when tests are written, run, and passing on unfixed code
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5_

- [ ] 3. Fix for discovery map placeholder (render real OpenStreetMap map via flutter_map)

  - [ ] 3.1 Add barrel exports for the mapping packages
    - Confirm `flutter_map` and `latlong2` are present in `pubspec.yaml` (added during Task 1 scaffolding); pin to current, mutually compatible versions and verify the resolved `flutter_map` supports the SDK constraint `>=3.5.0 <4.0.0`; run `flutter pub get`
    - In `lib/src/imports/packages_imports.dart` add `export 'package:flutter_map/flutter_map.dart';` and `export 'package:latlong2/latlong.dart';` (guard with a `hide` clause if any symbol collisions surface during analysis, matching the existing barrel convention)
    - _Bug_Condition: isBugCondition(input) - map required, center available, but no real map rendered (design Bug Condition)_
    - _Expected_Behavior: expectedBehavior(result) - OSM-backed map available to render (design Property 1)_
    - _Preservation: Non-map discovery behavior unchanged (design Preservation Requirements)_
    - _Requirements: 2.1, 2.5_

  - [ ] 3.2 Create the reusable `AppMap` widget and export it
    - Create `lib/src/shared/widgets/app_map.dart` wrapping `FlutterMap` with: `MapOptions(initialCenter: center, initialZoom: initialZoom)`; OSM `TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.example.area_connect')`; `MarkerLayer(markers: markers)`; and an attribution layer crediting "© OpenStreetMap contributors" with a tappable link to `https://www.openstreetmap.org/copyright`
    - Accept params: `center` (`LatLng`, required), `markers` (`List<Marker>`, default empty), `controller` (`MapController?`, optional), `initialZoom` (`double`, default `14`), optional `height`, and `borderRadius` (default `28.r`); wrap in `ClipRRect`/rounded `BorderRadius` and use `flutter_screenutil` (`.r`, `.h`) to match the prior card
    - Add `export 'app_map.dart';` to `lib/src/shared/widgets/widgets.dart` so it is reachable through `core_imports.dart` everywhere a map is required
    - **Security/policy note**: `userAgentPackageName` is `com.example.area_connect` (placeholder from `android/app/build.gradle.kts`); flag that this MUST be updated to the real published application ID before release per OSM tile usage policy. Centralizing tiles in `AppMap` keeps the provider swap a one-line change for production traffic.
    - _Bug_Condition: isBugCondition(input) - placeholder shown instead of OSM map (design Bug Condition)_
    - _Expected_Behavior: expectedBehavior(result) - reusable OSM-backed, attributed map widget (design Property 1, "used wherever a map is required")_
    - _Preservation: Non-map discovery behavior unchanged (design Preservation Requirements)_
    - _Requirements: 2.1, 2.5_

  - [ ] 3.3 Wire `NearbyDiscoveryScreen` to `AppMap`
    - Add `LatLng _center` to `_NearbyDiscoveryScreenState`, initialized to the New Delhi fallback `LatLng(28.6139, 77.2090)`; in `_loadNeighbors`, after resolving the position (or on the failure/fallback branch) update `_center` via `setState`, keeping the existing fold branches and all three bloc dispatches exactly as they are
    - Add `final MapController _mapController = MapController();` (dispose if needed)
    - Replace the gradient `Container` (`height: 160.h`) with `AppMap(center: _center, controller: _mapController, markers: _buildNeighborMarkers(state), height: 160.h)`, keeping the same height and rounded corners; keep the "Center on me" `ElevatedButton.icon` positioned as before but set `onPressed` to recenter via `_mapController.move(_center, _mapController.camera.zoom)` (or a fixed recenter zoom)
    - Add `_buildNeighborMarkers` helper that iterates `state.neighbors`, defensively parses optional coordinates per neighbor (supporting `neighbor['location']['coordinates'] == [lng, lat]` and top-level `lng`/`lat`), and emits a `Marker` only when coordinates are valid finite numbers; neighbors without coordinates are skipped (no crash, still listed below)
    - Leave `_buildPeopleList`, `_buildActivitiesList`, `_buildBusinessList`, chip rendering, the "Say hi" flow, and loading/empty states untouched
    - _Bug_Condition: isBugCondition(input) - center available but map not rendered/centered, markers not plotted, recenter inert (design Bug Condition)_
    - _Expected_Behavior: expectedBehavior(result) - OSM map rendered, centered on resolved/fallback center, coordinate-bearing neighbors plotted, "Center on me" recenters (design Property 1)_
    - _Preservation: location resolution + fallback, bloc dispatch, tab content, "Say hi", loading/empty states unchanged (design Preservation Requirements)_
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 3.1, 3.2, 3.3, 3.4, 3.5_

  - [ ] 3.4 Verify bug condition exploration test now passes
    - **Property 1: Expected Behavior** - OpenStreetMap Map Renders, Centers, Plots, and Recenters
    - **IMPORTANT**: Re-run the SAME test from Task 1 - do NOT write a new test
    - The test from Task 1 encodes the expected behavior; when it passes it confirms the bug is fixed (map rendered, centered, neighbors with valid coordinates plotted, "Center on me" recenters)
    - Run the bug condition exploration test from Task 1
    - **EXPECTED OUTCOME**: Test PASSES (confirms the bug is resolved)
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5_

  - [ ] 3.5 Verify preservation tests still pass
    - **Property 2: Preservation** - Non-Map Discovery Behavior
    - **IMPORTANT**: Re-run the SAME tests from Task 2 - do NOT write new tests
    - Run the preservation property tests from Task 2
    - **EXPECTED OUTCOME**: Tests PASS (confirms no regressions in location resolution/fallback, bloc dispatch, tab content, "Say hi", and loading/empty states)
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5_

- [ ] 4. Checkpoint - Ensure all tests pass
  - Run the full test suite (`flutter test`) and `flutter analyze`
  - Confirm Property 1 (Bug Condition / Expected Behavior) passes and Property 2 (Preservation) still passes
  - Confirm the supporting unit/property checks from the design hold: `_buildNeighborMarkers` parsing (valid `[lng, lat]` -> marker; missing/invalid/non-finite -> none; mixed -> only valid), center selection (resolved position -> its `LatLng`; failure -> New Delhi fallback `LatLng(28.6139, 77.2090)`), and `AppMap` config (OSM `urlTemplate`, non-empty `userAgentPackageName`, attribution layer)
  - Ensure all tests pass; ask the user if questions arise
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 3.1, 3.2, 3.3, 3.4, 3.5_

## Notes

- **Bug-condition methodology**: Task 1 (Property 1) writes the failing exploration test that
  encodes expected behavior; Task 2 (Property 2) captures baseline behavior via the
  observation-first approach. The fix (Task 3) is only applied after both are written and run
  against the unfixed code. Tasks 3.4 and 3.5 re-run the SAME tests — no new tests are written.
- **Property test hover status**: PBT tasks use the `**Property N: Type** - Title` header so
  status hover works. Property 1 covers the Bug Condition / Expected Behavior; Property 2
  covers Preservation.
- **No PBT package installed**: implement properties as generated-input loops in
  `flutter_test`, or optionally add `glados` as a dev dependency. Keep deterministic render
  assertions scoped to concrete centers/cases for reproducibility.
- **OSM tile usage policy**: `userAgentPackageName` is currently the placeholder
  `com.example.area_connect`; it MUST be set to the real published application ID before
  release, and attribution to "© OpenStreetMap contributors" must always be shown.
- **Optional coordinates**: neighbor coordinate shape from the `users/nearby` backend is
  unconfirmed in the client, so `_buildNeighborMarkers` parses coordinates defensively and
  skips neighbors without valid finite coordinates (they still appear in the People list).
