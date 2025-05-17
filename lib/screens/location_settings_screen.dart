import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';

class LocationSettingsScreen extends StatefulWidget {
  const LocationSettingsScreen({Key? key}) : super(key: key);

  @override
  State<LocationSettingsScreen> createState() => _LocationSettingsScreenState();
}

class _LocationSettingsScreenState extends State<LocationSettingsScreen> {
  bool _saveLocationData = true;
  bool _darkMode = false;
  bool _highQualityImages = true;
  String _defaultView = 'Date';

  // Location template settings
  bool _showMapType = true;
  bool _showShortAddress = true;
  bool _showFullAddress = true;
  bool _showLatLong = false;
  bool _showPlusCode = true;
  bool _showDateTime = true;
  bool _showTimeZone = false;
  bool _showNumbering = false;
  bool _showLogo = true;
  bool _showNote = true;
  bool _showPersonName = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _saveLocationData = prefs.getBool('save_location_data') ?? true;
      _darkMode = prefs.getBool('dark_mode') ?? false;
      _highQualityImages = prefs.getBool('high_quality_images') ?? true;
      _defaultView = prefs.getString('default_view') ?? 'Date';

      // Load location template settings
      _showMapType = prefs.getBool('show_map_type') ?? true;
      _showShortAddress = prefs.getBool('show_short_address') ?? true;
      _showFullAddress = prefs.getBool('show_full_address') ?? true;
      _showLatLong = prefs.getBool('show_lat_long') ?? false;
      _showPlusCode = prefs.getBool('show_plus_code') ?? true;
      _showDateTime = prefs.getBool('show_date_time') ?? true;
      _showTimeZone = prefs.getBool('show_time_zone') ?? false;
      _showNumbering = prefs.getBool('show_numbering') ?? false;
      _showLogo = prefs.getBool('show_logo') ?? true;
      _showNote = prefs.getBool('show_note') ?? true;
      _showPersonName = prefs.getBool('show_person_name') ?? false;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('save_location_data', _saveLocationData);
    await prefs.setBool('dark_mode', _darkMode);
    await prefs.setBool('high_quality_images', _highQualityImages);
    await prefs.setString('default_view', _defaultView);

