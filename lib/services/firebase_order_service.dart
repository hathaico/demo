import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart' as models;
import 'firebase_auth_service.dart';
// FirebaseException is available via cloud_firestore import; no extra import needed.
import 'dart:async';

class FirebaseOrderService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'orders';
  // Broadcast controller to notify local listeners when an order is created
  static final StreamController<models.Order> _orderCreatedController =
      StreamController<models.Order>.broadcast();

  static Stream<models.Order> get orderCreatedStream =>
      _orderCreatedController.stream;
  // Pending created orders (in-memory) to be consumed by screens that
  // subscribe after creation (avoids race where UI subscribes after the
  // creation event has already been emitted).
  static final List<models.Order> _pendingCreatedOrders = [];

  static List<models.Order> consumePendingCreatedOrders() {
    final list = List<models.Order>.from(_pendingCreatedOrders);
    _pendingCreatedOrders.clear();
    return list;
  }

  // Tạo đơn hàng mới
  static Future<Map<String, dynamic>> createOrder({
    required List<models.OrderItem> items,
    required double totalAmount,
    required String shippingAddress,
    required String paymentMethod,
  }) async {
    try {
      String? userId = FirebaseAuthService.currentUser?.uid;
      if (userId == null) {
        return {'success': false, 'error': 'Người dùng chưa đăng nhập'};
      }

      // Tạo ID đơn hàng
      String orderId = 'ORD${DateTime.now().millisecondsSinceEpoch}';

      // Chuyển đổi OrderItem thành Map
      List<Map<String, dynamic>> itemsData = items
          .map(
            (item) => {
              'productId': item.productId,
              'productName': item.productName,
              'productImage': item.productImage,
              'price': item.price,
              'quantity': item.quantity,
            },
          )
          .toList();

      // Tạo đơn hàng
      // Use a client timestamp for orderDate so the newly-created order
      // appears immediately in queries ordered by 'orderDate'. We still
      // keep server timestamps for createdAt/updatedAt.
      await _firestore.collection(_collection).doc(orderId).set({
        'id': orderId,
        'userId': userId,
        'items': itemsData,
        'totalAmount': totalAmount,
        'status': 'Chờ xác nhận',
        'orderDate': Timestamp.fromDate(DateTime.now()),
        'shippingAddress': shippingAddress,
        'paymentMethod': paymentMethod,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Cập nhật thống kê người dùng
      await _updateUserStats(userId, totalAmount);

      // Emit local event so UI listeners can show the new order immediately
      try {
        final Map<String, dynamic> createdData = {
          'id': orderId,
          'userId': userId,
          'items': itemsData,
          'totalAmount': totalAmount,
          'status': 'Chờ xác nhận',
          'orderDate': Timestamp.fromDate(DateTime.now()),
          'shippingAddress': shippingAddress,
          'paymentMethod': paymentMethod,
        };
        final models.Order createdOrder = _mapToOrder(createdData);
        // Keep a pending copy so screens that subscribe later can consume it.
        _pendingCreatedOrders.add(createdOrder);
        // Non-blocking broadcast for currently-listening screens
        _orderCreatedController.add(createdOrder);
      } catch (_) {}

      return {
        'success': true,
        'orderId': orderId,
        'message': 'Tạo đơn hàng thành công',
      };
    } catch (e) {
      return {'success': false, 'error': 'Lỗi tạo đơn hàng: $e'};
    }
  }

  // Cập nhật trạng thái đơn hàng
  static Future<Map<String, dynamic>> updateOrderStatus(
    String orderId,
    String newStatus,
  ) async {
    try {
      await _firestore.collection(_collection).doc(orderId).update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return {
        'success': true,
        'message': 'Cập nhật trạng thái đơn hàng thành công',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Lỗi cập nhật trạng thái đơn hàng: $e',
      };
    }
  }

  // Hủy đơn hàng
  static Future<Map<String, dynamic>> cancelOrder(String orderId) async {
    try {
      await _firestore.collection(_collection).doc(orderId).update({
        'status': 'Đã hủy',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return {'success': true, 'message': 'Hủy đơn hàng thành công'};
    } catch (e) {
      return {'success': false, 'error': 'Lỗi hủy đơn hàng: $e'};
    }
  }

  // Lấy đơn hàng theo ID
  static Future<models.Order?> getOrderById(String orderId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection(_collection)
          .doc(orderId)
          .get();

      if (doc.exists) {
        final Map<String, dynamic> data = Map<String, dynamic>.from(
          doc.data() as Map,
        );
        return _mapToOrder(data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Lấy đơn hàng của người dùng hiện tại
  static Future<List<models.Order>> getUserOrders() async {
    try {
      String? userId = FirebaseAuthService.currentUser?.uid;
      if (userId == null) return [];

      // Use server-side ordering for correct pagination and performance.
      QuerySnapshot snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .orderBy('orderDate', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final Map<String, dynamic> data = Map<String, dynamic>.from(
          doc.data() as Map,
        );
        return _mapToOrder(data);
      }).toList();
    } catch (e) {
      // If Firestore complains that the query requires an index, rethrow
      // so callers (UI) can surface a helpful dialog/link. Otherwise,
      // attempt the legacy fallback path.
      if (e is FirebaseException) {
        final msg = e.message ?? '';
        if (msg.contains('requires an index') ||
            e.code == 'failed-precondition') {
          rethrow;
        }
      }

      // As a fallback, attempt to read from a legacy path where some apps
      // stored orders under users/{uid}/orders subcollection. This will
      // help recover orders created by older versions of the app.
      try {
        String? userId = FirebaseAuthService.currentUser?.uid;
        if (userId == null) return [];
        QuerySnapshot fallback = await _firestore
            .collection('users')
            .doc(userId)
            .collection('orders')
            .orderBy('orderDate', descending: true)
            .get();

        return fallback.docs.map((doc) {
          final Map<String, dynamic> data = Map<String, dynamic>.from(
            doc.data() as Map,
          );
          return _mapToOrder(data);
        }).toList();
      } catch (e2) {
        print('Error fetching user orders (fallback): $e2');
        return [];
      }
    }
  }

  // Paginated fetch for orders for the current user.
  // Returns {'orders': List<Order>, 'lastDoc': DocumentSnapshot?}
  static Future<Map<String, dynamic>> getUserOrdersPage({
    int limit = 20,
    DocumentSnapshot? startAfterDoc,
  }) async {
    try {
      String? userId = FirebaseAuthService.currentUser?.uid;
      if (userId == null) return {'orders': <models.Order>[], 'lastDoc': null};

      Query query = _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .orderBy('orderDate', descending: true)
          .limit(limit);

      if (startAfterDoc != null) {
        query = query.startAfterDocument(startAfterDoc);
      }

      QuerySnapshot snapshot = await query.get();

      List<models.Order> orders = snapshot.docs.map((doc) {
        final Map<String, dynamic> data = Map<String, dynamic>.from(
          doc.data() as Map,
        );
        return _mapToOrder(data);
      }).toList();

      DocumentSnapshot? lastDoc = snapshot.docs.isNotEmpty
          ? snapshot.docs.last
          : null;
      return {'orders': orders, 'lastDoc': lastDoc};
    } catch (e) {
      return {'orders': <models.Order>[], 'lastDoc': null};
    }
  }

  // Stream đơn hàng của người dùng hiện tại
  static Stream<List<models.Order>> getUserOrdersStream() {
    String? userId = FirebaseAuthService.currentUser?.uid;
    if (userId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .orderBy('orderDate', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final Map<String, dynamic> data = Map<String, dynamic>.from(
              doc.data() as Map,
            );
            return _mapToOrder(data);
          }).toList();
        });
  }

  // Lấy tất cả đơn hàng (cho admin)
  static Future<List<models.Order>> getAllOrders() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(_collection)
          .orderBy('orderDate', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final Map<String, dynamic> data = Map<String, dynamic>.from(
          doc.data() as Map,
        );
        return _mapToOrder(data);
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // Paginated fetch for admin to browse all orders.
  // Returns {'orders': List<Order>, 'lastDoc': DocumentSnapshot?}
  static Future<Map<String, dynamic>> getOrdersPage({
    int limit = 20,
    DocumentSnapshot? startAfterDoc,
  }) async {
    try {
      Query query = _firestore
          .collection(_collection)
          .orderBy('orderDate', descending: true)
          .limit(limit);
      if (startAfterDoc != null) {
        query = query.startAfterDocument(startAfterDoc);
      }

      QuerySnapshot snapshot = await query.get();

      List<models.Order> orders = snapshot.docs.map((doc) {
        final Map<String, dynamic> data = Map<String, dynamic>.from(
          doc.data() as Map,
        );
        return _mapToOrder(data);
      }).toList();

      DocumentSnapshot? lastDoc = snapshot.docs.isNotEmpty
          ? snapshot.docs.last
          : null;
      return {'orders': orders, 'lastDoc': lastDoc};
    } catch (e) {
      return {'orders': <models.Order>[], 'lastDoc': null};
    }
  }

  // Stream tất cả đơn hàng (cho admin)
  static Stream<List<models.Order>> getAllOrdersStream() {
    return _firestore
        .collection(_collection)
        .orderBy('orderDate', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final Map<String, dynamic> data = Map<String, dynamic>.from(
              doc.data() as Map,
            );
            return _mapToOrder(data);
          }).toList();
        });
  }

  // Lấy đơn hàng theo trạng thái
  static Future<List<models.Order>> getOrdersByStatus(String status) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(_collection)
          .where('status', isEqualTo: status)
          .orderBy('orderDate', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final Map<String, dynamic> data = Map<String, dynamic>.from(
          doc.data() as Map,
        );
        return _mapToOrder(data);
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // Stream đơn hàng theo trạng thái
  static Stream<List<models.Order>> getOrdersByStatusStream(String status) {
    return _firestore
        .collection(_collection)
        .where('status', isEqualTo: status)
        .orderBy('orderDate', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final Map<String, dynamic> data = Map<String, dynamic>.from(
              doc.data() as Map,
            );
            return _mapToOrder(data);
          }).toList();
        });
  }

  // Lấy đơn hàng theo khoảng thời gian
  static Future<List<models.Order>> getOrdersByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(_collection)
          .where(
            'orderDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
          )
          .where('orderDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('orderDate', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final Map<String, dynamic> data = Map<String, dynamic>.from(
          doc.data() as Map,
        );
        return _mapToOrder(data);
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // Lấy thống kê đơn hàng
  static Future<Map<String, dynamic>> getOrderStats() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection(_collection).get();

      int totalOrders = snapshot.docs.length;
      double totalRevenue = 0;
      Map<String, int> statusCount = {};

      for (var doc in snapshot.docs) {
        final Map<String, dynamic> data = Map<String, dynamic>.from(
          doc.data() as Map,
        );
        String status = data['status'] ?? 'Unknown';
        double amount = (data['totalAmount'] ?? 0).toDouble();

        totalRevenue += amount;
        statusCount[status] = (statusCount[status] ?? 0) + 1;
      }

      return {
        'totalOrders': totalOrders,
        'totalRevenue': totalRevenue,
        'statusCount': statusCount,
        'averageOrderValue': totalOrders > 0 ? totalRevenue / totalOrders : 0,
      };
    } catch (e) {
      return {
        'totalOrders': 0,
        'totalRevenue': 0,
        'statusCount': {},
        'averageOrderValue': 0,
      };
    }
  }

  // Lấy thống kê đơn hàng theo ngày
  static Future<List<Map<String, dynamic>>> getDailyOrderStats(int days) async {
    try {
      DateTime endDate = DateTime.now();
      DateTime startDate = endDate.subtract(Duration(days: days));

      QuerySnapshot snapshot = await _firestore
          .collection(_collection)
          .where(
            'orderDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
          )
          .where('orderDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      Map<String, Map<String, dynamic>> dailyStats = {};

      for (var doc in snapshot.docs) {
        final Map<String, dynamic> data = Map<String, dynamic>.from(
          doc.data() as Map,
        );
        Timestamp orderDate = data['orderDate'] as Timestamp;
        String dateKey = orderDate.toDate().toIso8601String().split('T')[0];
        double amount = (data['totalAmount'] ?? 0).toDouble();

        if (!dailyStats.containsKey(dateKey)) {
          dailyStats[dateKey] = {
            'date': dateKey,
            'orderCount': 0,
            'revenue': 0.0,
          };
        }

        dailyStats[dateKey]!['orderCount']++;
        dailyStats[dateKey]!['revenue'] += amount;
      }

      return dailyStats.values.toList()
        ..sort((a, b) => a['date'].compareTo(b['date']));
    } catch (e) {
      return [];
    }
  }

  // Cập nhật thống kê người dùng
  static Future<void> _updateUserStats(
    String userId,
    double orderAmount,
  ) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'totalOrders': FieldValue.increment(1),
        'totalSpent': FieldValue.increment(orderAmount),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating user stats: $e');
    }
  }

  // Khởi tạo dữ liệu mẫu đơn hàng
  static Future<void> initializeSampleOrders() async {
    try {
      // Kiểm tra xem đã có dữ liệu chưa
      QuerySnapshot snapshot = await _firestore
          .collection(_collection)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return; // Đã có dữ liệu
      }

      // Tạo một số đơn hàng mẫu
      List<Map<String, dynamic>> sampleOrders = [
        {
          'id': 'ORD001',
          'userId': 'sample_user_1',
          'items': [
            {
              'productId': '1',
              'productName': 'Snapback Classic Black',
              'productImage': 'placeholder_widget',
              'price': 299000,
              'quantity': 1,
            },
          ],
          'totalAmount': 299000,
          'status': 'Đang xử lý',
          'orderDate': Timestamp.fromDate(
            DateTime.now().subtract(const Duration(days: 2)),
          ),
          'shippingAddress': '123 Nguyễn Văn A, Q1, TP.HCM',
          'paymentMethod': 'COD',
        },
        {
          'id': 'ORD002',
          'userId': 'sample_user_2',
          'items': [
            {
              'productId': '2',
              'productName': 'Bucket Hat Camo',
              'productImage': 'placeholder_widget',
              'price': 199000,
              'quantity': 2,
            },
          ],
          'totalAmount': 398000,
          'status': 'Đã giao',
          'orderDate': Timestamp.fromDate(
            DateTime.now().subtract(const Duration(days: 5)),
          ),
          'shippingAddress': '456 Lê Văn B, Q3, TP.HCM',
          'paymentMethod': 'Chuyển khoản',
        },
      ];

      // Thêm từng đơn hàng vào Firestore
      for (var orderData in sampleOrders) {
        await _firestore.collection(_collection).doc(orderData['id']).set({
          ...orderData,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error initializing sample orders: $e');
    }
  }

  // Helper method để chuyển đổi từ Firestore data sang Order
  static models.Order _mapToOrder(Map<String, dynamic> data) {
    List<models.OrderItem> items = (data['items'] as List<dynamic>).map((
      itemData,
    ) {
      return models.OrderItem(
        productId: itemData['productId'] ?? '',
        productName: itemData['productName'] ?? '',
        productImage: itemData['productImage'] ?? '',
        price: (itemData['price'] ?? 0).toDouble(),
        quantity: itemData['quantity'] ?? 0,
      );
    }).toList();

    Timestamp orderDate = data['orderDate'] as Timestamp? ?? Timestamp.now();

    return models.Order(
      id: data['id'] ?? '',
      userId: data['userId'] ?? '',
      items: items,
      totalAmount: (data['totalAmount'] ?? 0).toDouble(),
      status: data['status'] ?? '',
      orderDate: orderDate.toDate(),
      shippingAddress: data['shippingAddress'] ?? '',
      paymentMethod: data['paymentMethod'] ?? '',
    );
  }
}
