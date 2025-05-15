import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../models/image_details.dart';
import '../services/storage_service.dart';

import 'tabs/gallery_tab.dart';
import 'tabs/payment_tab.dart';
import 'tabs/settings_tab.dart';
import '../widgets/image_details_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<ImageDetails> _images = [];
  int _currentIndex = 0;
  bool _selectionMode = false;
  final List<int> _selectedIndices = [];

  @override
  void initState() {
    super.initState();
    _loadSavedImages();
  }

  Future<void> _loadSavedImages() async {
    final savedImages = await StorageService.loadSavedImages();
    setState(() {
      _images.addAll(savedImages);
    });
  }

  Future<void> _saveImages() async {
    await StorageService.saveImages(_images);
  }

  void _deleteImage(int index) {
    final String imagePath = _images[index].path;
    setState(() {
      _images.removeAt(index);
      _saveImages(); // Save after deleting
    });
    File(imagePath).delete();
  }

  void _toggleSelection(int index) {
    setState(() {
      if (_selectedIndices.contains(index)) {
        _selectedIndices.remove(index);
        if (_selectedIndices.isEmpty) {
          _selectionMode = false;
        }
      } else {
        _selectedIndices.add(index);
        _selectionMode = true;
      }
    });
  }

  Future<void> _shareSelectedImages() async {
    if (_selectedIndices.isEmpty) return;

    try {
      final List<XFile> filesToShare = [];
      final tempDir = await Directory.systemTemp.createTemp();

      for (final index in _selectedIndices) {
        final file = File(_images[index].path);
        if (await file.exists()) {
          final tempFile = File('${tempDir.path}/image_$index.jpg');
          await file.copy(tempFile.path);
          filesToShare.add(XFile(tempFile.path));
        }
      }

      if (filesToShare.isNotEmpty) {
        await Share.shareXFiles(filesToShare, text: 'Check out these images!');
      }

      await tempDir.delete(recursive: true);

      setState(() {
        _selectionMode = false;
        _selectedIndices.clear();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sharing: $e')),
        );
      }
    }
  }

  void _deleteSelectedImages() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete'),
        content:
            Text('Do you want to delete ${_selectedIndices.length} photos?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              final sortedIndices = _selectedIndices.toList()
                ..sort((a, b) => b.compareTo(a));
              for (final index in sortedIndices) {
                _deleteImage(index);
              }
              setState(() {
                _selectionMode = false;
                _selectedIndices.clear();
                _saveImages();
              });
            },
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }

  void _showImageDetails(int index) {
    showDialog(
      context: context,
      builder: (context) => ImageDetailsDialog(details: _images[index]),
    );
  }

  void _onImageCaptured(ImageDetails imageDetails) {
    setState(() {
      _images.add(imageDetails);
      _saveImages(); // Save after adding new image
    });
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          elevation: 0,
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.black,
          indicatorColor: Colors.blue.withOpacity(0.2),
          labelTextStyle: WidgetStateProperty.all(
            const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Photos',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
          centerTitle: false,
          leading: _selectionMode && _currentIndex == 0
              ? IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      _selectionMode = false;
                      _selectedIndices.clear();
                    });
                  },
                )
              : null,
          actions: [
            if (_selectionMode &&
                _selectedIndices.isNotEmpty &&
                _currentIndex == 0) ...[
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: _shareSelectedImages,
                tooltip: 'Share Selected Photos',
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: _deleteSelectedImages,
                tooltip: 'Delete Selected Photos',
              ),
            ],
          ],
        ),
        body: IndexedStack(
          index: _currentIndex,
          children: [
            GalleryTab(
              images: _images,
              onDeleteImage: _deleteImage,
              selectionMode: _selectionMode,
              selectedIndices: _selectedIndices,
              onSelectionChanged: _toggleSelection,
              onShareSelected: _shareSelectedImages,
              onDeleteSelected: _deleteSelectedImages,
              onShowDetails: _showImageDetails,
              onImageCaptured: _onImageCaptured,
            ),
            const PaymentTab(),
            const SettingsTab(),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            setState(() {
              if (_selectionMode) {
                _selectionMode = false;
                _selectedIndices.clear();
              }
              _currentIndex = index;
            });
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.photo_outlined),
              selectedIcon: Icon(Icons.photo),
              label: 'Photos',
            ),
            NavigationDestination(
              icon: Icon(Icons.payment_outlined),
              selectedIcon: Icon(Icons.payment),
              label: 'Payment',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: 'Setting',
            ),
          ],
        ),
      ),
    );
  }
}
