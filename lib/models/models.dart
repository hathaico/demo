// Model cho sản phẩm nón
class HatProduct {
  final String id;
  final String name;
  final String brand;
  final double price;
  final String imageUrl;
  final String category;
  final List<String> colors; // Thay đổi từ String thành List<String>
  final String material;
  final String gender;
  final String season;
  final String description;
  final int stock;
  final double rating;
  final int reviewCount;
  final bool isHot;

  HatProduct({
    required this.id,
    required this.name,
    required this.brand,
    required this.price,
    required this.imageUrl,
    required this.category,
    required this.colors, // Thay đổi từ color thành colors
    required this.material,
    required this.gender,
    required this.season,
    required this.description,
    required this.stock,
    required this.rating,
    required this.reviewCount,
    this.isHot = false,
  });
}

// Model cho đơn hàng
class Order {
  final String id;
  final String userId;
  final List<OrderItem> items;
  final double totalAmount;
  final String status;
  final DateTime orderDate;
  final String shippingAddress;
  final String paymentMethod;

  Order({
    required this.id,
    required this.userId,
    required this.items,
    required this.totalAmount,
    required this.status,
    required this.orderDate,
    required this.shippingAddress,
    required this.paymentMethod,
  });
}

class OrderItem {
  final String productId;
  final String productName;
  final String productImage;
  final double price;
  final int quantity;

  OrderItem({
    required this.productId,
    required this.productName,
    required this.productImage,
    required this.price,
    required this.quantity,
  });
}

// Model cho người dùng
class User {
  final String id;
  final String fullName;
  final String email;
  final String phone;
  final String username;
  final DateTime joinDate;
  final bool isActive;
  final int totalOrders;
  final double totalSpent;

  User({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.username,
    required this.joinDate,
    this.isActive = true,
    this.totalOrders = 0,
    this.totalSpent = 0.0,
  });
}

// Model cho địa chỉ (đơn giản nhưng có trường isDefault)
class Address {
  final String id;
  final String name; // tên người nhận
  final String phone;
  final String street; // đường, số nhà
  final String ward;
  final String district;
  final String city;
  final bool isDefault;

  Address({
    required this.id,
    required this.name,
    required this.phone,
    required this.street,
    required this.ward,
    required this.district,
    required this.city,
    this.isDefault = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'street': street,
      'ward': ward,
      'district': district,
      'city': city,
      'isDefault': isDefault,
    };
  }

  static Address fromMap(Map<String, dynamic> m) {
    return Address(
      id: m['id'] ?? (DateTime.now().millisecondsSinceEpoch.toString()),
      name: m['name'] ?? '',
      phone: m['phone'] ?? '',
      street: m['street'] ?? '',
      ward: m['ward'] ?? '',
      district: m['district'] ?? '',
      city: m['city'] ?? '',
      isDefault: m['isDefault'] ?? false,
    );
  }
}

// Model cho báo cáo thống kê
class SalesReport {
  final DateTime date;
  final double revenue;
  final int orderCount;
  final int newUsers;

  SalesReport({
    required this.date,
    required this.revenue,
    required this.orderCount,
    required this.newUsers,
  });
}

class ProductStats {
  final String productId;
  final String productName;
  final int views;
  final int purchases;
  final double conversionRate;

  ProductStats({
    required this.productId,
    required this.productName,
    required this.views,
    required this.purchases,
    required this.conversionRate,
  });
}

// Notification categories reflect core commerce operations.
enum NotificationCategory { order, promotion, stock, support, system }

class StoreNotification {
  final String id;
  final String title;
  final String body;
  final NotificationCategory category;
  final DateTime createdAt;
  final bool isRead;
  final String? orderId;
  final String? productId;
  final String? imageUrl;
  final bool isGlobal;
  final bool isSample;

  StoreNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.category,
    required this.createdAt,
    this.isRead = false,
    this.orderId,
    this.productId,
    this.imageUrl,
    this.isGlobal = false,
    this.isSample = false,
  });

  StoreNotification copyWith({
    String? id,
    String? title,
    String? body,
    NotificationCategory? category,
    DateTime? createdAt,
    bool? isRead,
    String? orderId,
    String? productId,
    String? imageUrl,
    bool? isGlobal,
    bool? isSample,
  }) {
    return StoreNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      orderId: orderId ?? this.orderId,
      productId: productId ?? this.productId,
      imageUrl: imageUrl ?? this.imageUrl,
      isGlobal: isGlobal ?? this.isGlobal,
      isSample: isSample ?? this.isSample,
    );
  }

  factory StoreNotification.fromMap(String id, Map<String, dynamic> data) {
    return StoreNotification(
      id: id,
      title: (data['title'] ?? 'Thông báo').toString(),
      body: (data['body'] ?? data['message'] ?? '').toString(),
      category: _categoryFromString(
        (data['category'] ?? data['type'] ?? 'system').toString(),
      ),
      createdAt: _parseDate(data['createdAt']),
      isRead: (data['isRead'] ?? data['read'] ?? false) == true,
      orderId: data['orderId']?.toString(),
      productId: data['productId']?.toString(),
      imageUrl:
          data['productImage']?.toString() ?? data['imageUrl']?.toString(),
      isGlobal: (data['isGlobal'] ?? false) == true,
      isSample: (data['isSample'] ?? false) == true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'body': body,
      'category': categoryToString(category),
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
      if (orderId != null) 'orderId': orderId,
      if (productId != null) 'productId': productId,
      if (imageUrl != null && imageUrl!.isNotEmpty) 'productImage': imageUrl,
      'isGlobal': isGlobal,
      'isSample': isSample,
    };
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    try {
      // Handle Firestore Timestamp without directly importing package.
      final dynamic milliseconds = value.millisecondsSinceEpoch;
      if (milliseconds is int) {
        return DateTime.fromMillisecondsSinceEpoch(milliseconds);
      }
    } catch (_) {}
    return DateTime.now();
  }

  static NotificationCategory _categoryFromString(String value) {
    switch (value.toLowerCase()) {
      case 'order':
      case 'order_update':
      case 'order-status':
        return NotificationCategory.order;
      case 'promotion':
      case 'marketing':
        return NotificationCategory.promotion;
      case 'stock':
      case 'inventory':
      case 'restock':
        return NotificationCategory.stock;
      case 'support':
      case 'service':
        return NotificationCategory.support;
      default:
        return NotificationCategory.system;
    }
  }

  static String categoryToString(NotificationCategory category) {
    switch (category) {
      case NotificationCategory.order:
        return 'order';
      case NotificationCategory.promotion:
        return 'promotion';
      case NotificationCategory.stock:
        return 'stock';
      case NotificationCategory.support:
        return 'support';
      case NotificationCategory.system:
        return 'system';
    }
  }
}
