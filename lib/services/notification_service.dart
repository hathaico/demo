import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';
import 'firebase_auth_service.dart';

class NotificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _readCacheKey = 'notification_read_ids';

  static String get readCacheKey => _readCacheKey;

  static Stream<List<StoreNotification>> watchNotifications({String? userId}) {
    final controller = StreamController<List<StoreNotification>>.broadcast();
    final String? uid = userId ?? FirebaseAuthService.currentUser?.uid;
    List<StoreNotification> personal = const [];
    List<StoreNotification> broadcast = const [];

    Future<void> emit() async {
      if (controller.isClosed) return;
      final readIds = await _getReadIds();
      final combined =
          <StoreNotification>[...personal, ...broadcast]
              .map(
                (n) => n.copyWith(isRead: n.isRead || readIds.contains(n.id)),
              )
              .toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      controller.add(combined);
    }

    final personalSubscription = _watchPersonal(uid).listen((data) {
      personal = data;
      unawaited(emit());
    }, onError: controller.addError);

    final broadcastSubscription = _watchBroadcast().listen((data) {
      broadcast = data;
      unawaited(emit());
    }, onError: controller.addError);

    controller.onListen = () {
      unawaited(emit());
    };

    controller.onCancel = () async {
      await personalSubscription.cancel();
      await broadcastSubscription.cancel();
    };

    return controller.stream;
  }

  static Stream<List<StoreNotification>> _watchPersonal(String? userId) {
    if (userId == null) {
      return Stream.value(const <StoreNotification>[]);
    }

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = Map<String, dynamic>.from(doc.data());
            data['isGlobal'] = false;
            return StoreNotification.fromMap(doc.id, data);
          }).toList();
        });
  }

  static Stream<List<StoreNotification>> _watchBroadcast() {
    return _firestore
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = Map<String, dynamic>.from(doc.data());
            data['isGlobal'] = true;
            return StoreNotification.fromMap(doc.id, data);
          }).toList();
        })
        .handleError((_) => const <StoreNotification>[]);
  }

  static Future<void> markNotificationAsRead(
    StoreNotification notification, {
    String? userId,
  }) async {
    await _markLocal(notification.id);
    if (notification.isSample) return;

    final String? uid = userId ?? FirebaseAuthService.currentUser?.uid;
    if (uid == null) return;

    if (!notification.isGlobal) {
      try {
        await _firestore
            .collection('users')
            .doc(uid)
            .collection('notifications')
            .doc(notification.id)
            .update({'isRead': true, 'readAt': FieldValue.serverTimestamp()});
      } catch (_) {}
    }
  }

  static Future<void> markAllAsRead(
    List<StoreNotification> notifications, {
    String? userId,
  }) async {
    if (notifications.isEmpty) return;
    final futures = <Future<void>>[];
    for (final notification in notifications) {
      if (notification.isRead && !notification.isSample) {
        futures.add(_markLocal(notification.id));
        continue;
      }
      futures.add(markNotificationAsRead(notification, userId: userId));
    }
    await Future.wait(futures, eagerError: false);
  }

  static Future<int> getUnreadCount({String? userId}) async {
    final String? uid = userId ?? FirebaseAuthService.currentUser?.uid;
    final readIds = await _getReadIds();
    int count = 0;

    if (uid != null) {
      final personalSnapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .get();
      count += personalSnapshot.docs.where((doc) {
        return !readIds.contains(doc.id);
      }).length;
    }

    final broadcastSnapshot = await _firestore
        .collection('notifications')
        .where('isGlobal', isEqualTo: true)
        .get();
    count += broadcastSnapshot.docs.where((doc) {
      return !readIds.contains(doc.id);
    }).length;

    return count;
  }

  static Future<Set<String>> _getReadIds() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(_readCacheKey) ?? <String>[];
    return stored.toSet();
  }

  static Future<void> _markLocal(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(_readCacheKey) ?? <String>[];
    if (stored.contains(id)) return;
    stored.add(id);
    await prefs.setStringList(_readCacheKey, stored);
  }

  static Future<String> createBroadcastNotification({
    required String title,
    required String body,
    NotificationCategory category = NotificationCategory.system,
    Map<String, dynamic>? extra,
  }) async {
    final payload = {
      'title': title,
      'body': body,
      'category': StoreNotification.categoryToString(category),
      'createdAt': FieldValue.serverTimestamp(),
      'isGlobal': true,
      'isRead': false,
      if (extra != null) ...extra,
    };

    final docRef = await _firestore.collection('notifications').add(payload);
    return docRef.id;
  }

  static Future<String?> createUserNotification({
    required String userId,
    required String title,
    required String body,
    NotificationCategory category = NotificationCategory.order,
    Map<String, dynamic>? extra,
  }) async {
    if (userId.isEmpty) return null;

    final payload = {
      'title': title,
      'body': body,
      'category': StoreNotification.categoryToString(category),
      'createdAt': FieldValue.serverTimestamp(),
      'isGlobal': false,
      'isRead': false,
      if (extra != null) ...extra,
    };

    final docRef = await _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .add(payload);
    return docRef.id;
  }

  static Future<List<StoreNotification>> fetchLatest({
    String? userId,
    int limit = 20,
  }) async {
    final uid = userId ?? FirebaseAuthService.currentUser?.uid;
    final readIds = await _getReadIds();
    final List<StoreNotification> items = [];

    if (uid != null) {
      final personalSnapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('notifications')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      for (final doc in personalSnapshot.docs) {
        final data = Map<String, dynamic>.from(doc.data());
        data['isGlobal'] = false;
        final notification = StoreNotification.fromMap(
          doc.id,
          data,
        ).copyWith(isRead: data['isRead'] == true || readIds.contains(doc.id));
        items.add(notification);
      }
    }

    final broadcastSnapshot = await _firestore
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();
    for (final doc in broadcastSnapshot.docs) {
      final data = Map<String, dynamic>.from(doc.data());
      data['isGlobal'] = true;
      final notification = StoreNotification.fromMap(
        doc.id,
        data,
      ).copyWith(isRead: data['isRead'] == true || readIds.contains(doc.id));
      items.add(notification);
    }

    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items.take(limit).toList();
  }
}
