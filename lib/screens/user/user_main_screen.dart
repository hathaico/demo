import 'package:flutter/material.dart';
import 'dart:async';
import 'auth/login_screen.dart';
import 'home/home_screen.dart';
import 'products/products_screen.dart';
import 'cart/cart_screen.dart';
import 'account/account_screen.dart';
import '../../services/cart_service.dart';

class UserMainScreen extends StatefulWidget {
  const UserMainScreen({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<UserMainScreen> createState() => _UserMainScreenState();
}

class _UserMainScreenState extends State<UserMainScreen> {
  late int _currentIndex;
  int _cartItemCount = 0;
  StreamSubscription<void>? _cartSubscription;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, 3);
    _screens = [
      HomeScreen(onViewAllProducts: () => _selectTab(1)),
      const ProductsScreen(),
      const CartScreen(),
      const AccountScreen(),
    ];
    _loadCartCount();
    // Lắng nghe thay đổi giỏ hàng để cập nhật badge theo thời gian thực
    _cartSubscription = CartService.changes.listen((_) {
      _loadCartCount();
    });
  }

  Future<void> _loadCartCount() async {
    int count = await CartService.getCartItemCount();
    setState(() {
      _cartItemCount = count;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _selectTab,
        type: BottomNavigationBarType.fixed,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Trang Chủ',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag),
            label: 'Sản Phẩm',
          ),
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                const Icon(Icons.shopping_cart),
                if (_cartItemCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '$_cartItemCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            label: 'Giỏ Hàng',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Tài Khoản',
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

  void _selectTab(int index) {
    if (_currentIndex == index) {
      if (index == 2) {
        _loadCartCount();
      }
      return;
    }

    setState(() {
      _currentIndex = index;
    });

    if (index == 2) {
      _loadCartCount();
    }
  }

  void logout() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }
}
