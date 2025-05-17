import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/image_details.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../services/export_service.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';
import '../services/location_service.dart';
import '../widgets/map_dialog.dart';
import '../services/maps_launcher_service.dart';

class GalleryScreen extends StatefulWidget {
  final List<ImageDetails> images;
  final Function(ImageDetails)? onImageCaptured;

  const GalleryScreen({
    Key? key,
    required this.images,
    this.onImageCaptured,
  }) : super(key: key);

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  bool _isDateView = true;
  bool _isSelectionMode = false;
  bool _isNewestFirst = true; // Default sort order: newest first
  final List<String> _selectedImages = [];

  List<ImageDetails> get _sortedImages {
    final sortedList = List<ImageDetails>.from(widget.images);
    if (_isNewestFirst) {
      sortedList
          .sort((a, b) => b.timestamp.compareTo(a.timestamp)); // Newest first
    } else {
      sortedList
          .sort((a, b) => a.timestamp.compareTo(b.timestamp)); // Oldest first
    }
    return sortedList;
  }

  Map<String, List<ImageDetails>> _organizeImagesByDate() {
    final Map<String, List<ImageDetails>> result = {};

    for (var image in _sortedImages) {
      final String key = _isDateView
          ? DateFormat('yyyy-MM-dd').format(image.timestamp)
          : DateFormat('yyyy-MM').format(image.timestamp);

      if (!result.containsKey(key)) {
        result[key] = [];
      }

      result[key]!.add(image);
    }

    return result;
  }

