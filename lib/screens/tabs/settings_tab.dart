import 'package:flutter/material.dart';

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ListTile(
          leading: const Icon(Icons.person),
          title: const Text('Profile'),
          onTap: () {
            // TODO: Implement profile settings
          },
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.image_outlined),
          title: const Text('Image Quality'),
          onTap: () {
            // TODO: Implement image quality settings
          },
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.dark_mode),
          title: const Text('Dark Mode'),
          onTap: () {
            // TODO: Implement dark mode settings
          },
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.info_outline),
          title: const Text('About'),
          onTap: () {
            // TODO: Implement about page
          },
        ),
        const Divider(),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16.0),
          child: Center(
            child: Text(
              'Version V 0.0.2',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
