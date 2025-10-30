import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;
import 'package:image/image.dart' as img;

class FirebaseStorageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  // Upload file từ đường dẫn
  static Future<Map<String, dynamic>> uploadFile({
    required File file,
    required String folder,
    String? fileName,
  }) async {
    try {
      // Kiểm tra Firebase Storage instance
      try {
        _storage.ref();
      } catch (e) {
        return {
          'success': false,
          'error': 'Firebase Storage chưa được khởi tạo: $e',
        };
      }

      // Tạo tên file nếu không có
      String finalFileName = fileName ?? path.basename(file.path);

      // Tạo đường dẫn trong Storage
      String storagePath = '$folder/$finalFileName';

      print('Uploading to path: $storagePath');
      print('File exists: ${await file.exists()}');
      print('File size: ${await file.length()} bytes');

      // Upload file
      Reference ref = _storage.ref().child(storagePath);
      UploadTask uploadTask = ref.putFile(file);

      // Chờ upload hoàn thành
      TaskSnapshot snapshot = await uploadTask;

      // Lấy URL download
      String downloadUrl = await snapshot.ref.getDownloadURL();

      print('Upload successful: $downloadUrl');

      return {
        'success': true,
        'downloadUrl': downloadUrl,
        'storagePath': storagePath,
        'fileName': finalFileName,
        'message': 'Upload file thành công',
      };
    } catch (e) {
      print('Upload error: $e');
      return {'success': false, 'error': 'Lỗi upload file: $e'};
    }
  }

  // Upload file từ bytes
  static Future<Map<String, dynamic>> uploadBytes({
    required Uint8List bytes,
    required String folder,
    required String fileName,
  }) async {
    try {
      // Tạo đường dẫn trong Storage
      String storagePath = '$folder/$fileName';

      // Upload bytes
      Reference ref = _storage.ref().child(storagePath);
      UploadTask uploadTask = ref.putData(bytes);

      // Chờ upload hoàn thành
      TaskSnapshot snapshot = await uploadTask;

      // Lấy URL download
      String downloadUrl = await snapshot.ref.getDownloadURL();

      return {
        'success': true,
        'downloadUrl': downloadUrl,
        'storagePath': storagePath,
        'fileName': fileName,
        'message': 'Upload file thành công',
      };
    } catch (e) {
      return {'success': false, 'error': 'Lỗi upload file: $e'};
    }
  }

  // Kiểm tra Firebase Storage rules
  static Future<Map<String, dynamic>> checkStorageRules() async {
    try {
      print('Checking Firebase Storage rules...');

      // Kiểm tra Firebase Storage instance
      try {
        _storage.ref();
      } catch (e) {
        return {
          'success': false,
          'error': 'Firebase Storage chưa được khởi tạo: $e',
        };
      }

      // Thử tạo một reference đơn giản
      Reference ref = _storage.ref().child('test/rules_check.txt');

      // Thử upload một file nhỏ để test rules
      String testContent = 'Rules check - ${DateTime.now()}';
      Uint8List testBytes = Uint8List.fromList(testContent.codeUnits);

      UploadTask uploadTask = ref.putData(testBytes);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      // Xóa file test
      await ref.delete();

      return {
        'success': true,
        'message': 'Storage rules OK - có thể upload và xóa file',
        'downloadUrl': downloadUrl,
      };
    } catch (e) {
      print('Storage rules check error: $e');
      return {'success': false, 'error': 'Storage rules check failed: $e'};
    }
  }

  // Test method để kiểm tra Firebase Storage
  static Future<Map<String, dynamic>> testUpload() async {
    try {
      print('Testing Firebase Storage...');
      print('Storage instance: $_storage');
      print('Storage app: ${_storage.app}');

      // Kiểm tra Firebase Storage instance
      try {
        _storage.ref();
      } catch (e) {
        return {
          'success': false,
          'error': 'Firebase Storage chưa được khởi tạo: $e',
        };
      }

      // Tạo một file test đơn giản
      String testContent = 'Test upload from Flutter app - ${DateTime.now()}';
      Uint8List testBytes = Uint8List.fromList(testContent.codeUnits);

      String fileName = 'test_${DateTime.now().millisecondsSinceEpoch}.txt';
      String storagePath = 'test/$fileName';

      print('Uploading test file to: $storagePath');

      Reference ref = _storage.ref().child(storagePath);
      UploadTask uploadTask = ref.putData(testBytes);

      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      print('Test upload successful: $downloadUrl');

      return {
        'success': true,
        'downloadUrl': downloadUrl,
        'message': 'Test upload thành công',
      };
    } catch (e) {
      print('Test upload error: $e');
      return {'success': false, 'error': 'Test upload failed: $e'};
    }
  }

  // Upload hình ảnh sản phẩm
  static Future<Map<String, dynamic>> uploadProductImage({
    required File imageFile,
    required String productId,
  }) async {
    try {
      // Tạo tên file với timestamp để tránh trùng lặp
      String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      String extension = path.extension(imageFile.path);
      String fileName = 'product_${productId}_$timestamp$extension';

      return await uploadFile(
        file: imageFile,
        folder: 'products',
        fileName: fileName,
      );
    } catch (e) {
      return {'success': false, 'error': 'Lỗi upload hình ảnh sản phẩm: $e'};
    }
  }

  // Upload avatar người dùng
  static Future<Map<String, dynamic>> uploadUserAvatar({
    required File imageFile,
    required String userId,
  }) async {
    try {
      // Tạo tên file với timestamp
      String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      String extension = path.extension(imageFile.path);
      String fileName = 'avatar_${userId}_$timestamp$extension';

      return await uploadFile(
        file: imageFile,
        folder: 'avatars',
        fileName: fileName,
      );
    } catch (e) {
      return {'success': false, 'error': 'Lỗi upload avatar: $e'};
    }
  }

  // Upload hình ảnh đánh giá
  static Future<Map<String, dynamic>> uploadReviewImage({
    required File imageFile,
    required String reviewId,
  }) async {
    try {
      String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      String extension = path.extension(imageFile.path);
      String fileName = 'review_${reviewId}_$timestamp$extension';

      return await uploadFile(
        file: imageFile,
        folder: 'reviews',
        fileName: fileName,
      );
    } catch (e) {
      return {'success': false, 'error': 'Lỗi upload hình ảnh đánh giá: $e'};
    }
  }

  // Xóa file
  static Future<Map<String, dynamic>> deleteFile(String storagePath) async {
    try {
      Reference ref = _storage.ref().child(storagePath);
      await ref.delete();

      return {'success': true, 'message': 'Xóa file thành công'};
    } catch (e) {
      return {'success': false, 'error': 'Lỗi xóa file: $e'};
    }
  }

  // Xóa file theo URL
  static Future<Map<String, dynamic>> deleteFileByUrl(
    String downloadUrl,
  ) async {
    try {
      Reference ref = _storage.refFromURL(downloadUrl);
      await ref.delete();

      return {'success': true, 'message': 'Xóa file thành công'};
    } catch (e) {
      return {'success': false, 'error': 'Lỗi xóa file: $e'};
    }
  }

  // Lấy danh sách file trong folder
  static Future<List<Map<String, dynamic>>> listFiles(String folder) async {
    try {
      Reference ref = _storage.ref().child(folder);
      ListResult result = await ref.listAll();

      List<Map<String, dynamic>> files = [];

      for (Reference fileRef in result.items) {
        String downloadUrl = await fileRef.getDownloadURL();
        FullMetadata metadata = await fileRef.getMetadata();

        files.add({
          'name': fileRef.name,
          'path': fileRef.fullPath,
          'downloadUrl': downloadUrl,
          'size': metadata.size,
          'contentType': metadata.contentType,
          'timeCreated': metadata.timeCreated,
          'updated': metadata.updated,
        });
      }

      return files;
    } catch (e) {
      return [];
    }
  }

  // Lấy metadata của file
  static Future<Map<String, dynamic>?> getFileMetadata(
    String storagePath,
  ) async {
    try {
      Reference ref = _storage.ref().child(storagePath);
      FullMetadata metadata = await ref.getMetadata();

      return {
        'name': ref.name,
        'path': ref.fullPath,
        'size': metadata.size,
        'contentType': metadata.contentType,
        'timeCreated': metadata.timeCreated,
        'updated': metadata.updated,
        'downloadUrl': await ref.getDownloadURL(),
      };
    } catch (e) {
      return null;
    }
  }

  // Download file
  static Future<Map<String, dynamic>> downloadFile({
    required String storagePath,
    required String localPath,
  }) async {
    try {
      Reference ref = _storage.ref().child(storagePath);
      File file = File(localPath);

      await ref.writeToFile(file);

      return {
        'success': true,
        'localPath': localPath,
        'message': 'Download file thành công',
      };
    } catch (e) {
      return {'success': false, 'error': 'Lỗi download file: $e'};
    }
  }

  // Lấy URL download
  static Future<String?> getDownloadUrl(String storagePath) async {
    try {
      Reference ref = _storage.ref().child(storagePath);
      return await ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }

  // Upload nhiều file cùng lúc
  static Future<List<Map<String, dynamic>>> uploadMultipleFiles({
    required List<File> files,
    required String folder,
    List<String>? fileNames,
  }) async {
    List<Map<String, dynamic>> results = [];

    for (int i = 0; i < files.length; i++) {
      String? fileName = fileNames != null && i < fileNames.length
          ? fileNames[i]
          : null;

      Map<String, dynamic> result = await uploadFile(
        file: files[i],
        folder: folder,
        fileName: fileName,
      );

      results.add(result);
    }

    return results;
  }

  // Compress và upload hình ảnh
  static Future<Map<String, dynamic>> uploadCompressedImage({
    required File imageFile,
    required String folder,
    required String fileName,
    int quality = 85,
  }) async {
    try {
      // Đọc file gốc
      Uint8List bytes = await imageFile.readAsBytes();

      // Giải mã ảnh
      img.Image? image = img.decodeImage(bytes);
      if (image == null) {
        return {'success': false, 'error': 'Không thể giải mã hình ảnh'};
      }

      // Resize nếu quá lớn (giữ tỷ lệ)
      const int maxDim = 1920;
      if (image.width > maxDim || image.height > maxDim) {
        image = img.copyResize(image, width: maxDim);
      }

      // Mã hóa lại với chất lượng đã cho
      List<int> encoded = img.encodeJpg(image, quality: quality);

      return await uploadBytes(
        bytes: Uint8List.fromList(encoded),
        folder: folder,
        fileName: fileName,
      );
    } catch (e) {
      return {'success': false, 'error': 'Lỗi compress và upload hình ảnh: $e'};
    }
  }

  // Tạo thumbnail cho hình ảnh
  static Future<Map<String, dynamic>> createThumbnail({
    required File imageFile,
    required String folder,
    required String fileName,
    int maxWidth = 300,
    int maxHeight = 300,
  }) async {
    try {
      // Đọc file và giải mã
      Uint8List bytes = await imageFile.readAsBytes();
      img.Image? image = img.decodeImage(bytes);
      if (image == null) {
        return {'success': false, 'error': 'Không thể giải mã hình ảnh'};
      }

      // Tính tỷ lệ resize sao cho vừa maxWidth/maxHeight
      image = img.copyResize(image, width: maxWidth, height: maxHeight);

      // Mã hóa thumbnail ở chất lượng thấp hơn để giảm dung lượng
      List<int> thumbBytes = img.encodeJpg(image, quality: 70);

      String thumbFileName = 'thumb_$fileName';

      return await uploadBytes(
        bytes: Uint8List.fromList(thumbBytes),
        folder: '$folder/thumbnails',
        fileName: thumbFileName,
      );
    } catch (e) {
      return {'success': false, 'error': 'Lỗi tạo thumbnail: $e'};
    }
  }

  // Kiểm tra file có tồn tại không
  static Future<bool> fileExists(String storagePath) async {
    try {
      Reference ref = _storage.ref().child(storagePath);
      await ref.getMetadata();
      return true;
    } catch (e) {
      return false;
    }
  }

  // Lấy kích thước folder
  static Future<Map<String, dynamic>> getFolderSize(String folder) async {
    try {
      Reference ref = _storage.ref().child(folder);
      ListResult result = await ref.listAll();

      int totalFiles = result.items.length;
      int totalSize = 0;

      for (Reference fileRef in result.items) {
        FullMetadata metadata = await fileRef.getMetadata();
        totalSize += metadata.size ?? 0;
      }

      return {
        'totalFiles': totalFiles,
        'totalSize': totalSize,
        'totalSizeMB': (totalSize / (1024 * 1024)).toStringAsFixed(2),
      };
    } catch (e) {
      return {'totalFiles': 0, 'totalSize': 0, 'totalSizeMB': '0.00'};
    }
  }

  // Cleanup files cũ (older than specified days)
  static Future<Map<String, dynamic>> cleanupOldFiles({
    required String folder,
    required int daysOld,
  }) async {
    try {
      Reference ref = _storage.ref().child(folder);
      ListResult result = await ref.listAll();

      DateTime cutoffDate = DateTime.now().subtract(Duration(days: daysOld));
      int deletedCount = 0;

      for (Reference fileRef in result.items) {
        FullMetadata metadata = await fileRef.getMetadata();
        DateTime? createdDate = metadata.timeCreated;

        if (createdDate != null && createdDate.isBefore(cutoffDate)) {
          await fileRef.delete();
          deletedCount++;
        }
      }

      return {
        'success': true,
        'deletedCount': deletedCount,
        'message': 'Đã xóa $deletedCount file cũ',
      };
    } catch (e) {
      return {'success': false, 'error': 'Lỗi cleanup files: $e'};
    }
  }
}
