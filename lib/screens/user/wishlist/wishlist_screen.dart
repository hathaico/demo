import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/models.dart';
import '../../../services/wishlist_service.dart';
import '../../../services/cart_service.dart';
import '../../../widgets/safe_network_image.dart';
import '../products/product_detail_screen.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  List<HatProduct> _wishlistItems = [];
  String _selectedSort = 'Mặc định';
  String _searchQuery = '';
  bool _isLoading = true;

  final List<Map<String, String>> _sortOptions = [
    {'code': 'default', 'name': 'Mặc định'},
    {'code': 'name', 'name': 'Tên A-Z'},
    {'code': 'price_low', 'name': 'Giá thấp đến cao'},
    {'code': 'price_high', 'name': 'Giá cao đến thấp'},
    {'code': 'rating', 'name': 'Đánh giá cao nhất'},
    {'code': 'newest', 'name': 'Mới nhất'},
  ];

  @override
  void initState() {
    super.initState();
    _loadWishlist();
  }

  double _getTotalValue() {
    return _wishlistItems.fold(0.0, (sum, product) => sum + product.price);
  }

  void _showSortDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sắp xếp danh sách'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _sortOptions.map((option) {
            return RadioListTile<String>(
              title: Text(option['name']!),
              value: option['code']!,
              groupValue: _selectedSort,
              onChanged: (value) {
                setState(() {
                  _selectedSort = value!;
                });
                Navigator.pop(context);
                _sortWishlist();
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showClearWishlistDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa tất cả'),
        content: const Text(
          'Bạn có chắc chắn muốn xóa tất cả sản phẩm khỏi danh sách yêu thích?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await WishlistService.clearWishlist();
              _loadWishlist();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Đã xóa tất cả sản phẩm khỏi danh sách yêu thích',
                  ),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _loadWishlist() async {
    setState(() {
      _isLoading = true;
    });

    try {
      List<HatProduct> wishlist = await WishlistService.getWishlist();
      setState(() {
        _wishlistItems = wishlist;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi tải danh sách yêu thích: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _removeFromWishlist(HatProduct product) async {
    try {
      await WishlistService.removeFromWishlist(product.id);
      setState(() {
        _wishlistItems.removeWhere((item) => item.id == product.id);
      });

      HapticFeedback.lightImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã xóa "${product.name}" khỏi danh sách yêu thích'),
          backgroundColor: Colors.orange,
          action: SnackBarAction(
            label: 'Hoàn tác',
            textColor: Colors.white,
            onPressed: () async {
              await WishlistService.addToWishlist(product);
              _loadWishlist();
            },
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi xóa sản phẩm: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _addToCart(HatProduct product) async {
    try {
      CartItem cartItem = CartItem(
        product: product,
        quantity: 1,
        selectedColor: product.colors.isNotEmpty ? product.colors.first : 'Đen',
        selectedSize: 'M',
      );

      await CartService.addToCart(cartItem);

      HapticFeedback.lightImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã thêm "${product.name}" vào giỏ hàng'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi thêm vào giỏ hàng: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _sortWishlist() async {
    try {
      List<HatProduct> sortedItems = await WishlistService.getSortedWishlist(
        _selectedSort,
      );
      setState(() {
        _wishlistItems = sortedItems;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi sắp xếp: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _searchWishlist() async {
    if (_searchQuery.isEmpty) {
      _loadWishlist();
      return;
    }

    try {
      List<HatProduct> searchResults = await WishlistService.searchWishlist(
        _searchQuery,
      );
      setState(() {
        _wishlistItems = searchResults;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi tìm kiếm: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Danh Sách Yêu Thích'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
        actions: [
          if (_wishlistItems.isNotEmpty)
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'sort':
                    _showSortDialog();
                    break;
                  case 'clear':
                    _showClearWishlistDialog();
                    break;
                  case 'export':
                    _exportWishlist();
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'sort',
                  child: ListTile(
                    leading: Icon(Icons.sort),
                    title: Text('Sắp xếp'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'clear',
                  child: ListTile(
                    leading: Icon(Icons.clear_all),
                    title: Text('Xóa tất cả'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'export',
                  child: ListTile(
                    leading: Icon(Icons.file_download),
                    title: Text('Xuất danh sách'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Tìm kiếm trong danh sách yêu thích...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchQuery = '';
                          });
                          _loadWishlist();
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
                _searchWishlist();
              },
            ),
          ),

          // Stats bar
          if (_wishlistItems.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_wishlistItems.length} sản phẩm',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                  Text(
                    'Tổng giá trị: ${_getTotalValue().toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}đ',
                    style: TextStyle(
                      color: Colors.blue.shade600,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

          // Wishlist content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _wishlistItems.isEmpty
                ? _buildEmptyWishlist()
                : _buildWishlistGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWishlist() {
    final bottomPad =
        MediaQuery.of(context).padding.bottom +
        kBottomNavigationBarHeight +
        16.0;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottomPad),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_border, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty
                  ? 'Danh sách yêu thích trống'
                  : 'Không tìm thấy sản phẩm',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isEmpty
                  ? 'Hãy thêm sản phẩm vào danh sách yêu thích để dễ dàng tìm lại sau này'
                  : 'Hãy thử tìm kiếm với từ khóa khác',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500),
            ),
            const SizedBox(height: 24),
            if (_searchQuery.isEmpty)
              ElevatedButton.icon(
                onPressed: () {
                  // Navigate to products screen
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.shopping_bag),
                label: const Text('Khám phá sản phẩm'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWishlistGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 2;
        if (constraints.maxWidth > 600) {
          crossAxisCount = 3;
        }
        if (constraints.maxWidth > 900) {
          crossAxisCount = 4;
        }

        final bottomPad =
            MediaQuery.of(context).padding.bottom +
            kBottomNavigationBarHeight +
            16.0;

        return GridView.builder(
          padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPad),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            // slightly taller cards for better spacing
            childAspectRatio: 0.66,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: _wishlistItems.length,
          itemBuilder: (context, index) {
            final product = _wishlistItems[index];
            return _buildWishlistItem(product);
          },
        );
      },
    );
  }

  Widget _buildWishlistItem(HatProduct product) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(product: product),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.08),
              spreadRadius: 1,
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image area with fixed height to avoid unpredictable expansion
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: Container(
                height: 130,
                color: Colors.grey.shade100,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    SafeNetworkImage(
                      imageUrl: product.imageUrl,
                      fit: BoxFit.cover,
                      placeholderText: product.name,
                    ),
                    if (product.isHot)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'HOT',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      top: 6,
                      right: 6,
                      child: InkWell(
                        onTap: () => _removeFromWishlist(product),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.8),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.favorite,
                            color: Colors.red,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Info area
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.brand,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          '${product.price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}đ',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.star,
                            size: 12,
                            color: Colors.amber.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${product.rating}',
                            style: const TextStyle(fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 36,
                    child: ElevatedButton.icon(
                      onPressed: () => _addToCart(product),
                      icon: const Icon(Icons.shopping_cart, size: 16),
                      label: const Text(
                        'Thêm vào giỏ',
                        style: TextStyle(fontSize: 13),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        backgroundColor: Colors.blue.shade600,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
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

  void _exportWishlist() async {
    try {
      await WishlistService.exportWishlist();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Danh sách yêu thích đã được xuất thành công'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi xuất danh sách: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
