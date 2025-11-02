import 'package:flutter/material.dart';

class AdminHelpScreen extends StatefulWidget {
  const AdminHelpScreen({super.key});

  @override
  State<AdminHelpScreen> createState() => _AdminHelpScreenState();
}

class _AdminHelpScreenState extends State<AdminHelpScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trợ Giúp'),
        backgroundColor: const Color.from(alpha: 1, red: 1, green: 1, blue: 1),
        foregroundColor: const Color.fromRGBO(0, 0, 0, 1),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Quick Links
          _buildSectionTitle('Liên kết nhanh'),
          _buildQuickLinks(),

          const SizedBox(height: 22),

          // Common Tasks
          _buildSectionTitle('Tác vụ thường dùng'),
          _buildCommonTasks(),

          const SizedBox(height: 22),

          // FAQs
          _buildSectionTitle('Câu hỏi thường gặp'),
          _buildFAQs(),

          const SizedBox(height: 22),

          // System Guide
          _buildSectionTitle('Hướng dẫn hệ thống'),
          _buildSystemGuides(),

          const SizedBox(height: 22),

          // Keyboard Shortcuts
          _buildSectionTitle('Phím tắt'),
          _buildKeyboardShortcuts(),
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

  Widget _buildQuickLinks() {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.dashboard, color: Colors.blue),
            title: const Text('Hướng dẫn Dashboard'),
            subtitle: const Text('Cách sử dụng bảng điều khiển'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showGuide('Dashboard'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.inventory, color: Colors.green),
            title: const Text('Quản lý sản phẩm'),
            subtitle: const Text('Thêm, sửa, xóa sản phẩm'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showGuide('Products'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.shopping_cart, color: Colors.orange),
            title: const Text('Quản lý đơn hàng'),
            subtitle: const Text('Xử lý và theo dõi đơn hàng'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showGuide('Orders'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.people, color: Colors.purple),
            title: const Text('Quản lý người dùng'),
            subtitle: const Text('Xem và chỉnh sửa thông tin user'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showGuide('Users'),
          ),
        ],
      ),
    );
  }

  Widget _buildCommonTasks() {
    final tasks = [
      {
        'icon': Icons.add_circle_outline,
        'title': 'Thêm sản phẩm mới',
        'color': Colors.green,
      },
      {'icon': Icons.edit, 'title': 'Chỉnh sửa sản phẩm', 'color': Colors.blue},
      {
        'icon': Icons.update,
        'title': 'Cập nhật trạng thái đơn hàng',
        'color': Colors.orange,
      },
      {
        'icon': Icons.block,
        'title': 'Khóa/Mở khóa tài khoản',
        'color': Colors.red,
      },
      {'icon': Icons.report, 'title': 'Xem báo cáo', 'color': Colors.purple},
      {
        'icon': Icons.settings,
        'title': 'Cài đặt hệ thống',
        'color': Colors.grey,
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return Card(
          child: InkWell(
            onTap: () => _showTaskHelp(task['title'] as String),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    task['icon'] as IconData,
                    color: task['color'] as Color,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    task['title'] as String,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFAQs() {
    final faqs = [
      {
        'question': 'Làm sao để reset mật khẩu admin?',
        'answer':
            'Liên hệ IT Support hoặc sử dụng tính năng "Quên mật khẩu" trong trang đăng nhập.',
      },
      {
        'question': 'Cách backup dữ liệu?',
        'answer':
            'Vào Settings > Backup & Restore > Nhấn "Backup Now". Hệ thống sẽ tự động tạo backup mỗi ngày.',
      },
      {
        'question': 'Làm sao để xóa sản phẩm?',
        'answer':
            'Vào Products > Chọn sản phẩm > Nhấn biểu tượng xóa > Xác nhận. Lưu ý: Xóa sản phẩm sẽ không thể hoàn tác!',
      },
      {
        'question': 'Tôi không thấy một số đơn hàng?',
        'answer':
            'Kiểm tra bộ lọc trạng thái đơn hàng. Thử reset filter hoặc liên hệ IT Support.',
      },
    ];

    return Column(
      children: faqs.map((faq) {
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ExpansionTile(
            title: Text(faq['question'] ?? ''),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  faq['answer'] ?? '',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSystemGuides() {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.video_library, color: Colors.red),
            title: const Text('Video hướng dẫn'),
            subtitle: const Text('Xem hướng dẫn sử dụng hệ thống'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.article, color: Colors.blue),
            title: const Text('Tài liệu chi tiết'),
            subtitle: const Text('PDF guide đầy đủ về hệ thống'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.book, color: Colors.green),
            title: const Text('Best Practices'),
            subtitle: const Text('Các thực hành tốt nhất'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildKeyboardShortcuts() {
    final shortcuts = [
      {'key': 'Ctrl + S', 'desc': 'Lưu thay đổi'},
      {'key': 'Ctrl + F', 'desc': 'Tìm kiếm'},
      {'key': 'Ctrl + R', 'desc': 'Refresh dữ liệu'},
      {'key': 'Esc', 'desc': 'Đóng dialog'},
      {'key': 'Ctrl + P', 'desc': 'Xuất báo cáo'},
    ];

    return Card(
      child: Column(
        children: shortcuts.map((shortcut) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(shortcut['desc'] ?? ''),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    shortcut['key'] ?? '',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showGuide(String guideType) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hướng dẫn $guideType'),
        content: Text(
          'Hướng dẫn chi tiết về $guideType sẽ sớm được cập nhật.\n\n'
          'Vui lòng liên hệ IT Support để được hướng dẫn trực tiếp.',
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

  void _showTaskHelp(String taskName) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              taskName,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Hướng dẫn chi tiết sẽ sớm được cập nhật.\n\n'
              'Hiện tại bạn có thể tham khảo tài liệu hoặc liên hệ IT Support.',
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng'),
            ),
          ],
        ),
      ),
    );
  }
}
