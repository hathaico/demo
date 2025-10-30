# 🔍 Kiểm Tra Kết Nối Firebase

## ✅ ĐÃ THIẾT LẬP

### 1. **Đăng ký tài khoản** - ✅ ĐÃ KẾT NỐI FIRESTORE
- File: `lib/services/firebase_auth_service.dart` (dòng 40-52)
- Lưu vào Firestore: `users/{uid}`
- Fields: email, fullName, phone, username, role, isActive, totalOrders, totalSpent, timestamps

### 2. **Quản lý sản phẩm (CRUD)** - ✅ ĐÃ KẾT NỐI FIRESTORE

#### **Thêm sản phẩm:**
- File: `lib/screens/admin/products/add_product_screen.dart` (dòng 702)
- Service: `FirebaseProductService.addProduct()`
- Lưu vào Firestore: `products/{productId}`

#### **Sửa sản phẩm:**
- File: `lib/screens/admin/products/edit_product_screen.dart` (dòng 742)
- Service: `FirebaseProductService.updateProduct()`
- Cập nhật Firestore: `products/{productId}`

#### **Xóa sản phẩm:**
- File: `lib/screens/admin/products/admin_products_screen.dart` (dòng 455)
- Service: `FirebaseProductService.deleteProduct()`
- Xóa khỏi Firestore: `products/{productId}`

---

## 🧪 CÁCH TEST FIREBASE

### Cách 1: Test Trong App
1. Đăng nhập với tài khoản admin
2. Vào **Cài đặt** (Drawer menu > Cài đặt)
3. Nhấn **"Kiểm tra Firebase"**
4. Xem kết quả:
   - ✅ Kết nối: Test Firestore connection
   - ✅ Authentication: Test Firebase Auth
   - ✅ Users: Số lượng users trong database
   - ✅ Products: Số lượng products trong database
   - ✅ Orders: Số lượng orders trong database

### Cách 2: Test Bằng Code
```dart
// Test Firebase connection
Map<String, dynamic> result = await FirebaseTestService.testFirebaseConnection();

// Test users collection
Map<String, dynamic> users = await FirebaseTestService.testUsersCollection();

// Test products collection
Map<String, dynamic> products = await FirebaseTestService.testProductsCollection();

// Full test
Map<String, dynamic> all = await FirebaseTestService.runFullTest();
```

---

## 📊 TRẠNG THÁI KẾT NỐI

### ✅ Services Đã Kết Nối Firebase:
1. ✅ **firebase_auth_service.dart** - Authentication + Firestore users
2. ✅ **firebase_product_service.dart** - CRUD products
3. ✅ **firebase_order_service.dart** - CRUD orders
4. ✅ **firebase_user_service.dart** - CRUD users
5. ✅ **firebase_storage_service.dart** - Image upload/delete

### ⚠️ Dịch vụ chưa kết nối Firebase:
1. ⚠️ **cart_service.dart** - Chỉ lưu local (SharedPreferences)
2. ⚠️ **wishlist_service.dart** - Chỉ lưu local (SharedPreferences)
3. ⚠️ **user_service.dart** - Demo mode (hardcoded data)
4. ⚠️ **settings_service.dart** - Chỉ lưu local (SharedPreferences)

---

## 🔧 KIỂM TRA TRONG FIREBASE CONSOLE

### Bước 1: Mở Firebase Console
```
https://console.firebase.google.com/project/appbannon
```

### Bước 2: Kiểm tra Collections:

#### **users** collection:
```
users/
  {userId}/
    - email: string
    - fullName: string
    - phone: string
    - username: string
    - role: "user" hoặc "admin"
    - isActive: boolean
    - totalOrders: number
    - totalSpent: number
    - joinDate: timestamp
    - createdAt: timestamp
    - updatedAt: timestamp
```

#### **products** collection:
```
products/
  {productId}/
    - name: string
    - brand: string
    - price: number
    - imageUrl: string
    - category: string
    - colors: array<string>
    - material: string
    - gender: string
    - season: string
    - description: string
    - stock: number
    - rating: number
    - reviewCount: number
    - isHot: boolean
    - createdAt: timestamp
    - updatedAt: timestamp
```

#### **orders** collection:
```
orders/
  {orderId}/
    - id: string
    - userId: string
    - items: array<OrderItem>
    - totalAmount: number
    - status: string
    - orderDate: timestamp
    - shippingAddress: string
    - paymentMethod: string
    - createdAt: timestamp
    - updatedAt: timestamp
```

---

## 🐛 NẾU KHÔNG THẤY DỮ LIỆU TRONG FIRESTORE

### Có thể do:

1. **Firebase chưa được khởi tạo đúng:**
   - Check `firebase_options.dart`
   - Check `main.dart` đã gọi `Firebase.initializeApp()`

2. **Firestore Rules chưa cho phép:**
   - Vào Firebase Console > Firestore > Rules
   - Cần rules như sau:
   ```javascript
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       match /{document=**} {
         allow read, write: if true;
       }
     }
   }
   ```

3. **Permissions chưa đúng:**
   - Check Google Services file: `android/app/google-services.json`
   - Check project ID trong `firebase_options.dart`

---

## ✅ XÁC NHẬN KẾT NỐI

Để kiểm tra xem dữ liệu đã lưu chưa:

1. **Trong app:** Cài đặt > Kiểm tra Firebase
2. **Firebase Console:** Xem collections và documents
3. **Test registration:** Đăng ký tài khoản mới và xem trong Firestore
4. **Test product:** Thêm/sửa/xóa sản phẩm và xem trong Firestore

---

**Đã thiết lập xong tính năng test Firebase! 🎉**

