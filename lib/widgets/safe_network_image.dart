import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'placeholder_hat_widget.dart';

class SafeNetworkImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final String? placeholderText;

  const SafeNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit,
    this.placeholderText,
  });

  @override
  Widget build(BuildContext context) {
    // Nếu là placeholder widget
    if (imageUrl == 'placeholder_widget') {
      return PlaceholderHatWidget(
        text: placeholderText ?? 'Hình ảnh sản phẩm',
        width: width,
        height: height,
      );
    }

    // Nếu là data URL (base64)
    if (imageUrl.startsWith('data:')) {
      try {
        // Tách data URL để lấy base64 string
        String base64String = imageUrl.split(',')[1];
        Uint8List bytes = base64Decode(base64String);

        return Image.memory(
          bytes,
          width: width,
          height: height,
          fit: fit ?? BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return PlaceholderHatWidget(
              text: placeholderText ?? 'Lỗi hiển thị hình ảnh',
              width: width,
              height: height,
            );
          },
        );
      } catch (e) {
        print('Error decoding base64 image: $e');
        return PlaceholderHatWidget(
          text: placeholderText ?? 'Lỗi giải mã hình ảnh',
          width: width,
          height: height,
        );
      }
    }

    // Nếu là asset image
    if (imageUrl.startsWith('assets/')) {
      return Image.asset(
        imageUrl,
        width: width,
        height: height,
        fit: fit ?? BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return PlaceholderHatWidget(
            text: placeholderText ?? 'Không thể tải hình ảnh',
            width: width,
            height: height,
          );
        },
      );
    }

    // Nếu là network image, dùng CachedNetworkImage để cache và tối ưu
    if (imageUrl.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: imageUrl,
        width: width,
        height: height,
        fit: fit ?? BoxFit.cover,
        placeholder: (context, url) => Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(child: CircularProgressIndicator()),
        ),
        errorWidget: (context, url, error) => PlaceholderHatWidget(
          text: placeholderText ?? 'Không thể tải hình ảnh',
          width: width,
          height: height,
        ),
      );
    }

    // Fallback cho các trường hợp khác
    return PlaceholderHatWidget(
      text: placeholderText ?? 'Hình ảnh không hợp lệ',
      width: width,
      height: height,
    );
  }
}
