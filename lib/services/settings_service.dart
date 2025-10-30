import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class SettingsService {
  static const String _settingsKey = 'app_settings';
  static const String _userPreferencesKey = 'user_preferences';
  static const String _adminPreferencesKey = 'admin_preferences';

  // User Settings
  static const String _notificationsKey = 'notifications_enabled';
  static const String _languageKey = 'language';
  static const String _themeKey = 'theme_mode';
  static const String _biometricKey = 'biometric_enabled';
  static const String _autoLoginKey = 'auto_login';
  static const String _soundKey = 'sound_enabled';
  static const String _vibrationKey = 'vibration_enabled';

  // Admin Settings
  static const String _systemMaintenanceKey = 'system_maintenance';
  static const String _backupEnabledKey = 'backup_enabled';
  static const String _autoBackupKey = 'auto_backup';
  static const String _securityLevelKey = 'security_level';
  static const String _emailNotificationsKey = 'email_notifications';
  static const String _smsNotificationsKey = 'sms_notifications';

  // User Settings Methods
  static Future<bool> getNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_notificationsKey) ?? true;
  }

  static Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsKey, enabled);
  }

  static Future<String> getLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_languageKey) ?? 'vi';
  }

  static Future<void> setLanguage(String language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, language);
  }

  static Future<String> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_themeKey) ?? 'system';
  }

  static Future<void> setThemeMode(String themeMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, themeMode);
  }

  static Future<bool> getBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_biometricKey) ?? false;
  }

  static Future<void> setBiometricEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricKey, enabled);
  }

  static Future<bool> getAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_autoLoginKey) ?? false;
  }

  static Future<void> setAutoLogin(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoLoginKey, enabled);
  }

  static Future<bool> getSoundEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_soundKey) ?? true;
  }

  static Future<void> setSoundEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_soundKey, enabled);
  }

  static Future<bool> getVibrationEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_vibrationKey) ?? true;
  }

  static Future<void> setVibrationEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_vibrationKey, enabled);
  }

  // Admin Settings Methods
  static Future<bool> getSystemMaintenance() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_systemMaintenanceKey) ?? false;
  }

  static Future<void> setSystemMaintenance(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_systemMaintenanceKey, enabled);
  }

  static Future<bool> getBackupEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_backupEnabledKey) ?? true;
  }

  static Future<void> setBackupEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_backupEnabledKey, enabled);
  }

  static Future<bool> getAutoBackup() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_autoBackupKey) ?? true;
  }

  static Future<void> setAutoBackup(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoBackupKey, enabled);
  }

  static Future<String> getSecurityLevel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_securityLevelKey) ?? 'medium';
  }

  static Future<void> setSecurityLevel(String level) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_securityLevelKey, level);
  }

  static Future<bool> getEmailNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_emailNotificationsKey) ?? true;
  }

  static Future<void> setEmailNotifications(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_emailNotificationsKey, enabled);
  }

  static Future<bool> getSmsNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_smsNotificationsKey) ?? false;
  }

  static Future<void> setSmsNotifications(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_smsNotificationsKey, enabled);
  }

  // Get all user settings
  static Future<Map<String, dynamic>> getAllUserSettings() async {
    return {
      'notifications': await getNotificationsEnabled(),
      'language': await getLanguage(),
      'themeMode': await getThemeMode(),
      'biometric': await getBiometricEnabled(),
      'autoLogin': await getAutoLogin(),
      'sound': await getSoundEnabled(),
      'vibration': await getVibrationEnabled(),
    };
  }

  // Get all admin settings
  static Future<Map<String, dynamic>> getAllAdminSettings() async {
    return {
      'systemMaintenance': await getSystemMaintenance(),
      'backupEnabled': await getBackupEnabled(),
      'autoBackup': await getAutoBackup(),
      'securityLevel': await getSecurityLevel(),
      'emailNotifications': await getEmailNotifications(),
      'smsNotifications': await getSmsNotifications(),
    };
  }

  // Reset all settings
  static Future<void> resetAllSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_settingsKey);
    await prefs.remove(_userPreferencesKey);
    await prefs.remove(_adminPreferencesKey);
  }

  // Reset user settings
  static Future<void> resetUserSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_notificationsKey);
    await prefs.remove(_languageKey);
    await prefs.remove(_themeKey);
    await prefs.remove(_biometricKey);
    await prefs.remove(_autoLoginKey);
    await prefs.remove(_soundKey);
    await prefs.remove(_vibrationKey);
  }

  // Reset admin settings
  static Future<void> resetAdminSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_systemMaintenanceKey);
    await prefs.remove(_backupEnabledKey);
    await prefs.remove(_autoBackupKey);
    await prefs.remove(_securityLevelKey);
    await prefs.remove(_emailNotificationsKey);
    await prefs.remove(_smsNotificationsKey);
  }

  // Export settings
  static Future<String> exportSettings() async {
    final userSettings = await getAllUserSettings();
    final adminSettings = await getAllAdminSettings();
    
    final exportData = {
      'userSettings': userSettings,
      'adminSettings': adminSettings,
      'exportDate': DateTime.now().toIso8601String(),
      'appVersion': '1.0.0',
    };
    
    return jsonEncode(exportData);
  }

  // Import settings
  static Future<bool> importSettings(String jsonData) async {
    try {
      final Map<String, dynamic> data = jsonDecode(jsonData);
      
      if (data.containsKey('userSettings')) {
        final userSettings = data['userSettings'] as Map<String, dynamic>;
        await setNotificationsEnabled(userSettings['notifications'] ?? true);
        await setLanguage(userSettings['language'] ?? 'vi');
        await setThemeMode(userSettings['themeMode'] ?? 'system');
        await setBiometricEnabled(userSettings['biometric'] ?? false);
        await setAutoLogin(userSettings['autoLogin'] ?? false);
        await setSoundEnabled(userSettings['sound'] ?? true);
        await setVibrationEnabled(userSettings['vibration'] ?? true);
      }
      
      if (data.containsKey('adminSettings')) {
        final adminSettings = data['adminSettings'] as Map<String, dynamic>;
        await setSystemMaintenance(adminSettings['systemMaintenance'] ?? false);
        await setBackupEnabled(adminSettings['backupEnabled'] ?? true);
        await setAutoBackup(adminSettings['autoBackup'] ?? true);
        await setSecurityLevel(adminSettings['securityLevel'] ?? 'medium');
        await setEmailNotifications(adminSettings['emailNotifications'] ?? true);
        await setSmsNotifications(adminSettings['smsNotifications'] ?? false);
      }
      
      return true;
    } catch (e) {
      return false;
    }
  }
}

