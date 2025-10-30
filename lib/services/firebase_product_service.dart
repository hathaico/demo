import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';
import 'product_cache_service.dart';

class FirebaseProductService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'products';
  // In-memory cache for product lookups to reduce repeated reads.
  static final Map<String, HatProduct> _productCache = {};

  // Thêm sản phẩm mới
  static Future<Map<String, dynamic>> addProduct(HatProduct product) async {
    try {
      DocumentReference docRef = await _firestore.collection(_collection).add({
        'name': product.name,
        // lowercase helper for server-side case-insensitive prefix search
        'name_lower': product.name.toLowerCase(),
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
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return {
        'success': true,
        'productId': docRef.id,
        'message': 'Thêm sản phẩm thành công',
      };
    } catch (e) {
      return {'success': false, 'error': 'Lỗi thêm sản phẩm: $e'};
    }
  }

  // Cập nhật sản phẩm
  static Future<Map<String, dynamic>> updateProduct(
    String productId,
    HatProduct product,
  ) async {
    try {
      await _firestore.collection(_collection).doc(productId).update({
        'name': product.name,
        // update lowercase helper
        'name_lower': product.name.toLowerCase(),
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
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Invalidate cache for this product
      _productCache.remove(productId);

      // Also update persistent cache if available
      try {
        await ProductCacheService.cacheProducts([
          _mapToHatProduct(productId, {
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
          }),
        ]);
      } catch (_) {}

      return {'success': true, 'message': 'Cập nhật sản phẩm thành công'};
    } catch (e) {
      return {'success': false, 'error': 'Lỗi cập nhật sản phẩm: $e'};
    }
  }

  // Xóa sản phẩm
  static Future<Map<String, dynamic>> deleteProduct(String productId) async {
    try {
      await _firestore.collection(_collection).doc(productId).delete();
      // Remove from cache
      _productCache.remove(productId);

      // Remove from persistent cache
      try {
        await ProductCacheService.delete(productId);
      } catch (_) {}

      return {'success': true, 'message': 'Xóa sản phẩm thành công'};
    } catch (e) {
      return {'success': false, 'error': 'Lỗi xóa sản phẩm: $e'};
    }
  }

  /// One-time migration helper to add `name_lower` to existing product documents
  /// so server-side prefix search works. This method runs in batches and will
  /// skip documents that already have `name_lower` set. It returns a map with
  /// counters for updated/skipped/errors.
  static Future<Map<String, int>> migrateAddNameLower({
    int batchSize = 200,
    bool dryRun = true,
  }) async {
    int updated = 0;
    int skipped = 0;
    int errors = 0;

    try {
      Query query = _firestore
          .collection(_collection)
          .orderBy(FieldPath.documentId)
          .limit(batchSize);
      DocumentSnapshot? lastDoc;

      while (true) {
        Query q = query;
        if (lastDoc != null) q = q.startAfterDocument(lastDoc);
        final snapshot = await q.get();
        if (snapshot.docs.isEmpty) break;

        for (var doc in snapshot.docs) {
          try {
            final Map<String, dynamic> data = Map<String, dynamic>.from(
              doc.data() as Map,
            );
            if (data.containsKey('name_lower') &&
                (data['name_lower'] ?? '').toString().isNotEmpty) {
              skipped++;
              continue;
            }

            final name = (data['name'] ?? '').toString();
            if (name.isEmpty) {
              skipped++;
              continue;
            }

            if (!dryRun) {
              await _firestore.collection(_collection).doc(doc.id).update({
                'name_lower': name.toLowerCase(),
                'updatedAt': FieldValue.serverTimestamp(),
              });
            }
            updated++;
          } catch (e) {
            errors++;
          }
        }

        lastDoc = snapshot.docs.last;
        if (snapshot.docs.length < batchSize) break;
      }
    } catch (e) {
      // top-level failure
    }

    return {'updated': updated, 'skipped': skipped, 'errors': errors};
  }

  // Lấy sản phẩm theo ID
  static Future<HatProduct?> getProductById(
    String productId, {
    bool forceRefresh = false,
  }) async {
    try {
      if (!forceRefresh && _productCache.containsKey(productId)) {
        return _productCache[productId];
      }

      DocumentSnapshot doc = await _firestore
          .collection(_collection)
          .doc(productId)
          .get();

      if (doc.exists) {
        final Map<String, dynamic> data = Map<String, dynamic>.from(
          doc.data() as Map,
        );
        final product = _mapToHatProduct(doc.id, data);
        _productCache[productId] = product;
        return product;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Lấy tất cả sản phẩm
  static Future<List<HatProduct>> getAllProducts() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection(_collection).get();
      return snapshot.docs.map((doc) {
        final Map<String, dynamic> data = Map<String, dynamic>.from(
          doc.data() as Map,
        );
        return _mapToHatProduct(doc.id, data);
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // Paginated fetch for products. Returns {'products': List<HatProduct>, 'lastDoc': DocumentSnapshot?}
  static Future<Map<String, dynamic>> getProductsPage({
    int limit = 20,
    DocumentSnapshot? startAfterDoc,
    String orderByField = 'createdAt',
    bool descending = true,
    String? category,
    String? search,
  }) async {
    try {
      Query query = _firestore.collection(_collection);

      // Apply category filter server-side when provided
      if (category != null && category.isNotEmpty) {
        query = query.where('category', isEqualTo: category);
      }

      // Apply ordering and pagination
      query = query.orderBy(orderByField, descending: descending).limit(limit);

      if (startAfterDoc != null) {
        query = query.startAfterDocument(startAfterDoc);
      }

      // If search provided, prefer server-side prefix search on a `name_lower` field.
      // Note: this requires documents to contain a `name_lower` lowercase field.
      if (search != null && search.trim().isNotEmpty) {
        final s = search.trim().toLowerCase();
        // When using name_lower search we must order by that field.
        query = _firestore
            .collection(_collection)
            .orderBy('name_lower')
            .startAt([s])
            .endAt(['$s\uf8ff'])
            .limit(limit);
      }

      QuerySnapshot snapshot = await query.get();

      List<HatProduct> products = snapshot.docs.map((doc) {
        final Map<String, dynamic> data = Map<String, dynamic>.from(
          doc.data() as Map,
        );
        final p = _mapToHatProduct(doc.id, data);
        // cache product
        _productCache[doc.id] = p;
        return p;
      }).toList();

      // Persist this page to local cache (best-effort)
      try {
        await ProductCacheService.cacheProducts(products);
      } catch (_) {}

      DocumentSnapshot? lastDoc = snapshot.docs.isNotEmpty
          ? snapshot.docs.last
          : null;
      return {'products': products, 'lastDoc': lastDoc};
    } catch (e) {
      return {'products': <HatProduct>[], 'lastDoc': null};
    }
  }

  // Stream tất cả sản phẩm
  static Stream<List<HatProduct>> getAllProductsStream() {
    return _firestore.collection(_collection).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final Map<String, dynamic> data = Map<String, dynamic>.from(
          doc.data() as Map,
        );
        return _mapToHatProduct(doc.id, data);
      }).toList();
    });
  }

  // Lấy sản phẩm theo danh mục
  static Future<List<HatProduct>> getProductsByCategory(String category) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(_collection)
          .where('category', isEqualTo: category)
          .get();

      return snapshot.docs.map((doc) {
        final Map<String, dynamic> data = Map<String, dynamic>.from(
          doc.data() as Map,
        );
        return _mapToHatProduct(doc.id, data);
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // Stream sản phẩm theo danh mục
  static Stream<List<HatProduct>> getProductsByCategoryStream(String category) {
    return _firestore
        .collection(_collection)
        .where('category', isEqualTo: category)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final Map<String, dynamic> data = Map<String, dynamic>.from(
              doc.data() as Map,
            );
            return _mapToHatProduct(doc.id, data);
          }).toList();
        });
  }

  // Lấy sản phẩm hot
  static Future<List<HatProduct>> getHotProducts() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(_collection)
          .where('isHot', isEqualTo: true)
          .limit(10)
          .get();

      return snapshot.docs.map((doc) {
        final Map<String, dynamic> data = Map<String, dynamic>.from(
          doc.data() as Map,
        );
        return _mapToHatProduct(doc.id, data);
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // Stream sản phẩm hot
  static Stream<List<HatProduct>> getHotProductsStream() {
    return _firestore
        .collection(_collection)
        .where('isHot', isEqualTo: true)
        .limit(10)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final Map<String, dynamic> data = Map<String, dynamic>.from(
              doc.data() as Map,
            );
            return _mapToHatProduct(doc.id, data);
          }).toList();
        });
  }

  // Tìm kiếm sản phẩm
  static Future<List<HatProduct>> searchProducts(String query) async {
    try {
      // Limit the amount of documents loaded for search. For large datasets,
      // consider adding indexed lowercase fields (e.g., `name_lower`) and
      // query on them instead of fetching and filtering client-side.
      const int pageLimit = 200;
      QuerySnapshot snapshot = await _firestore
          .collection(_collection)
          .limit(pageLimit)
          .get();

      List<HatProduct> products = snapshot.docs.map((doc) {
        final Map<String, dynamic> data = Map<String, dynamic>.from(
          doc.data() as Map,
        );
        return _mapToHatProduct(doc.id, data);
      }).toList();

      // Filter locally (Firestore doesn't support case-insensitive search)
      return products.where((product) {
        return product.name.toLowerCase().contains(query.toLowerCase()) ||
            product.brand.toLowerCase().contains(query.toLowerCase()) ||
            product.category.toLowerCase().contains(query.toLowerCase()) ||
            product.description.toLowerCase().contains(query.toLowerCase());
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // Lấy sản phẩm theo giá
  static Future<List<HatProduct>> getProductsByPriceRange({
    required double minPrice,
    required double maxPrice,
  }) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(_collection)
          .where('price', isGreaterThanOrEqualTo: minPrice)
          .where('price', isLessThanOrEqualTo: maxPrice)
          .get();

      return snapshot.docs.map((doc) {
        final Map<String, dynamic> data = Map<String, dynamic>.from(
          doc.data() as Map,
        );
        return _mapToHatProduct(doc.id, data);
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // Cập nhật số lượng tồn kho
  static Future<Map<String, dynamic>> updateStock(
    String productId,
    int newStock,
  ) async {
    try {
      await _firestore.collection(_collection).doc(productId).update({
        'stock': newStock,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return {'success': true, 'message': 'Cập nhật tồn kho thành công'};
    } catch (e) {
      return {'success': false, 'error': 'Lỗi cập nhật tồn kho: $e'};
    }
  }

  // Cập nhật đánh giá sản phẩm
  static Future<Map<String, dynamic>> updateRating(
    String productId,
    double newRating,
    int reviewCount,
  ) async {
    try {
      await _firestore.collection(_collection).doc(productId).update({
        'rating': newRating,
        'reviewCount': reviewCount,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return {'success': true, 'message': 'Cập nhật đánh giá thành công'};
    } catch (e) {
      return {'success': false, 'error': 'Lỗi cập nhật đánh giá: $e'};
    }
  }

  // Lấy danh sách danh mục
  static Future<List<String>> getCategories() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection(_collection).get();
      Set<String> categories = {};

      for (var doc in snapshot.docs) {
        final Map<String, dynamic> data = Map<String, dynamic>.from(
          doc.data() as Map,
        );
        categories.add(data['category'] ?? '');
      }

      return categories.toList()..sort();
    } catch (e) {
      return [];
    }
  }

  // Lấy thống kê sản phẩm
  static Future<Map<String, dynamic>> getProductStats() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection(_collection).get();

      int totalProducts = snapshot.docs.length;
      int totalStock = 0;
      double totalValue = 0;
      int hotProducts = 0;

      for (var doc in snapshot.docs) {
        final Map<String, dynamic> data = Map<String, dynamic>.from(
          doc.data() as Map,
        );
        int stock = data['stock'] ?? 0;
        double price = (data['price'] ?? 0).toDouble();

        totalStock += stock;
        totalValue += stock * price;

        if (data['isHot'] == true) {
          hotProducts++;
        }
      }

      return {
        'totalProducts': totalProducts,
        'totalStock': totalStock,
        'totalValue': totalValue,
        'hotProducts': hotProducts,
      };
    } catch (e) {
      return {
        'totalProducts': 0,
        'totalStock': 0,
        'totalValue': 0,
        'hotProducts': 0,
      };
    }
  }

  // Helper method để chuyển đổi từ Firestore data sang HatProduct
  static HatProduct _mapToHatProduct(String id, Map<String, dynamic> data) {
    return HatProduct(
      id: id,
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
  }
}
