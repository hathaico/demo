import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart' as app_models;

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

  /// Update an order's status in Firestore.
  static Future<void> updateOrderStatus(String orderId, String status) async {
    await _firestore.collection('orders').doc(orderId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
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
    Map<String, dynamic> userData,
  ) async {
    final data = Map<String, dynamic>.from(userData);
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _firestore.collection('users').doc(userId).update(data);
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
