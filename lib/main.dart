import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/firebase_user_service.dart';
import 'services/product_cache_service.dart';
import 'screens/user/auth/login_screen.dart';
import 'utils/app_themes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Kiểm tra xem Firebase đã được khởi tạo chưa
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // Firebase đã được khởi tạo rồi, bỏ qua lỗi
    print('Firebase already initialized: $e');
  }
  // Khởi tạo helper của FirebaseUserService (kết nối emulator nếu cần)
  await FirebaseUserService.initialize();
  // Initialize local product cache
  try {
    await ProductCacheService.initialize();
  } catch (e) {
    print('ProductCacheService init error: $e');
  }
  // Firebase helper initialized. To seed or run tests, call
  // FirebaseUserService.initializeSampleUsers() or FirebaseTestService.runFullTest()
  // manually from a debug flow or Admin screen.

  runApp(const HatStyleApp());
}

class HatStyleApp extends StatelessWidget {
  const HatStyleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HatStyle - Nón Thời Trang',
      debugShowCheckedModeBanner: false,
      theme: AppThemes.userTheme,
      home: const LoginScreen(),
    );
  }
}
