import 'dart:io';
import 'package:url_launcher/url_launcher.dart';

class MapsLauncherService {
  static Future<bool> openMap(double latitude, double longitude) async {
    final Uri googleMapsUrl = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
    );

    final Uri appleMapsUrl = Uri.parse(
      'https://maps.apple.com/?q=$latitude,$longitude',
    );

    if (Platform.isIOS && await canLaunchUrl(appleMapsUrl)) {
      return await launchUrl(appleMapsUrl);
    } else if (await canLaunchUrl(googleMapsUrl)) {
      return await launchUrl(googleMapsUrl);
    } else {
      return false;
    }
  }
}
