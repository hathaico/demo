import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/models.dart' as app_models;
import 'notification_service.dart';

class AdminDataService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Stream of users mapped to app User model
  static Stream<List<app_models.User>> usersStream() {
    return _firestore.collection('users').snapshots().map((snap) {
      return snap.docs.map((doc) {
        final Map<String, dynamic> data = Map<String, dynamic>.from(
          doc.data() as Map,
        );
        return app_models.User(
          id: doc.id,
          fullName: data['fullName'] ?? data['name'] ?? '',
          email: data['email'] ?? '',
          phone: data['phone'] ?? '',
          username:
              data['username'] ??
              (data['email'] is String
                  ? (data['email'] as String).split('@').first
                  : ''),
          joinDate: data['createdAt'] != null && data['createdAt'] is Timestamp
              ? (data['createdAt'] as Timestamp).toDate()
              : DateTime.now(),
          isActive: data['isActive'] ?? true,
          totalOrders: data['totalOrders'] ?? 0,
          totalSpent: (data['totalSpent'] ?? 0).toDouble(),
        );
      }).toList();
    });
  }

  /// Stream of orders mapped to app Order model
  static Stream<List<app_models.Order>> ordersStream() {
    return _firestore
        .collection('orders')
        .orderBy('orderDate', descending: true)
        .snapshots()
        .map((snap) {
          return snap.docs.map((doc) {
            final Map<String, dynamic> data = Map<String, dynamic>.from(
              doc.data() as Map,
            );

            final List<app_models.OrderItem> items =
                (data['items'] as List? ?? []).map((raw) {
                  final Map<String, dynamic> d = Map<String, dynamic>.from(
                    raw as Map,
                  );
                  return app_models.OrderItem(
                    productId: d['productId'] ?? '',
                    productName: d['productName'] ?? d['name'] ?? '',
                    productImage: d['productImage'] ?? '',
                    price: (d['price'] ?? 0).toDouble(),
                    quantity: (d['quantity'] ?? 1) as int,
                  );
                }).toList();

            DateTime orderDate;
            if (data['orderDate'] != null && data['orderDate'] is Timestamp) {
              orderDate = (data['orderDate'] as Timestamp).toDate();
            } else if (data['createdAt'] != null &&
                data['createdAt'] is Timestamp) {
              orderDate = (data['createdAt'] as Timestamp).toDate();
            } else {
              orderDate = DateTime.now();
            }

            return app_models.Order(
              id: doc.id,
              userId: data['userId'] ?? data['userUID'] ?? '',
              items: items,
              totalAmount: (data['totalAmount'] ?? data['total'] ?? 0)
                  .toDouble(),
              status: data['status'] ?? 'Đang xử lý',
              orderDate: orderDate,
              shippingAddress: data['shippingAddress'] ?? data['address'] ?? '',
              paymentMethod: data['paymentMethod'] ?? data['payment'] ?? '',
            );
          }).toList();
        });
  }

  /// Fetch orders once (limited result) for analytics use without streams.
  static Future<List<app_models.Order>> fetchOrdersOnce({
    int limit = 50,
  }) async {
    final query = await _firestore
        .collection('orders')
        .orderBy('orderDate', descending: true)
        .limit(limit)
        .get();
    return query.docs.map((doc) {
      final Map<String, dynamic> data = Map<String, dynamic>.from(
        doc.data() as Map,
      );
      final List<app_models.OrderItem> items = (data['items'] as List? ?? [])
          .map((raw) {
            final Map<String, dynamic> d = Map<String, dynamic>.from(
              raw as Map,
            );
            return app_models.OrderItem(
              productId: d['productId'] ?? '',
              productName: d['productName'] ?? d['name'] ?? '',
              productImage: d['productImage'] ?? '',
              price: (d['price'] ?? 0).toDouble(),
              quantity: (d['quantity'] ?? 1) as int,
            );
          })
          .toList();

      DateTime orderDate;
      if (data['orderDate'] != null && data['orderDate'] is Timestamp) {
        orderDate = (data['orderDate'] as Timestamp).toDate();
      } else if (data['createdAt'] != null && data['createdAt'] is Timestamp) {
        orderDate = (data['createdAt'] as Timestamp).toDate();
      } else {
        orderDate = DateTime.now();
      }

      return app_models.Order(
        id: data['id']?.toString() ?? doc.id,
        userId: data['userId'] ?? data['userUID'] ?? '',
        items: items,
        totalAmount: (data['totalAmount'] ?? data['total'] ?? 0).toDouble(),
        status: data['status'] ?? 'Đang xử lý',
        orderDate: orderDate,
        shippingAddress: data['shippingAddress'] ?? data['address'] ?? '',
        paymentMethod: data['paymentMethod'] ?? data['payment'] ?? '',
      );
    }).toList();
  }

  /// Fetch users once for analytics summaries.
  static Future<List<app_models.User>> fetchUsersOnce({int limit = 200}) async {
    final query = await _firestore
        .collection('users')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();
    return query.docs.map((doc) {
      final Map<String, dynamic> data = Map<String, dynamic>.from(
        doc.data() as Map,
      );
      return app_models.User(
        id: doc.id,
        fullName: data['fullName'] ?? data['name'] ?? '',
        email: data['email'] ?? '',
        phone: data['phone'] ?? '',
        username:
            data['username'] ??
            (data['email'] is String
                ? (data['email'] as String).split('@').first
                : ''),
        joinDate: data['createdAt'] != null && data['createdAt'] is Timestamp
            ? (data['createdAt'] as Timestamp).toDate()
            : DateTime.now(),
        isActive: data['isActive'] ?? true,
        totalOrders: data['totalOrders'] ?? 0,
        totalSpent: (data['totalSpent'] ?? 0).toDouble(),
      );
    }).toList();
  }

  /// Ensure some minimal admin metadata exists so admin can detect initialization.
  ///
  /// This does NOT create fake user or order documents. It only writes a small
  /// document under `meta/admin_init` to mark that admin views were initialized.
  static Future<void> ensureAdminInitialized() async {
    final docRef = _firestore.collection('meta').doc('admin_init');
    final snap = await docRef.get();
    if (!snap.exists) {
      await docRef.set({
        'initializedAt': FieldValue.serverTimestamp(),
        'by': 'admin_ui',
      });
    }
  }

  /// Update an order's status in Firestore and notify the customer.
  static Future<void> updateOrderStatus(String orderId, String status) async {
    final docRef = _firestore.collection('orders').doc(orderId);
    final snapshot = await docRef.get();

    if (!snapshot.exists) {
      throw StateError('Không tìm thấy đơn hàng với mã $orderId');
    }

    final data = Map<String, dynamic>.from(snapshot.data() as Map);
    final String previousStatus = (data['status'] ?? '').toString();
    final String userId = (data['userId'] ?? data['userUID'] ?? '').toString();

    if (previousStatus == status) {
      // Vẫn cập nhật mốc thời gian để admin biết lần thao tác mới nhất.
      await docRef.update({'updatedAt': FieldValue.serverTimestamp()});
      return;
    }

    await docRef.update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (userId.isEmpty) {
      return;
    }

    final _StatusNotificationMessage message = _buildStatusNotificationMessage(
      orderId,
      status,
    );

    try {
      await NotificationService.createUserNotification(
        userId: userId,
        title: message.title,
        body: message.body,
        category: app_models.NotificationCategory.order,
        extra: {
          'orderId': orderId,
          'status': status,
          'previousStatus': previousStatus,
        },
      );
    } catch (_) {
      // Không để lỗi thông báo làm thất bại cập nhật trạng thái.
    }
  }

  /// Update a user's active status
  static Future<void> updateUserStatus(String userId, bool isActive) async {
    await _firestore.collection('users').doc(userId).update({
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Add a new user document (note: does not create Firebase Auth user)
  static Future<void> addUser(Map<String, dynamic> userData) async {
    final data = Map<String, dynamic>.from(userData);
    data['createdAt'] = FieldValue.serverTimestamp();
    await _firestore.collection('users').add(data);
  }

  /// Update user document
  static Future<void> updateUser(
    String userId,
    Map<String, dynamic> userData, {
    String? newPassword,
  }) async {
    final data = Map<String, dynamic>.from(userData);
    data['updatedAt'] = FieldValue.serverTimestamp();
    if (newPassword != null && newPassword.isNotEmpty) {
      data['password'] = newPassword;
      data['passwordUpdatedAt'] = FieldValue.serverTimestamp();
      data['passwordUpdatedBy'] = 'admin';
    }
    await _firestore.collection('users').doc(userId).update(data);
  }

  /// Delete a user document in Firestore (does not remove Firebase Auth user)
  static Future<void> deleteUser(String userId) async {
    await _firestore.collection('users').doc(userId).delete();
  }

  /// Fetch all orders for a specific user (one-off query)
  static Future<List<app_models.Order>> getOrdersForUser(String userId) async {
    final res = await _firestore
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .orderBy('orderDate', descending: true)
        .get();

    return res.docs.map((doc) {
      final Map<String, dynamic> data = Map<String, dynamic>.from(
        doc.data() as Map,
      );

      final List<app_models.OrderItem> items = (data['items'] as List? ?? [])
          .map((raw) {
            final Map<String, dynamic> d = Map<String, dynamic>.from(
              raw as Map,
            );
            return app_models.OrderItem(
              productId: d['productId'] ?? '',
              productName: d['productName'] ?? d['name'] ?? '',
              productImage: d['productImage'] ?? '',
              price: (d['price'] ?? 0).toDouble(),
              quantity: (d['quantity'] ?? 1) as int,
            );
          })
          .toList();

      DateTime orderDate;
      if (data['orderDate'] != null && data['orderDate'] is Timestamp) {
        orderDate = (data['orderDate'] as Timestamp).toDate();
      } else if (data['createdAt'] != null && data['createdAt'] is Timestamp) {
        orderDate = (data['createdAt'] as Timestamp).toDate();
      } else {
        orderDate = DateTime.now();
      }

      return app_models.Order(
        id: doc.id,
        userId: data['userId'] ?? data['userUID'] ?? '',
        items: items,
        totalAmount: (data['totalAmount'] ?? data['total'] ?? 0).toDouble(),
        status: data['status'] ?? 'Đang xử lý',
        orderDate: orderDate,
        shippingAddress: data['shippingAddress'] ?? data['address'] ?? '',
        paymentMethod: data['paymentMethod'] ?? data['payment'] ?? '',
      );
    }).toList();
  }
}

_StatusNotificationMessage _buildStatusNotificationMessage(
  String orderId,
  String rawStatus,
) {
  final normalized = rawStatus.trim().toLowerCase();

  if (normalized.contains('đang xử lý')) {
    return _StatusNotificationMessage(
      title: 'Đơn hàng #$orderId đang được xử lý',
      body:
          'Đơn hàng của bạn đang được chúng tôi chuẩn bị và sẽ sớm bàn giao cho đơn vị vận chuyển.',
    );
  }

  if (normalized.contains('đã giao') || normalized.contains('hoàn tất')) {
    return _StatusNotificationMessage(
      title: 'Đơn hàng #$orderId đã giao thành công',
      body:
          'Đơn hàng đã được giao đến bạn. Cảm ơn bạn đã mua sắm tại cửa hàng, chúc bạn có trải nghiệm tuyệt vời!',
    );
  }

  if (normalized.contains('hủy') || normalized.contains('huỷ')) {
    return _StatusNotificationMessage(
      title: 'Đơn hàng #$orderId đã được hủy',
      body:
          'Đơn hàng đã được hủy theo yêu cầu hoặc do sự cố xử lý. Nếu cần hỗ trợ thêm, vui lòng liên hệ với chúng tôi.',
    );
  }

  return _StatusNotificationMessage(
    title: 'Đơn hàng #$orderId được cập nhật',
    body: 'Đơn hàng của bạn vừa có cập nhật trạng thái: $rawStatus.',
  );
}

class _StatusNotificationMessage {
  const _StatusNotificationMessage({required this.title, required this.body});

  final String title;
  final String body;
}
