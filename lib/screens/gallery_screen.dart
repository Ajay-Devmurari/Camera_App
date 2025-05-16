import 'dart:io';
import 'package:flutter/material.dart';
import '../models/image_details.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

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
      sortedList.sort((a, b) => b.timestamp.compareTo(a.timestamp)); // Newest first
    } else {
      sortedList.sort((a, b) => a.timestamp.compareTo(b.timestamp)); // Oldest first
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
          TextButton(
            onPressed: () {
              setState(() {
                _isSelectionMode = !_isSelectionMode;
                if (!_isSelectionMode) {
                  _selectedImages.clear();
                }
              });
            },
            child: Text(
              _isSelectionMode ? 'Cancel' : 'Select',
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.black),
            onPressed: () {
              // Open settings
            },
          ),
        ],
      ),
      body: Column(
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
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
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
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 2,
                              mainAxisSpacing: 2,
                            ),
                            itemCount: imagesForDate.length,
                            itemBuilder: (context, imageIndex) {
                              final imagePath = imagesForDate[imageIndex].path;
                              final isSelected =
                                  _selectedImages.contains(imagePath);

                              return GestureDetector(
                                onTap: () {
                                  if (_isSelectionMode) {
                                    setState(() {
                                      if (isSelected) {
                                        _selectedImages.remove(imagePath);
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
                                                : Colors.white.withOpacity(0.7),
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
          Container(
            color: Colors.grey[300],
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Row(
              children: [
                // Sort button
                IconButton(
                  icon: Icon(
                    _isNewestFirst ? Icons.arrow_downward : Icons.arrow_upward,
                    color: Colors.grey[700],
                    size: 20,
                  ),
                  tooltip: _isNewestFirst ? 'Newest first' : 'Oldest first',
                  onPressed: () {
                    setState(() {
                      _isNewestFirst = !_isNewestFirst;
                    });
                  },
                ),
                Expanded(
                  child: Container(
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
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
                                    ? Colors.white
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Center(
                                child: Text(
                                  'Date',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: _isDateView
                                        ? Colors.black
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
                                    ? Colors.white
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Center(
                                child: Text(
                                  'Month',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: !_isDateView
                                        ? Colors.black
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
                IconButton(
                  icon: const Icon(
                    Icons.more_vert,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    // Show more options menu
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _captureImage(context),
        backgroundColor: Colors.blue,
        child: const Icon(Icons.camera_alt),
      ),
    );
  }
  
  Future<void> _captureImage(BuildContext context) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);

    if (image != null) {
      // Start getting location and saving image in parallel
      final Future<Position?> positionFuture = _getCurrentLocation(context);
      final Future<String> savedImagePathFuture = _saveImagePermanently(image);

      // Wait for both operations to complete
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

      // Call the callback if provided
      if (widget.onImageCaptured != null) {
        widget.onImageCaptured!(imageDetails);
      }

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
  
  Future<Position?> _getCurrentLocation(BuildContext context) async {
    try {
      // Check if location service is enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please enable location services in device settings'),
              duration: Duration(seconds: 3),
            ),
          );
        }
        return null;
      }

      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Location permission denied'),
                duration: Duration(seconds: 2),
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
              content: Text('Location permission permanently denied'),
              duration: Duration(seconds: 2),
            ),
          );
        }
        return null;
      }

      // Get location
      try {
        return await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 10),
        );
      } catch (e) {
        // Try to get last known position if current position times out
        final lastPosition = await Geolocator.getLastKnownPosition();
        if (lastPosition != null) return lastPosition;
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Using approximate location due to timeout'),
              duration: Duration(seconds: 2),
            ),
          );
        }

        // If no last position, try with lower accuracy
        return await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.low,
          timeLimit: const Duration(seconds: 5),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not get location, photo will be saved without location'),
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
    final permanentImage = await File(image.path).copy('${directory.path}/$name');
    return permanentImage.path;
  }

  void _viewImage(ImageDetails image) {
    // Navigate to image view
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.file(File(image.path)),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Taken on ${DateFormat('MMM d, yyyy').format(image.timestamp)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }
}
