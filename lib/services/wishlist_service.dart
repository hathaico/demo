import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:convert';
import '../models/models.dart';

class WishlistService {
  static const String _wishlistKey = 'user_wishlist';
  static final StreamController<void> _changes = StreamController<void>.broadcast();
  static Set<String>? _wishlistIdCache; // in-memory cache of product IDs

  // Stream phát sự kiện khi wishlist thay đổi
  static Stream<void> get changes => _changes.stream;
  
  // Thêm sản phẩm vào wishlist
  static Future<void> addToWishlist(HatProduct product) async {
    try {
      List<HatProduct> wishlist = await getWishlist();
      
      // Kiểm tra xem sản phẩm đã có trong wishlist chưa
      bool exists = wishlist.any((item) => item.id == product.id);
      
      if (!exists) {
        wishlist.add(product);
        await _saveWishlist(wishlist);
        // Update cache and notify
        (_wishlistIdCache ??= <String>{}).add(product.id);
        _changes.add(null);
      }
    } catch (e) {
      print('Error adding to wishlist: $e');
    }
  }
  
  // Xóa sản phẩm khỏi wishlist
  static Future<void> removeFromWishlist(String productId) async {
    try {
      List<HatProduct> wishlist = await getWishlist();
      wishlist.removeWhere((product) => product.id == productId);
      await _saveWishlist(wishlist);
      // Update cache and notify
      _wishlistIdCache?.remove(productId);
      _changes.add(null);
    } catch (e) {
      print('Error removing from wishlist: $e');
    }
  }
  
  // Lấy danh sách wishlist
  static Future<List<HatProduct>> getWishlist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final wishlistJson = prefs.getString(_wishlistKey);
      
      if (wishlistJson == null) return [];
      
      final List<dynamic> wishlistData = jsonDecode(wishlistJson);
      
