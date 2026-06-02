import 'package:area_connect/src/imports/core_imports.dart';
import 'package:area_connect/src/imports/packages_imports.dart';

/// A reusable OpenStreetMap-backed map widget.
///
/// Wraps [FlutterMap] with an OpenStreetMap tile layer, a marker layer, and the
/// required "© OpenStreetMap contributors" attribution. Use this anywhere a map
/// is required so the tile provider and attribution stay centralized.
class AppMap extends StatelessWidget {
  /// Center the map is initially focused on.
  final LatLng center;

  /// Markers to plot on the map.
  final List<Marker> markers;

  /// Optional controller for programmatic camera moves (e.g. recenter).
  final MapController? controller;

  /// Initial zoom level.
  final double initialZoom;

  /// Optional fixed height for the map.
  final double? height;

  /// Corner radius applied via [ClipRRect].
  final double borderRadius;

  const AppMap({
    super.key,
    required this.center,
    this.markers = const [],
    this.controller,
    this.initialZoom = 14,
    this.height,
    this.borderRadius = 28,
  });

  @override
  Widget build(BuildContext context) {
    final map = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius.r),
      child: FlutterMap(
        mapController: controller,
        options: MapOptions(
          initialCenter: center,
          initialZoom: initialZoom,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            // NOTE: placeholder application id from android/app/build.gradle.kts.
            // MUST be updated to the real published application id before release
            // per the OpenStreetMap tile usage policy.
            userAgentPackageName: 'com.example.area_connect',
          ),
          if (markers.isNotEmpty) MarkerLayer(markers: markers),
          RichAttributionWidget(
            attributions: [
              TextSourceAttribution(
                '© OpenStreetMap contributors',
                onTap: () => launchUrl(
                  Uri.parse('https://www.openstreetmap.org/copyright'),
                  mode: LaunchMode.externalApplication,
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (height != null) {
      return SizedBox(height: height, child: map);
    }
    return map;
  }
}
