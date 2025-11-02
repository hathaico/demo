import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class UserSupportScreen extends StatefulWidget {
  const UserSupportScreen({super.key});

  @override
  State<UserSupportScreen> createState() => _UserSupportScreenState();
}

class _UserSupportScreenState extends State<UserSupportScreen> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  String _selectedCategory = 'Tổng quát';

  final List<String> _categories = [
    'Tổng quát',
    'Đơn hàng',
    'Sản phẩm',
    'Thanh toán',
    'Vận chuyển',
    'Tài khoản',
    'Kỹ thuật',
    'Khác',
  ];

  @override
  void dispose() {
    _messageController.dispose();
    _subjectController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hỗ Trợ'),
        backgroundColor: const Color(0xFFFFFFFF),
        foregroundColor: const Color.fromARGB(255, 0, 0, 0),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Banner
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade400, Colors.pink.shade400],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(Icons.support_agent, size: 48, color: Colors.white),
                const SizedBox(height: 12),
                const Text(
                  'Chúng tôi luôn sẵn sàng hỗ trợ bạn!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Liên hệ chúng tôi qua nhiều kênh khác nhau',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Quick Contact
          _buildSectionTitle('Liên hệ nhanh'),
          _buildQuickContactCard(),

          const SizedBox(height: 24),

          // Contact Form
          _buildSectionTitle('Gửi tin nhắn cho chúng tôi'),
          _buildContactForm(),

          const SizedBox(height: 24),

          // FAQ
          _buildSectionTitle('Câu hỏi thường gặp'),
          _buildFAQSection(),

          const SizedBox(height: 24),

          // Social Media
          _buildSectionTitle('Mạng xã hội'),
          _buildSocialMediaSection(),
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

  Widget _buildQuickContactCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildContactItem(
              icon: Icons.phone,
              title: 'Hotline',
              subtitle: '1900 8888',
              color: Colors.green,
              onTap: () => _makePhoneCall('19008888'),
            ),
            const Divider(),
            _buildContactItem(
              icon: Icons.email,
              title: 'Email',
              subtitle: 'support@hatstyle.com',
              color: Colors.blue,
              onTap: () => _sendEmail('support@hatstyle.com'),
            ),
            const Divider(),
            _buildContactItem(
              icon: Icons.chat,
              title: 'Chat trực tuyến',
              subtitle: 'Sẵn sàng 24/7',
              color: Colors.orange,
              onTap: () => _openLiveChat(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.1),
        child: Icon(icon, color: color),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Widget _buildContactForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Danh mục',
                border: OutlineInputBorder(),
              ),
              items: _categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedCategory = value!);
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _subjectController,
              decoration: const InputDecoration(
                labelText: 'Tiêu đề',
                border: OutlineInputBorder(),
                hintText: 'Nhập tiêu đề tin nhắn',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _messageController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Nội dung',
                border: OutlineInputBorder(),
                hintText: 'Nhập nội dung tin nhắn...',
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _sendMessage,
                icon: const Icon(Icons.send),
                label: const Text('Gửi tin nhắn'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQSection() {
    return Column(
      children: _faqItems.map((item) {
        return ExpansionTile(
          title: Text(item['question'] ?? ''),
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                item['answer'] ?? '',
                style: TextStyle(color: Colors.grey.shade700),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildSocialMediaSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildSocialIcon(Icons.facebook, 'Facebook', Colors.blue, () {}),
        _buildSocialIcon(Icons.chat_bubble, 'Zalo', Colors.blue.shade700, () {}),
        _buildSocialIcon(Icons.message, 'Messenger', Colors.blue.shade600, () {}),
        _buildSocialIcon(Icons.video_call, 'Zoom', Colors.blue, () {}),
      ],
    );
  }

  Widget _buildSocialIcon(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.1),
            radius: 30,
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  void _makePhoneCall(String phone) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể gọi điện thoại')),
        );
      }
    }
  }

  void _sendEmail(String email) async {
    final Uri mailUri = Uri(
      scheme: 'mailto',
      path: email,
    );
    if (await canLaunchUrl(mailUri)) {
      await launchUrl(mailUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể mở email')),
        );
      }
    }
  }

  void _openLiveChat() {
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Chat trực tuyến'),
          content: const Text(
            'Tính năng chat trực tuyến sẽ sớm được cập nhật.\n\n'
            'Vui lòng liên hệ qua:\n'
            '• Hotline: 1900 8888\n'
            '• Email: support@hatstyle.com\n'
            '• Facebook: facebook.com/hatstyle',
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

  void _sendMessage() {
    if (_subjectController.text.isEmpty || _messageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng điền đầy đủ thông tin'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gửi tin nhắn'),
        content: Text(
          'Cảm ơn bạn đã liên hệ!\n\n'
          'Danh mục: $_selectedCategory\n'
          'Tiêu đề: ${_subjectController.text}\n\n'
          'Chúng tôi sẽ phản hồi trong vòng 24 giờ.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _subjectController.clear();
              _messageController.clear();
            },
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  final List<Map<String, String>> _faqItems = [
    {
      'question': 'Tôi có thể hủy đơn hàng không?',
      'answer': 'Bạn có thể hủy đơn hàng trong vòng 24 giờ kể từ khi đặt hàng bằng cách vào mục "Đơn hàng của tôi" > Chọn đơn hàng cần hủy > Nhấn "Hủy đơn hàng".',
    },
    {
      'question': 'Làm thế nào để đổi/trả hàng?',
      'answer': 'HatStyle chấp nhận đổi/trả hàng trong vòng 7 ngày kể từ khi nhận hàng. Vui lòng liên hệ hotline 1900 8888 hoặc email support@hatstyle.com.',
    },
    {
      'question': 'Thời gian giao hàng là bao lâu?',
      'answer': 'Thời gian giao hàng từ 2-5 ngày làm việc tùy theo khu vực. Khách hàng ở TP.HCM và Hà Nội sẽ nhận hàng nhanh hơn (1-2 ngày).',
    },
    {
      'question': 'Tôi có thể thanh toán bằng cách nào?',
      'answer': 'HatStyle hỗ trợ nhiều hình thức thanh toán: Tiền mặt (COD), Chuyển khoản, Thẻ tín dụng/ghi nợ, Ví điện tử (MoMo, ZaloPay).',
    },
    {
      'question': 'Làm sao để theo dõi đơn hàng?',
      'answer': 'Bạn có thể theo dõi đơn hàng trong mục "Đơn hàng của tôi" trên ứng dụng. Chúng tôi sẽ gửi thông báo qua email và SMS cho mọi cập nhật trạng thái.',
    },
    {
      'question': 'Tôi quên mật khẩu, làm thế nào?',
      'answer': 'Vào trang đăng nhập > Nhấn "Quên mật khẩu?" > Nhập email > Kiểm tra hộp thư và làm theo hướng dẫn để đặt lại mật khẩu.',
    },
    {
      'question': 'Sản phẩm có chính hãng không?',
      'answer': 'Tất cả sản phẩm tại HatStyle đều là chính hãng 100%, có tem bảo hành và chứng nhận xuất xứ. Chúng tôi cam kết đổi hàng nếu phát hiện hàng giả.',
    },
    {
      'question': 'Làm sao để tích điểm khi mua hàng?',
      'answer': 'Mỗi đơn hàng của bạn sẽ được tự động tích điểm. 1.000đ = 1 điểm. Điểm có thể dùng để giảm giá ở đơn hàng tiếp theo.',
    },
  ];
}

