import 'package:flutter/material.dart';
import '../services/settings_service.dart';

class SettingsDemoScreen extends StatefulWidget {
  const SettingsDemoScreen({super.key});

  @override
  State<SettingsDemoScreen> createState() => _SettingsDemoScreenState();
}

class _SettingsDemoScreenState extends State<SettingsDemoScreen> {
  Map<String, dynamic> _userSettings = {};
  Map<String, dynamic> _adminSettings = {};

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final userSettings = await SettingsService.getAllUserSettings();
    final adminSettings = await SettingsService.getAllAdminSettings();

    setState(() {
      _userSettings = userSettings;
      _adminSettings = adminSettings;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings Demo'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Settings
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'User Settings',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ..._userSettings.entries.map(
                      (entry) =>
                          _buildSettingItem(entry.key, entry.value.toString()),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Admin Settings
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Admin Settings',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ..._adminSettings.entries.map(
                      (entry) =>
                          _buildSettingItem(entry.key, entry.value.toString()),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Test Buttons
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Test Functions',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade600,
                      ),
                    ),
                    const SizedBox(height: 16),

                    ElevatedButton(
                      onPressed: () async {
                        await SettingsService.setNotificationsEnabled(true);
                        _loadSettings();
                      },
                      child: const Text('Enable Notifications'),
                    ),

                    const SizedBox(height: 8),

                    ElevatedButton(
                      onPressed: () async {
                        await SettingsService.setLanguage('en');
                        _loadSettings();
                      },
                      child: const Text('Set Language to English'),
                    ),

                    const SizedBox(height: 8),

                    ElevatedButton(
                      onPressed: () async {
                        await SettingsService.setSystemMaintenance(true);
                        _loadSettings();
                      },
                      child: const Text('Enable System Maintenance'),
                    ),

                    const SizedBox(height: 8),

                    ElevatedButton(
                      onPressed: () async {
                        await SettingsService.resetAllSettings();
                        _loadSettings();
                      },
                      child: const Text('Reset All Settings'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem(String key, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(key, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: TextStyle(color: Colors.grey.shade600)),
        ],
      ),
    );
  }
}
