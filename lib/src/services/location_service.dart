import 'package:geolocator/geolocator.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../utils/utils.dart';

/// A service to handle device location requests and status checks.
class LocationService {
  LocationService._();
  static final LocationService instance = LocationService._();

  /// Check the status of location permission.
  FutureEither<LocationPermission> checkPermission() async {
    return runTask(() => Geolocator.checkPermission());
  }

  /// Request location permission.
  FutureEither<LocationPermission> requestPermission() async {
    return runTask(() => Geolocator.requestPermission());
  }

  /// Check if location services are enabled.
  FutureEither<bool> isLocationServiceEnabled() async {
    return runTask(() => Geolocator.isLocationServiceEnabled());
  }

  /// Open the location settings.
  FutureEither<bool> openLocationSettings() async {
    return runTask(() => Geolocator.openLocationSettings());
  }

  /// Get the current position.
  FutureEither<Position> getCurrentPosition({
    LocationAccuracy accuracy = LocationAccuracy.high,
  }) async {
    return runTask(() async {
      bool serviceEnabled;
      LocationPermission permission;

      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled.');
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied.');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception(
            'Location permissions are permanently denied, we cannot request permissions.');
      }

      return await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(accuracy: accuracy),
      );
    });
  }

  /// Get the last known position.
  FutureEither<Position?> getLastKnownPosition() async {
    return runTask(() => Geolocator.getLastKnownPosition());
  }

  /// Get a stream of position updates.
  Stream<Position> getPositionStream({
    LocationAccuracy accuracy = LocationAccuracy.high,
    int distanceFilter = 0,
  }) {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilter,
      ),
    );
  }

  /// Get address string from coordinates via Nominatim reverse geocoding
  FutureEither<String> getAddressFromCoordinates(double lat, double lng) async {
    return runTask(() async {
      final dio = Dio();
      dio.options.connectTimeout = const Duration(seconds: 5);
      dio.options.receiveTimeout = const Duration(seconds: 5);
      dio.options.headers['User-Agent'] = 'AreaConnect/1.0';

      final response = await dio.get<Map<String, dynamic>>(
        dotenv.get('NOMINATIM_BASE_URL', fallback: 'https://nominatim.openstreetmap.org/reverse'),
        queryParameters: {
          'lat': lat,
          'lon': lng,
          'format': 'json',
          'accept-language': 'en',
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final address = data['address'] as Map<String, dynamic>?;
        if (address != null) {
          final suburb = address['suburb'] ??
              address['neighbourhood'] ??
              address['residential'] ??
              address['village'] ??
              address['subdistrict'] ??
              '';
          final city =
              address['city'] ?? address['town'] ?? address['county'] ?? '';
          if (suburb.isNotEmpty && city.isNotEmpty) {
            return '$suburb, $city';
          } else if (suburb.isNotEmpty) {
            return suburb.toString();
          } else if (city.isNotEmpty) {
            return city.toString();
          }
        }
        final displayName = data['display_name']?.toString() ?? '';
        if (displayName.isNotEmpty) {
          final parts = displayName.split(',');
          if (parts.length >= 2) {
            return '${parts[0].trim()}, ${parts[1].trim()}';
          }
          return displayName;
        }
      }
      throw Exception('Failed to reverse geocode coordinates.');
    });
  }
}
