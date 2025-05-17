import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';

class MapDialog extends StatefulWidget {
  final double latitude;
  final double longitude;

  const MapDialog({
    Key? key,
    required this.latitude,
    required this.longitude,
  }) : super(key: key);

  @override
  State<MapDialog> createState() => _MapDialogState();
}

class _MapDialogState extends State<MapDialog> {
  GoogleMapController? _mapController;
  String _address = 'Loading address...';
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _getAddressFromLatLng();
    _markers.add(
      Marker(
        markerId: const MarkerId('photo_location'),
        position: LatLng(widget.latitude, widget.longitude),
        infoWindow: InfoWindow(
          title: 'Photo Location',
          snippet: _address,
        ),
      ),
    );
  }

  Future<void> _getAddressFromLatLng() async {
    try {
      final List<Placemark> placemarks = await placemarkFromCoordinates(
        widget.latitude,
        widget.longitude,
      );

      if (placemarks.isNotEmpty) {
        final Placemark place = placemarks.first;
        setState(() {
          _address = '${place.street}, ${place.locality}, ${place.country}';

          // Update marker info window
          _markers.clear();
          _markers.add(
            Marker(
              markerId: const MarkerId('photo_location'),
              position: LatLng(widget.latitude, widget.longitude),
              infoWindow: InfoWindow(
                title: 'Photo Location',
                snippet: _address,
              ),
            ),
          );
        });
      }
    } catch (e) {
      setState(() {
        _address = 'Could not determine address';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Icon(Icons.location_on, color: Colors.red),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _address,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 400,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: LatLng(widget.latitude, widget.longitude),
                  zoom: 15,
                ),
                markers: _markers,
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
                zoomControlsEnabled: true,
                mapToolbarEnabled: true,
                onMapCreated: (controller) {
                  _mapController = controller;
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('CLOSE'),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: () {
                    // Open in maps app
                    Navigator.pop(context, true);
                  },
                  icon: const Icon(Icons.map),
                  label: const Text('OPEN IN MAPS'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
