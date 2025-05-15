import 'dart:io';
import 'package:flutter/material.dart';

class ImageGrid extends StatelessWidget {
  final List<String> images;
  final Function(int) onTap;
  final bool selectionMode;
  final List<int> selectedIndices;
  final Function(int) onSelectionChanged;
  final VoidCallback onShareSelected;
  final VoidCallback onDeleteSelected;

  const ImageGrid({
    super.key,
    required this.images,
    required this.onTap,
    this.selectionMode = false,
    this.selectedIndices = const [],
    required this.onSelectionChanged,
    required this.onShareSelected,
    required this.onDeleteSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) {
      return const Center(
        child: Text(
          'No images yet.\nTap the + button to add images.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: images.length,
      itemBuilder: (context, index) {
        final bool isSelected = selectedIndices.contains(index);

        return Hero(
          tag: 'image_$index',
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                if (selectionMode) {
                  onSelectionChanged(index);
                } else {
                  onTap(index);
                }
              },
              onLongPress: () {
                if (!selectionMode) {
                  onSelectionChanged(index);
                }
              },
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(File(images[index]), fit: BoxFit.cover),
                  ),
                  if (selectionMode)
                    Container(
                      decoration: BoxDecoration(
                        color:
                            isSelected
                                ? Colors.blue.withOpacity(0.3)
                                : Colors.black26,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  if (isSelected)
                    const Positioned(
                      top: 8,
                      right: 8,
                      child: CircleAvatar(
                        radius: 12,
                        backgroundColor: Colors.blue,
                        child: Icon(Icons.check, size: 16, color: Colors.white),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
