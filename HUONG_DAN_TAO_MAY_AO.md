# 📱 Hướng Dẫn Tạo Máy Ảo Android Cho Flutter

## ✅ TÌNH TRẠNG HIỆN TẠI

- ✅ Flutter đã cài đặt (v3.35.3)
- ✅ Android SDK đã cài đặt (v36.1.0-rc1)
- ✅ Android Studio đã cài đặt (v2025.1.3)
- ❌ **Chưa có máy ảo Android nào**

---

## 🎯 CÁCH 1: TẠO MÁY ẢO TRONG ANDROID STUDIO (ĐỀ XUẤT)

### Bước 1: Mở Android Studio
1. Mở **Android Studio**
2. Chọn **More Actions** > **Virtual Device Manager**
   Hoặc: **Tools** > **Device Manager** (nếu đã mở project)

### Bước 2: Tạo Virtual Device
1. Nhấn **Create Device**
2. Chọn **Phone** > **Pixel 5** (hoặc model khác)
3. Nhấn **Next**

### Bước 3: Chọn System Image
1. Chọn **API Level** (đề xuất: **Android 13.0 - Tiramisu** hoặc **Android 11.0 - Red Velvet Cake**)
2. Nếu chưa tải: Nhấn **Download** bên cạnh
3. Nhấn **Next**

### Bước 4: Cấu Hình Máy Ảo
1. **AVD Name**: Đặt tên (ví dụ: `Pixel_5_API_33`)
2. **Advanced Settings** (tùy chọn):
   - Front Camera: Webcam
   - Back Camera: Webcam
   - Graphics: Hardware - GLES 2.0
3. Nhấn **Finish**

### Bước 5: Chạy Máy Ảo
1. Nhấn nút **▶️ Play** bên cạnh AVD vừa tạo
2. Đợi máy ảo khởi động (2-5 phút lần đầu)

---

## 🎯 CÁCH 2: TẠO MÁY ẢO BẰNG COMMAND LINE

### Bước 1: Kiểm tra AVD Manager
```bash
flutter doctor -v
```

### Bước 2: Tạo AVD bằng avdmanager
Mở Command Prompt hoặc PowerShell và chạy:

```bash
# Tìm đường dẫn SDK (thường là)
# C:\Users\YourName\AppData\Local\Android\Sdk

# Sử dụng avdmanager
C:\Users\YourName\AppData\Local\Android\Sdk\cmdline-tools\latest\bin\avdmanager create avd -n test_device -k "system-images;android-33;google_apis;x86_64"
```

### Bước 3: Liệt kê AVD đã tạo
```bash
C:\Users\YourName\AppData\Local\Android\Sdk\cmdline-tools\latest\bin\avdmanager list avd
```

---

## 🎯 CÁCH 3: SỬ DỤNG FLUTTER TẠO EMULATOR (NHANH NHẤT)

### Kiểm tra available system images
Chạy lệnh:
```bash
flutter emulators --create --name my_android_emulator
```

Hoặc tạo với cấu hình cụ thể:
```bash
flutter create --org com.hatstyle --project-name test_avd
cd test_avd
flutter emulators
```

---

## 🚀 SAU KHI TẠO XONG MÁY ẢO

### Bước 1: Khởi động máy ảo
```bash
flutter emulators --launch <tên_emulator>
```

### Bước 2: Kiểm tra devices
```bash
flutter devices
```

Bạn sẽ thấy:
```
2 connected devices:
  Pixel 5 (mobile) • emulator-5554 • android-arm64 • Android 13
  Chrome (web)     • chrome       • web-javascript • Google Chrome
```

### Bước 3: Chạy ứng dụng
```bash
flutter run
```

Hoặc chọn thiết bị cụ thể:
```bash
flutter run -d emulator-5554
```

---

## 💡 TIPS & TROUBLESHOOTING

### Lỗi thường gặp:

#### 1. "No emulators available"
- **Giải pháp**: Tạo emulator bằng 1 trong 3 cách trên

#### 2. "Android SDK not found"
- **Giải pháp**: Cài đặt Android Studio và SDK

#### 3. "Unable to launch emulator"
- **Giải pháp**: 
  - Kiểm tra **Intel HAXM** hoặc **Hyper-V** đã bật
  - Trong Windows: Bật Virtualization trong BIOS

#### 4. Emulator chạy quá chậm
- **Giải pháp**:
  - Giảm RAM allocation
  - Tắt animation trong Developer Options
  - Sử dụng Quick Boot

### Tối ưu Performance:

1. **Tăng RAM cho emulator**:
   - Android Studio > Edit AVD > Show Advanced Settings > RAM: 4096 MB

2. **Sử dụng Hardware Acceleration**:
   - Kiểm tra: `flutter doctor -v`
   - Tìm dòng "Android toolchain"

3. **Sử dụng Physical Device** (Nhanh hơn):
   - Bật USB Debugging
   - Kết nối điện thoại qua USB
   - `flutter devices` sẽ hiển thị thiết bị

---

## 📱 TẠO MÁY ẢO CHO iOS (Nếu có Mac)

### Yêu cầu:
- ✅ macOS
- ✅ Xcode đã cài đặt
- ✅ CocoaPods

### Các bước:
1. Mở **Xcode**
2. **Window** > **Devices and Simulators**
3. **+** để tạo simulator mới
4. Chọn Device & iOS Version

---

## 🎯 GỢI Ý CẤU HÌNH MÁY ẢO TỐI ƯU

### Cấu hình đề xuất:

| Loại | Giá trị khuyên dùng |
|------|---------------------|
| RAM | 4096 MB (4GB) |
| Internal Storage | 2048 MB (2GB) |
| SD Card | 512 MB |
| Graphics | Hardware - GLES 2.0 |
| Camera | Front: Webcam / Back: None |
| Multi-core CPU | 2-4 cores |

### Device Model đề xuất:
- ✅ **Pixel 5** (Android 13)
- ✅ **Pixel 6** (Android 14)
- ✅ **Samsung Galaxy S21** (Android 11+)

---

## 📞 LIÊN HỆ & HỖ TRỢ

Nếu vẫn gặp vấn đề:
1. Chạy `flutter doctor -v` và xem chi tiết
2. Kiểm tra Android Studio logs
3. Kiểm tra Windows Event Viewer
4. Xem tài liệu: https://flutter.dev/setup

---

**Chúc bạn thành công! 🎉**

