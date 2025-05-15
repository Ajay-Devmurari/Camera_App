import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/image_details.dart';

class OrganizedImageGrid extends StatelessWidget {
  final List<ImageDetails> images;
  final bool selectionMode;
  final List<int> selectedIndices;
  final Function(int) onSelectionChanged;
  final Function(int) onTap;

  const OrganizedImageGrid({
    super.key,
    required this.images,
    required this.selectionMode,
    required this.selectedIndices,
    required this.onSelectionChanged,
    required this.onTap,
  });

  String _getFormattedDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateToCheck = DateTime(date.year, date.month, date.day);

    if (dateToCheck == today) {
      return 'Today';
    } else if (dateToCheck == yesterday) {
      return 'Yesterday';
    } else {
      return DateFormat('dd-MMM-yyyy')
          .format(date)
          .replaceAll('-', ' ')
          .toUpperCase();
    }
  }

  Map<String, List<MapEntry<int, ImageDetails>>> _organizeImagesByDate() {
    final Map<String, List<MapEntry<int, ImageDetails>>> organizedImages = {};

    // Sort images by date, newest first
    final sortedImages = images.asMap().entries.toList()
      ..sort((a, b) => b.value.timestamp.compareTo(a.value.timestamp));

    for (final indexedImage in sortedImages) {
      final date = _getFormattedDate(indexedImage.value.timestamp);
      organizedImages.putIfAbsent(date, () => []);
      organizedImages[date]!.add(indexedImage);
    }

    return organizedImages;
  }

  @override
  Widget build(BuildContext context) {
    final organizedImages = _organizeImagesByDate();

    return ListView.builder(
      itemCount: organizedImages.length,
      itemBuilder: (context, sectionIndex) {
        final date = organizedImages.keys.elementAt(sectionIndex);
        final sectionImages = organizedImages[date]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
              child: Text(
                date,
                style: TextStyle(
                  fontSize: date == 'Today' || date == 'Yesterday' ? 28 : 24,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                  letterSpacing: 0.5,
                  height: 1.2,
                ),
              ),
            ),
            GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 1,
                crossAxisSpacing: 1,
                childAspectRatio: 1,
              ),
              itemCount: sectionImages.length,
              itemBuilder: (context, index) {
                final imageEntry = sectionImages[index];
                final originalIndex = imageEntry.key;
                final isSelected = selectedIndices.contains(originalIndex);

                return GestureDetector(
                  onTap: () => selectionMode
                      ? onSelectionChanged(originalIndex)
                      : onTap(originalIndex),
                  onLongPress: () {
                    if (!selectionMode) {
                      onSelectionChanged(originalIndex);
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected
                            ? Theme.of(context).primaryColor
                            : Colors.black,
                        width: isSelected ? 2 : 0.5,
                      ),
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Hero(
                          tag: 'image_$originalIndex',
                          child: Image.file(
                            File(imageEntry.value.path),
                            fit: BoxFit.cover,
                          ),
                        ),
                        if (isSelected)
                          Container(
                            color:
                                Theme.of(context).primaryColor.withOpacity(0.3),
                            child: const Icon(
                              Icons.check_circle,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        // Add video duration overlay if it's a video
                        if (imageEntry.value.path
                            .toLowerCase()
                            .endsWith('.mp4'))
                          Positioned(
                            left: 8,
                            bottom: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.play_arrow,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
