import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';
import 'notification_service.dart';
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

      final HatProduct createdProduct = HatProduct(
        id: docRef.id,
        name: product.name,
        brand: product.brand,
        price: product.price,
        imageUrl: product.imageUrl,
        category: product.category,
        colors: product.colors,
        material: product.material,
        gender: product.gender,
        season: product.season,
        description: product.description,
        stock: product.stock,
        rating: product.rating,
        reviewCount: product.reviewCount,
        isHot: product.isHot,
      );

      // Cache the freshly created product for faster subsequent reads.
      _productCache[docRef.id] = createdProduct;
      try {
        await ProductCacheService.cacheProducts([createdProduct]);
      } catch (_) {}

      // Broadcast a notification so users know a new style just landed.
      final String displayName = product.name.trim().isEmpty
          ? 'Mẫu nón mới'
          : product.name.trim();
      try {
        await NotificationService.createBroadcastNotification(
          title: '$displayName vừa lên kệ',
          body:
              'Khám phá ngay mẫu nón mới toanh và chọn lựa phong cách của bạn!',
          category: NotificationCategory.promotion,
          extra: {
            'productId': docRef.id,
            'productName': product.name,
            if (product.imageUrl.isNotEmpty) 'productImage': product.imageUrl,
            'type': 'new_product',
            'isHot': product.isHot,
          },
        );
      } catch (_) {}

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
      final docRef = _firestore.collection(_collection).doc(productId);
      final snapshot = await docRef.get();
      if (!snapshot.exists) {
        return {
          'success': false,
          'error': 'Sản phẩm với mã $productId không tồn tại',
        };
      }

      final Map<String, dynamic> previousData = Map<String, dynamic>.from(
        snapshot.data() as Map,
      );
      final int previousStock = _normalizeStock(previousData['stock']);

      await docRef.update({
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

      final bool restocked = previousStock <= 0 && product.stock > 0;

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

      if (restocked) {
        try {
          await _notifyProductRestocked(
            productId: productId,
            productName: product.name,
            productImage: product.imageUrl,
          );
        } catch (_) {}
      }

      return {'success': true, 'message': 'Cập nhật sản phẩm thành công'};
    } catch (e) {
      return {'success': false, 'error': 'Lỗi cập nhật sản phẩm: $e'};
    }
  }

  static int _normalizeStock(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  static int _normalizeReviewCount(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  static Future<void> _notifyProductRestocked({
    required String productId,
    required String productName,
    required String productImage,
  }) async {
    final Set<String> userIds = <String>{};
    final CollectionReference<Map<String, dynamic>> ordersRef = _firestore
        .collection('orders');
    const List<String> statusesToCheck = ['Đã hủy', 'Chờ xác nhận'];
    final Timestamp cutoff = Timestamp.fromDate(
      DateTime.now().subtract(const Duration(days: 60)),
    );

    for (final status in statusesToCheck) {
      Query<Map<String, dynamic>> query = ordersRef.where(
        'status',
        isEqualTo: status,
      );
      QuerySnapshot<Map<String, dynamic>> snapshot;
      try {
        snapshot = await query
            .where('orderDate', isGreaterThanOrEqualTo: cutoff)
            .limit(200)
            .get();
      } on FirebaseException catch (e) {
        final String message = e.message ?? '';
        if (e.code == 'failed-precondition' ||
            message.contains('index') ||
            message.contains('requires')) {
          snapshot = await query.limit(200).get();
        } else {
          rethrow;
        }
      }

      for (final doc in snapshot.docs) {
        final Map<String, dynamic> data = Map<String, dynamic>.from(doc.data());
        final List<dynamic> rawItems = data['items'] as List<dynamic>? ?? [];
        final bool containsProduct = rawItems.any((raw) {
          if (raw is Map<String, dynamic>) {
            return raw['productId'] == productId;
          }
          try {
            final map = Map<String, dynamic>.from(raw as Map);
            return map['productId'] == productId;
          } catch (_) {
            return false;
          }
        });

        if (!containsProduct) {
          continue;
        }

        final String userId = (data['userId'] ?? data['userUID'] ?? '')
            .toString()
            .trim();
        if (userId.isNotEmpty) {
          userIds.add(userId);
        }
      }
    }

    if (userIds.isEmpty) {
      return;
    }

    final String displayName = productName.trim().isEmpty
        ? 'Sản phẩm bạn quan tâm'
        : productName;
    final String title = '$displayName đã có hàng trở lại';
    final String body =
        'Sản phẩm bạn quan tâm đã được bổ sung kho. Bạn có thể đặt lại đơn hàng ngay bây giờ.';

    for (final userId in userIds) {
      try {
        await NotificationService.createUserNotification(
          userId: userId,
          title: title,
          body: body,
          category: NotificationCategory.stock,
          extra: {
            'productId': productId,
            'productName': productName,
            if (productImage.isNotEmpty) 'productImage': productImage,
            'type': 'restock',
          },
        );
      } catch (_) {}
    }
  }

  static Future<Map<String, dynamic>> upsertProductReview({
    required String productId,
    required String userId,
    required String userName,
    required double rating,
    required String comment,
    String? reviewId,
  }) async {
    final double sanitizedRating = rating.clamp(1, 5);
    final String trimmedComment = comment.trim();
    if (trimmedComment.isEmpty) {
      return {
        'success': false,
        'error': 'Nội dung đánh giá không được để trống.',
      };
    }

    String? targetReviewId = reviewId;
    if (targetReviewId == null || targetReviewId.isEmpty) {
      try {
        final existing = await _firestore
            .collection('reviews')
            .where('productId', isEqualTo: productId)
            .where('userId', isEqualTo: userId)
            .limit(1)
            .get();
        if (existing.docs.isNotEmpty) {
          targetReviewId = existing.docs.first.id;
        }
      } catch (_) {
        // Ignore lookup errors, treat as new review.
      }
    }

    final DocumentReference<Map<String, dynamic>> productRef = _firestore
        .collection(_collection)
        .doc(productId);
    final DocumentReference<Map<String, dynamic>> reviewRef =
        (targetReviewId != null && targetReviewId.isNotEmpty)
        ? _firestore.collection('reviews').doc(targetReviewId)
        : _firestore.collection('reviews').doc();

    try {
      final result = await _firestore.runTransaction<Map<String, dynamic>>((
        transaction,
      ) async {
        final productSnapshot = await transaction.get(productRef);
        if (!productSnapshot.exists) {
          throw StateError('Sản phẩm không tồn tại');
        }

        final Map<String, dynamic> productData = Map<String, dynamic>.from(
          productSnapshot.data() ?? {},
        );
        final double currentAverage = (productData['rating'] ?? 0).toDouble();
        final int currentCount = _normalizeReviewCount(
          productData['reviewCount'],
        );

        DocumentSnapshot<Map<String, dynamic>>? reviewSnapshot;
        try {
          reviewSnapshot = await transaction.get(reviewRef);
        } catch (_) {
          reviewSnapshot = null;
        }

        final bool isUpdate = reviewSnapshot?.exists == true;
        final double previousRating = isUpdate
            ? ((reviewSnapshot!.data()?['rating']) as num?)?.toDouble() ??
                  sanitizedRating
            : 0;

        int newCount = currentCount;
        double newAverage;
        if (isUpdate && currentCount > 0) {
          final double total = currentAverage * currentCount;
          newAverage =
              (total - previousRating + sanitizedRating) / currentCount;
        } else {
          newCount = currentCount + 1;
          final double total = currentAverage * currentCount + sanitizedRating;
          newAverage = newCount == 0 ? 0 : total / newCount;
        }

        newAverage = double.parse(newAverage.toStringAsFixed(1));

        transaction.update(productRef, {
          'rating': newAverage,
          'reviewCount': newCount,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        final Map<String, dynamic> payload = {
          'productId': productId,
          'userId': userId,
          'userName': userName,
          'rating': sanitizedRating,
          'comment': trimmedComment,
          'updatedAt': FieldValue.serverTimestamp(),
        };

        if (isUpdate) {
          transaction.update(reviewRef, payload);
        } else {
          payload['createdAt'] = FieldValue.serverTimestamp();
          transaction.set(reviewRef, payload);
        }

        return {
          'averageRating': newAverage,
          'reviewCount': newCount,
          'reviewId': reviewRef.id,
        };
      }, maxAttempts: 3);

      return {'success': true, ...result};
    } catch (e) {
      return {'success': false, 'error': 'Không thể gửi đánh giá: $e'};
    }
  }

  static Future<Map<String, dynamic>> deleteProductReview({
    required String productId,
    required String userId,
    String? reviewId,
  }) async {
    late final DocumentReference<Map<String, dynamic>> reviewRef;

    if (reviewId != null && reviewId.isNotEmpty) {
      reviewRef = _firestore.collection('reviews').doc(reviewId);
    } else {
      try {
        final query = await _firestore
            .collection('reviews')
            .where('productId', isEqualTo: productId)
            .where('userId', isEqualTo: userId)
            .limit(1)
            .get();
        if (query.docs.isEmpty) {
          return {'success': false, 'error': 'Không tìm thấy đánh giá để xóa.'};
        }
        reviewRef = query.docs.first.reference;
      } catch (e) {
        return {'success': false, 'error': 'Không thể tìm đánh giá: $e'};
      }
    }

    final DocumentReference<Map<String, dynamic>> productRef = _firestore
        .collection(_collection)
        .doc(productId);

    try {
      final result = await _firestore.runTransaction<Map<String, dynamic>>((
        transaction,
      ) async {
        final productSnapshot = await transaction.get(productRef);
        if (!productSnapshot.exists) {
          throw StateError('Sản phẩm không tồn tại');
        }

        final reviewSnapshot = await transaction.get(reviewRef);
        if (!reviewSnapshot.exists) {
          throw StateError('Đánh giá không tồn tại');
        }

        final Map<String, dynamic> reviewData = Map<String, dynamic>.from(
          reviewSnapshot.data() ?? {},
        );
        final String ownerId = (reviewData['userId'] ?? '').toString();
        if (ownerId.isNotEmpty && ownerId != userId) {
          throw StateError('Bạn không thể xóa đánh giá này.');
        }

        final double reviewRating =
            (reviewData['rating'] as num?)?.toDouble() ?? 0;

        final Map<String, dynamic> productData = Map<String, dynamic>.from(
          productSnapshot.data() ?? {},
        );
        final double currentAverage = (productData['rating'] ?? 0).toDouble();
        final int currentCount = _normalizeReviewCount(
          productData['reviewCount'],
        );

        final int newCount = currentCount > 0 ? currentCount - 1 : 0;
        double newAverage;
        if (newCount == 0) {
          newAverage = 0;
        } else {
          final double total = currentAverage * currentCount;
          newAverage = (total - reviewRating) / newCount;
        }

        if (newAverage.isNaN || newAverage.isInfinite) {
          newAverage = 0;
        }

        newAverage = double.parse(newAverage.toStringAsFixed(1));
        if (newAverage < 0) newAverage = 0;
        if (newAverage > 5) newAverage = 5;

        transaction.update(productRef, {
          'rating': newAverage,
          'reviewCount': newCount,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        transaction.delete(reviewRef);

        return {'averageRating': newAverage, 'reviewCount': newCount};
      }, maxAttempts: 3);

      return {'success': true, ...result};
    } catch (e) {
      return {'success': false, 'error': 'Không thể xóa đánh giá: $e'};
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
      final bool hasCategoryFilter = category != null && category.isNotEmpty;
      final bool hasSearch = search != null && search.trim().isNotEmpty;

      Query query = _firestore.collection(_collection);

      if (hasCategoryFilter) {
        query = query.where('category', isEqualTo: category);
      }

      if (hasSearch) {
        final String keyword = search.trim().toLowerCase();
        query = _firestore
            .collection(_collection)
            .orderBy('name_lower')
            .startAt([keyword])
            .endAt(['$keyword\uf8ff']);
        // Search results ignore category filter to keep query lightweight.
      } else {
        query = query.orderBy(orderByField, descending: descending);
      }

      if (startAfterDoc != null) {
        query = query.startAfterDocument(startAfterDoc);
      }

      query = query.limit(limit);

      QuerySnapshot snapshot;
      try {
        snapshot = await query.get();
      } on FirebaseException catch (e) {
        final String message = e.message ?? '';
        final bool isMissingIndex =
            e.code == 'failed-precondition' && message.contains('index');

        if (!hasSearch && isMissingIndex) {
          // Re-run without ordering so Firestore doesn't require a composite index.
          Query fallback = _firestore.collection(_collection);
          if (hasCategoryFilter) {
            fallback = fallback.where('category', isEqualTo: category);
          }
          if (startAfterDoc != null) {
            fallback = fallback.startAfterDocument(startAfterDoc);
          }
          fallback = fallback.limit(limit);
          snapshot = await fallback.get();
        } else {
          rethrow;
        }
      }

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
