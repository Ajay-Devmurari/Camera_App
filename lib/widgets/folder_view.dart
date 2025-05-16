import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/image_details.dart';

class FolderView extends StatelessWidget {
  final List<ImageDetails> images;
  final Function(int) onTap;

  // Date formatters
  static final _monthYearFormat = DateFormat('MMMM yyyy');
  static final _dateTimeFormat = DateFormat('MMM dd, yyyy HH:mm');
  static final _fileNameFormat = DateFormat('yyyyMMdd_HHmmss');

  // Category names
  static const _categoryToday = 'Today';
  static const _categoryYesterday = 'Yesterday';
  static const _categoryThisWeek = 'This Week';
  static const _categoryThisMonth = 'This Month';
  static const _defaultCategories = [
    _categoryToday,
    _categoryYesterday,
    _categoryThisWeek,
    _categoryThisMonth
  ];

  const FolderView({
    super.key,
    required this.images,
    required this.onTap,
  });

  Map<String, List<ImageDetails>> _organizeByDate() {
    final Map<String, List<ImageDetails>> organized = {};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    for (var image in images) {
      final imageDate = DateTime(
        image.timestamp.year,
        image.timestamp.month,
        image.timestamp.day,
      );

      String category;
      if (imageDate == today) {
        category = _categoryToday;
      } else if (imageDate == yesterday) {
        category = _categoryYesterday;
      } else if (today.difference(imageDate).inDays <= 7) {
        category = _categoryThisWeek;
      } else if (imageDate.year == now.year && imageDate.month == now.month) {
        category = _categoryThisMonth;
      } else {
        category = _monthYearFormat.format(image.timestamp);
      }

      organized.putIfAbsent(category, () => []).add(image);
    }

    // Sort images within each category by date (newest first)
    for (var images in organized.values) {
      images.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    }

    // Create ordered map
    return Map.fromEntries([
      ..._defaultCategories
          .where((category) => organized.containsKey(category))
          .map((category) => MapEntry(category, organized[category]!)),
      ...organized.entries
          .where((entry) => !_defaultCategories.contains(entry.key))
          .toList()
        ..sort((a, b) => _monthYearFormat
            .parse(b.key)
            .compareTo(_monthYearFormat.parse(a.key)))
    ]);
  }

  String _getFileSize(String filepath) {
    final file = File(filepath);
    final sizeInBytes = file.lengthSync();
    if (sizeInBytes < 1024) return '$sizeInBytes B';
    if (sizeInBytes < 1024 * 1024) {
      return '${(sizeInBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(sizeInBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final organizedImages = _organizeByDate();

    return ListView.builder(
      itemCount: organizedImages.length,
      itemBuilder: (context, index) {
        final date = organizedImages.keys.elementAt(index);
        final dateImages = organizedImages[date]!;

        return ExpansionTile(
          initiallyExpanded: index == 0,
          title: Row(
            children: [
              Text(
                date,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '(${dateImages.length} items)',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
          children: [
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: dateImages.length,
              itemBuilder: (context, imageIndex) {
                final image = dateImages[imageIndex];
                return _buildImageListTile(image);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildImageListTile(ImageDetails image) {
    return ListTile(
      leading: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          image: DecorationImage(
            image: FileImage(File(image.path)),
            fit: BoxFit.cover,
          ),
        ),
      ),
      title: Text(
        'IMG_${_fileNameFormat.format(image.timestamp)}',
        style: const TextStyle(fontSize: 14),
      ),
      subtitle: Text(
        '${_dateTimeFormat.format(image.timestamp)}\n${_getFileSize(image.path)}',
        style: const TextStyle(fontSize: 12),
      ),
      isThreeLine: true,
      onTap: () => onTap(images.indexOf(image)),
    );
  }
}
