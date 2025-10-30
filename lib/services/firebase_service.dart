import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user
  static User? get currentUser => _auth.currentUser;

  // Authentication methods
  static Future<UserCredential?> signUpWithEmail(String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result;
    } catch (e) {
      print('Error signing up: $e');
      return null;
    }
  }

  static Future<UserCredential?> signInWithEmail(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result;
    } catch (e) {
      print('Error signing in: $e');
      return null;
    }
  }

  static Future<void> signOut() async {
    await _auth.signOut();
  }

  // Firestore methods
  static Future<void> addDocument(String collection, Map<String, dynamic> data) async {
    try {
      await _firestore.collection(collection).add(data);
      print('Document added successfully');
    } catch (e) {
      print('Error adding document: $e');
    }
  }

  static Future<void> updateDocument(String collection, String docId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection(collection).doc(docId).update(data);
      print('Document updated successfully');
    } catch (e) {
      print('Error updating document: $e');
    }
  }

  static Future<void> deleteDocument(String collection, String docId) async {
    try {
      await _firestore.collection(collection).doc(docId).delete();
      print('Document deleted successfully');
    } catch (e) {
      print('Error deleting document: $e');
    }
  }

  static Future<DocumentSnapshot?> getDocument(String collection, String docId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection(collection).doc(docId).get();
      return doc;
    } catch (e) {
      print('Error getting document: $e');
      return null;
    }
  }

  static Stream<QuerySnapshot> getCollectionStream(String collection) {
    return _firestore.collection(collection).snapshots();
  }

  static Future<QuerySnapshot?> getCollection(String collection) async {
    try {
      QuerySnapshot snapshot = await _firestore.collection(collection).get();
      return snapshot;
    } catch (e) {
      print('Error getting collection: $e');
      return null;
    }
  }

  // Specific methods for your app
  static Future<void> addUser(Map<String, dynamic> userData) async {
    if (currentUser != null) {
      await addDocument('users', {
        'uid': currentUser!.uid,
        'email': currentUser!.email,
        ...userData,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  static Future<void> updateUserProfile(Map<String, dynamic> userData) async {
    if (currentUser != null) {
      await updateDocument('users', currentUser!.uid, {
        ...userData,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  static Stream<DocumentSnapshot> getUserProfile() {
    if (currentUser != null) {
      return _firestore.collection('users').doc(currentUser!.uid).snapshots();
    }
    throw Exception('User not authenticated');
  }

  // Test connection
  static Future<bool> testConnection() async {
    try {
      await _firestore.collection('test').doc('connection').set({
        'timestamp': FieldValue.serverTimestamp(),
        'message': 'Connection test successful',
      });
      print('Firebase connection test successful');
      return true;
    } catch (e) {
      print('Firebase connection test failed: $e');
      return false;
    }
  }
}
