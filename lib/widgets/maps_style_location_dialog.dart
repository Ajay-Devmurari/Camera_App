import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

enum LocationPermissionChoice {
  precise,
  approximate,
  whileUsingApp,
  onlyThisTime,
  dontAllow
}

class MapsStyleLocationDialog extends StatelessWidget {
  const MapsStyleLocationDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF2A2A2A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with icon and text
            Row(
              children: [
                const Icon(
                  Icons.location_on,
                  color: Colors.blue,
                  size: 36,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Allow Gallery to access this device\'s location?',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Precision options
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Precise option
                _buildPrecisionOption(
                  context,
                  'Precise',
                  _buildPreciseLocationIcon(),
                  () => _handlePermissionChoice(
                      context, LocationPermissionChoice.precise),
                ),

                // Approximate option
                _buildPrecisionOption(
                  context,
                  'Approximate',
                  _buildApproximateLocationIcon(),
                  () => _handlePermissionChoice(
                      context, LocationPermissionChoice.approximate),
                ),
              ],
            ),

            const SizedBox(height: 36),

            // "While using the app" button
            _buildOptionButton(
              context,
              'While using the app',
              () => _handlePermissionChoice(
                  context, LocationPermissionChoice.whileUsingApp),
            ),

            const SizedBox(height: 16),

            // "Only this time" button
            _buildOptionButton(
              context,
              'Only this time',
              () => _handlePermissionChoice(
                  context, LocationPermissionChoice.onlyThisTime),
            ),

            const SizedBox(height: 16),

            // "Don't allow" button
            _buildOptionButton(
              context,
              'Don\'t allow',
              () => _handlePermissionChoice(
                  context, LocationPermissionChoice.dontAllow),
              isNegative: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrecisionOption(
      BuildContext context, String label, Widget icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: icon,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreciseLocationIcon() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.blue.withOpacity(0.7), width: 2),
      ),
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Grid lines
            CustomPaint(
              size: const Size(130, 130),
              painter: GridPainter(color: Colors.white.withOpacity(0.3)),
            ),
            // Blue dot
            Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
            ),
            // White dot in center
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
            // Location pin shadow
            Positioned(
              bottom: 20,
              child: Container(
                width: 20,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Location pin
            Positioned(
              bottom: 25,
              child: Icon(
                Icons.location_on,
                color: Colors.blue.withOpacity(0.9),
                size: 30,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApproximateLocationIcon() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.blue.withOpacity(0.7), width: 2),
      ),
      child: CustomPaint(
        size: const Size(130, 130),
        painter: RoadMapPainter(),
      ),
    );
  }

  Widget _buildOptionButton(
      BuildContext context, String label, VoidCallback onTap,
      {bool isNegative = false}) {
    return TextButton(
      onPressed: onTap,
      child: Text(
        label,
        style: TextStyle(
          color: isNegative ? Colors.red.shade300 : Colors.blue,
          fontSize: 16,
        ),
      ),
    );
  }

  Future<void> _handlePermissionChoice(
      BuildContext context, LocationPermissionChoice choice) async {
    switch (choice) {
      case LocationPermissionChoice.precise:
      case LocationPermissionChoice.approximate:
      case LocationPermissionChoice.whileUsingApp:
        await Geolocator.requestPermission();
        if (context.mounted) Navigator.pop(context, true);
        break;
      case LocationPermissionChoice.onlyThisTime:
        await Geolocator.requestPermission();
        if (context.mounted) Navigator.pop(context, true);
        break;
      case LocationPermissionChoice.dontAllow:
        if (context.mounted) Navigator.pop(context, false);
        break;
    }
  }
}

class GridPainter extends CustomPainter {
  final Color color;

  GridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;

    // Draw horizontal lines
    for (int i = 0; i < 7; i++) {
      final y = i * size.height / 6;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Draw vertical lines
    for (int i = 0; i < 7; i++) {
      final x = i * size.width / 6;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Draw some dots for points of interest
    final dotPaint = Paint()..color = Colors.orange;
    canvas.drawCircle(Offset(size.width * 0.3, size.height * 0.3), 3, dotPaint);

    final blueDotPaint = Paint()..color = Colors.blue.withOpacity(0.7);
    canvas.drawCircle(
        Offset(size.width * 0.7, size.height * 0.2), 3, blueDotPaint);
    canvas.drawCircle(
        Offset(size.width * 0.2, size.height * 0.7), 3, blueDotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class RoadMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final whitePaint = Paint()
      ..color = Colors.white.withOpacity(0.7)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final yellowPaint = Paint()
      ..color = Colors.yellow.withOpacity(0.7)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    // Draw white grid roads
    for (int i = 1; i < 6; i++) {
      final pos = i * size.width / 6;
      // Horizontal roads
      canvas.drawLine(Offset(0, pos), Offset(size.width, pos), whitePaint);
      // Vertical roads
      canvas.drawLine(Offset(pos, 0), Offset(pos, size.height), whitePaint);
    }

    // Draw yellow main roads
    final path = Path();
    // Curved road 1
    path.moveTo(size.width * 0.2, 0);
    path.quadraticBezierTo(
        size.width * 0.5, size.height * 0.3, size.width, size.height * 0.4);

    // Curved road 2
    path.moveTo(0, size.height * 0.6);
    path.quadraticBezierTo(
        size.width * 0.3, size.height * 0.7, size.width * 0.7, size.height);

    // Curved road 3
    path.moveTo(size.width * 0.8, 0);
    path.quadraticBezierTo(
        size.width * 0.9, size.height * 0.5, size.width, size.height * 0.9);

    canvas.drawPath(path, yellowPaint);

    // Draw blue location markers
    final bluePaint = Paint()..color = Colors.blue;
    canvas.drawCircle(
        Offset(size.width * 0.5, size.height * 0.3), 5, bluePaint);
    canvas.drawCircle(
        Offset(size.width * 0.3, size.height * 0.7), 5, bluePaint);
    canvas.drawCircle(
        Offset(size.width * 0.7, size.height * 0.9), 5, bluePaint);

    // Draw red marker
    final redPaint = Paint()..color = Colors.red;
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.5), 3, redPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
