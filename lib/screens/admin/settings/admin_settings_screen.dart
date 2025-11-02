import 'package:flutter/material.dart';
import '../../../services/firebase_test_service.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;
  bool _autoBackupEnabled = true;
  String _selectedLanguage = 'Tiếng Việt';
  String _selectedCurrency = 'VND';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // General Settings
            _buildSectionHeader('Cài đặt chung'),
            _buildSettingsCard([
              _buildSwitchTile(
                'Thông báo',
                'Nhận thông báo về đơn hàng và hệ thống',
                _notificationsEnabled,
                (value) => setState(() => _notificationsEnabled = value),
                Icons.notifications,
              ),
              _buildSwitchTile(
                'Chế độ tối',
                'Sử dụng giao diện tối',
                _darkModeEnabled,
                (value) => setState(() => _darkModeEnabled = value),
                Icons.dark_mode,
              ),
              _buildDropdownTile(
                'Ngôn ngữ',
                _selectedLanguage,
                ['Tiếng Việt', 'Tiếng Anh', 'Tiếng Trung'],
                (value) => setState(() => _selectedLanguage = value!),
                Icons.language,
              ),
              _buildDropdownTile(
                'Đơn vị tiền tệ',
                _selectedCurrency,
                ['VND', 'USD', 'EUR'],
                (value) => setState(() => _selectedCurrency = value!),
                Icons.attach_money,
              ),
            ]),

            const SizedBox(height: 20),

            // System Settings
            _buildSectionHeader('Hệ thống'),
            _buildSettingsCard([
              _buildSwitchTile(
                'Sao lưu tự động',
                'Tự động sao lưu dữ liệu hàng ngày',
                _autoBackupEnabled,
                (value) => setState(() => _autoBackupEnabled = value),
                Icons.backup,
              ),
              _buildActionTile(
                'Xóa cache',
                'Xóa dữ liệu cache để tăng hiệu suất',
                () => _clearCache(),
                Icons.delete_sweep,
              ),
              _buildActionTile(
                'Kiểm tra cập nhật',
                'Kiểm tra phiên bản mới',
                () => _checkUpdates(),
                Icons.system_update,
              ),
              _buildActionTile(
                'Kiểm tra Firebase',
                'Test kết nối Firebase & Firestore',
                () => _testFirebase(),
                Icons.check_circle,
              ),
              _buildActionTile(
                'Khởi động lại hệ thống',
                'Khởi động lại toàn bộ hệ thống',
                () => _restartSystem(),
                Icons.restart_alt,
              ),
            ]),

            const SizedBox(height: 20),

            // Security Settings
            _buildSectionHeader('Bảo mật'),
            _buildSettingsCard([
              _buildActionTile(
                'Đổi mật khẩu',
                'Thay đổi mật khẩu admin',
                () => _changePassword(),
                Icons.lock,
              ),
              _buildActionTile(
                'Xác thực 2FA',
                'Bật xác thực hai yếu tố',
                () => _setup2FA(),
                Icons.security,
              ),
              _buildActionTile(
                'Lịch sử đăng nhập',
                'Xem lịch sử đăng nhập',
                () => _viewLoginHistory(),
                Icons.history,
              ),
              _buildActionTile(
                'Quản lý phiên',
                'Quản lý các phiên đăng nhập',
                () => _manageSessions(),
                Icons.devices,
              ),
            ]),

            const SizedBox(height: 20),

            // Data Management
            _buildSectionHeader('Quản lý dữ liệu'),
            _buildSettingsCard([
              _buildActionTile(
                'Sao lưu dữ liệu',
                'Tạo bản sao lưu toàn bộ dữ liệu',
                () => _backupData(),
                Icons.cloud_upload,
              ),
              _buildActionTile(
                'Khôi phục dữ liệu',
                'Khôi phục dữ liệu từ bản sao lưu',
                () => _restoreData(),
                Icons.cloud_download,
              ),
              _buildActionTile(
                'Xuất dữ liệu',
                'Xuất dữ liệu ra file Excel/CSV',
                () => _exportData(),
                Icons.file_download,
              ),
              _buildActionTile(
                'Xóa dữ liệu cũ',
                'Xóa dữ liệu cũ hơn 1 năm',
                () => _cleanOldData(),
                Icons.cleaning_services,
              ),
            ]),

            const SizedBox(height: 20),

            // App Settings
            _buildSectionHeader('Ứng dụng'),
            _buildSettingsCard([
              _buildActionTile(
                'Thông tin ứng dụng',
                'Phiên bản và thông tin chi tiết',
                () => _showAppInfo(),
                Icons.info,
              ),
              _buildActionTile(
                'Điều khoản sử dụng',
                'Xem điều khoản và chính sách',
                () => _showTerms(),
                Icons.description,
              ),
              _buildActionTile(
                'Liên hệ hỗ trợ',
                'Liên hệ với đội ngũ hỗ trợ',
                () => _contactSupport(),
                Icons.support_agent,
              ),
              _buildActionTile(
                'Đánh giá ứng dụng',
                'Đánh giá ứng dụng trên store',
                () => _rateApp(),
                Icons.star_rate,
              ),
            ]),

            const SizedBox(height: 20),

            // Danger Zone
            _buildSectionHeader('Khu vực nguy hiểm'),
            _buildSettingsCard([
              _buildDangerTile(
                'Đặt lại cài đặt',
                'Khôi phục tất cả cài đặt về mặc định',
                () => _resetSettings(),
                Icons.restore,
              ),
              _buildDangerTile(
                'Xóa tài khoản',
                'Xóa vĩnh viễn tài khoản admin',
                () => _deleteAccount(),
                Icons.person_remove,
              ),
            ]),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
    IconData icon,
  ) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey.shade600),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: Colors.red.shade600,
      ),
    );
  }

  Widget _buildDropdownTile(
    String title,
    String value,
    List<String> items,
    ValueChanged<String?> onChanged,
    IconData icon,
  ) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey.shade600),
      title: Text(title),
      subtitle: Text(value),
      trailing: DropdownButton<String>(
        value: value,
        underline: const SizedBox(),
        items: items.map((String item) {
          return DropdownMenuItem<String>(value: item, child: Text(item));
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildActionTile(
    String title,
    String subtitle,
    VoidCallback onTap,
    IconData icon,
  ) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey.shade600),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  Widget _buildDangerTile(
    String title,
    String subtitle,
    VoidCallback onTap,
    IconData icon,
  ) {
    return ListTile(
      leading: Icon(icon, color: Colors.red.shade600),
      title: Text(title, style: TextStyle(color: Colors.red.shade600)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  void _clearCache() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa cache'),
        content: const Text('Bạn có chắc chắn muốn xóa cache?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã xóa cache thành công')),
              );
            },
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  void _checkUpdates() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Đang kiểm tra cập nhật...')));
  }

  void _restartSystem() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Khởi động lại hệ thống'),
        content: const Text('Bạn có chắc chắn muốn khởi động lại hệ thống?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đang khởi động lại hệ thống...')),
              );
            },
            child: const Text('Khởi động lại'),
          ),
        ],
      ),
    );
  }

  void _changePassword() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Đổi mật khẩu',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            TextField(
              decoration: const InputDecoration(
                labelText: 'Mật khẩu hiện tại',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 12),

            TextField(
              decoration: const InputDecoration(
                labelText: 'Mật khẩu mới',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 12),

            TextField(
              decoration: const InputDecoration(
                labelText: 'Xác nhận mật khẩu mới',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Hủy'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Đổi mật khẩu thành công'),
                        ),
                      );
                    },
                    child: const Text('Đổi mật khẩu'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _setup2FA() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tính năng 2FA sẽ được cập nhật')),
    );
  }

  void _viewLoginHistory() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tính năng lịch sử đăng nhập sẽ được cập nhật'),
      ),
    );
  }

  void _manageSessions() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tính năng quản lý phiên sẽ được cập nhật')),
    );
  }

  void _backupData() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Đang tạo bản sao lưu...')));
  }

  void _restoreData() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tính năng khôi phục dữ liệu sẽ được cập nhật'),
      ),
    );
  }

  void _exportData() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tính năng xuất dữ liệu sẽ được cập nhật')),
    );
  }

  void _cleanOldData() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa dữ liệu cũ'),
        content: const Text('Bạn có chắc chắn muốn xóa dữ liệu cũ hơn 1 năm?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã xóa dữ liệu cũ')),
              );
            },
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  void _showAppInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thông tin ứng dụng'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tên: HatStyle Admin'),
            Text('Phiên bản: 1.0.0'),
            Text('Build: 2024.01.01'),
            Text('Nhà phát triển: HatStyle Team'),
            Text('Email: admin@hatstyle.com'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _showTerms() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tính năng điều khoản sẽ được cập nhật')),
    );
  }

  void _contactSupport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tính năng hỗ trợ sẽ được cập nhật')),
    );
  }

  void _rateApp() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tính năng đánh giá sẽ được cập nhật')),
    );
  }

  void _resetSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đặt lại cài đặt'),
        content: const Text(
          'Bạn có chắc chắn muốn đặt lại tất cả cài đặt về mặc định?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã đặt lại cài đặt')),
              );
            },
            child: const Text('Đặt lại'),
          ),
        ],
      ),
    );
  }

  void _deleteAccount() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa tài khoản'),
        content: const Text(
          'Bạn có chắc chắn muốn xóa vĩnh viễn tài khoản admin? Hành động này không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tài khoản đã được xóa')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  Future<void> _testFirebase() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Đang kiểm tra Firebase...'),
              ],
            ),
          ),
        ),
      ),
    );

    Map<String, dynamic> results = await FirebaseTestService.runFullTest();

    if (context.mounted) {
      Navigator.pop(context);

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Kết Quả Kiểm Tra Firebase'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTestResult('Kết nối', results['connection']),
                _buildTestResult('Authentication', results['authentication']),
                _buildTestResult('Users', results['users']),
                _buildTestResult('Products', results['products']),
                _buildTestResult('Orders', results['orders']),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng'),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildTestResult(String label, Map<String, dynamic>? result) {
    if (result == null) return const SizedBox();

    final bool success = result['success'] == true;
    final String message = result['message'] ?? result['error'] ?? '';
    final int? count = result['count'];

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            success ? Icons.check_circle : Icons.error,
            color: success ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (count != null) Text('Số lượng: $count'),
                Text(
                  message,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
