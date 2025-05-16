import 'dart:io';
import 'package:flutter/material.dart';
import '../models/image_details.dart';
import 'package:intl/intl.dart';

class GalleryScreen extends StatefulWidget {
  final List<ImageDetails> images;

  const GalleryScreen({
    Key? key,
    required this.images,
  }) : super(key: key);

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  bool _isDateView = true;
  bool _isSelectionMode = false;
  final List<String> _selectedImages = [];

  List<ImageDetails> get _sortedImages {
    final sortedList = List<ImageDetails>.from(widget.images);
    sortedList.sort((a, b) => b.timestamp.compareTo(a.timestamp));
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
    );
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
