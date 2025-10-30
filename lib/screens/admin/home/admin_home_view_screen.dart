import 'package:flutter/material.dart';
import '../../user/home/home_screen.dart';

/// Màn hình hiển thị trang chủ user trong admin panel
/// Cho phép admin xem được giao diện và nội dung mà user thấy
class AdminHomeViewScreen extends StatelessWidget {
  const AdminHomeViewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Xem Trang Chủ'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Thông tin'),
                  content: const Text(
                    'Đây là giao diện trang chủ mà người dùng thấy. '
                    'Admin có thể xem và kiểm tra nội dung hiển thị cho user.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Đóng'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: const HomeScreen(),
    );
  }
}

