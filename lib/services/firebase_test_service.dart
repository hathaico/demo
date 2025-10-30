import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseTestService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Test Firebase connection
  static Future<Map<String, dynamic>> testFirebaseConnection() async {
    try {
      // Test Firestore
      await _firestore.collection('test').doc('connection').set({
        'timestamp': FieldValue.serverTimestamp(),
        'message': 'Firebase connection test successful',
      });

      await _firestore.collection('test').doc('connection').get();

      return {
        'success': true,
        'message': 'Firebase kết nối thành công!',
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {'success': false, 'error': 'Lỗi kết nối Firebase: $e'};
    }
  }

  // Test User collection
  static Future<Map<String, dynamic>> testUsersCollection() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .limit(5)
          .get();

      return {
        'success': true,
        'count': snapshot.docs.length,
        'users': snapshot.docs.map((doc) {
          final Map<String, dynamic> data = Map<String, dynamic>.from(
            doc.data() as Map,
          );
          return {
            'id': doc.id,
            'email': data['email'],
            'fullName': data['fullName'],
            'username': data['username'],
          };
        }).toList(),
      };
    } catch (e) {
      return {'success': false, 'error': 'Lỗi đọc users: $e'};
    }
  }

  // Test Products collection
  static Future<Map<String, dynamic>> testProductsCollection() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('products')
          .limit(5)
          .get();

      return {
        'success': true,
        'count': snapshot.docs.length,
        'products': snapshot.docs.map((doc) {
          final Map<String, dynamic> data = Map<String, dynamic>.from(
            doc.data() as Map,
          );
          return {
            'id': doc.id,
            'name': data['name'],
            'brand': data['brand'],
            'price': data['price'],
          };
        }).toList(),
      };
    } catch (e) {
      return {'success': false, 'error': 'Lỗi đọc products: $e'};
    }
  }

  // Test Orders collection
  static Future<Map<String, dynamic>> testOrdersCollection() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('orders')
          .limit(5)
          .get();

      return {'success': true, 'count': snapshot.docs.length};
    } catch (e) {
      return {'success': false, 'error': 'Lỗi đọc orders: $e'};
    }
  }

  // Test Authentication
  static Future<Map<String, dynamic>> testAuthentication() async {
    try {
      User? user = _auth.currentUser;

      return {
        'success': true,
        'isAuthenticated': user != null,
        'userId': user?.uid,
        'email': user?.email,
      };
    } catch (e) {
      return {'success': false, 'error': 'Lỗi authentication: $e'};
    }
  }

  // Full test
  static Future<Map<String, dynamic>> runFullTest() async {
    Map<String, dynamic> results = {
      'connection': await testFirebaseConnection(),
      'authentication': await testAuthentication(),
      'users': await testUsersCollection(),
      'products': await testProductsCollection(),
      'orders': await testOrdersCollection(),
    };

    return results;
  }
}
