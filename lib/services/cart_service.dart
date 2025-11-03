import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:convert';
import '../models/models.dart';
import 'firebase_auth_service.dart';

class CartService {
  static const String _legacyCartKey = 'user_cart';
  static const String _guestCartKey = 'cart_guest';
  static final StreamController<void> _cartChanges =
      StreamController<void>.broadcast();

  // Stream thông báo khi giỏ hàng thay đổi (thêm/xóa/cập nhật)
  static Stream<void> get changes => _cartChanges.stream;

  static String _cartKeyForCurrentUser() {
    final String? userId = FirebaseAuthService.currentUser?.uid;
    if (userId == null || userId.isEmpty) {
      return _guestCartKey;
    }
    return 'cart_$userId';
  }

  static bool _isAuthenticated() {
    final String? userId = FirebaseAuthService.currentUser?.uid;
    return userId != null && userId.isNotEmpty;
  }

  // Lưu giỏ hàng vào SharedPreferences
  static Future<void> saveCart(List<CartItem> cartItems) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String storageKey = _cartKeyForCurrentUser();
      final cartJson = cartItems
          .map(
            (item) => {
              'productId': item.product.id,
              'productName': item.product.name,
              'productImage': item.product.imageUrl,
              'productPrice': item.product.price,
              'productBrand': item.product.brand,
              'productCategory': item.product.category,
              'productColors': item.product.colors,
              'productMaterial': item.product.material,
              'productGender': item.product.gender,
              'productSeason': item.product.season,
              'productDescription': item.product.description,
              'productStock': item.product.stock,
              'productRating': item.product.rating,
              'productReviewCount': item.product.reviewCount,
              'productIsHot': item.product.isHot,
              'quantity': item.quantity,
              'selectedColor': item.selectedColor,
              'selectedSize': item.selectedSize,
            },
          )
          .toList();

      await prefs.setString(storageKey, jsonEncode(cartJson));
      if (storageKey != _legacyCartKey) {
        await prefs.remove(_legacyCartKey);
      }
      _cartChanges.add(null);
    } catch (e) {
      print('Error saving cart: $e');
    }
  }

  // Lấy giỏ hàng từ SharedPreferences
  static Future<List<CartItem>> getCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String storageKey = _cartKeyForCurrentUser();
      String? cartJson = prefs.getString(storageKey);

      if (cartJson == null) {
        // Migrate guest cart when user signs in so their pre-login selections persist.
        if (_isAuthenticated()) {
          final String? guestJson = prefs.getString(_guestCartKey);
          if (guestJson != null) {
            await prefs.setString(storageKey, guestJson);
            await prefs.remove(_guestCartKey);
            cartJson = guestJson;
          }
        } else {
          // Backward compatibility with legacy key prior to per-user carts.
          final String? legacyJson = prefs.getString(_legacyCartKey);
          if (legacyJson != null) {
            await prefs.setString(_guestCartKey, legacyJson);
            await prefs.remove(_legacyCartKey);
            cartJson = legacyJson;
          }
          cartJson ??= prefs.getString(_guestCartKey);
        }
      }

      if (cartJson == null) return [];

      final List<dynamic> cartData = jsonDecode(cartJson);

      return cartData.map((item) {
        final product = HatProduct(
          id: item['productId'],
          name: item['productName'],
          brand: item['productBrand'],
          price: (item['productPrice'] as num).toDouble(),
          imageUrl: item['productImage'],
          category: item['productCategory'],
          colors: List<String>.from(item['productColors'] ?? []),
          material: item['productMaterial'],
          gender: item['productGender'],
          season: item['productSeason'],
          description: item['productDescription'],
          stock: item['productStock'],
          rating: (item['productRating'] as num).toDouble(),
          reviewCount: item['productReviewCount'],
          isHot: item['productIsHot'],
        );

        return CartItem(
          product: product,
          quantity: item['quantity'],
          selectedColor: item['selectedColor'],
          selectedSize: item['selectedSize'],
        );
      }).toList();
    } catch (e) {
      print('Error loading cart: $e');
      return [];
    }
  }

  // Thêm sản phẩm vào giỏ hàng
  static Future<void> addToCart(CartItem newItem) async {
    try {
      List<CartItem> cartItems = await getCart();

      // Kiểm tra xem sản phẩm đã có trong giỏ hàng chưa
      int existingIndex = cartItems.indexWhere(
        (item) =>
            item.product.id == newItem.product.id &&
            item.selectedColor == newItem.selectedColor &&
            item.selectedSize == newItem.selectedSize,
      );

      if (existingIndex != -1) {
        // Cập nhật số lượng nếu sản phẩm đã tồn tại
        cartItems[existingIndex].quantity += newItem.quantity;
      } else {
        // Thêm sản phẩm mới
        cartItems.add(newItem);
      }

      await saveCart(cartItems);
    } catch (e) {
      print('Error adding to cart: $e');
    }
  }

  // Cập nhật số lượng sản phẩm trong giỏ hàng
  static Future<void> updateQuantity(
    String productId,
    String selectedColor,
    String selectedSize,
    int quantity,
  ) async {
    try {
      List<CartItem> cartItems = await getCart();

      int index = cartItems.indexWhere(
        (item) =>
            item.product.id == productId &&
            item.selectedColor == selectedColor &&
            item.selectedSize == selectedSize,
      );

      if (index != -1) {
        if (quantity <= 0) {
          cartItems.removeAt(index);
        } else {
          cartItems[index].quantity = quantity;
        }
        await saveCart(cartItems);
      }
    } catch (e) {
      print('Error updating quantity: $e');
    }
  }

  // Xóa sản phẩm khỏi giỏ hàng
  static Future<void> removeFromCart(
    String productId,
    String selectedColor,
    String selectedSize,
  ) async {
    try {
      List<CartItem> cartItems = await getCart();

      cartItems.removeWhere(
        (item) =>
            item.product.id == productId &&
            item.selectedColor == selectedColor &&
            item.selectedSize == selectedSize,
      );

      await saveCart(cartItems);
    } catch (e) {
      print('Error removing from cart: $e');
    }
  }

  // Xóa tất cả sản phẩm khỏi giỏ hàng
  static Future<void> clearCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String storageKey = _cartKeyForCurrentUser();
      await prefs.remove(storageKey);
      _cartChanges.add(null);
    } catch (e) {
      print('Error clearing cart: $e');
    }
  }

  // Lấy tổng số sản phẩm trong giỏ hàng
  static Future<int> getCartItemCount() async {
    try {
      List<CartItem> cartItems = await getCart();
      return cartItems.fold<int>(0, (sum, item) => sum + item.quantity);
    } catch (e) {
      print('Error getting cart count: $e');
      return 0;
    }
  }

  // Lấy tổng giá trị giỏ hàng
  static Future<double> getCartTotal() async {
    try {
      List<CartItem> cartItems = await getCart();
      return cartItems.fold<double>(
        0.0,
        (sum, item) => sum + (item.product.price * item.quantity),
      );
    } catch (e) {
      print('Error getting cart total: $e');
      return 0.0;
    }
  }
}

class CartItem {
  final HatProduct product;
  int quantity;
  final String selectedColor;
  final String selectedSize;

  CartItem({
    required this.product,
    required this.quantity,
    required this.selectedColor,
    required this.selectedSize,
  });
}
