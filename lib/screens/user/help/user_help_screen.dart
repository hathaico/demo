import 'package:flutter/material.dart';

class UserHelpScreen extends StatefulWidget {
  const UserHelpScreen({super.key});

  @override
  State<UserHelpScreen> createState() => _UserHelpScreenState();
}

class _UserHelpScreenState extends State<UserHelpScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trợ Giúp'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearchDialog,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Search bar
          TextField(
            decoration: InputDecoration(
              hintText: 'Tìm kiếm trong trợ giúp...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _searchQuery = ''),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey.shade100,
            ),
            onChanged: (value) => setState(() => _searchQuery = value),
          ),

          const SizedBox(height: 24),

          // Categories
          _buildSectionTitle('Danh mục'),
          _buildCategoryGrid(),

          const SizedBox(height: 24),

          // Popular Topics
          _buildSectionTitle('Chủ đề phổ biến'),
          ..._buildPopularTopics(),

          const SizedBox(height: 24),

          // Quick Start Guides
          _buildSectionTitle('Hướng dẫn nhanh'),
          ..._buildQuickGuides(),

          const SizedBox(height: 24),

          // Video Tutorials
          _buildSectionTitle('Video hướng dẫn'),
          _buildVideoSection(),
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

  Widget _buildCategoryGrid() {
    final categories = [
      {'icon': Icons.shopping_bag, 'title': 'Mua hàng', 'color': Colors.blue},
      {'icon': Icons.payment, 'title': 'Thanh toán', 'color': Colors.green},
      {'icon': Icons.local_shipping, 'title': 'Giao hàng', 'color': Colors.orange},
      {'icon': Icons.reply, 'title': 'Đổi trả', 'color': Colors.red},
      {'icon': Icons.account_circle, 'title': 'Tài khoản', 'color': Colors.purple},
      {'icon': Icons.star, 'title': 'Đánh giá', 'color': Colors.amber},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.5,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return Card(
          child: InkWell(
            onTap: () => _showCategoryDetails(category['title'] as String),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  category['icon'] as IconData,
                  size: 40,
                  color: category['color'] as Color,
                ),
                const SizedBox(height: 8),
                Text(
                  category['title'] as String,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildPopularTopics() {
    final topics = [
      {
        'question': 'Cách đặt hàng?',
        'answer': 'Chọn sản phẩm > Thêm vào giỏ hàng > Điền thông tin giao hàng > Chọn phương thức thanh toán > Xác nhận đơn hàng.',
      },
      {
        'question': 'Cách theo dõi đơn hàng?',
        'answer': 'Vào "Tài khoản" > "Đơn hàng của tôi" > Chọn đơn hàng để xem chi tiết và trạng thái.',
      },
      {
        'question': 'Làm sao để đánh giá sản phẩm?',
        'answer': 'Vào "Đơn hàng của tôi" > Chọn đơn hàng đã nhận > Nhấn "Đánh giá" và chia sẻ trải nghiệm.',
      },
    ];

    return topics.map((topic) {
      return Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ExpansionTile(
          title: Text(topic['question'] ?? ''),
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                topic['answer'] ?? '',
                style: TextStyle(color: Colors.grey.shade700),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  List<Widget> _buildQuickGuides() {
    final guides = [
      {
        'icon': Icons.app_registration,
        'title': 'Hướng dẫn đăng ký',
        'steps': [
          'Nhấn "Đăng ký ngay" ở trang đăng nhập',
          'Điền đầy đủ thông tin',
          'Xác nhận email',
          'Hoàn tất đăng ký',
        ],
      },
      {
        'icon': Icons.shopping_cart,
        'title': 'Hướng dẫn mua hàng',
        'steps': [
          'Duyệt sản phẩm hoặc tìm kiếm',
          'Thêm sản phẩm vào giỏ hàng',
          'Kiểm tra và chỉnh sửa giỏ hàng',
          'Thanh toán và xác nhận đơn hàng',
        ],
      },
      {
        'icon': Icons.favorite,
        'title': 'Sử dụng wishlist',
        'steps': [
          'Nhấn icon trái tim trên sản phẩm',
          'Xem danh sách yêu thích trong "Tài khoản"',
          'Thêm vào giỏ hàng trực tiếp từ wishlist',
          'Xóa sản phẩm khỏi wishlist bất cứ lúc nào',
        ],
      },
    ];

    return guides.map((guide) {
      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: ListTile(
          leading: Icon(
            guide['icon'] as IconData,
            color: Colors.blue.shade600,
            size: 32,
          ),
          title: Text(
            guide['title'] as String,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showGuideDetails(guide),
        ),
      );
    }).toList();
  }

  Widget _buildVideoSection() {
    final videos = [
      {
        'title': 'Hướng dẫn sử dụng HatStyle',
        'duration': '5:30',
        'thumbnail': '🎥',
      },
      {
        'title': 'Cách đặt hàng nhanh',
        'duration': '2:45',
        'thumbnail': '🎬',
      },
      {
        'title': 'Thanh toán an toàn',
        'duration': '3:15',
        'thumbnail': '📹',
      },
    ];

    return Column(
      children: videos.map((video) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              radius: 25,
              backgroundColor: Colors.red.shade50,
              child: Text(
                video['thumbnail'] ?? '🎥',
                style: const TextStyle(fontSize: 20),
              ),
            ),
            title: Text(video['title'] ?? ''),
            subtitle: Row(
              children: [
                const Icon(Icons.play_circle_outline, size: 16),
                const SizedBox(width: 4),
                Text(video['duration'] ?? ''),
              ],
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _playVideo(video['title'] as String),
          ),
        );
      }).toList(),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tìm kiếm trong trợ giúp'),
        content: const Text(
          'Tính năng tìm kiếm nâng cao sẽ sớm được cập nhật.\n\n'
          'Hiện tại bạn có thể tìm kiếm bằng thanh tìm kiếm ở đầu trang.',
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

  void _showCategoryDetails(String category) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    category,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                children: List.generate(5, (index) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ExpansionTile(
                      title: Text('Câu hỏi ${index + 1} về $category'),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'Đây là câu trả lời cho câu hỏi ${index + 1} về $category. '
                            'Thông tin chi tiết sẽ được cập nhật trong tương lai.',
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showGuideDetails(Map<String, dynamic> guide) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(guide['title'] as String),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: (guide['steps'] as List<String>).asMap().entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: Colors.blue.shade600,
                      child: Text(
                        '${entry.key + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        entry.value,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
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

  void _playVideo(String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Phát video: $title'),
        action: SnackBarAction(
          label: 'Xem',
          onPressed: () {},
        ),
      ),
    );
  }
}

