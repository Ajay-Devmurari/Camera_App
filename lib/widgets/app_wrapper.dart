import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:gallery_app/widgets/location_permission_dialog.dart';
import 'package:gallery_app/widgets/location_disabled_dialog.dart';

class AppWrapper extends StatefulWidget {
  final Widget child;

  const AppWrapper({super.key, required this.child});

  @override
  State<AppWrapper> createState() => _AppWrapperState();
}

class _AppWrapperState extends State<AppWrapper> with WidgetsBindingObserver {
  static const String _hasShownLocationDialogKey = 'has_shown_location_dialog';
  static const String _locationPermissionTypeKey = 'location_permission_type';
  bool _isShowingDialog = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkLocationPermission();
    _startLocationMonitoring();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkLocationStatus();
    }
  }

  Future<void> _startLocationMonitoring() async {
    geo.Geolocator.getServiceStatusStream().listen((geo.ServiceStatus status) {
      if (status == geo.ServiceStatus.disabled) {
        _showLocationDisabledDialog();
      }
    });
  }

  Future<void> _checkLocationStatus() async {
    if (!mounted) return;

    final isLocationEnabled = await geo.Geolocator.isLocationServiceEnabled();
    if (!isLocationEnabled) {
      await _showLocationDisabledDialog();
      return;
    }

    final locationPermission = await geo.Geolocator.checkPermission();
    if (locationPermission == geo.LocationPermission.denied ||
        locationPermission == geo.LocationPermission.deniedForever) {
      await _checkLocationPermission();
    }
  }

  Future<void> _showLocationDisabledDialog() async {
    if (!mounted || _isShowingDialog) return;

    _isShowingDialog = true;
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (context) => const LocationDisabledDialog(),
    );
    _isShowingDialog = false;

    if (result == true && mounted) {
      // User chose to enable location services
      await geo.Geolocator.openLocationSettings();
      // Wait for a moment to allow the settings to open
      await Future.delayed(const Duration(seconds: 1));
      // Check if location services were enabled
      final isEnabled = await geo.Geolocator.isLocationServiceEnabled();
      if (isEnabled && mounted) {
        // Location services are now enabled, check permission
        await _checkLocationPermission();
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Location services are required for photo location tagging'),
          duration: Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _checkLocationPermission() async {
    final prefs = await SharedPreferences.getInstance();
    final hasShownDialog = prefs.getBool(_hasShownLocationDialogKey) ?? false;
    final permissionType = prefs.getString(_locationPermissionTypeKey);

    if (!hasShownDialog && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final status = await Permission.location.status;

        if (!status.isGranted && mounted && !_isShowingDialog) {
          _isShowingDialog = true;
          final result = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            barrierColor: Colors.black54,
            builder: (context) => const LocationPermissionDialog(),
          );
          _isShowingDialog = false;

          await prefs.setBool(_hasShownLocationDialogKey, true);

          if (mounted && result != null) {
            if (!result) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Location access helps in tagging your photos with location information',
                  ),
                  duration: Duration(seconds: 4),
                  behavior: SnackBarBehavior.floating,
                  action: SnackBarAction(
                    label: 'SETTINGS',
                    onPressed: openAppSettings,
                  ),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Location access ${permissionType == 'always' ? 'always' : 'while using app'} enabled',
                  ),
                  duration: const Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: Colors.green,
                ),
              );
            }
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