      final items = wishlistData.map((item) {
        return HatProduct(
          id: item['id'],
          name: item['name'],
          brand: item['brand'],
          price: (item['price'] as num).toDouble(),
          imageUrl: item['imageUrl'],
          category: item['category'],
          colors: List<String>.from(item['colors'] ?? []),
          material: item['material'],
          gender: item['gender'],
          season: item['season'],
          description: item['description'],
          stock: item['stock'],
          rating: (item['rating'] as num).toDouble(),
          reviewCount: item['reviewCount'],
          isHot: item['isHot'] ?? false,
        );
      }).toList();
      // Warm up ID cache
      _wishlistIdCache = items.map((e) => e.id).toSet();
      return items;
    } catch (e) {
      print('Error loading wishlist: $e');
      return [];
    }
  }

  // Lấy tập ID sản phẩm trong wishlist (cache in-memory để tra cứu nhanh)
  static Future<Set<String>> getWishlistIds() async {
    if (_wishlistIdCache != null) return _wishlistIdCache!;
    final list = await getWishlist();
    _wishlistIdCache = list.map((e) => e.id).toSet();
    return _wishlistIdCache!;
  }
  
  // Kiểm tra sản phẩm có trong wishlist không
  static Future<bool> isInWishlist(String productId) async {
    try {
      final ids = await getWishlistIds();
      return ids.contains(productId);
    } catch (e) {
      print('Error checking wishlist: $e');
      return false;
    }
  }
  
  // Lấy số lượng sản phẩm trong wishlist
  static Future<int> getWishlistCount() async {
    try {
      List<HatProduct> wishlist = await getWishlist();
      return wishlist.length;
    } catch (e) {
      print('Error getting wishlist count: $e');
      return 0;
    }
  }
  
  // Xóa tất cả sản phẩm khỏi wishlist
  static Future<void> clearWishlist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_wishlistKey);
      _wishlistIdCache = <String>{};
      _changes.add(null);
    } catch (e) {
      print('Error clearing wishlist: $e');
    }
  }
  
  // Toggle wishlist (thêm nếu chưa có, xóa nếu đã có)
  static Future<bool> toggleWishlist(HatProduct product) async {
    try {
      bool isInList = await isInWishlist(product.id);
      
      if (isInList) {
        await removeFromWishlist(product.id);
        return false; // Đã xóa
      } else {
        await addToWishlist(product);
        return true; // Đã thêm
      }
    } catch (e) {
      print('Error toggling wishlist: $e');
      return false;
    }
  }
  
  // Lưu wishlist vào SharedPreferences
  static Future<void> _saveWishlist(List<HatProduct> wishlist) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final wishlistJson = wishlist.map((product) => {
        'id': product.id,
        'name': product.name,
        'brand': product.brand,
        'price': product.price,
        'imageUrl': product.imageUrl,
        'category': product.category,
        'colors': product.colors,
        'material': product.material,
        'gender': product.gender,
        'season': product.season,
        'description': product.description,
        'stock': product.stock,
        'rating': product.rating,
        'reviewCount': product.reviewCount,
        'isHot': product.isHot,
      }).toList();
      
      await prefs.setString(_wishlistKey, jsonEncode(wishlistJson));
      // Keep cache in sync when saving full list
      _wishlistIdCache = wishlist.map((e) => e.id).toSet();
    } catch (e) {
      print('Error saving wishlist: $e');
    }
  }
  
  // Lấy danh sách sản phẩm theo danh mục từ wishlist
  static Future<List<HatProduct>> getWishlistByCategory(String category) async {
    try {
      List<HatProduct> wishlist = await getWishlist();
      return wishlist.where((product) => product.category == category).toList();
    } catch (e) {
      print('Error getting wishlist by category: $e');
      return [];
    }
  }
  
  // Lấy danh sách sản phẩm theo giá từ wishlist
  static Future<List<HatProduct>> getWishlistByPriceRange({
    required double minPrice,
    required double maxPrice,
  }) async {
    try {
      List<HatProduct> wishlist = await getWishlist();
      return wishlist.where((product) => 
        product.price >= minPrice && product.price <= maxPrice
      ).toList();
    } catch (e) {
      print('Error getting wishlist by price range: $e');
      return [];
    }
  }
  
  // Sắp xếp wishlist theo tiêu chí
  static Future<List<HatProduct>> getSortedWishlist(String sortBy) async {
    try {
      List<HatProduct> wishlist = await getWishlist();
      
      switch (sortBy) {
        case 'name':
          wishlist.sort((a, b) => a.name.compareTo(b.name));
          break;
        case 'price_low':
          wishlist.sort((a, b) => a.price.compareTo(b.price));
          break;
        case 'price_high':
          wishlist.sort((a, b) => b.price.compareTo(a.price));
          break;
        case 'rating':
          wishlist.sort((a, b) => b.rating.compareTo(a.rating));
          break;
        case 'newest':
          // Giữ nguyên thứ tự thêm (không dựa vào ID)
          break;
        default:
          // Mặc định: theo thứ tự thêm vào
          break;
      }
      
      return wishlist;
    } catch (e) {
      print('Error sorting wishlist: $e');
      return [];
    }
  }
  
  // Tìm kiếm trong wishlist
  static Future<List<HatProduct>> searchWishlist(String query) async {
    try {
      List<HatProduct> wishlist = await getWishlist();
      String searchQuery = query.toLowerCase();
      
      return wishlist.where((product) {
        return product.name.toLowerCase().contains(searchQuery) ||
               product.brand.toLowerCase().contains(searchQuery) ||
               product.category.toLowerCase().contains(searchQuery) ||
               product.description.toLowerCase().contains(searchQuery);
      }).toList();
    } catch (e) {
      print('Error searching wishlist: $e');
      return [];
    }
  }
  
  // Lấy thống kê wishlist
  static Future<Map<String, dynamic>> getWishlistStats() async {
    try {
      List<HatProduct> wishlist = await getWishlist();
      
      if (wishlist.isEmpty) {
        return {
          'totalItems': 0,
          'totalValue': 0.0,
          'averagePrice': 0.0,
          'categories': <String, int>{},
          'priceRange': {'min': 0.0, 'max': 0.0},
        };
      }
      
      double totalValue = wishlist.fold(0.0, (sum, product) => sum + product.price);
      double averagePrice = totalValue / wishlist.length;
      
      Map<String, int> categories = {};
      for (var product in wishlist) {
        categories[product.category] = (categories[product.category] ?? 0) + 1;
      }
      
      double minPrice = wishlist.map((p) => p.price).reduce((a, b) => a < b ? a : b);
      double maxPrice = wishlist.map((p) => p.price).reduce((a, b) => a > b ? a : b);
      
      return {
        'totalItems': wishlist.length,
        'totalValue': totalValue,
        'averagePrice': averagePrice,
        'categories': categories,
        'priceRange': {'min': minPrice, 'max': maxPrice},
      };
    } catch (e) {
      print('Error getting wishlist stats: $e');
      return {
        'totalItems': 0,
        'totalValue': 0.0,
        'averagePrice': 0.0,
        'categories': <String, int>{},
        'priceRange': {'min': 0.0, 'max': 0.0},
      };
    }
  }
  
  // Export wishlist
  static Future<String> exportWishlist() async {
    try {
      List<HatProduct> wishlist = await getWishlist();
      Map<String, dynamic> exportData = {
        'wishlist': wishlist.map((product) => {
          'id': product.id,
          'name': product.name,
          'brand': product.brand,
          'price': product.price,
          'imageUrl': product.imageUrl,
          'category': product.category,
          'colors': product.colors,
          'material': product.material,
          'gender': product.gender,
          'season': product.season,
          'description': product.description,
          'stock': product.stock,
          'rating': product.rating,
          'reviewCount': product.reviewCount,
          'isHot': product.isHot,
        }).toList(),
        'exportDate': DateTime.now().toIso8601String(),
        'totalItems': wishlist.length,
      };
      
      return jsonEncode(exportData);
    } catch (e) {
      print('Error exporting wishlist: $e');
      return '{}';
    }
  }
  
  // Import wishlist
  static Future<bool> importWishlist(String jsonData) async {
    try {
      Map<String, dynamic> data = jsonDecode(jsonData);
      
      if (data.containsKey('wishlist')) {
        List<dynamic> wishlistData = data['wishlist'];
        List<HatProduct> wishlist = wishlistData.map((item) {
          return HatProduct(
            id: item['id'],
            name: item['name'],
            brand: item['brand'],
            price: (item['price'] as num).toDouble(),
            imageUrl: item['imageUrl'],
            category: item['category'],
            colors: List<String>.from(item['colors'] ?? []),
            material: item['material'],
            gender: item['gender'],
            season: item['season'],
            description: item['description'],
            stock: item['stock'],
            rating: (item['rating'] as num).toDouble(),
            reviewCount: item['reviewCount'],
            isHot: item['isHot'] ?? false,
          );
        }).toList();
        
        await _saveWishlist(wishlist);
        _changes.add(null);
        return true;
      }
      
      return false;
    } catch (e) {
      print('Error importing wishlist: $e');
      return false;
    }
  }
}


