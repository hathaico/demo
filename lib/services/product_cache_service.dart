import 'package:hive_flutter/hive_flutter.dart';
import '../models/models.dart';

class ProductCacheService {
  static const String _boxName = 'products_cache';

  static Future<void> initialize() async {
    await Hive.initFlutter();
    await Hive.openBox(_boxName);
  }

  static Future<void> cacheProducts(List<HatProduct> products) async {
    final box = Hive.box(_boxName);
    final Map<String, Map<String, dynamic>> map = {
      for (var p in products)
        p.id: {
          'id': p.id,
          'name': p.name,
          'brand': p.brand,
          'price': p.price,
          'imageUrl': p.imageUrl,
          'category': p.category,
          'colors': p.colors,
          'material': p.material,
          'gender': p.gender,
          'season': p.season,
          'description': p.description,
          'stock': p.stock,
          'rating': p.rating,
          'reviewCount': p.reviewCount,
          'isHot': p.isHot,
        },
    };

    await box.putAll(map);
  }

  static List<HatProduct> getCachedProducts() {
    final box = Hive.box(_boxName);
    return box.values.map((v) {
      final Map<String, dynamic> data = Map<String, dynamic>.from(v as Map);
      return HatProduct(
        id: data['id'] ?? '',
        name: data['name'] ?? '',
        brand: data['brand'] ?? '',
        price: (data['price'] ?? 0).toDouble(),
        imageUrl: data['imageUrl'] ?? '',
        category: data['category'] ?? '',
        colors: List<String>.from(data['colors'] ?? []),
        material: data['material'] ?? '',
        gender: data['gender'] ?? '',
        season: data['season'] ?? '',
        description: data['description'] ?? '',
        stock: data['stock'] ?? 0,
        rating: (data['rating'] ?? 0).toDouble(),
        reviewCount: data['reviewCount'] ?? 0,
        isHot: data['isHot'] ?? false,
      );
    }).toList();
  }

  /// Remove a product from the persistent cache by id.
  static Future<void> delete(String productId) async {
    final box = Hive.box(_boxName);
    if (box.containsKey(productId)) {
      await box.delete(productId);
    }
  }

  /// Clear the entire product cache.
  static Future<void> clearAll() async {
    final box = Hive.box(_boxName);
    await box.clear();
  }
}
