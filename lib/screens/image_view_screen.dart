import 'dart:io';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:share_plus/share_plus.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:geocoding/geocoding.dart';
import '../models/image_details.dart';

class ImageViewScreen extends StatefulWidget {
  final String imagePath;
  final String tag;
  final VoidCallback? onShowDetails;
  final ImageDetails imageDetails;

  const ImageViewScreen({
    super.key,
    required this.imagePath,
    required this.tag,
    required this.imageDetails,
    this.onShowDetails,
  });

  @override
  State<ImageViewScreen> createState() => _ImageViewScreenState();
}

class _ImageViewScreenState extends State<ImageViewScreen> {
  bool _showMap = false;
  String? _locationName;
  bool _isLoadingLocation = false;

  @override
  void initState() {
    super.initState();
    _getLocationName();
  }

  Future<void> _getLocationName() async {
    if (widget.imageDetails.latitude == null ||
        widget.imageDetails.longitude == null) {
      debugPrint('No location data available');
      return;
    }

    setState(() {
      _isLoadingLocation = true;
      _locationName = null;
    });

    try {
      debugPrint('Attempting to fetch city name...');
      debugPrint(
          'Coordinates: ${widget.imageDetails.latitude}, ${widget.imageDetails.longitude}');

      // First attempt to get city name
      try {
        final List<Placemark> placemarks = await placemarkFromCoordinates(
          widget.imageDetails.latitude!,
          widget.imageDetails.longitude!,
        );

        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          String cityName = '';

          // Try to get city name in order of preference
          if (place.locality?.isNotEmpty == true) {
            cityName = place.locality!;
          } else if (place.subAdministrativeArea?.isNotEmpty == true) {
            cityName = place.subAdministrativeArea!;
          }

          if (cityName.isNotEmpty) {
            setState(() {
              _locationName = cityName;
              _isLoadingLocation = false;
            });
            return;
          }
        }
      } catch (e) {
        debugPrint('First attempt failed: $e');
      }

      // Second attempt with different locale
      try {
        final List<Placemark> placemarks = await placemarkFromCoordinates(
          widget.imageDetails.latitude!,
          widget.imageDetails.longitude!,
          localeIdentifier: 'en_US',
        );

        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          String cityName = '';

          if (place.locality?.isNotEmpty == true) {
            cityName = place.locality!;
          } else if (place.subAdministrativeArea?.isNotEmpty == true) {
            cityName = place.subAdministrativeArea!;
          }

          setState(() {
            _locationName = cityName.isEmpty ? 'City not found' : cityName;
            _isLoadingLocation = false;
          });
          return;
        }
      } catch (e) {
        debugPrint('Second attempt failed: $e');
      }

      // If both attempts fail, show coordinates
      setState(() {
        _locationName = 'City not found';
        _isLoadingLocation = false;
      });
    } catch (e) {
      debugPrint('Error getting city name: $e');
      setState(() {
        _locationName = 'City not found';
        _isLoadingLocation = false;
      });
    }
  }

  String _formatDateTime(DateTime dateTime) {
    // Format like: 09/05/2025 04:28 PM GMT +05:30
    final date = DateFormat('dd/MM/yyyy').format(dateTime);
    final time = DateFormat('hh:mm a').format(dateTime);
    final offset = dateTime.timeZoneOffset;
    final hours = offset.inHours.abs().toString().padLeft(2, '0');
    final minutes = (offset.inMinutes % 60).abs().toString().padLeft(2, '0');
    final sign = offset.isNegative ? '-' : '+';
    return '$date $time GMT $sign$hours:$minutes';
  }

  String _formatCoordinates(double? lat, double? long) {
    if (lat == null || long == null) return '';
    return 'Lat ${lat.toStringAsFixed(6)}° Long ${long.toStringAsFixed(6)}°';
  }

  Widget _buildLocationOverlay() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Small Map Preview
              Container(
                width: 100,
                height: 100,
                margin: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 1),
                ),
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(
                      widget.imageDetails.latitude!,
                      widget.imageDetails.longitude!,
                    ),
                    zoom: 15,
                  ),
                  markers: {
                    Marker(
                      markerId: const MarkerId('imageLocation'),
                      position: LatLng(
                        widget.imageDetails.latitude!,
                        widget.imageDetails.longitude!,
                      ),
                    ),
                  },
                  zoomControlsEnabled: false,
                  mapType: MapType.normal,
                  rotateGesturesEnabled: false,
                  scrollGesturesEnabled: false,
                  tiltGesturesEnabled: false,
                  zoomGesturesEnabled: false,
                  myLocationEnabled: false,
                  myLocationButtonEnabled: false,
                ),
              ),
              // Location Details
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_isLoadingLocation)
                        const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      else if (_locationName != null)
                        Text(
                          _locationName!,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                        ),
                      const SizedBox(height: 8),
                      Text(
                        _formatCoordinates(
                          widget.imageDetails.latitude,
                          widget.imageDetails.longitude,
                        ),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white70,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDateTime(widget.imageDetails.timestamp),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white70,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasLocation = widget.imageDetails.latitude != null &&
        widget.imageDetails.longitude != null;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (widget.imageDetails.latitude != null) ...[
            IconButton(
              icon: Icon(
                _showMap ? Icons.image : Icons.location_on,
                color: Colors.white,
              ),
              onPressed: () => setState(() => _showMap = !_showMap),
            ),
          ],
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white),
            onPressed: widget.onShowDetails,
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          Hero(
            tag: widget.tag,
            child: PhotoView(
              imageProvider: FileImage(File(widget.imagePath)),
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered * 2,
              backgroundDecoration: const BoxDecoration(color: Colors.black),
            ),
          ),
          if (_showMap && hasLocation)
            Positioned(
              left: 0,
              bottom: 0,
              child: _buildLocationOverlay(),
            ),
        ],
      ),
    );
  }
}