  String _formatDateHeader(String dateKey) {
    if (_isDateView) {
      final DateTime date = DateFormat('yyyy-MM-dd').parse(dateKey);
      final DateTime now = DateTime.now();
      final DateTime today = DateTime(now.year, now.month, now.day);
      final DateTime yesterday = today.subtract(const Duration(days: 1));

      if (date == today) {
        return 'Today';
      } else if (date == yesterday) {
        return 'Yesterday';
      } else {
        return DateFormat('MMM d, yyyy').format(date);
      }
    } else {
      final DateTime date = DateFormat('yyyy-MM').parse(dateKey);
      return DateFormat('MMMM yyyy').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final organizedImages = _organizeImagesByDate();
    final dateKeys = organizedImages.keys.toList();

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        backgroundColor: Colors.grey[200],
        elevation: 0,
        title: const Text(
          'Photos',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          _isSelectionMode
              ? TextButton(
                  onPressed: () {
                    setState(() {
                      _isSelectionMode = false;
                      _selectedImages.clear();
                    });
                  },
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )
              : TextButton(
                  onPressed: () {
                    setState(() {
                      _isSelectionMode = true;
                    });
                  },
                  child: const Text(
                    'Select',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
          if (!_isSelectionMode)
            IconButton(
              icon: const Icon(Icons.settings, color: Colors.black),
              onPressed: () {
                // Open settings
              },
            ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: widget.images.isEmpty
                    ? const Center(
                        child: Text(
                          'No photos found',
                          style: TextStyle(color: Colors.black54),
                        ),
                      )
                    : ListView.builder(
                        itemCount: dateKeys.length,
                        itemBuilder: (context, index) {
                          final dateKey = dateKeys[index];
                          final imagesForDate = organizedImages[dateKey]!;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 16, 16, 8),
                                child: Text(
                                  _formatDateHeader(dateKey),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  crossAxisSpacing: 2,
                                  mainAxisSpacing: 2,
                                ),
                                itemCount: imagesForDate.length,
                                itemBuilder: (context, imageIndex) {
                                  final imagePath =
                                      imagesForDate[imageIndex].path;
                                  final isSelected =
                                      _selectedImages.contains(imagePath);

                                  return GestureDetector(
                                    onTap: () {
                                      if (_isSelectionMode) {
                                        setState(() {
                                          if (isSelected) {
                                            _selectedImages.remove(imagePath);
                                            if (_selectedImages.isEmpty) {
                                              _isSelectionMode = false;
                                            }
                                          } else {
                                            _selectedImages.add(imagePath);
                                          }
                                        });
                                      } else {
                                        // View image
                                        _viewImage(imagesForDate[imageIndex]);
                                      }
                                    },
                                    onLongPress: () {
                                      if (!_isSelectionMode) {
                                        setState(() {
                                          _isSelectionMode = true;
                                          _selectedImages.add(imagePath);
                                        });
                                      }
                                    },
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        Image.file(
                                          File(imagePath),
                                          fit: BoxFit.cover,
                                        ),
                                        if (_isSelectionMode)
                                          Positioned(
                                            top: 8,
                                            right: 8,
                                            child: Container(
                                              width: 24,
                                              height: 24,
                                              decoration: BoxDecoration(
                                                color: isSelected
                                                    ? Colors.blue
                                                    : Colors.white
                                                        .withOpacity(0.7),
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: Colors.white,
                                                  width: 2,
                                                ),
                                              ),
                                              child: isSelected
                                                  ? const Icon(
                                                      Icons.check,
                                                      color: Colors.white,
                                                      size: 16,
                                                    )
                                                  : null,
                                            ),
                                          ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          );
                        },
                      ),
              ),
            ],
          ),

          // iOS-style blurred selection bottom bar - only shown when in selection mode
          if (_isSelectionMode)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    height: 60,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.7),
                          Colors.black.withOpacity(0.85),
                        ],
                      ),
                      border: Border(
                        top: BorderSide(
                            color: Colors.grey.withOpacity(0.3), width: 0.5),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Share button
                        IconButton(
                          icon: const Icon(
                            Icons.ios_share,
                            color: Colors.blue,
                            size: 28,
                          ),
                          onPressed: _selectedImages.isNotEmpty
                              ? () => _shareSelectedImages()
                              : null,
                        ),
                        // Selected count
                        Text(
                          '${_selectedImages.length} ${_selectedImages.length == 1 ? "Item" : "Items"}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        // Menu button
                        IconButton(
                          icon: const Icon(
                            Icons.more_horiz,
                            color: Colors.blue,
                            size: 28,
                          ),
                          onPressed: _selectedImages.isNotEmpty
                              ? () => _showExportMenu(context)
                              : null,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Floating action buttons - only shown when not in selection mode
          if (!_isSelectionMode) ...[
            // Sort button (left)
            Positioned(
              left: 16,
              bottom: 16,
              child: SizedBox(
                height: 42, // Smaller size
                width: 42,
                child: FloatingActionButton(
                  heroTag: 'sort',
                  mini: true,
                  elevation: 3,
                  backgroundColor: Colors.white,
                  onPressed: () {
                    setState(() {
                      _isNewestFirst = !_isNewestFirst;
                    });
                  },
                  child: Icon(
                    _isNewestFirst ? Icons.arrow_downward : Icons.arrow_upward,
                    color: Colors.black,
                    size: 20,
                  ),
                ),
              ),
            ),

            // Category button (center)
            Positioned(
              left: 0,
              right: 0,
              bottom: 16,
              child: Center(
                child: Container(
                  height: 36, // Smaller size
                  width: 100,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _isDateView = true;
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: _isDateView
                                  ? Colors.blue.withOpacity(0.2)
                                  : Colors.transparent,
                              borderRadius: const BorderRadius.horizontal(
                                  left: Radius.circular(18)),
                            ),
                            child: Center(
                              child: Text(
                                'Date',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: _isDateView
                                      ? Colors.blue
                                      : Colors.black45,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _isDateView = false;
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: !_isDateView
                                  ? Colors.blue.withOpacity(0.2)
                                  : Colors.transparent,
                              borderRadius: const BorderRadius.horizontal(
                                  right: Radius.circular(18)),
                            ),
                            child: Center(
                              child: Text(
                                'Month',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: !_isDateView
                                      ? Colors.blue
                                      : Colors.black45,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Camera button (right)
            Positioned(
              right: 16,
              bottom: 16,
              child: SizedBox(
                height: 42, // Smaller size
                width: 42,
                child: FloatingActionButton(
                  heroTag: 'camera',
                  mini: true,
                  elevation: 3,
                  backgroundColor: Colors.blue,
                  onPressed: () => _takePicture(context),
                  child: const Icon(Icons.camera_alt, size: 20),
                ),
              ),
            ),
          ],
          if (_isSelectionMode && _selectedImages.isNotEmpty)
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FloatingActionButton.extended(
                      heroTag: 'share',
                      onPressed: _shareSelectedImages,
                      icon: const Icon(Icons.share),
                      label: const Text('Share'),
                      backgroundColor: Colors.blue,
                    ),
                    const SizedBox(width: 16),
                    FloatingActionButton.extended(
                      heroTag: 'delete',
                      onPressed: _deleteSelectedImages,
                      icon: const Icon(Icons.delete),
                      label: const Text('Delete'),
                      backgroundColor: Colors.red,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: _isSelectionMode
          ? null
          : FloatingActionButton(
              onPressed: () => _takePicture(context),
              backgroundColor: Colors.blue,
              child: const Icon(Icons.camera_alt, color: Colors.white),
            ),
    );
  }

  Future<void> _takePicture(BuildContext context) async {
    // Check location permissions without showing dialogs if already granted
    final hasLocationPermission =
        await LocationService.checkAndRequestLocationPermission(context);

    // Continue with taking picture regardless of location permission
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);

    if (image != null) {
      // Get location if permission was granted
      Position? position;
      if (hasLocationPermission) {
        try {
          position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
            timeLimit: const Duration(seconds: 5),
          );
        } catch (e) {
          // Silently fail if location can't be obtained
          print('Error getting location: $e');
        }
      }

      // Save the image
      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          DateTime.now().millisecondsSinceEpoch.toString() + '.jpg';
      final savedImage =
          await File(image.path).copy('${directory.path}/$fileName');

      // Create image details
      final imageDetails = ImageDetails(
        path: savedImage.path,
        timestamp: DateTime.now(),
        latitude: position?.latitude,
        longitude: position?.longitude,
      );

      // Add to the list and refresh UI
      setState(() {
        widget.images.add(imageDetails);
      });

      // Call the callback if provided
      if (widget.onImageCaptured != null) {
        widget.onImageCaptured!(imageDetails);
      }

      // Show success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Photo saved ${position != null ? 'with location' : 'without location'}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _showExportMenu(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[600],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Export Options',
              style: TextStyle(
                color: Colors.grey[400],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
            title: const Text('Export to PDF',
                style: TextStyle(color: Colors.white)),
            subtitle: const Text('Create a PDF document with selected images',
                style: TextStyle(color: Colors.grey)),
            onTap: () {
              Navigator.pop(context);
              _exportSelectedImages('pdf');
            },
          ),
          ListTile(
            leading: const Icon(Icons.table_chart, color: Colors.green),
            title: const Text('Export to Excel',
                style: TextStyle(color: Colors.white)),
            subtitle: const Text('Create a spreadsheet with image details',
                style: TextStyle(color: Colors.grey)),
            onTap: () {
              Navigator.pop(context);
              _exportSelectedImages('excel');
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Future<void> _exportSelectedImages(String format) async {
    try {
      // Get the selected image details
      final List<ImageDetails> selectedImageDetails = [];
      for (String path in _selectedImages) {
        for (ImageDetails image in widget.images) {
          if (image.path == path) {
            selectedImageDetails.add(image);
            break;
          }
        }
      }

      if (selectedImageDetails.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No images selected')),
        );
        return;
      }

      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Exporting images...')),
      );

      // Export based on format
      String filePath;
      if (format == 'excel') {
        filePath = await ExportService.exportToExcel(selectedImageDetails);
      } else {
        filePath = await ExportService.exportToPDF(selectedImageDetails);
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${selectedImageDetails.length} images exported successfully'),
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
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  Future<void> _shareSelectedImages() async {
    if (_selectedImages.isEmpty) return;

    final files = _selectedImages.map((path) => XFile(path)).toList();
    await Share.shareXFiles(files,
        text: 'Sharing ${_selectedImages.length} photos');

    setState(() {
      _isSelectionMode = false;
      _selectedImages.clear();
    });
  }

  void _deleteSelectedImages() {
    if (_selectedImages.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Photos'),
        content: Text('Delete ${_selectedImages.length} photos?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);

              // Remove the selected images
              for (final path in _selectedImages) {
                // Delete file
                File(path).deleteSync();

                // Remove from the list
                widget.images.removeWhere((img) => img.path == path);
              }

              setState(() {
                _isSelectionMode = false;
                _selectedImages.clear();
              });

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Photos deleted'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _viewImage(ImageDetails image) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                Image.file(File(image.path)),
                if (image.latitude != null && image.longitude != null)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: IconButton(
                        icon:
                            const Icon(Icons.location_on, color: Colors.white),
                        onPressed: () {
                          Navigator.pop(context);
                          _showLocationOnMap(image);
                        },
                        tooltip: 'View Location',
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Taken on ${DateFormat('MMM d, yyyy').format(image.timestamp)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (image.latitude != null && image.longitude != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on,
                              size: 16, color: Colors.red),
                          const SizedBox(width: 4),
                          Text(
                            'Location: ${image.latitude!.toStringAsFixed(6)}, ${image.longitude!.toStringAsFixed(6)}',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            ButtonBar(
              alignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  label: const Text('Close'),
                ),
                if (image.latitude != null && image.longitude != null)
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _showLocationOnMap(image);
                    },
                    icon: const Icon(Icons.map),
                    label: const Text('Show on Map'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showLocationOnMap(ImageDetails image) async {
    if (image.latitude == null || image.longitude == null) return;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => MapDialog(
        latitude: image.latitude!,
        longitude: image.longitude!,
      ),
    );

    if (result == true) {
      // User wants to open in maps app
      final success = await MapsLauncherService.openMap(
        image.latitude!,
        image.longitude!,
      );

      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open maps app'),
          ),
        );
      }
    }
  }
}
