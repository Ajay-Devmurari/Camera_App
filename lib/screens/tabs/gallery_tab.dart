import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../../widgets/organized_image_grid.dart';
import '../image_view_screen.dart';
import '../../models/image_details.dart';

class GalleryTab extends StatelessWidget {
  final List<ImageDetails> images;
  final Function(int) onDeleteImage;
  final bool selectionMode;
  final List<int> selectedIndices;
  final Function(int) onSelectionChanged;
  final VoidCallback onShareSelected;
  final VoidCallback onDeleteSelected;
  final Function(int) onShowDetails;
  final Function(ImageDetails) onImageCaptured;

  const GalleryTab({
    super.key,
    required this.images,
    required this.onDeleteImage,
    required this.selectionMode,
    required this.selectedIndices,
    required this.onSelectionChanged,
    required this.onShareSelected,
    required this.onDeleteSelected,
    required this.onShowDetails,
    required this.onImageCaptured,
  });

  Future<Position?> _getCurrentLocation(BuildContext context) async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Please enable location services in device settings'),
              duration: Duration(seconds: 3),
            ),
          );
        }
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'Location permission is required to add location to photos'),
                duration: Duration(seconds: 3),
              ),
            );
          }
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Please enable location permission in app settings'),
              duration: Duration(seconds: 3),
            ),
          );
        }
        return null;
      }

      Position? lastPosition = await Geolocator.getLastKnownPosition();

      try {
        return await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 10),
        );
      } catch (e) {
        if (lastPosition != null) {
          return lastPosition;
        }

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Using approximate location due to timeout'),
              duration: Duration(seconds: 2),
            ),
          );
        }

        return await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.low,
          timeLimit: const Duration(seconds: 5),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Could not get location, photo will be saved without location'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return null;
    }
  }

  Future<String> _saveImagePermanently(XFile image) async {
    final directory = await getApplicationDocumentsDirectory();
    final name = path.basename(image.path);
    final permanentImage =
        await File(image.path).copy('${directory.path}/$name');
    return permanentImage.path;
  }

  Future<void> _captureImage(BuildContext context) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);

    if (image != null) {
      final Future<Position?> positionFuture = _getCurrentLocation(context);
      final Future<String> savedImagePathFuture = _saveImagePermanently(image);

      final List<dynamic> results = await Future.wait([
        positionFuture,
        savedImagePathFuture,
      ]);

      final Position? position = results[0] as Position?;
      final String savedImagePath = results[1] as String;

      final imageDetails = ImageDetails(
        path: savedImagePath,
        timestamp: DateTime.now(),
        latitude: position?.latitude,
        longitude: position?.longitude,
      );

      onImageCaptured(imageDetails);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo saved successfully'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (images.isEmpty)
          const Center(
            child: Text(
              'No photos yet\nTap the camera button to take a photo',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          )
        else
          OrganizedImageGrid(
            images: images,
            selectionMode: selectionMode,
            selectedIndices: selectedIndices,
            onSelectionChanged: onSelectionChanged,
            onTap: (index) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ImageViewScreen(
                    imagePath: images[index].path,
                    tag: 'image_$index',
                    imageDetails: images[index],
                    onDelete: () => onDeleteImage(index),
                    onShowDetails: () => onShowDetails(index),
                  ),
                ),
              );
            },
          ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            onPressed: () => _captureImage(context),
            child: const Icon(Icons.camera_alt),
          ),
        ),
      ],
    );
  }
}