    // Save location template settings
    await prefs.setBool('show_map_type', _showMapType);
    await prefs.setBool('show_short_address', _showShortAddress);
    await prefs.setBool('show_full_address', _showFullAddress);
    await prefs.setBool('show_lat_long', _showLatLong);
    await prefs.setBool('show_plus_code', _showPlusCode);
    await prefs.setBool('show_date_time', _showDateTime);
    await prefs.setBool('show_time_zone', _showTimeZone);
    await prefs.setBool('show_numbering', _showNumbering);
    await prefs.setBool('show_logo', _showLogo);
    await prefs.setBool('show_note', _showNote);
    await prefs.setBool('show_person_name', _showPersonName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Location Settings',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: Colors.grey[100],
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: ListView(
        children: [
          _buildSectionHeader('Privacy'),
          _buildSwitchTile(
            'Save Location Data',
            'Save location information with photos',
            Icons.location_on,
            _saveLocationData,
            (value) {
              setState(() {
                _saveLocationData = value;
                _saveSettings();

                // If enabling location, check for permissions
                if (value) {
                  _checkLocationPermission();
                }
              });
            },
          ),
          _buildSectionHeader('Location Template Customization'),
          _buildLocationTemplatePreview(),
          _buildCheckboxTile(
            'Map Type',
            'Show map type in location details',
            _showMapType,
            (value) {
              setState(() {
                _showMapType = value;
                _saveSettings();
              });
            },
          ),
          _buildCheckboxTile(
            'Short Address',
            'Show short address in location details',
            _showShortAddress,
            (value) {
              setState(() {
                _showShortAddress = value;
                _saveSettings();
              });
            },
          ),
          _buildCheckboxTile(
            'Full Address',
            'Show full address in location details',
            _showFullAddress,
            (value) {
              setState(() {
                _showFullAddress = value;
                _saveSettings();
              });
            },
          ),
          _buildCheckboxTile(
            'Latitude / Longitude',
            'Show coordinates in location details',
            _showLatLong,
            (value) {
              setState(() {
                _showLatLong = value;
                _saveSettings();
              });
            },
          ),
          _buildCheckboxTile(
            'Plus Code',
            'Show plus code in location details',
            _showPlusCode,
            (value) {
              setState(() {
                _showPlusCode = value;
                _saveSettings();
              });
            },
          ),
          _buildCheckboxTile(
            'Date & Time',
            'Show date and time in location details',
            _showDateTime,
            (value) {
              setState(() {
                _showDateTime = value;
                _saveSettings();
              });
            },
          ),
          _buildCheckboxTile(
            'Time Zone',
            'Show time zone in location details',
            _showTimeZone,
            (value) {
              setState(() {
                _showTimeZone = value;
                _saveSettings();
              });
            },
          ),
          _buildCheckboxTile(
            'Numbering',
            'Show numbering in location details',
            _showNumbering,
            (value) {
              setState(() {
                _showNumbering = value;
                _saveSettings();
              });
            },
          ),
          _buildCheckboxTile(
            'Logo',
            'Show logo in location details',
            _showLogo,
            (value) {
              setState(() {
                _showLogo = value;
                _saveSettings();
              });
            },
          ),
          _buildCheckboxTile(
            'Note / Hashtag',
            'Show note or hashtag in location details',
            _showNote,
            (value) {
              setState(() {
                _showNote = value;
                _saveSettings();
              });
            },
          ),
          _buildCheckboxTile(
            'Person Name',
            'Show person name in location details',
            _showPersonName,
            (value) {
              setState(() {
                _showPersonName = value;
                _saveSettings();
              });
            },
          ),
          _buildSectionHeader('About'),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('App Version'),
            subtitle: const Text('1.0.0'),
          ),
          ListTile(
            leading: const Icon(Icons.code),
            title: const Text('Source Code'),
            subtitle: const Text('View on GitHub'),
            onTap: () {
              // Open GitHub link
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLocationTemplatePreview() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade700,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.green.shade200,
                  ),
                  child: Stack(
                    children: [
                      // Map grid lines
                      CustomPaint(
                        size: const Size(80, 80),
                        painter: _MapGridPainter(
                            color: Colors.white.withOpacity(0.7)),
                      ),
                      // Location pin
                      Center(
                        child: Icon(
                          Icons.location_on,
                          color: Colors.red.shade700,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Current Location',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Your City, Your Country',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (_showDateTime)
                        Text(
                          'Today, ${DateTime.now().hour}:${DateTime.now().minute}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                if (_showMapType) _buildTemplateItem('Map Type', 'Standard'),
                if (_showShortAddress)
                  _buildTemplateItem('Short Address', 'Automatic'),
                if (_showFullAddress)
                  _buildTemplateItem('Full Address', 'Automatic'),
                if (_showLatLong)
                  _buildTemplateItem('Lat / Long', '00.000000, 00.000000'),
                if (_showPlusCode) _buildTemplateItem('Plus Code', 'XXXX+XX'),
                if (_showTimeZone)
                  _buildTemplateItem('Time Zone', 'GMT +00:00'),
                if (_showNumbering) _buildTemplateItem('Numbering', '1'),
                if (_showNote)
                  _buildTemplateItem('Note / Hashtag', 'Add your note here'),
                if (_showPersonName)
                  _buildTemplateItem('Person Name', 'Your Name'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.amber, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckboxTile(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
  ) {
    return ListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      leading: Icon(
        value ? Icons.check_circle : Icons.circle_outlined,
        color: value ? Colors.amber : Colors.grey,
      ),
      onTap: () => onChanged(!value),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.blue[700],
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    Function(bool) onChanged,
  ) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: Colors.blue,
      ),
    );
  }

  Future<void> _checkLocationPermission() async {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      await Geolocator.requestPermission();
    } else if (permission == LocationPermission.deniedForever) {
      // Show a dialog to guide the user to app settings
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Location Permission Required'),
            content: const Text(
                'Location permission is required to save location with photos. '
                'Please enable it in app settings.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('CANCEL'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Geolocator.openAppSettings();
                },
                child: const Text('OPEN SETTINGS'),
              ),
            ],
          ),
        );
      }
    }
  }
}

class _MapGridPainter extends CustomPainter {
  final Color color;

  const _MapGridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    // Background
    final bgPaint = Paint()
      ..color = Colors.green.shade200
      ..style = PaintingStyle.fill;

    final rect = Rect.fromLTRB(0, 0, size.width, size.height);
    canvas.drawRect(rect, bgPaint);

    // Grid lines
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 1;

    // Draw horizontal lines
    for (int i = 0; i <= 4; i++) {
      final y = i * size.height / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }

    // Draw vertical lines
    for (int i = 0; i <= 4; i++) {
      final x = i * size.width / 4;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
    }

    // Draw a small road
    final roadPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2;

    canvas.drawLine(
      Offset(size.width * 0.2, size.height * 0.5),
      Offset(size.width * 0.8, size.height * 0.5),
      roadPaint,
    );

    canvas.drawLine(
      Offset(size.width * 0.5, size.height * 0.2),
      Offset(size.width * 0.5, size.height * 0.8),
      roadPaint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}
