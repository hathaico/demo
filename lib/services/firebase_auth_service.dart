import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class FirebaseAuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);

  // Get current user
  static User? get currentUser => _auth.currentUser;

  // Stream để theo dõi trạng thái đăng nhập
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Đăng ký tài khoản mới
  static Future<Map<String, dynamic>?> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String username,
  }) async {
    try {
      // Kiểm tra email đã tồn tại chưa
      if (await isEmailExists(email)) {
        return {'success': false, 'error': 'Email đã được sử dụng'};
      }

      // Kiểm tra username đã tồn tại chưa
      if (await isUsernameExists(username)) {
        return {'success': false, 'error': 'Tên đăng nhập đã được sử dụng'};
      }

      // Tạo tài khoản Firebase Auth
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Lưu thông tin người dùng vào Firestore
      await _firestore.collection('users').doc(result.user!.uid).set({
        'email': email,
        'fullName': fullName,
        'phone': phone,
        'username': username,
        'role': 'user',
        'isActive': true,
        'totalOrders': 0,
        'totalSpent': 0.0,
        'joinDate': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return {
        'success': true,
        'user': result.user,
        'message': 'Đăng ký thành công!',
      };
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Có lỗi xảy ra';
      switch (e.code) {
        case 'weak-password':
          errorMessage = 'Mật khẩu quá yếu';
          break;
        case 'email-already-in-use':
          errorMessage = 'Email đã được sử dụng';
          break;
        case 'invalid-email':
          errorMessage = 'Email không hợp lệ';
          break;
        default:
          errorMessage = e.message ?? 'Có lỗi xảy ra';
      }
      return {'success': false, 'error': errorMessage};
    } catch (e) {
      return {'success': false, 'error': 'Có lỗi xảy ra: $e'};
    }
  }

  // Đăng nhập
  static Future<Map<String, dynamic>?> signIn({
    required String emailOrUsername,
    required String password,
  }) async {
    try {
      String email = emailOrUsername;

      // Nếu không phải email, tìm email từ username
      if (!emailOrUsername.contains('@')) {
        String? foundEmail = await findEmailByUsername(emailOrUsername);
        if (foundEmail == null) {
          return {'success': false, 'error': 'Tên đăng nhập không tồn tại'};
        }
        email = foundEmail;
      }

      // Đăng nhập với Firebase Auth
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Lấy thông tin người dùng từ Firestore
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(result.user!.uid)
          .get();

      if (!userDoc.exists) {
        await signOut();
        return {
          'success': false,
          'error': 'Thông tin người dùng không tồn tại',
        };
      }

      final Map<String, dynamic> userData = Map<String, dynamic>.from(
        userDoc.data() as Map,
      );

      // Kiểm tra tài khoản có bị khóa không
      if (userData['isActive'] == false) {
        await signOut();
        return {'success': false, 'error': 'Tài khoản đã bị khóa'};
      }

      return {
        'success': true,
        'user': result.user,
        'userData': userData,
        'message': 'Đăng nhập thành công!',
      };
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Có lỗi xảy ra';
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'Tài khoản không tồn tại';
          break;
        case 'wrong-password':
          errorMessage = 'Mật khẩu không đúng';
          break;
        case 'invalid-email':
          errorMessage = 'Email không hợp lệ';
          break;
        case 'user-disabled':
          errorMessage = 'Tài khoản đã bị khóa';
          break;
        default:
          errorMessage = e.message ?? 'Có lỗi xảy ra';
      }
      return {'success': false, 'error': errorMessage};
    } catch (e) {
      return {'success': false, 'error': 'Có lỗi xảy ra: $e'};
    }
  }

  // Đăng xuất
  static Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut().catchError((_) => null),
      FacebookAuth.instance.logOut().catchError((_) => null),
    ]);
  }

  // Kiểm tra email đã tồn tại chưa
  static Future<bool> isEmailExists(String email) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Kiểm tra username đã tồn tại chưa
  static Future<bool> isUsernameExists(String username) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Tìm email từ username
  static Future<String?> findEmailByUsername(String username) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final Map<String, dynamic> userData = Map<String, dynamic>.from(
          snapshot.docs.first.data() as Map,
        );
        return userData['email'] as String?;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Lấy thông tin người dùng hiện tại
  static Future<Map<String, dynamic>?> getCurrentUserData() async {
    if (currentUser == null) return null;

    try {
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .get();

      if (doc.exists) {
        return Map<String, dynamic>.from(doc.data() as Map);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Cập nhật thông tin người dùng
  static Future<bool> updateUserProfile(Map<String, dynamic> data) async {
    if (currentUser == null) return false;

    try {
      await _firestore.collection('users').doc(currentUser!.uid).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  // Đổi mật khẩu
  static Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (currentUser == null) {
      return {'success': false, 'error': 'Chưa đăng nhập'};
    }

    try {
      // Xác thực mật khẩu hiện tại
      AuthCredential credential = EmailAuthProvider.credential(
        email: currentUser!.email!,
        password: currentPassword,
      );

      await currentUser!.reauthenticateWithCredential(credential);

      // Đổi mật khẩu mới
      await currentUser!.updatePassword(newPassword);

      return {'success': true, 'message': 'Đổi mật khẩu thành công'};
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Có lỗi xảy ra';
      switch (e.code) {
        case 'wrong-password':
          errorMessage = 'Mật khẩu hiện tại không đúng';
          break;
        case 'weak-password':
          errorMessage = 'Mật khẩu mới quá yếu';
          break;
        default:
          errorMessage = e.message ?? 'Có lỗi xảy ra';
      }
      return {'success': false, 'error': errorMessage};
    } catch (e) {
      return {'success': false, 'error': 'Có lỗi xảy ra: $e'};
    }
  }

  // Gửi email reset mật khẩu
  static Future<Map<String, dynamic>> sendPasswordResetEmail(
    String email,
  ) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return {'success': true, 'message': 'Email reset mật khẩu đã được gửi'};
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Có lỗi xảy ra';
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'Email không tồn tại';
          break;
        case 'invalid-email':
          errorMessage = 'Email không hợp lệ';
          break;
        default:
          errorMessage = e.message ?? 'Có lỗi xảy ra';
      }
      return {'success': false, 'error': errorMessage};
    } catch (e) {
      return {'success': false, 'error': 'Có lỗi xảy ra: $e'};
    }
  }

  // Kiểm tra có phải admin không
  static Future<bool> isAdmin() async {
    Map<String, dynamic>? userData = await getCurrentUserData();
    return userData?['role'] == 'admin';
  }

  // Lấy stream thông tin người dùng
  static Stream<DocumentSnapshot> getUserStream() {
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }
    return _firestore.collection('users').doc(currentUser!.uid).snapshots();
  }

  static Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return {
          'success': false,
          'error': 'Người dùng đã hủy đăng nhập Google',
        };
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );
      final User? user = userCredential.user;

      if (user == null) {
        return {
          'success': false,
          'error': 'Không thể lấy thông tin người dùng Google',
        };
      }

      final Map<String, dynamic> userData = await _ensureUserDocument(
        user,
        fullName: user.displayName ?? googleUser.displayName,
        email: user.email ?? googleUser.email,
        providerId: userCredential.credential?.providerId,
      );

      return {
        'success': true,
        'user': user,
        'userData': userData,
        'isNewUser': userCredential.additionalUserInfo?.isNewUser ?? false,
      };
    } on FirebaseAuthException catch (e) {
      return {
        'success': false,
        'error': e.message ?? 'Không thể đăng nhập bằng Google',
      };
    } catch (e) {
      return {'success': false, 'error': 'Không thể đăng nhập bằng Google: $e'};
    }
  }

  static Future<Map<String, dynamic>> signInWithFacebook() async {
    try {
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
      );

      if (result.status != LoginStatus.success || result.accessToken == null) {
        return {
          'success': false,
          'error': result.message ?? 'Người dùng đã hủy đăng nhập Facebook',
        };
      }

      final OAuthCredential credential = FacebookAuthProvider.credential(
        result.accessToken!.token,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );
      final User? user = userCredential.user;

      if (user == null) {
        return {
          'success': false,
          'error': 'Không thể lấy thông tin người dùng Facebook',
        };
      }

      final Map<String, dynamic> facebookData = await FacebookAuth.instance
          .getUserData(fields: 'name,email');

      final Map<String, dynamic> userData = await _ensureUserDocument(
        user,
        fullName: facebookData['name'] as String? ?? user.displayName,
        email:
            (facebookData['email'] as String?) ??
            user.email ??
            '${user.uid}@facebook.com',
        providerId: userCredential.credential?.providerId,
      );

      return {
        'success': true,
        'user': user,
        'userData': userData,
        'isNewUser': userCredential.additionalUserInfo?.isNewUser ?? false,
      };
    } on FirebaseAuthException catch (e) {
      return {
        'success': false,
        'error': e.message ?? 'Không thể đăng nhập bằng Facebook',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Không thể đăng nhập bằng Facebook: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> _ensureUserDocument(
    User user, {
    String? fullName,
    String? email,
    String? phone,
    String? providerId,
  }) async {
    final DocumentReference<Map<String, dynamic>> docRef = _firestore
        .collection('users')
        .doc(user.uid);

    final DocumentSnapshot<Map<String, dynamic>> snapshot = await docRef.get();
    if (snapshot.exists && snapshot.data() != null) {
      return Map<String, dynamic>.from(snapshot.data()!);
    }

    final Map<String, dynamic> data = {
      'email': (email ?? user.email ?? '').trim(),
      'fullName': (fullName ?? user.displayName ?? 'Người dùng').trim(),
      'phone': (phone ?? user.phoneNumber ?? '').trim(),
      'username': user.email ?? user.uid,
      'role': 'user',
      'isActive': true,
      'totalOrders': 0,
      'totalSpent': 0.0,
      'joinDate': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'authProvider':
          providerId ??
          (user.providerData.isNotEmpty
              ? user.providerData.first.providerId
              : 'unknown'),
    };

    await docRef.set(data);
    final DocumentSnapshot<Map<String, dynamic>> refreshed = await docRef.get();
    if (refreshed.data() == null) {
      return data;
    }
    return Map<String, dynamic>.from(refreshed.data()!);
  }
}
