import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';
import '../models/models.dart';
import 'firebase_auth_service.dart';

class FirebaseUserService {
  // Truy cập FirebaseFirestore động (lấy instance hiện tại).
  static FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  static const String _collection = 'users';
  // Simple in-memory cache to reduce repeated network lookups for the same user.
  // This cache lives only for the app process lifetime. Use `getUserById(..., forceRefresh: true)`
  // to bypass the cache when needed.
  static final Map<String, User> _userCache = {};

  /// Khởi tạo Firebase nếu chưa khởi tạo và (tuỳ chọn) kết nối đến Firestore emulator.
  ///
  /// Gọi `await FirebaseUserService.initialize()` trong `main()` (sau
  /// `WidgetsFlutterBinding.ensureInitialized()`). Nếu bạn muốn dùng emulator,
  /// truyền `useEmulator: true` và host/port tương ứng.
  static Future<bool> initialize({
    bool useEmulator = false,
    String host = 'localhost',
    int port = 8080,
  }) async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }

      if (useEmulator) {
        try {
          // Kết nối Firestore đến emulator
          FirebaseFirestore.instance.useFirestoreEmulator(host, port);
          // Tắt persistence trên emulator để tránh một số lỗi
          FirebaseFirestore.instance.settings = const Settings(
            persistenceEnabled: false,
          );
        } catch (e) {
          // Một số phiên bản cloud_firestore có API khác, nên ghi log và tiếp tục
          print('Could not enable Firestore emulator: $e');
        }
      }

      return true;
    } catch (e) {
      print('FirebaseUserService.initialize error: $e');
      return false;
    }
  }

  // Lấy thông tin người dùng theo ID
  static Future<User?> getUserById(
    String userId, {
    bool forceRefresh = false,
  }) async {
    try {
      if (!forceRefresh && _userCache.containsKey(userId)) {
        return _userCache[userId];
      }

      DocumentSnapshot doc = await _firestore
          .collection(_collection)
          .doc(userId)
          .get();

      if (doc.exists) {
        final Map<String, dynamic> data = Map<String, dynamic>.from(
          doc.data() as Map,
        );
        final user = _mapToUser(userId, data);
        _userCache[userId] = user;
        return user;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Lấy thông tin người dùng hiện tại
  static Future<User?> getCurrentUser() async {
    String? userId = FirebaseAuthService.currentUser?.uid;
    if (userId == null) return null;
    return getUserById(userId);
  }

  // Stream thông tin người dùng hiện tại
  static Stream<User?> getCurrentUserStream() {
    String? userId = FirebaseAuthService.currentUser?.uid;
    if (userId == null) {
      return Stream.value(null);
    }

    return _firestore.collection(_collection).doc(userId).snapshots().map((
      doc,
    ) {
      if (doc.exists) {
        final Map<String, dynamic> data = Map<String, dynamic>.from(
          doc.data() as Map,
        );
        return _mapToUser(userId, data);
      }
      return null;
    });
  }

  // Lấy tất cả người dùng (cho admin)
  static Future<List<User>> getAllUsers() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection(_collection).get();

      return snapshot.docs.map((doc) {
        final Map<String, dynamic> data = Map<String, dynamic>.from(
          doc.data() as Map,
        );
        return _mapToUser(doc.id, data);
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // Paginated fetch for users to avoid loading entire collections into memory.
  // Returns a map with 'users' -> List<User> and 'lastDoc' -> DocumentSnapshot? (useful for next page)
  static Future<Map<String, dynamic>> getUsersPage({
    int limit = 20,
    DocumentSnapshot? startAfterDoc,
    String orderByField = 'createdAt',
    bool descending = true,
  }) async {
    try {
      Query query = _firestore
          .collection(_collection)
          .orderBy(orderByField, descending: descending)
          .limit(limit);
      if (startAfterDoc != null) {
        query = query.startAfterDocument(startAfterDoc);
      }

      QuerySnapshot snapshot = await query.get();

      List<User> users = snapshot.docs.map((doc) {
        final Map<String, dynamic> data = Map<String, dynamic>.from(
          doc.data() as Map,
        );
        return _mapToUser(doc.id, data);
      }).toList();

      DocumentSnapshot? lastDoc = snapshot.docs.isNotEmpty
          ? snapshot.docs.last
          : null;

      return {'users': users, 'lastDoc': lastDoc};
    } catch (e) {
      return {'users': <User>[], 'lastDoc': null};
    }
  }

  // Stream tất cả người dùng (cho admin)
  static Stream<List<User>> getAllUsersStream() {
    return _firestore.collection(_collection).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final Map<String, dynamic> data = Map<String, dynamic>.from(
          doc.data() as Map,
        );
        return _mapToUser(doc.id, data);
      }).toList();
    });
  }

  // Lấy người dùng theo vai trò
  static Future<List<User>> getUsersByRole(String role) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(_collection)
          .where('role', isEqualTo: role)
          .get();

      return snapshot.docs.map((doc) {
        final Map<String, dynamic> data = Map<String, dynamic>.from(
          doc.data() as Map,
        );
        return _mapToUser(doc.id, data);
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // Stream người dùng theo vai trò
  static Stream<List<User>> getUsersByRoleStream(String role) {
    return _firestore
        .collection(_collection)
        .where('role', isEqualTo: role)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final Map<String, dynamic> data = Map<String, dynamic>.from(
              doc.data() as Map,
            );
            return _mapToUser(doc.id, data);
          }).toList();
        });
  }

  // Cập nhật thông tin người dùng
  static Future<Map<String, dynamic>> updateUserProfile({
    String? fullName,
    String? phone,
    String? username,
  }) async {
    try {
      String? userId = FirebaseAuthService.currentUser?.uid;
      if (userId == null) {
        return {'success': false, 'error': 'Người dùng chưa đăng nhập'};
      }

      Map<String, dynamic> updateData = {
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (fullName != null) updateData['fullName'] = fullName;
      if (phone != null) updateData['phone'] = phone;
      if (username != null) {
        // Kiểm tra username đã tồn tại chưa
        if (await FirebaseAuthService.isUsernameExists(username)) {
          return {'success': false, 'error': 'Tên đăng nhập đã được sử dụng'};
        }
        updateData['username'] = username;
      }

      await _firestore.collection(_collection).doc(userId).update(updateData);

      // Invalidate cache for updated user so next read fetches fresh data
      _userCache.remove(userId);

      return {'success': true, 'message': 'Cập nhật thông tin thành công'};
    } catch (e) {
      return {'success': false, 'error': 'Lỗi cập nhật thông tin: $e'};
    }
  }

  // Cập nhật trạng thái người dùng (cho admin)
  static Future<Map<String, dynamic>> updateUserStatus(
    String userId,
    bool isActive,
  ) async {
    try {
      await _firestore.collection(_collection).doc(userId).update({
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Invalidate cache when user status changes
      _userCache.remove(userId);

      return {
        'success': true,
        'message': 'Cập nhật trạng thái người dùng thành công',
      };
    } catch (e) {
      return {'success': false, 'error': 'Lỗi cập nhật trạng thái: $e'};
    }
  }

  // Cập nhật vai trò người dùng (cho admin)
  static Future<Map<String, dynamic>> updateUserRole(
    String userId,
    String role,
  ) async {
    try {
      await _firestore.collection(_collection).doc(userId).update({
        'role': role,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Invalidate cache when role changes
      _userCache.remove(userId);

      return {'success': true, 'message': 'Cập nhật vai trò thành công'};
    } catch (e) {
      return {'success': false, 'error': 'Lỗi cập nhật vai trò: $e'};
    }
  }

  // Xóa người dùng (cho admin)
  static Future<Map<String, dynamic>> deleteUser(String userId) async {
    try {
      await _firestore.collection(_collection).doc(userId).delete();

      // Remove from cache
      _userCache.remove(userId);

      return {'success': true, 'message': 'Xóa người dùng thành công'};
    } catch (e) {
      return {'success': false, 'error': 'Lỗi xóa người dùng: $e'};
    }
  }

  // Tìm kiếm người dùng
  static Future<List<User>> searchUsers(String query) async {
    try {
      // Avoid loading entire collection when searching: fetch a limited page and filter locally.
      // This is a safer default; for large collections consider adding dedicated indexed
      // lowercase fields (e.g., `username_lower`) and query on them.
      const int pageLimit = 100;
      QuerySnapshot snapshot = await _firestore
          .collection(_collection)
          .limit(pageLimit)
          .get();

      List<User> users = snapshot.docs.map((doc) {
        final Map<String, dynamic> data = Map<String, dynamic>.from(
          doc.data() as Map,
        );
        return _mapToUser(doc.id, data);
      }).toList();

      // Filter locally (Firestore doesn't support case-insensitive search)
      return users.where((user) {
        return user.fullName.toLowerCase().contains(query.toLowerCase()) ||
            user.email.toLowerCase().contains(query.toLowerCase()) ||
            user.username.toLowerCase().contains(query.toLowerCase()) ||
            user.phone.contains(query);
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // Lấy thống kê người dùng
  static Future<Map<String, dynamic>> getUserStats() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection(_collection).get();

      int totalUsers = snapshot.docs.length;
      int activeUsers = 0;
      int adminUsers = 0;
      int regularUsers = 0;
      double totalSpent = 0;
      int totalOrders = 0;

      for (var doc in snapshot.docs) {
        final Map<String, dynamic> data = Map<String, dynamic>.from(
          doc.data() as Map,
        );

        if (data['isActive'] == true) activeUsers++;
        if (data['role'] == 'admin') adminUsers++;
        if (data['role'] == 'user') regularUsers++;

        totalSpent += (data['totalSpent'] ?? 0).toDouble();
        totalOrders += (data['totalOrders'] as int? ?? 0);
      }

      return {
        'totalUsers': totalUsers,
        'activeUsers': activeUsers,
        'inactiveUsers': totalUsers - activeUsers,
        'adminUsers': adminUsers,
        'regularUsers': regularUsers,
        'totalSpent': totalSpent,
        'totalOrders': totalOrders,
        'averageSpent': totalUsers > 0 ? totalSpent / totalUsers : 0,
        'averageOrders': totalUsers > 0 ? totalOrders / totalUsers : 0,
      };
    } catch (e) {
      return {
        'totalUsers': 0,
        'activeUsers': 0,
        'inactiveUsers': 0,
        'adminUsers': 0,
        'regularUsers': 0,
        'totalSpent': 0,
        'totalOrders': 0,
        'averageSpent': 0,
        'averageOrders': 0,
      };
    }
  }

  // Lấy thống kê người dùng mới theo ngày
  static Future<List<Map<String, dynamic>>> getNewUsersStats(int days) async {
    try {
      DateTime endDate = DateTime.now();
      DateTime startDate = endDate.subtract(Duration(days: days));

      QuerySnapshot snapshot = await _firestore
          .collection(_collection)
          .where(
            'joinDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
          )
          .where('joinDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      Map<String, int> dailyStats = {};

      for (var doc in snapshot.docs) {
        final Map<String, dynamic> data = Map<String, dynamic>.from(
          doc.data() as Map,
        );
        Timestamp joinDate = data['joinDate'] as Timestamp? ?? Timestamp.now();
        String dateKey = joinDate.toDate().toIso8601String().split('T')[0];

        dailyStats[dateKey] = (dailyStats[dateKey] ?? 0) + 1;
      }

      List<Map<String, dynamic>> result = [];
      for (int i = 0; i < days; i++) {
        DateTime date = endDate.subtract(Duration(days: i));
        String dateKey = date.toIso8601String().split('T')[0];

        result.add({'date': dateKey, 'newUsers': dailyStats[dateKey] ?? 0});
      }

      return result.reversed.toList();
    } catch (e) {
      return [];
    }
  }

  // Lấy top người dùng chi tiêu nhiều nhất
  static Future<List<User>> getTopSpendingUsers({int limit = 10}) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(_collection)
          .orderBy('totalSpent', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        final Map<String, dynamic> data = Map<String, dynamic>.from(
          doc.data() as Map,
        );
        return _mapToUser(doc.id, data);
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // Lấy top người dùng đặt hàng nhiều nhất
  static Future<List<User>> getTopOrderingUsers({int limit = 10}) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(_collection)
          .orderBy('totalOrders', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        final Map<String, dynamic> data = Map<String, dynamic>.from(
          doc.data() as Map,
        );
        return _mapToUser(doc.id, data);
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // Khởi tạo dữ liệu mẫu người dùng
  static Future<void> initializeSampleUsers() async {
    try {
      // Kiểm tra xem đã có dữ liệu chưa
      QuerySnapshot snapshot = await _firestore
          .collection(_collection)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return; // Đã có dữ liệu
      }

      // Tạo một số người dùng mẫu
      List<Map<String, dynamic>> sampleUsers = [
        {
          'email': 'admin@hatstyle.com',
          'fullName': 'System Administrator',
          'phone': '0000000000',
          'username': 'admin',
          'role': 'admin',
          'isActive': true,
          'totalOrders': 0,
          'totalSpent': 0.0,
          'joinDate': Timestamp.fromDate(
            DateTime.now().subtract(const Duration(days: 365)),
          ),
        },
        {
          'email': 'manager@hatstyle.com',
          'fullName': 'Manager User',
          'phone': '0000000001',
          'username': 'manager',
          'role': 'admin',
          'isActive': true,
          'totalOrders': 0,
          'totalSpent': 0.0,
          'joinDate': Timestamp.fromDate(
            DateTime.now().subtract(const Duration(days: 300)),
          ),
        },
        {
          'email': 'user@demo.com',
          'fullName': 'Nguyễn Văn Demo',
          'phone': '0901234567',
          'username': 'demo_user',
          'role': 'user',
          'isActive': true,
          'totalOrders': 5,
          'totalSpent': 1200000,
          'joinDate': Timestamp.fromDate(
            DateTime.now().subtract(const Duration(days: 30)),
          ),
        },
        {
          'email': 'customer@hatstyle.com',
          'fullName': 'Trần Thị Customer',
          'phone': '0912345678',
          'username': 'customer',
          'role': 'user',
          'isActive': true,
          'totalOrders': 3,
          'totalSpent': 800000,
          'joinDate': Timestamp.fromDate(
            DateTime.now().subtract(const Duration(days: 15)),
          ),
        },
      ];

      // Thêm từng người dùng vào Firestore
      for (var userData in sampleUsers) {
        await _firestore.collection(_collection).add({
          ...userData,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error initializing sample users: $e');
    }
  }

  // Lấy danh sách địa chỉ của người dùng hiện tại (mảng object trong doc user)
  static Future<List<Address>> getCurrentUserAddresses() async {
    try {
      String? userId = FirebaseAuthService.currentUser?.uid;
      if (userId == null) return [];

      final doc = await _firestore.collection(_collection).doc(userId).get();
      if (!doc.exists) return [];
      final data = Map<String, dynamic>.from(doc.data() as Map);
      final List<dynamic>? addrs = data['addresses'] as List<dynamic>?;
      if (addrs == null) return [];
      return addrs.map((e) {
        if (e is Map) {
          return Address.fromMap(Map<String, dynamic>.from(e));
        }
        return Address.fromMap({'id': e.toString(), 'street': e.toString()});
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // Lưu danh sách địa chỉ của người dùng hiện tại (ghi đè)
  static Future<Map<String, dynamic>> saveCurrentUserAddresses(
    List<Address> addresses,
  ) async {
    try {
      String? userId = FirebaseAuthService.currentUser?.uid;
      if (userId == null) {
        return {'success': false, 'error': 'Người dùng chưa đăng nhập'};
      }

      await _firestore.collection(_collection).doc(userId).update({
        'addresses': addresses.map((a) => a.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Invalidate cache
      _userCache.remove(userId);

      return {'success': true, 'message': 'Đã cập nhật địa chỉ'};
    } catch (e) {
      return {'success': false, 'error': 'Lỗi lưu địa chỉ: $e'};
    }
  }

  // Helper method để chuyển đổi từ Firestore data sang User
  static User _mapToUser(String id, Map<String, dynamic> data) {
    Timestamp joinDate = data['joinDate'] as Timestamp? ?? Timestamp.now();

    return User(
      id: id,
      fullName: data['fullName'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      username: data['username'] ?? '',
      joinDate: joinDate.toDate(),
      isActive: data['isActive'] ?? true,
      totalOrders: data['totalOrders'] ?? 0,
      totalSpent: (data['totalSpent'] ?? 0).toDouble(),
    );
  }
}
