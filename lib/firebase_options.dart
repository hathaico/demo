// File cấu hình Firebase cho Flutter
// Được tạo tự động từ Firebase Console

import 'package:firebase_core/firebase_core.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    // Android configuration
    return const FirebaseOptions(
      apiKey: 'AIzaSyC3j5wqNx-8dekegnWvFNiWNA4GsSX_KIQ',
      appId: '1:1007482621957:android:62db08c470815085048c6c',
      messagingSenderId: '1007482621957',
      projectId: 'appbannon',
      storageBucket: 'appbannon.firebasestorage.app',
      authDomain: 'appbannon.firebaseapp.com',
      databaseURL: 'https://appbannon-default-rtdb.firebaseio.com',
    );
  }
}
