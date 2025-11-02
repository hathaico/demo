import 'package:flutter/material.dart';
import '../../../services/settings_service.dart';
import '../../../services/cart_service.dart';
import '../../../services/wishlist_service.dart';
import '../../../services/product_cache_service.dart';
import '../help/user_help_screen.dart';
import '../support/user_support_screen.dart';

class UserSettingsScreen extends StatefulWidget {
  const UserSettingsScreen({super.key});

  @override
  State<UserSettingsScreen> createState() => _UserSettingsScreenState();
}

class _UserSettingsScreenState extends State<UserSettingsScreen> {
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _biometricEnabled = false;
  bool _autoLogin = false;
  String _language = 'vi';
  String _themeMode = 'system';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await SettingsService.getAllUserSettings();
    setState(() {
      _notificationsEnabled = settings['notifications'] ?? true;
      _soundEnabled = settings['sound'] ?? true;
      _vibrationEnabled = settings['vibration'] ?? true;
      _biometricEnabled = settings['biometric'] ?? false;
      _autoLogin = settings['autoLogin'] ?? false;
      _language = settings['language'] ?? 'vi';
      _themeMode = settings['themeMode'] ?? 'system';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài Đặt'),
        backgroundColor: const Color.fromARGB(255, 249, 249, 249),
        foregroundColor: const Color.fromARGB(255, 0, 0, 0),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Thông báo
          _buildSectionTitle('Thông báo'),
          _buildSwitchTile(
            title: 'Bật thông báo',
            subtitle: 'Nhận thông báo về đơn hàng và khuyến mãi',
            value: _notificationsEnabled,
            onChanged: (value) async {
              setState(() => _notificationsEnabled = value);
              await SettingsService.setNotificationsEnabled(value);
            },
          ),
          _buildSwitchTile(
            title: 'Âm thanh',
            subtitle: 'Phát âm thanh khi có thông báo',
            value: _soundEnabled,
            onChanged: (value) async {
              setState(() => _soundEnabled = value);
              await SettingsService.setSoundEnabled(value);
            },
            enabled: _notificationsEnabled,
          ),
          _buildSwitchTile(
            title: 'Rung',
            subtitle: 'Rung điện thoại khi có thông báo',
            value: _vibrationEnabled,
            onChanged: (value) async {
              setState(() => _vibrationEnabled = value);
              await SettingsService.setVibrationEnabled(value);
            },
            enabled: _notificationsEnabled,
          ),

          const SizedBox(height: 24),

          // Bảo mật
          _buildSectionTitle('Bảo mật'),
          _buildSwitchTile(
            title: 'Đăng nhập sinh trắc học',
            subtitle: 'Sử dụng vân tay hoặc Face ID',
            value: _biometricEnabled,
            onChanged: (value) async {
              setState(() => _biometricEnabled = value);
              await SettingsService.setBiometricEnabled(value);
            },
          ),
          _buildSwitchTile(
            title: 'Tự động đăng nhập',
            subtitle: 'Giữ trạng thái đăng nhập',
            value: _autoLogin,
            onChanged: (value) async {
              setState(() => _autoLogin = value);
              await SettingsService.setAutoLogin(value);
            },
          ),

          const SizedBox(height: 24),

          // Giao diện
          _buildSectionTitle('Giao diện'),
          ListTile(
            title: const Text('Ngôn ngữ'),
            subtitle: Text(_getLanguageName(_language)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showLanguagePicker(),
          ),
          ListTile(
            title: const Text('Chủ đề'),
            subtitle: Text(_getThemeModeName(_themeMode)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showThemePicker(),
          ),

          const SizedBox(height: 24),

          // Hỗ trợ
          _buildSectionTitle('Hỗ trợ'),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('Trung tâm trợ giúp'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const UserHelpScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.feedback_outlined),
            title: const Text('Gửi phản hồi'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const UserSupportScreen(),
                ),
              );
            },
          ),

          const SizedBox(height: 24),

          // Thông tin
          _buildSectionTitle('Thông tin'),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Giới thiệu HatStyle'),
            subtitle: const Text('Phiên bản 1.0.0'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'HatStyle',
                applicationVersion: '1.0.0',
                applicationIcon: Icon(
                  Icons.style,
                  size: 48,
                  color: Colors.blue.shade600,
                ),
              );
            },
          ),

          const SizedBox(height: 24),

          // Khu vực nguy hiểm
          _buildSectionTitle('Khu vực nguy hiểm'),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.red),
            title: const Text(
              'Xóa dữ liệu ứng dụng',
              style: TextStyle(color: Colors.red),
            ),
            subtitle: const Text('Xóa tất cả dữ liệu local'),
            onTap: () => _showDeleteDataDialog(),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade700,
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool enabled = true,
  }) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: enabled ? onChanged : null,
    );
  }

  String _getLanguageName(String code) {
    switch (code) {
      case 'vi':
        return 'Tiếng Việt';
      case 'en':
        return 'English';
      case 'zh':
        return '中文';
      case 'ja':
        return '日本語';
      default:
        return 'Tiếng Việt';
    }
  }

  String _getThemeModeName(String mode) {
    switch (mode) {
      case 'system':
        return 'Theo hệ thống';
      case 'light':
        return 'Sáng';
      case 'dark':
        return 'Tối';
      default:
        return 'Theo hệ thống';
    }
  }

  void _showLanguagePicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chọn ngôn ngữ'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLanguageOption('vi', 'Tiếng Việt'),
            _buildLanguageOption('en', 'English'),
            _buildLanguageOption('zh', '中文'),
            _buildLanguageOption('ja', '日本語'),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(String code, String name) {
    final isSelected = _language == code;
    return ListTile(
      title: Text(name),
      trailing: isSelected ? const Icon(Icons.check, color: Colors.blue) : null,
      selected: isSelected,
      onTap: () async {
        setState(() => _language = code);
        await SettingsService.setLanguage(code);
        Navigator.pop(context);
      },
    );
  }

  void _showThemePicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chọn chủ đề'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildThemeOption('system', 'Theo hệ thống', Icons.brightness_auto),
            _buildThemeOption('light', 'Sáng', Icons.light_mode),
            _buildThemeOption('dark', 'Tối', Icons.dark_mode),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption(String mode, String name, IconData icon) {
    final isSelected = _themeMode == mode;
    return ListTile(
      leading: Icon(icon),
      title: Text(name),
      trailing: isSelected ? const Icon(Icons.check, color: Colors.blue) : null,
      selected: isSelected,
      onTap: () async {
        setState(() => _themeMode = mode);
        await SettingsService.setThemeMode(mode);
        Navigator.pop(context);
      },
    );
  }

  void _showDeleteDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa dữ liệu'),
        content: const Text(
          'Bạn có chắc chắn muốn xóa tất cả dữ liệu local?\n\n'
          'Hành động này không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await Future.wait([
                  CartService.clearCart(),
                  WishlistService.clearWishlist(),
                  SettingsService.resetUserSettings(),
                  ProductCacheService.clearAll(),
                ]);
                if (!mounted) {
                  return;
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã xóa dữ liệu local và thiết lập ứng dụng'),
                  ),
                );
              } catch (e) {
                if (!mounted) {
                  return;
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Không thể xóa dữ liệu: $e'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
