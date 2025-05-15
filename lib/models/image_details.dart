import 'package:intl/intl.dart';

class ImageDetails {
  final String path;
  final DateTime timestamp;
  final double? latitude;
  final double? longitude;

  ImageDetails({
    required this.path,
    required this.timestamp,
    this.latitude,
    this.longitude,
  });

  String get formattedDate {
    return DateFormat('dd MMM yyyy, HH:mm').format(timestamp);
  }

  String? get locationString {
    if (latitude != null && longitude != null) {
      return 'Latitude: ${latitude!.toStringAsFixed(6)}\nLongitude: ${longitude!.toStringAsFixed(6)}';
    }
    return null;
  }
}
