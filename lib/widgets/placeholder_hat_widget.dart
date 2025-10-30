import 'package:flutter/material.dart';

class PlaceholderHatWidget extends StatelessWidget {
  final String? text;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final double? height;

  const PlaceholderHatWidget({
    super.key,
    this.text,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? 300,
      height: height ?? 300,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.grey.shade300,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey.shade400,
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_bag_outlined,
            size: 60,
            color: textColor ?? Colors.grey.shade600,
          ),
          const SizedBox(height: 8),
          Text(
            text ?? 'Hình ảnh sản phẩm',
            style: TextStyle(
              color: textColor ?? Colors.grey.shade600,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

