import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';
import '../../widgets/organized_image_grid.dart';
import '../../widgets/folder_view.dart';
import '../../services/export_service.dart';
import '../image_view_screen.dart';
import '../../models/image_details.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';

class GalleryTab extends StatefulWidget {
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

  @override
  State<GalleryTab> createState() => _GalleryTabState();
}

class _GalleryTabState extends State<GalleryTab> {
  bool _isGridView = true;

  Future<Position?> _getCurrentLocation(BuildContext context) async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showSnackBar('Please enable location services in device settings',
            isError: true, seconds: 3);
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showSnackBar(
              'Location permission is required to add location to photos',
              isError: true,
              seconds: 3);
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showSnackBar('Please enable location permission in app settings',
            isError: true, seconds: 3);
        return null;
      }

      try {
        return await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 10),
        );
      } catch (e) {
        final lastPosition = await Geolocator.getLastKnownPosition();
        if (lastPosition != null) return lastPosition;

        _showSnackBar('Using approximate location due to timeout');
        return await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.low,
          timeLimit: const Duration(seconds: 5),
        );
      }
    } catch (e) {
      _showSnackBar(
          'Could not get location, photo will be saved without location');
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

      widget.onImageCaptured(imageDetails);

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

  void _navigateToImage(int index) {
    if (!widget.selectionMode) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ImageViewScreen(
            imagePath: widget.images[index].path,
            tag: 'image_$index',
            imageDetails: widget.images[index],
            onShowDetails: () => widget.onShowDetails(index),
          ),
        ),
      );
    } else {
      widget.onSelectionChanged(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(''),
        actions: [
          IconButton(
            icon: Icon(
              _isGridView ? Icons.folder_outlined : Icons.grid_view,
              color: _isGridView ? Colors.blue : Colors.orange,
              size: 28,
            ),
            style: IconButton.styleFrom(
              backgroundColor: Colors.grey[100],
              padding: const EdgeInsets.all(8),
            ),
            onPressed: () => setState(() => _isGridView = !_isGridView),
          ),
          const SizedBox(width: 8),
          if (widget.selectionMode) ...[
            IconButton(
              icon: const Icon(Icons.file_download),
              onPressed: () => _handleExportSelected('excel'),
              tooltip: 'Export to Excel',
            ),
          ],
        ],
      ),
      body: Stack(
        children: [
          if (widget.images.isEmpty)
            const Center(
              child: Text(
                'No photos yet\nTap the camera button to take a photo',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            )
          else if (_isGridView)
            OrganizedImageGrid(
              images: widget.images,
              selectionMode: widget.selectionMode,
              selectedIndices: widget.selectedIndices,
              onSelectionChanged: widget.onSelectionChanged,
              onTap: _navigateToImage,
            )
          else
            FolderView(
              images: widget.images,
              onTap: _navigateToImage,
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
      ),
    );
  }

  Future<void> _exportSelected() async {
    if (widget.selectedIndices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select images to export'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Selected Images'),
        content: const Text('Choose export format'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _handleExportSelected('excel');
            },
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.table_chart, color: Colors.green),
                SizedBox(width: 8),
                Text('Excel'),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _handleExportSelected('pdf');
            },
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.picture_as_pdf, color: Colors.red),
                SizedBox(width: 8),
                Text('PDF'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleExportSelected(String type) async {
    try {
      final selectedImages =
          widget.selectedIndices.map((index) => widget.images[index]).toList();

      if (selectedImages.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please select images to export'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Show loading indicator
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Exporting images...'),
            duration: Duration(seconds: 1),
          ),
        );
      }

      String filePath = await ExportService.exportToExcel(selectedImages);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('${selectedImages.length} images exported successfully'),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'OPEN',
              onPressed: () => OpenFile.open(filePath),
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Export error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to export files'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _handleExport(String type) async {
    if (widget.images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No images to export'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      String filePath;
      if (type == 'excel') {
        filePath = await ExportService.exportToExcel(widget.images);
      } else {
        filePath = await ExportService.exportToPDF(widget.images);
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('${widget.images.length} images exported successfully'),
            action: SnackBarAction(
              label: 'OPEN',
              onPressed: () => OpenFile.open(filePath),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to export files'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleShare() async {
    try {
      final selectedImages =
          widget.selectedIndices.map((index) => widget.images[index]).toList();

      if (selectedImages.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select images to share'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Create a temporary file for image details
      final directory = await getTemporaryDirectory();
      final detailsFile = File('${directory.path}/image_details.txt');

      // Generate details text
      final buffer = StringBuffer();
      buffer.writeln('Image Details Report');
      buffer.writeln(
          'Generated: ${DateFormat('dd/MM/yyyy hh:mm a').format(DateTime.now())}');
      buffer.writeln('Total Images: ${selectedImages.length}\n');

      for (var image in selectedImages) {
        final file = File(image.path);
        final fileSize = _formatFileSize(file.lengthSync());
        final date = DateFormat('dd/MM/yyyy').format(image.timestamp);
        final time = DateFormat('hh:mm a').format(image.timestamp);
        final location = image.locationString ?? 'No location';
        final coordinates = image.latitude != null && image.longitude != null
            ? '${image.latitude!.toStringAsFixed(6)}°, ${image.longitude!.toStringAsFixed(6)}°'
            : 'No coordinates';

        buffer.writeln('Image: ${path.basename(image.path)}');
        buffer.writeln('Date: $date');
        buffer.writeln('Time: $time');
        buffer.writeln('Location: $location');
        buffer.writeln('Coordinates: $coordinates');
        buffer.writeln('File Size: $fileSize');
        buffer.writeln('File Path: ${image.path}\n');
      }

      // Save details to file
      await detailsFile.writeAsString(buffer.toString());

      // Share both images and details file
      await Share.shareXFiles(
        [
          ...selectedImages.map((image) => XFile(image.path)),
          XFile(detailsFile.path),
        ],
        text: 'Sharing ${selectedImages.length} images with details',
      );
    } catch (e) {
      debugPrint('Share error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Share failed: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  String _formatFileSize(int sizeInBytes) {
    if (sizeInBytes < 1024) return '$sizeInBytes B';
    if (sizeInBytes < 1024 * 1024) {
      return '${(sizeInBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(sizeInBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  void _showSnackBar(String message, {bool isError = false, int seconds = 2}) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : null,
          duration: Duration(seconds: seconds),
        ),
      );
    }
  }
}
