import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/models.dart';
import '../../../services/cart_service.dart';
import '../../../services/wishlist_service.dart';
import '../../../widgets/safe_network_image.dart';
import '../checkout/checkout_screen.dart';
import '../wishlist/wishlist_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final HatProduct product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductReview {
  const _ProductReview({
    required this.id,
    required this.author,
    required this.rating,
    required this.comment,
    this.createdAt,
  });

  final String id;
  final String author;
  final double rating;
  final String comment;
  final DateTime? createdAt;
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _selectedColorIndex = 0;
  int _quantity = 1;
  bool _isFavorite = false;
  late final TextEditingController _quantityController;
  List<_ProductReview> _reviews = const [];
  bool _isReviewLoading = false;
  String? _reviewError;

  final List<String> _defaultColors = [
    'Đen',
    'Trắng',
    'Xanh Navy',
    'Xám',
    'Nâu',
  ];
  List<String> get _colors => (widget.product.colors.isNotEmpty)
      ? widget.product.colors
      : _defaultColors;

  @override
  void initState() {
    super.initState();
    _quantity = widget.product.stock > 0 ? 1 : 0;
    _quantityController = TextEditingController(text: _quantity.toString());
    _checkWishlistStatus();
    if (widget.product.reviewCount > 0) {
      _loadReviews();
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _checkWishlistStatus() async {
    bool isInWishlist = await WishlistService.isInWishlist(widget.product.id);
    if (mounted) {
      setState(() {
        _isFavorite = isInWishlist;
      });
    }
  }

  Future<void> _loadReviews() async {
    setState(() {
      _isReviewLoading = true;
      _reviewError = null;
    });

    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot =
          await FirebaseFirestore.instance
              .collection('reviews')
              .where('productId', isEqualTo: widget.product.id)
              .orderBy('createdAt', descending: true)
              .limit(5)
              .get();

      final List<_ProductReview> fetched = snapshot.docs.map((doc) {
        final Map<String, dynamic> data = doc.data();
        final dynamic createdValue = data['createdAt'];
        DateTime? createdAt;
        if (createdValue is Timestamp) {
          createdAt = createdValue.toDate();
        } else if (createdValue is DateTime) {
          createdAt = createdValue;
        }

        final double rating = (data['rating'] is num)
            ? (data['rating'] as num).toDouble()
            : 0;
        final String rawAuthor =
            (data['authorName'] ??
                    data['userName'] ??
                    data['fullName'] ??
                    data['displayName'] ??
                    data['email'] ??
                    '')
                .toString()
                .trim();
        final String author = rawAuthor.isEmpty ? 'Người dùng' : rawAuthor;
        final String rawComment =
            (data['comment'] ?? data['content'] ?? data['review'] ?? '')
                .toString()
                .trim();
        final String comment = rawComment.isEmpty
            ? 'Người dùng chưa để lại đánh giá chi tiết.'
            : rawComment;

        return _ProductReview(
          id: doc.id,
          author: author,
          rating: rating.clamp(0, 5),
          comment: comment,
          createdAt: createdAt,
        );
      }).toList();

      if (!mounted) {
        return;
      }

      setState(() {
        _reviews = fetched;
        _isReviewLoading = false;
      });
    } catch (e, stackTrace) {
      debugPrint('Không thể tải đánh giá: $e');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) {
        return;
      }

      setState(() {
        _reviewError = 'Không thể tải đánh giá. Vui lòng thử lại sau.';
        _isReviewLoading = false;
      });
    }
  }

  void _showSnack(String message, {Color? backgroundColor}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: backgroundColor ?? Colors.orange,
        ),
      );
  }

  void _showStockWarning() {
    final int available = widget.product.stock;
    final String message = available <= 0
        ? 'Sản phẩm hiện đã hết hàng.'
        : 'Sản phẩm chỉ còn $available sản phẩm.';
    _showSnack(message, backgroundColor: Colors.redAccent);
  }

  void _syncQuantityController() {
    final String text = _quantity.toString();
    if (_quantityController.text == text) {
      return;
    }
    _quantityController.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  void _updateQuantity(int value, {bool showWarningOnExceed = false}) {
    final int available = widget.product.stock;
    int target = value;

    if (available <= 0) {
      target = 0;
      if (showWarningOnExceed) {
        _showStockWarning();
      }
    } else {
      if (target < 1) {
        target = 1;
      }
      if (target > available) {
        target = available;
        if (showWarningOnExceed) {
          _showStockWarning();
        }
      }
    }

    if (mounted) {
      setState(() {
        _quantity = target;
      });
    } else {
      _quantity = target;
    }
    _syncQuantityController();
  }

  void _finalizeManualQuantity() {
    if (_quantityController.text.trim().isEmpty) {
      _updateQuantity(widget.product.stock > 0 ? 1 : 0);
      return;
    }
    final int parsed = int.tryParse(_quantityController.text) ?? 0;
    _updateQuantity(parsed, showWarningOnExceed: true);
  }

  bool _ensureQuantityAvailable() {
    final int available = widget.product.stock;
    if (available <= 0) {
      _showStockWarning();
      return false;
    }
    if (_quantity < 1) {
      _showSnack('Vui lòng chọn số lượng hợp lệ.');
      _updateQuantity(1);
      return false;
    }
    if (_quantity > available) {
      _showStockWarning();
      _updateQuantity(available);
      return false;
    }
    return true;
  }

  bool _isColorLight(Color color) => color.computeLuminance() > 0.6;

  bool _hasMeaningfulDescription(String value) {
    final String trimmed = value.trim();
    if (trimmed.isEmpty) {
      return false;
    }
    final String normalized = trimmed.toLowerCase();
    const Set<String> placeholders = {
      'hiphop',
      'hip hop',
      'hip-hop',
      'updating',
      'updating...',
      'đang cập nhật',
      'dang cap nhat',
      'n/a',
      '-',
      '...',
    };
    return !placeholders.contains(normalized);
  }

  @override
  Widget build(BuildContext context) {
    final String description = widget.product.description.trim();
    final bool hasDescription = _hasMeaningfulDescription(description);

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
                  bool wasAdded = await WishlistService.toggleWishlist(
                    widget.product,
                  );
                  HapticFeedback.lightImpact();

                  setState(() {
                    _isFavorite = wasAdded;
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        wasAdded
                            ? 'Đã thêm "${widget.product.name}" vào danh sách yêu thích'
                            : 'Đã xóa "${widget.product.name}" khỏi danh sách yêu thích',
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
                    const SnackBar(
                      content: Text('Tính năng chia sẻ sẽ được cập nhật'),
                    ),
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
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
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
                      Text(
                        '${widget.product.rating} (${widget.product.reviewCount} đánh giá)',
                      ),
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
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 50,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _colors.length,
                      itemBuilder: (context, index) {
                        final String colorName = _colors[index];
                        final Color baseColor = _getColorFromName(colorName);
                        final bool isSelected = _selectedColorIndex == index;
                        final Color backgroundColor = isSelected
                            ? baseColor
                            : Colors.white;
                        final Color borderColor = isSelected
                            ? (_isColorLight(baseColor)
                                  ? Colors.grey.shade400
                                  : baseColor)
                            : Colors.black.withOpacity(0.15);
                        final Color textColor = isSelected
                            ? _getTextColorForBackground(baseColor)
                            : Colors.black;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedColorIndex = index;
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 12),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: backgroundColor,
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(
                                color: borderColor,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                colorName,
                                style: TextStyle(
                                  color: textColor,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w500,
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
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
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
                              onPressed:
                                  widget.product.stock > 0 && _quantity > 1
                                  ? () {
                                      _updateQuantity(_quantity - 1);
                                    }
                                  : null,
                              icon: const Icon(Icons.remove),
                            ),
                            SizedBox(
                              width: 64,
                              child: TextField(
                                controller: _quantityController,
                                enabled: widget.product.stock > 0,
                                textAlign: TextAlign.center,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(
                                    vertical: 12,
                                    horizontal: 0,
                                  ),
                                ),
                                onChanged: (value) {
                                  final int parsed = int.tryParse(value) ?? 0;
                                  setState(() {
                                    _quantity = parsed;
                                  });
                                },
                                onEditingComplete: _finalizeManualQuantity,
                                onTapOutside: (_) => _finalizeManualQuantity(),
                              ),
                            ),
                            IconButton(
                              onPressed: widget.product.stock > 0
                                  ? () {
                                      _updateQuantity(
                                        _quantity + 1,
                                        showWarningOnExceed: true,
                                      );
                                    }
                                  : null,
                              icon: const Icon(Icons.add),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          widget.product.stock > 0
                              ? 'Còn ${widget.product.stock} sản phẩm'
                              : 'Sản phẩm đã hết hàng',
                          style: TextStyle(
                            color: widget.product.stock <= 0
                                ? Colors.red
                                : (widget.product.stock < 10
                                      ? Colors.orange.shade700
                                      : Colors.grey.shade600),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Mô tả sản phẩm
                  const Text(
                    'Mô tả sản phẩm',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  if (hasDescription) ...[
                    const SizedBox(height: 12),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                        height: 1.5,
                      ),
                    ),
                  ],
                  SizedBox(height: hasDescription ? 16 : 12),

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
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),

                  ..._buildReviewsSection(),

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
                  FocusScope.of(context).unfocus();
                  _finalizeManualQuantity();
                  if (!_ensureQuantityAvailable()) {
                    return;
                  }
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
                  FocusScope.of(context).unfocus();
                  _finalizeManualQuantity();
                  if (!_ensureQuantityAvailable()) {
                    return;
                  }
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
                        builder: (context) =>
                            CheckoutScreen(items: [cartItem], isQuickBuy: true),
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
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
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
                      color: _getTextColorForBackground(
                        _getColorFromName(color),
                      ),
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
    final String normalized = colorName.trim().toLowerCase();

    final hexMatch = RegExp(r'^#?[0-9a-f]{6}').firstMatch(normalized);
    if (hexMatch != null) {
      final String hex = hexMatch.group(0)!.replaceFirst('#', '');
      final int? value = int.tryParse(hex, radix: 16);
      if (value != null) {
        return Color(0xFF000000 | value);
      }
    }

    switch (normalized) {
      case 'đen':
      case 'black':
        return Colors.black;
      case 'trắng':
      case 'white':
        return Colors.white;
      case 'đỏ':
      case 'đỏ tươi':
      case 'red':
        return Colors.redAccent;
      case 'đỏ đô':
      case 'burgundy':
        return const Color(0xFF800020);
      case 'xanh':
      case 'xanh dương':
      case 'xanh lam':
      case 'blue':
        return Colors.blueAccent;
      case 'xanh navy':
      case 'navy':
      case 'navy blue':
        return const Color(0xFF0A1D37);
      case 'xanh da trời':
      case 'sky blue':
        return const Color(0xFF6AB7FF);
      case 'xanh biển':
      case 'ocean blue':
        return const Color(0xFF01579B);
      case 'xanh lá':
      case 'xanh lá cây':
      case 'green':
        return Colors.green;
      case 'xanh lục':
      case 'olive':
        return const Color(0xFF708238);
      case 'cam':
      case 'orange':
        return Colors.orange;
      case 'vàng':
      case 'gold':
      case 'yellow':
        return Colors.amber;
      case 'hồng':
      case 'pink':
        return Colors.pinkAccent;
      case 'tím':
      case 'purple':
        return Colors.deepPurpleAccent;
      case 'xám':
      case 'ghi':
      case 'grey':
      case 'gray':
        return Colors.grey;
      case 'bạc':
      case 'silver':
        return const Color(0xFFC0C0C0);
      case 'nâu':
      case 'brown':
        return const Color(0xFF795548);
      case 'be':
      case 'beige':
      case 'kem':
        return const Color(0xFFF5DEB3);
      case 'xanh mint':
      case 'mint':
        return const Color(0xFF98FF98);
      default:
        return Colors.grey.shade300;
    }
  }

  Color _getTextColorForBackground(Color backgroundColor) {
    // Tính độ sáng của màu nền
    double brightness =
        (backgroundColor.red * 0.299 +
            backgroundColor.green * 0.587 +
            backgroundColor.blue * 0.114) /
        255;

    // Nếu màu nền sáng thì dùng chữ đen, ngược lại dùng chữ trắng
    return brightness > 0.5 ? Colors.black : Colors.white;
  }

  List<Widget> _buildReviewsSection() {
    if (_isReviewLoading) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }

    if (_reviewError != null) {
      return [_buildReviewErrorCard(_reviewError!)];
    }

    if (_reviews.isNotEmpty) {
      return _reviews
          .map(
            (review) => _buildReviewCard(
              review.author,
              review.rating,
              review.comment,
              createdAt: review.createdAt,
            ),
          )
          .toList();
    }

    return [_buildEmptyReviewCard()];
  }

  Widget _buildReviewErrorCard(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade400),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message, style: TextStyle(color: Colors.red.shade700)),
          ),
          TextButton(onPressed: _loadReviews, child: const Text('Thử lại')),
        ],
      ),
    );
  }

  Widget _buildEmptyReviewCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.star_border, size: 48, color: Colors.grey.shade400),
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
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(
    String name,
    double rating,
    String comment, {
    DateTime? createdAt,
  }) {
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
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Row(
                      children: [
                        ...List.generate(5, (index) {
                          IconData icon;
                          if (rating >= index + 1) {
                            icon = Icons.star;
                          } else if (rating >= index + 0.5) {
                            icon = Icons.star_half;
                          } else {
                            icon = Icons.star_border;
                          }
                          return Icon(
                            icon,
                            size: 12,
                            color: Colors.amber.shade600,
                          );
                        }),
                        const SizedBox(width: 4),
                        Text(
                          rating.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    if (createdAt != null)
                      Text(
                        '${createdAt.day}/${createdAt.month}/${createdAt.year}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(comment, style: TextStyle(color: Colors.grey.shade700)),
        ],
      ),
    );
  }
}
