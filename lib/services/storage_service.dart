import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/image_details.dart';

class StorageService {
  static const String _key = 'saved_images';

  static Future<List<ImageDetails>> loadSavedImages() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString(_key);

    if (jsonString == null) return [];

    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList
        .map(
          (json) => ImageDetails(
            path: json['path'],
            timestamp: DateTime.parse(json['timestamp']),
            latitude:
                json['latitude'] != null
                    ? double.parse(json['latitude'].toString())
                    : null,
            longitude:
                json['longitude'] != null
                    ? double.parse(json['longitude'].toString())
                    : null,
          ),
        )
        .toList();
  }

  static Future<void> saveImages(List<ImageDetails> images) async {
    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> jsonList =
        images
            .map(
              (image) => {
                'path': image.path,
                'timestamp': image.timestamp.toIso8601String(),
                'latitude': image.latitude,
                'longitude': image.longitude,
              },
            )
            .toList();

    await prefs.setString(_key, json.encode(jsonList));
  }
}
