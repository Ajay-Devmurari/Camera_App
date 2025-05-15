import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

enum LocationPermissionOption { always, whileInUse, onlyThisTime, deny }

class LocationPermissionDialog extends StatelessWidget {
  const LocationPermissionDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.location_on,
                        color: Theme.of(context).primaryColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Use your location',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Allow Gallery App to access your location to tag photos with location information',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Colors.grey[600],
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              _PermissionOption(
                title: 'Allow all the time',
                subtitle: 'Access location in background',
                icon: Icons.location_on,
                onTap: () =>
                    _handlePermission(context, LocationPermissionOption.always),
              ),
              _PermissionOption(
                title: 'While using the app',
                subtitle: 'Only access location when app is in use',
                icon: Icons.location_searching,
                onTap: () => _handlePermission(
                    context, LocationPermissionOption.whileInUse),
              ),
              _PermissionOption(
                title: 'Only this time',
                subtitle: 'Ask again next time',
                icon: Icons.timer,
                onTap: () => _handlePermission(
                    context, LocationPermissionOption.onlyThisTime),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(
                    'DON\'T ALLOW',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handlePermission(
      BuildContext context, LocationPermissionOption option) async {
    PermissionStatus status;

    switch (option) {
      case LocationPermissionOption.always:
        status = await Permission.locationAlways.request();
        break;
      case LocationPermissionOption.whileInUse:
        status = await Permission.locationWhenInUse.request();
        break;
      case LocationPermissionOption.onlyThisTime:
        status = await Permission.locationWhenInUse.request();
        break;
      case LocationPermissionOption.deny:
        status = PermissionStatus.denied;
        break;
    }

    if (context.mounted) {
      Navigator.pop(context, status.isGranted);
    }
  }
}

class _PermissionOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _PermissionOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Icon(
              icon,
              size: 24,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
