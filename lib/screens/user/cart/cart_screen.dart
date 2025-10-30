import 'package:flutter/material.dart';
import 'dart:async';
import '../../../services/cart_service.dart';
import '../../../widgets/safe_network_image.dart';
import '../checkout/checkout_screen.dart';
import '../products/products_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  List<CartItem> _cartItems = [];
  String _promoCode = '';
  bool _promoApplied = false;
  StreamSubscription<void>? _cartSubscription;

  @override
  void initState() {
    super.initState();
    _loadCartItems();
    // Listen to cart changes so the screen updates in real-time
    _cartSubscription = CartService.changes.listen((_) {
      _loadCartItems();
    });
  }

  Future<void> _loadCartItems() async {
    try {
      List<CartItem> cartItems = await CartService.getCart();
      setState(() {
        _cartItems = cartItems;
      });
    } catch (e) {
      print('Error loading cart items: $e');
      // Fallback to empty cart
      setState(() {
        _cartItems = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalAmount = _cartItems.fold<double>(
      0.0,
      (sum, item) => sum + (item.product.price * item.quantity),
    );
    final discountAmount = _promoApplied ? totalAmount * 0.1 : 0.0;
    final finalAmount = totalAmount - discountAmount;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Giỏ Hàng'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_cartItems.isNotEmpty)
            TextButton(
              onPressed: () async {
                await CartService.clearCart();
                _loadCartItems();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã xóa tất cả sản phẩm')),
                );
              },
              child: const Text('Xóa tất cả'),
            ),
        ],
      ),
      body: _cartItems.isEmpty
          ? _buildEmptyCart()
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _cartItems.length,
                    itemBuilder: (context, index) {
                      final item = _cartItems[index];
                      return _buildCartItem(item, index);
                    },
                  ),
                ),

                // Promo code section
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              decoration: InputDecoration(
                                hintText: 'Nhập mã giảm giá',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                              onChanged: (value) {
                                _promoCode = value;
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _promoCode.isNotEmpty
                                ? _applyPromoCode
                                : null,
                            child: const Text('Áp dụng'),
                          ),
                        ],
                      ),
                      if (_promoApplied)
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: Colors.green.shade600,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Đã áp dụng mã giảm giá 10%',
                                style: TextStyle(color: Colors.green.shade700),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),

                // Order summary
                Container(
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
                  child: Column(
                    children: [
                      _buildSummaryRow('Tạm tính', totalAmount),
                      if (_promoApplied)
                        _buildSummaryRow('Giảm giá', -discountAmount),
                      _buildSummaryRow('Phí vận chuyển', 30000),
                      const Divider(),
                      _buildSummaryRow(
                        'Tổng cộng',
                        finalAmount + 30000,
                        isTotal: true,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _checkout,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text(
                            'Thanh Toán',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  @override
  void dispose() {
    _cartSubscription?.cancel();
    super.dispose();
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Giỏ hàng trống',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Hãy thêm sản phẩm vào giỏ hàng để tiếp tục mua sắm',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // Navigate to products screen
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProductsScreen()),
              );
            },
            icon: const Icon(Icons.shopping_bag),
            label: const Text('Mua sắm ngay'),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(CartItem item, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Product image
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: SafeNetworkImage(
              imageUrl: item.product.imageUrl,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              placeholderText: item.product.name,
            ),
          ),

          const SizedBox(width: 12),

          // Product details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  item.product.brand,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 4),
                Text(
                  'Màu: ${item.selectedColor} | Size: ${item.selectedSize}',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        '${item.product.price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}đ',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: item.quantity > 1
                              ? () async {
                                  await CartService.updateQuantity(
                                    item.product.id,
                                    item.selectedColor,
                                    item.selectedSize,
                                    item.quantity - 1,
                                  );
                                  _loadCartItems();
                                }
                              : null,
                          icon: const Icon(Icons.remove_circle_outline),
                          iconSize: 20,
                        ),
                        SizedBox(
                          width: 30,
                          child: Text(
                            item.quantity.toString(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        IconButton(
                          onPressed: () async {
                            await CartService.updateQuantity(
                              item.product.id,
                              item.selectedColor,
                              item.selectedSize,
                              item.quantity + 1,
                            );
                            _loadCartItems();
                          },
                          icon: const Icon(Icons.add_circle_outline),
                          iconSize: 20,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Remove button
          IconButton(
            onPressed: () async {
              await CartService.removeFromCart(
                item.product.id,
                item.selectedColor,
                item.selectedSize,
              );
              _loadCartItems();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã xóa sản phẩm khỏi giỏ hàng')),
              );
            },
            icon: const Icon(Icons.delete_outline),
            color: Colors.red.shade600,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            '${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}đ',
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? Colors.blue.shade600 : null,
            ),
          ),
        ],
      ),
    );
  }

  void _applyPromoCode() {
    if (_promoCode.toLowerCase() == 'hatstyle10') {
      setState(() {
        _promoApplied = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Áp dụng mã giảm giá thành công!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mã giảm giá không hợp lệ'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _checkout() async {
    if (_cartItems.isEmpty) return;

    // Navigate to checkout screen
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            CheckoutScreen(items: _cartItems, isQuickBuy: false),
      ),
    );

    // Reload cart items if order was placed
    if (result == true) {
      _loadCartItems();
    }
  }
}
