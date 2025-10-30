import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';

class FirebaseTestScreen extends StatefulWidget {
  const FirebaseTestScreen({super.key});

  @override
  State<FirebaseTestScreen> createState() => _FirebaseTestScreenState();
}

class _FirebaseTestScreenState extends State<FirebaseTestScreen> {
  String _testResult = 'Chưa test';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firebase Storage Test'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Kiểm tra Firebase Storage',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: _isLoading ? null : _testFirebaseStorage,
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Test Firebase Storage'),
            ),

            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Kết quả test:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(_testResult, style: const TextStyle(fontSize: 14)),
                ],
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'Các bước khắc phục:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            const Text(
              '1. Kiểm tra Firebase Console → Storage\n'
              '2. Đảm bảo Storage bucket tồn tại\n'
              '3. Kiểm tra Storage Rules\n'
              '4. Đảm bảo quyền truy cập đúng',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _testFirebaseStorage() async {
    setState(() {
      _isLoading = true;
      _testResult = 'Đang test...';
    });

    try {
      // Test 1: Kiểm tra Firebase Storage instance
      FirebaseStorage storage = FirebaseStorage.instance;
      _testResult += '\n✓ Firebase Storage instance: OK';

      // Test 2: Kiểm tra bucket
      String bucket = storage.bucket;
      _testResult += '\n✓ Storage bucket: $bucket';

      // Test 3: Thử tạo reference
      Reference ref = storage.ref().child('test/test.txt');
      _testResult += '\n✓ Reference created: OK';

      // Test 4: Thử upload dữ liệu test
      String testData = 'Test data from Flutter app';
      UploadTask uploadTask = ref.putString(testData);

      _testResult += '\n✓ Upload task created: OK';

      // Test 5: Chờ upload hoàn thành
      TaskSnapshot snapshot = await uploadTask;
      _testResult += '\n✓ Upload completed: OK';

      // Test 6: Lấy download URL
      String downloadUrl = await snapshot.ref.getDownloadURL();
      _testResult += '\n✓ Download URL: $downloadUrl';

      // Test 7: Xóa file test
      await snapshot.ref.delete();
      _testResult += '\n✓ Test file deleted: OK';

      _testResult += '\n\n🎉 TẤT CẢ TEST THÀNH CÔNG!';
    } catch (e) {
      _testResult += '\n\n❌ LỖI: $e';

      // Phân tích lỗi cụ thể
      if (e.toString().contains('404')) {
        _testResult += '\n\n🔍 Phân tích lỗi:';
        _testResult +=
            '\n- Lỗi 404: Storage bucket không tồn tại hoặc không accessible';
        _testResult += '\n- Kiểm tra Firebase Console → Storage';
        _testResult += '\n- Đảm bảo Storage đã được enable';
      } else if (e.toString().contains('permission')) {
        _testResult += '\n\n🔍 Phân tích lỗi:';
        _testResult += '\n- Lỗi permission: Quyền truy cập không đúng';
        _testResult += '\n- Kiểm tra Storage Rules trong Firebase Console';
      } else if (e.toString().contains('network')) {
        _testResult += '\n\n🔍 Phân tích lỗi:';
        _testResult += '\n- Lỗi network: Vấn đề kết nối mạng';
        _testResult += '\n- Kiểm tra kết nối internet';
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
