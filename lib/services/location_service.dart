import 'dart:developer' as dev;
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

sealed class LocationResult {}

class LocationSuccess extends LocationResult {
  final double latitude;
  final double longitude;

  LocationSuccess({required this.latitude, required this.longitude});
}

class LocationFailure extends LocationResult {
  final String reason;

  LocationFailure(this.reason);
}

class LocationService {
  /// Returns [LocationSuccess] with lat/lng on success.
  /// Returns [LocationFailure] with a user-friendly message

  static Future<LocationResult> getCurrentLocation() async {
    dev.log(
      '📍 [LocationService] Starting location fetch...',
      name: 'LocationService',
    );

    final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      dev.log('❌ [LocationService] GPS is disabled', name: 'LocationService');
      return LocationFailure(
        'Location services are turned off. Please enable GPS and try again.',
      );
    }

    dev.log('✅ [LocationService] GPS is enabled', name: 'LocationService');

    LocationPermission permission = await Geolocator.checkPermission();
    dev.log(
      '🔍 [LocationService] Permission status: $permission',
      name: 'LocationService',
    );

    if (permission == LocationPermission.denied) {
      dev.log(
        '⚠️ [LocationService] Requesting permission...',
        name: 'LocationService',
      );
      permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied) {
        dev.log(
          '❌ [LocationService] Permission denied by user',
          name: 'LocationService',
        );
        return LocationFailure(
          'Location permission denied. Please allow location access to continue.',
        );
      }
    }

    if (permission == LocationPermission.deniedForever) {
      dev.log(
        '🚫 [LocationService] Permission permanently denied',
        name: 'LocationService',
      );
      return LocationFailure(
        'Location permission is permanently denied. '
        'Please enable it from your phone Settings → App Permissions.',
      );
    }

    dev.log(
      '📡 [LocationService] Fetching coordinates...',
      name: 'LocationService',
    );

    try {
      final Position position =
          await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
          ).timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw Exception('Location request timed out');
            },
          );

      dev.log(
        '✅ [LocationService] Got position: '
        'lat=${position.latitude}, lng=${position.longitude}',
        name: 'LocationService',
      );

      return LocationSuccess(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (e) {
      dev.log(
        '❌ [LocationService] Error fetching position: $e',
        name: 'LocationService',
      );
      return LocationFailure(
        'Could not fetch your location. Please check GPS and try again.',
      );
    }
  }

  static Future<String> getPlaceName(double lat, double lng) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);

      if (placemarks.isEmpty) {
        return "Unknown location";
      }

      final place = placemarks.first;

      dev.log('name = ${place.name}', name: 'LocationService');
      dev.log('street = ${place.street}', name: 'LocationService');
      dev.log('subLocality = ${place.subLocality}', name: 'LocationService');
      dev.log('locality = ${place.locality}', name: 'LocationService');
      dev.log(
        'subAdministrativeArea = ${place.subAdministrativeArea}',
        name: 'LocationService',
      );
      dev.log(
        'administrativeArea = ${place.administrativeArea}',
        name: 'LocationService',
      );

      final location = (place.subLocality?.trim().isNotEmpty ?? false)
          ? place.subLocality!
          : (place.locality?.trim().isNotEmpty ?? false)
          ? place.locality!
          : (place.subAdministrativeArea?.trim().isNotEmpty ?? false)
          ? place.subAdministrativeArea!
          : "Unknown location";

      dev.log(
        '📍 [LocationService] Final location: $location',
        name: 'LocationService',
      );

      return location;
    } catch (e) {
      dev.log(
        '❌ [LocationService] Reverse geocoding failed: $e',
        name: 'LocationService',
      );
      return "Unknown location";
    }
  }

  /// Call this when permission is [LocationPermission.deniedForever].
  static Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  static Future<void> openAppSettings() async {
    await Geolocator.openAppSettings();
  }
}
