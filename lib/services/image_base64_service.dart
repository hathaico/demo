import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';

class ImageBase64Service {
  // Chuyển đổi File thành base64 string
  static Future<String> fileToBase64(File file) async {
    try {
      Uint8List bytes = await file.readAsBytes();
      String base64String = base64Encode(bytes);
      return base64String;
    } catch (e) {
      throw Exception('Lỗi chuyển đổi file thành base64: $e');
    }
  }

  // Chuyển đổi XFile thành base64 string
  static Future<String> xFileToBase64(XFile file) async {
    try {
      Uint8List bytes = await file.readAsBytes();
      String base64String = base64Encode(bytes);
      return base64String;
    } catch (e) {
      throw Exception('Lỗi chuyển đổi XFile thành base64: $e');
    }
  }

  // Chuyển đổi base64 string thành Uint8List
  static Uint8List base64ToBytes(String base64String) {
    try {
      return base64Decode(base64String);
    } catch (e) {
      throw Exception('Lỗi chuyển đổi base64 thành bytes: $e');
    }
  }

  // Tạo data URL từ base64 string
  static String base64ToDataUrl(String base64String, String mimeType) {
    return 'data:$mimeType;base64,$base64String';
  }

  // Nén hình ảnh trước khi chuyển thành base64
  static Future<String> compressAndConvertToBase64({
    required File imageFile,
    int quality = 85,
    int maxWidth = 1024,
    int maxHeight = 1024,
  }) async {
    try {
      // Đọc file gốc
      Uint8List originalBytes = await imageFile.readAsBytes();
      
      // TODO: Implement image compression
      // Có thể sử dụng package image để compress
      // Hiện tại chỉ return base64 của file gốc
      
      String base64String = base64Encode(originalBytes);
      return base64String;
    } catch (e) {
      throw Exception('Lỗi nén và chuyển đổi hình ảnh: $e');
    }
  }

  // Kiểm tra kích thước file
  static Future<bool> isFileSizeValid(File file, int maxSizeInMB) async {
    try {
      int fileSizeInBytes = await file.length();
      int maxSizeInBytes = maxSizeInMB * 1024 * 1024;
      return fileSizeInBytes <= maxSizeInBytes;
    } catch (e) {
      return false;
    }
  }

  // Lấy MIME type từ file extension
  static String getMimeTypeFromExtension(String filePath) {
    String extension = filePath.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg'; // Default
    }
  }

  // Tạo thumbnail từ base64
  static Future<String> createThumbnailFromBase64({
    required String base64String,
    int maxWidth = 300,
    int maxHeight = 300,
  }) async {
    try {
      // TODO: Implement thumbnail creation
      // Có thể sử dụng package image để tạo thumbnail
      // Hiện tại return base64 gốc
      return base64String;
    } catch (e) {
      throw Exception('Lỗi tạo thumbnail: $e');
    }
  }

  // Kiểm tra base64 string có hợp lệ không
  static bool isValidBase64(String base64String) {
    try {
      base64Decode(base64String);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Lấy kích thước base64 string (ước tính)
  static int getBase64SizeInBytes(String base64String) {
    try {
      // Base64 encoding tăng kích thước khoảng 33%
      // Decode để lấy kích thước thực
      Uint8List bytes = base64Decode(base64String);
      return bytes.length;
    } catch (e) {
      return 0;
    }
  }

  // Format kích thước file
  static String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  // Upload hình ảnh sản phẩm dưới dạng base64
  static Future<Map<String, dynamic>> uploadProductImageAsBase64({
    required File imageFile,
    required String productId,
    int quality = 85,
    int maxSizeInMB = 5,
  }) async {
    try {
      // Kiểm tra kích thước file
      if (!await isFileSizeValid(imageFile, maxSizeInMB)) {
        return {
          'success': false,
          'error': 'File quá lớn. Kích thước tối đa: ${maxSizeInMB}MB',
        };
      }

      // Chuyển đổi thành base64
      String base64String = await compressAndConvertToBase64(
        imageFile: imageFile,
        quality: quality,
      );

      // Lấy MIME type
      String mimeType = getMimeTypeFromExtension(imageFile.path);

      // Tạo data URL
      String dataUrl = base64ToDataUrl(base64String, mimeType);

      return {
        'success': true,
        'base64String': base64String,
        'dataUrl': dataUrl,
        'mimeType': mimeType,
        'fileSize': getBase64SizeInBytes(base64String),
        'message': 'Chuyển đổi hình ảnh thành base64 thành công',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Lỗi chuyển đổi hình ảnh: $e',
      };
    }
  }

  // Upload avatar người dùng dưới dạng base64
  static Future<Map<String, dynamic>> uploadUserAvatarAsBase64({
    required File imageFile,
    required String userId,
    int quality = 80,
    int maxSizeInMB = 2,
  }) async {
    try {
      // Kiểm tra kích thước file
      if (!await isFileSizeValid(imageFile, maxSizeInMB)) {
        return {
          'success': false,
          'error': 'File quá lớn. Kích thước tối đa: ${maxSizeInMB}MB',
        };
      }

      // Chuyển đổi thành base64
      String base64String = await compressAndConvertToBase64(
        imageFile: imageFile,
        quality: quality,
      );

      // Lấy MIME type
      String mimeType = getMimeTypeFromExtension(imageFile.path);

      // Tạo data URL
      String dataUrl = base64ToDataUrl(base64String, mimeType);

      return {
        'success': true,
        'base64String': base64String,
        'dataUrl': dataUrl,
        'mimeType': mimeType,
        'fileSize': getBase64SizeInBytes(base64String),
        'message': 'Chuyển đổi avatar thành base64 thành công',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Lỗi chuyển đổi avatar: $e',
      };
    }
  }
}





