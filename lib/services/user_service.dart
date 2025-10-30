class UserService {
  // Lưu trữ người dùng đã đăng ký (trong thực tế sẽ lưu vào database)
  static final Map<String, Map<String, dynamic>> _registeredUsers = {
    // Demo users
    'user@demo.com': {
      'password': '123456',
      'fullName': 'Nguyễn Văn Demo',
      'phone': '0901234567',
      'username': 'demo_user',
      'role': 'user',
    },
    'customer@hatstyle.com': {
      'password': 'password123',
      'fullName': 'Trần Thị Customer',
      'phone': '0912345678',
      'username': 'customer',
      'role': 'user',
    },
    'demo@demo.com': {
      'password': 'demo123',
      'fullName': 'Demo User',
      'phone': '0923456789',
      'username': 'demo',
      'role': 'user',
    },
    'test@test.com': {
      'password': 'test123',
      'fullName': 'Test User',
      'phone': '0934567890',
      'username': 'test',
      'role': 'user',
    },
    // Admin accounts (system provided, cannot register)
    'admin': {
      'password': 'admin123',
      'fullName': 'System Administrator',
      'phone': '0000000000',
      'username': 'admin',
      'role': 'admin',
    },
    'admin1': {
      'password': 'admin123',
      'fullName': 'Admin User 1',
      'phone': '0000000001',
      'username': 'admin1',
      'role': 'admin',
    },
    'manager': {
      'password': 'manager123',
      'fullName': 'Manager User',
      'phone': '0000000002',
      'username': 'manager',
      'role': 'admin',
    },
  };

  // Đăng ký người dùng mới (chỉ cho user, không cho admin)
  static bool registerUser({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String username,
  }) {
    // Kiểm tra email đã tồn tại chưa
    if (_registeredUsers.containsKey(email)) {
      return false; // Email đã tồn tại
    }

    // Kiểm tra username đã tồn tại chưa
    for (var user in _registeredUsers.values) {
      if (user['username'] == username) {
        return false; // Username đã tồn tại
      }
    }

    // Thêm người dùng mới (chỉ role user)
    _registeredUsers[email] = {
      'password': password,
      'fullName': fullName,
      'phone': phone,
      'username': username,
      'role': 'user',
    };

    return true; // Đăng ký thành công
  }

  // Đăng nhập người dùng và trả về thông tin role
  static Map<String, dynamic>? loginUser(String emailOrUsername, String password) {
    // Tìm kiếm theo email hoặc username
    String? email;
    
    // Kiểm tra theo email trước
    if (_registeredUsers.containsKey(emailOrUsername)) {
      email = emailOrUsername;
    } else {
      // Tìm kiếm theo username
      for (var entry in _registeredUsers.entries) {
        if (entry.value['username'] == emailOrUsername) {
          email = entry.key;
          break;
        }
      }
    }

    if (email != null && _registeredUsers[email]!['password'] == password) {
      var userData = _registeredUsers[email]!;
      return {
        'email': email,
        'fullName': userData['fullName'],
        'phone': userData['phone'],
        'username': userData['username'],
        'role': userData['role'],
        'success': true,
      };
    }

    return null; // Đăng nhập thất bại
  }

  // Kiểm tra đăng nhập thành công (backward compatibility)
  static bool isLoginSuccessful(String emailOrUsername, String password) {
    return loginUser(emailOrUsername, password) != null;
  }

  // Lấy thông tin người dùng
  static Map<String, dynamic>? getUserInfo(String emailOrUsername) {
    String? email;
    
    if (_registeredUsers.containsKey(emailOrUsername)) {
      email = emailOrUsername;
    } else {
      for (var entry in _registeredUsers.entries) {
        if (entry.value['username'] == emailOrUsername) {
          email = entry.key;
          break;
        }
      }
    }

    if (email != null) {
      var userData = _registeredUsers[email]!;
      return {
        'email': email,
        'fullName': userData['fullName'],
        'phone': userData['phone'],
        'username': userData['username'],
        'role': userData['role'],
      };
    }

    return null;
  }

  // Kiểm tra email đã tồn tại chưa
  static bool isEmailExists(String email) {
    return _registeredUsers.containsKey(email);
  }

  // Kiểm tra username đã tồn tại chưa
  static bool isUsernameExists(String username) {
    for (var user in _registeredUsers.values) {
      if (user['username'] == username) {
        return true;
      }
    }
    return false;
  }

  // Lấy danh sách tất cả người dùng (cho admin)
  static List<Map<String, dynamic>> getAllUsers() {
    List<Map<String, dynamic>> users = [];
    for (var entry in _registeredUsers.entries) {
      users.add({
        'email': entry.key,
        'fullName': entry.value['fullName'],
        'phone': entry.value['phone'],
        'username': entry.value['username'],
        'role': entry.value['role'],
      });
    }
    return users;
  }

  // Kiểm tra có phải admin không
  static bool isAdmin(String emailOrUsername) {
    var userInfo = getUserInfo(emailOrUsername);
    return userInfo != null && userInfo['role'] == 'admin';
  }

  // Lấy danh sách admin
  static List<Map<String, dynamic>> getAdminUsers() {
    return getAllUsers().where((user) => user['role'] == 'admin').toList();
  }

  // Lấy danh sách user thường
  static List<Map<String, dynamic>> getRegularUsers() {
    return getAllUsers().where((user) => user['role'] == 'user').toList();
  }

  // Kiểm tra tài khoản admin có thể đăng ký không (luôn false)
  static bool canRegisterAdmin() {
    return false; // Admin accounts are system provided only
  }
}
