import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/models.dart';
import '../../../services/cart_service.dart';
import '../../../services/wishlist_service.dart';
import '../../../widgets/safe_network_image.dart';
import '../checkout/checkout_screen.dart';
import '../wishlist/wishlist_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final HatProduct product;

  const ProductDetailScreen({
    super.key,
    required this.product,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _selectedColorIndex = 0;
  int _quantity = 1;
  bool _isFavorite = false;

  final List<String> _defaultColors = ['Đen', 'Trắng', 'Xanh Navy', 'Xám', 'Nâu'];
  List<String> get _colors => (widget.product.colors.isNotEmpty)
      ? widget.product.colors
      : _defaultColors;

  @override
  void initState() {
    super.initState();
    _checkWishlistStatus();
  }

  Future<void> _checkWishlistStatus() async {
    bool isInWishlist = await WishlistService.isInWishlist(widget.product.id);
    if (mounted) {
      setState(() {
        _isFavorite = isInWishlist;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // App Bar với hình ảnh sản phẩm
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: Colors.white,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  _isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: _isFavorite ? Colors.red : Colors.black,
                ),
                onPressed: () async {
                  bool wasAdded = await WishlistService.toggleWishlist(widget.product);
                  HapticFeedback.lightImpact();
                  
                  setState(() {
                    _isFavorite = wasAdded;
                  });
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        wasAdded 
                            ? 'Đã thêm "${widget.product.name}" vào danh sách yêu thích'
                            : 'Đã xóa "${widget.product.name}" khỏi danh sách yêu thích'
                      ),
                      backgroundColor: wasAdded ? Colors.green : Colors.orange,
                      action: SnackBarAction(
                        label: wasAdded ? 'Xem danh sách' : 'Hoàn tác',
                        textColor: Colors.white,
                        onPressed: () {
                          if (wasAdded) {
                            // Navigate to wishlist
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const WishlistScreen(),
                              ),
                            );
                          } else {
                            // Undo remove
                            WishlistService.addToWishlist(widget.product);
                            setState(() {
                              _isFavorite = true;
                            });
                          }
                        },
                      ),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.share, color: Colors.black),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Tính năng chia sẻ sẽ được cập nhật')),
                  );
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: SafeNetworkImage(
                imageUrl: widget.product.imageUrl,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                placeholderText: widget.product.name,
              ),
            ),
          ),
          
          // Thông tin sản phẩm
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tên và thương hiệu
                  Text(
                    widget.product.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.product.brand,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Đánh giá và giá
                  Row(
                    children: [
                      Row(
                        children: List.generate(5, (index) {
                          return Icon(
                            Icons.star,
                            size: 16,
                            color: index < widget.product.rating.floor()
                                ? Colors.amber.shade600
                                : Colors.grey.shade300,
                          );
                        }),
                      ),
                      const SizedBox(width: 8),
                      Text('${widget.product.rating} (${widget.product.reviewCount} đánh giá)'),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Giá
                  Text(
                    '${widget.product.price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}đ',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade600,
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Chọn màu sắc
                  const Text(
                    'Màu sắc',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 50,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _colors.length,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedColorIndex = index;
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 12),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: _selectedColorIndex == index
                                  ? Colors.blue.shade600
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(
                                color: _selectedColorIndex == index
                                    ? Colors.blue.shade600
                                    : Colors.grey.shade300,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                _colors[index],
                                style: TextStyle(
                                  color: _selectedColorIndex == index
                                      ? Colors.white
                                      : Colors.black87,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Chọn số lượng
                  const Text(
                    'Số lượng',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: _quantity > 1
                                  ? () {
                                      setState(() {
                                        _quantity--;
                                      });
                                    }
                                  : null,
                              icon: const Icon(Icons.remove),
                            ),
                            Container(
                              width: 60,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                _quantity.toString(),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  _quantity++;
                                });
                              },
                              icon: const Icon(Icons.add),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Còn ${widget.product.stock} sản phẩm',
                          style: TextStyle(
                            color: widget.product.stock < 10
                                ? Colors.red
                                : Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Mô tả sản phẩm
                  const Text(
                    'Mô tả sản phẩm',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.product.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                      height: 1.5,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Thông tin chi tiết
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        _buildInfoRow('Danh mục', widget.product.category),
                        _buildColorInfoRow('Màu sắc', widget.product.colors),
                        _buildInfoRow('Chất liệu', widget.product.material),
                        _buildInfoRow('Giới tính', widget.product.gender),
                        _buildInfoRow('Mùa vụ', widget.product.season),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Đánh giá từ khách hàng
                  const Text(
                    'Đánh giá từ khách hàng',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Hiển thị đánh giá thực tế từ Firebase
                  if (widget.product.reviewCount > 0) ...[
                    // TODO: Lấy đánh giá thực từ Firebase khi có hệ thống review
                    _buildReviewCard('Nguyễn Văn A', 5, 'Sản phẩm chất lượng tốt, giao hàng nhanh!'),
                    _buildReviewCard('Trần Thị B', 4, 'Nón đẹp, phù hợp với phong cách của tôi.'),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.star_border,
                            size: 48,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Chưa có đánh giá nào',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Hãy là người đầu tiên đánh giá sản phẩm này!',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 100), // Space for bottom buttons
                ],
              ),
            ),
          ),
        ],
      ),
      
      // Bottom buttons
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  try {
                    // Thêm vào giỏ hàng local
                    CartItem cartItem = CartItem(
                      product: widget.product,
                      quantity: _quantity,
                      selectedColor: _colors[_selectedColorIndex],
                      selectedSize: 'M', // Default size
                    );
                    
                    await CartService.addToCart(cartItem);
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đã thêm vào giỏ hàng'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Lỗi: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.shopping_cart),
                label: const Text('Thêm vào giỏ'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () async {
                  try {
                    // Tạo cart item từ sản phẩm hiện tại
                    CartItem cartItem = CartItem(
                      product: widget.product,
                      quantity: _quantity,
                      selectedColor: _colors[_selectedColorIndex],
                      selectedSize: 'M', // Default size
                    );

                    // Navigate to checkout với chế độ mua ngay
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CheckoutScreen(
                          items: [cartItem],
                          isQuickBuy: true,
                        ),
                      ),
                    );

                    // Nếu đặt hàng thành công
                    if (result == true) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Đặt hàng thành công!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Lỗi: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.flash_on),
                label: const Text('Mua ngay'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorInfoRow(String label, List<String> colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: colors.map((color) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getColorFromName(color),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Text(
                    color,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _getTextColorForBackground(_getColorFromName(color)),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Color _getColorFromName(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'đen':
      case 'black':
        return Colors.black;
      case 'trắng':
      case 'white':
        return Colors.white;
      case 'đỏ':
      case 'red':
        return Colors.red;
      case 'xanh':
      case 'blue':
        return Colors.blue;
      case 'vàng':
      case 'yellow':
        return Colors.yellow;
      case 'hồng':
      case 'pink':
        return Colors.pink;
      case 'xám':
      case 'grey':
      case 'gray':
        return Colors.grey;
      case 'nâu':
      case 'brown':
        return Colors.brown;
      case 'xanh lá':
      case 'green':
        return Colors.green;
      case 'cam':
      case 'orange':
        return Colors.orange;
      case 'tím':
      case 'purple':
        return Colors.purple;
      default:
        return Colors.grey.shade200;
    }
  }

  Color _getTextColorForBackground(Color backgroundColor) {
    // Tính độ sáng của màu nền
    double brightness = (backgroundColor.red * 0.299 + 
                       backgroundColor.green * 0.587 + 
                       backgroundColor.blue * 0.114) / 255;
    
    // Nếu màu nền sáng thì dùng chữ đen, ngược lại dùng chữ trắng
    return brightness > 0.5 ? Colors.black : Colors.white;
  }

  Widget _buildReviewCard(String name, int rating, String comment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.blue.shade100,
                child: Text(
                  name[0],
                  style: TextStyle(
                    color: Colors.blue.shade600,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Row(
                      children: List.generate(5, (index) {
                        return Icon(
                          Icons.star,
                          size: 12,
                          color: index < rating
                              ? Colors.amber.shade600
                              : Colors.grey.shade300,
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            comment,
            style: TextStyle(
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}
