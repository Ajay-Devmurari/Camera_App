import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  // Add a flag to track if we've already checked permissions in this session
  static bool _hasCheckedPermissions = false;

  static Future<bool> checkAndRequestLocationPermission(
      BuildContext context) async {
    // If we've already checked permissions and they were granted, return true immediately
    if (_hasCheckedPermissions) {
      return true;
    }

    // First check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Use system settings directly without showing custom dialog
      await Geolocator.openLocationSettings();

      // Wait a bit for settings to potentially change
      await Future.delayed(const Duration(seconds: 2));
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return false; // Location services still disabled
      }
    }

    // Check permission status
    LocationPermission permission = await Geolocator.checkPermission();

    // If permission is already granted, mark as checked and return true
    if (permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse) {
      _hasCheckedPermissions = true;
      return true;
    }

    if (permission == LocationPermission.denied) {
      // Request permission directly without showing custom dialog
      permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return false;
      }
    }

    // Permission granted, mark as checked
    _hasCheckedPermissions = true;
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }
}
