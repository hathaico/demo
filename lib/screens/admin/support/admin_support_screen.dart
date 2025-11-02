import 'package:flutter/material.dart';

class AdminSupportScreen extends StatefulWidget {
  const AdminSupportScreen({super.key});

  @override
  State<AdminSupportScreen> createState() => _AdminSupportScreenState();
}

class _AdminSupportScreenState extends State<AdminSupportScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hỗ Trợ'),
        backgroundColor: const Color.fromRGBO(255, 255, 255, 1),
        foregroundColor: const Color.fromRGBO(0, 0, 0, 1),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // System Status
          _buildSystemStatusCard(),

          const SizedBox(height: 24),

          // Technical Support
          _buildSectionTitle('Hỗ trợ kỹ thuật'),
          _buildTechnicalSupport(),

          const SizedBox(height: 24),

          // System Resources
          _buildSectionTitle('Tài nguyên hệ thống'),
          _buildSystemResources(),

          const SizedBox(height: 24),

          // Contact Information
          _buildSectionTitle('Thông tin liên hệ'),
          _buildContactInfo(),

          const SizedBox(height: 24),

          // Documentation
          _buildSectionTitle('Tài liệu'),
          _buildDocumentation(),
        ],
      ),
    );
  }

  Widget _buildSystemStatusCard() {
    return Card(
      color: const Color.fromARGB(255, 255, 255, 255),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green.shade600),
                const SizedBox(width: 8),
                const Text(
                  'Trạng thái hệ thống',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildStatusItem('Firebase', 'Đang hoạt động', Colors.green),
            _buildStatusItem('Database', 'Kết nối ổn định', Colors.green),
            _buildStatusItem('Storage', 'Kết nối ổn định', Colors.green),
            _buildStatusItem('API Server', 'Đang hoạt động', Colors.green),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusItem(String label, String status, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color),
            ),
            child: Row(
              children: [
                Icon(Icons.fiber_manual_record, size: 8, color: color),
                const SizedBox(width: 4),
                Text(
                  status,
                  style: TextStyle(color: color, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade700,
        ),
      ),
    );
  }

  Widget _buildTechnicalSupport() {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.bug_report, color: Colors.red),
            title: const Text('Báo lỗi hệ thống'),
            subtitle: const Text('Gửi báo cáo về lỗi hoặc sự cố'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _reportBug(),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.help, color: Colors.blue),
            title: const Text('Yêu cầu hỗ trợ'),
            subtitle: const Text('Liên hệ với đội ngũ kỹ thuật'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _requestSupport(),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.lightbulb_outline, color: Colors.green),
            title: const Text('Đề xuất tính năng'),
            subtitle: const Text('Đóng góp ý kiến cải thiện'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _suggestFeature(),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemResources() {
    return Column(
      children: [
        _buildResourceCard(
          icon: Icons.memory,
          title: 'Sử dụng tài nguyên',
          description: 'CPU: 25% | RAM: 45% | Storage: 60%',
          color: Colors.blue,
        ),
        const SizedBox(height: 12),
        _buildResourceCard(
          icon: Icons.cloud,
          title: 'Firebase Usage',
          description: 'Reads: 1.2K/day | Writes: 450/day',
          color: Colors.orange,
        ),
        const SizedBox(height: 12),
        _buildResourceCard(
          icon: Icons.storage,
          title: 'Database Size',
          description: 'Total: 2.5GB | Available: 47.5GB',
          color: Colors.green,
        ),
      ],
    );
  }

  Widget _buildResourceCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.1),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
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

  Widget _buildContactInfo() {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.email),
            title: const Text('Email hỗ trợ'),
            subtitle: const Text('admin-support@hatstyle.com'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.phone),
            title: const Text('Điện thoại'),
            subtitle: const Text('1900 8888 (Phím 0)'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.schedule),
            title: const Text('Giờ làm việc'),
            subtitle: const Text('24/7 - Hỗ trợ liên tục'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentation() {
    return Column(
      children: [
        _buildDocCard(
          icon: Icons.menu_book,
          title: 'Hướng dẫn sử dụng Admin',
          description: 'Cách sử dụng tất cả tính năng quản trị',
        ),
        const SizedBox(height: 12),
        _buildDocCard(
          icon: Icons.api,
          title: 'API Documentation',
          description: 'Chi tiết về REST API và Firebase',
        ),
        const SizedBox(height: 12),
        _buildDocCard(
          icon: Icons.security,
          title: 'Bảo mật',
          description: 'Hướng dẫn bảo mật hệ thống',
        ),
      ],
    );
  }

  Widget _buildDocCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: Colors.blue.shade600),
        title: Text(title),
        subtitle: Text(description),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {},
      ),
    );
  }

  void _reportBug() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Báo lỗi hệ thống'),
        content: const Text(
          'Tính năng báo lỗi sẽ sớm được cập nhật.\n\n'
          'Hiện tại bạn có thể liên hệ trực tiếp qua:\n'
          '• Email: admin-support@hatstyle.com\n'
          '• Hotline: 1900 8888',
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

  void _requestSupport() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yêu cầu hỗ trợ'),
        content: const Text(
          'Vui lòng liên hệ:\n\n'
          '• Hotline: 1900 8888 (Phím 0 cho admin)\n'
          '• Email: admin-support@hatstyle.com\n'
          '• Chat: Chưa khả dụng\n\n'
          'Giờ làm việc: 24/7',
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

  void _suggestFeature() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đề xuất tính năng'),
        content: const Text(
          'Cảm ơn bạn đã quan tâm đến việc cải thiện HatStyle!\n\n'
          'Vui lòng gửi đề xuất qua:\n'
          '• Email: feedback@hatstyle.com\n'
          '• Form: https://hatstyle.com/feedback',
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

