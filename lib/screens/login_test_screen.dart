import 'package:flutter/material.dart';
import '../services/firebase_auth_service.dart';

class LoginTestScreen extends StatefulWidget {
  const LoginTestScreen({super.key});

  @override
  State<LoginTestScreen> createState() => _LoginTestScreenState();
}

class _LoginTestScreenState extends State<LoginTestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String _result = '';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Đăng Nhập'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Test Đăng Nhập',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email hoặc Tên đăng nhập',
                          hintText: 'Nhập email hoặc username',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Vui lòng nhập email hoặc tên đăng nhập';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Mật khẩu',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Vui lòng nhập mật khẩu';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _testLogin,
                          child: _isLoading
                              ? const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                    SizedBox(width: 8),
                                    Text('Đang test...'),
                                  ],
                                )
                              : const Text('Test Đăng Nhập'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              if (_result.isNotEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kết Quả:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _result,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              
              const SizedBox(height: 16),
              
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tài Khoản Test:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text('Email: test@example.com'),
                      const Text('Username: testuser'),
                      const Text('Password: 123456'),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () {
                          _emailController.text = 'testuser';
                          _passwordController.text = '123456';
                        },
                        child: const Text('Điền thông tin test'),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Test Functions:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _testEmailExists,
                              child: const Text('Test Email Exists'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _testUsernameExists,
                              child: const Text('Test Username Exists'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _testFindEmailByUsername,
                          child: const Text('Test Find Email By Username'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _testLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _result = '';
      });

      try {
        final emailOrUsername = _emailController.text.trim();
        final password = _passwordController.text.trim();
        
        var result = await FirebaseAuthService.signIn(
          emailOrUsername: emailOrUsername,
          password: password,
        );
        
        if (result != null && result['success'] == true) {
          Map<String, dynamic> userData = result['userData'];
          setState(() {
            _result = 'Đăng nhập thành công!\n'
                'Email: ${userData['email']}\n'
                'Username: ${userData['username']}\n'
                'Full Name: ${userData['fullName']}\n'
                'Role: ${userData['role']}';
          });
        } else {
          setState(() {
            _result = 'Đăng nhập thất bại: ${result?['error'] ?? 'Lỗi không xác định'}';
          });
        }
      } catch (e) {
        setState(() {
          _result = 'Lỗi: $e';
        });
      }
      
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _testEmailExists() async {
    try {
      bool exists = await FirebaseAuthService.isEmailExists('test@example.com');
      setState(() {
        _result = 'Email test@example.com exists: $exists';
      });
    } catch (e) {
      setState(() {
        _result = 'Lỗi test email exists: $e';
      });
    }
  }

  void _testUsernameExists() async {
    try {
      bool exists = await FirebaseAuthService.isUsernameExists('testuser');
      setState(() {
        _result = 'Username testuser exists: $exists';
      });
    } catch (e) {
      setState(() {
        _result = 'Lỗi test username exists: $e';
      });
    }
  }

  void _testFindEmailByUsername() async {
    try {
      String? email = await FirebaseAuthService.findEmailByUsername('testuser');
      setState(() {
        _result = 'Email for username testuser: ${email ?? 'Not found'}';
      });
    } catch (e) {
      setState(() {
        _result = 'Lỗi test find email by username: $e';
      });
    }
  }
}


