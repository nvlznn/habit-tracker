import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Consumer<ThemeProvider>(
            builder: (context, theme, _) => SwitchListTile(
              secondary: Icon(
                theme.isDark ? Icons.dark_mode : Icons.light_mode,
              ),
              title: const Text('Dark mode'),
              subtitle: Text(theme.isDark ? 'On' : 'Off'),
              value: theme.isDark,
              onChanged: (_) => theme.toggle(),
            ),
          ),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('About habibi'),
            subtitle: Text(
                'A minimal habit tracker. School project for the DSAP course.'),
          ),
          const ListTile(
            leading: Icon(Icons.tag),
            title: Text('Version'),
            subtitle: Text('0.1.0 (prototype)'),
          ),
        ],
      ),
    );
  }
}
