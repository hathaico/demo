import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import '../user_main_screen.dart';
import 'register_screen.dart';
import '../../../services/user_service.dart';
import '../../../services/firebase_auth_service.dart';
import '../../../services/credential_storage_service.dart';
import '../../admin/admin_main_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _isLoading = false;
  bool _isSocialLoading = false;
  String? _activeSocialProvider;
  bool _isBiometricLoading = false;

  @override
  void initState() {
    super.initState();
    _loadStoredCredentials();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadStoredCredentials() async {
    final stored = await CredentialStorageService.loadCredentials();
    if (!mounted || stored == null) {
      return;
    }

    setState(() {
      _rememberMe = true;
      _emailController.text = stored['identifier'] ?? '';
      _passwordController.text = stored['password'] ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),

                // Logo và tiêu đề
                Center(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          Icons.style,
                          size: 60,
                          color: Colors.blue.shade600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Chào mừng trở lại!',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Đăng nhập để khám phá bộ sưu tập nón thời trang',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // Form đăng nhập
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.text,
                  decoration: const InputDecoration(
                    labelText: 'Email hoặc Tên đăng nhập',
                    prefixIcon: Icon(Icons.person_outline),
                    hintText: 'Nhập email hoặc tên đăng nhập của bạn',
                    helperText:
                        'Bạn có thể đăng nhập bằng email hoặc tên đăng nhập',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập email hoặc tên đăng nhập';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  enableSuggestions: false,
                  autocorrect: false,
                  decoration: InputDecoration(
                    labelText: 'Mật khẩu',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: _obscurePassword ? Colors.grey : Colors.blue,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                      tooltip: _obscurePassword
                          ? 'Hiện mật khẩu'
                          : 'Ẩn mật khẩu',
                    ),
                    hintText: 'Nhập mật khẩu của bạn',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập mật khẩu';
                    }
                    if (value.length < 6) {
                      return 'Mật khẩu phải có ít nhất 6 ký tự';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Nhớ đăng nhập và quên mật khẩu
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Checkbox(
                          value: _rememberMe,
                          onChanged: (value) {
                            setState(() {
                              _rememberMe = value ?? false;
                            });
                          },
                        ),
                        const Text('Nhớ đăng nhập'),
                      ],
                    ),
                    TextButton(
                      onPressed:
                          _isLoading || _isSocialLoading || _isBiometricLoading
                          ? null
                          : _showForgotPasswordDialog,
                      child: Text(
                        'Quên mật khẩu?',
                        style: TextStyle(color: Colors.blue.shade600),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Nút đăng nhập
                ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                            Text('Đang đăng nhập...'),
                          ],
                        )
                      : const Text(
                          'Đăng Nhập',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),

                const SizedBox(height: 20),

                // Đăng nhập bằng sinh trắc học
                OutlinedButton.icon(
                  onPressed:
                      _isBiometricLoading || _isLoading || _isSocialLoading
                      ? null
                      : _loginWithBiometrics,
                  icon: const Icon(Icons.fingerprint),
                  label: _isBiometricLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Đăng nhập bằng vân tay'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),

                const SizedBox(height: 30),

                // Đăng nhập bằng mạng xã hội
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed:
                            (_isSocialLoading ||
                                _isLoading ||
                                _isBiometricLoading)
                            ? null
                            : _loginWithGoogle,
                        icon: const Icon(Icons.g_mobiledata, color: Colors.red),
                        label:
                            _isSocialLoading &&
                                _activeSocialProvider == 'google'
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Google'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed:
                            (_isSocialLoading ||
                                _isLoading ||
                                _isBiometricLoading)
                            ? null
                            : _loginWithFacebook,
                        icon: const Icon(Icons.facebook, color: Colors.blue),
                        label:
                            _isSocialLoading &&
                                _activeSocialProvider == 'facebook'
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Facebook'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Chuyển đến đăng ký
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Chưa có tài khoản? '),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RegisterScreen(),
                          ),
                        );
                      },
                      child: Text(
                        'Đăng ký ngay',
                        style: TextStyle(
                          color: Colors.blue.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final String emailOrUsername = _emailController.text.trim();
    final String password = _passwordController.text.trim();

    final firebaseResult = await FirebaseAuthService.signIn(
      emailOrUsername: emailOrUsername,
      password: password,
    );

    if (firebaseResult != null && firebaseResult['success'] == true) {
      await _handleFirebaseLoginSuccess(
        firebaseResult,
        successMessage: 'Đăng nhập thành công! Chào mừng ',
        shouldRemember: _rememberMe,
        clearStoredCredentials: !_rememberMe,
        identifier: emailOrUsername,
        password: password,
      );
    } else {
      final loginResult = UserService.loginUser(emailOrUsername, password);

      if (loginResult != null) {
        HapticFeedback.lightImpact();

        if (_rememberMe) {
          await CredentialStorageService.saveCredentials(
            identifier: emailOrUsername,
            password: password,
          );
        } else {
          await CredentialStorageService.clearCredentials();
        }

        final String role = loginResult['role'];
        final String fullName = loginResult['fullName'];

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Đăng nhập thành công! (Demo mode) Chào mừng $fullName',
              ),
              backgroundColor: Colors.orange,
            ),
          );

          if (role == 'admin') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const AdminMainScreen()),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const UserMainScreen()),
            );
          }
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              firebaseResult?['error'] ??
                  'Email/tên đăng nhập hoặc mật khẩu không đúng',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleFirebaseLoginSuccess(
    Map<String, dynamic> firebaseResult, {
    required String successMessage,
    bool shouldRemember = false,
    bool clearStoredCredentials = true,
    String? identifier,
    String? password,
  }) async {
    HapticFeedback.lightImpact();

    final Map<String, dynamic> userData = Map<String, dynamic>.from(
      firebaseResult['userData'] as Map,
    );
    final String role = userData['role'] ?? 'user';
    final String fullName = userData['fullName'] ?? 'Người dùng';

    if (shouldRemember && identifier != null && password != null) {
      await CredentialStorageService.saveCredentials(
        identifier: identifier,
        password: password,
      );
    } else if (clearStoredCredentials) {
      await CredentialStorageService.clearCredentials();
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$successMessage$fullName'),
        backgroundColor: Colors.green,
      ),
    );

    if (role == 'admin') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AdminMainScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const UserMainScreen()),
      );
    }
  }

  Future<void> _showForgotPasswordDialog() async {
    final TextEditingController emailController = TextEditingController(
      text: _emailController.text.trim(),
    );

    final bool? shouldSend = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Quên mật khẩu'),
          content: TextField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email đăng ký',
              hintText: 'Nhập email để nhận liên kết đặt lại',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Gửi'),
            ),
          ],
        );
      },
    );

    if (shouldSend != true) {
      emailController.dispose();
      return;
    }

    final String email = emailController.text.trim();
    emailController.dispose();

    if (email.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập email hợp lệ')),
      );
      return;
    }

    final result = await FirebaseAuthService.sendPasswordResetEmail(email);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result['success'] == true
              ? 'Đã gửi email đặt lại mật khẩu đến $email'
              : (result['error'] as String? ?? 'Gửi email thất bại'),
        ),
        backgroundColor: result['success'] == true ? Colors.green : Colors.red,
      ),
    );
  }

  Future<void> _loginWithGoogle() async {
    setState(() {
      _isSocialLoading = true;
      _activeSocialProvider = 'google';
    });

    final result = await FirebaseAuthService.signInWithGoogle();

    if (!mounted) {
      setState(() {
        _isSocialLoading = false;
        _activeSocialProvider = null;
      });
      return;
    }

    if (result['success'] == true) {
      await _handleFirebaseLoginSuccess(
        result,
        successMessage: 'Đăng nhập Google thành công! Chào mừng ',
        shouldRemember: false,
        clearStoredCredentials: false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['error'] as String? ?? 'Không thể đăng nhập bằng Google',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() {
      _isSocialLoading = false;
      _activeSocialProvider = null;
    });
  }

  Future<void> _loginWithFacebook() async {
    setState(() {
      _isSocialLoading = true;
      _activeSocialProvider = 'facebook';
    });

    final result = await FirebaseAuthService.signInWithFacebook();

    if (!mounted) {
      setState(() {
        _isSocialLoading = false;
        _activeSocialProvider = null;
      });
      return;
    }

    if (result['success'] == true) {
      await _handleFirebaseLoginSuccess(
        result,
        successMessage: 'Đăng nhập Facebook thành công! Chào mừng ',
        shouldRemember: false,
        clearStoredCredentials: false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['error'] as String? ?? 'Không thể đăng nhập bằng Facebook',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() {
      _isSocialLoading = false;
      _activeSocialProvider = null;
    });
  }

  Future<void> _loginWithBiometrics() async {
    final stored = await CredentialStorageService.loadCredentials();
    if (stored == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng đăng nhập và chọn "Nhớ đăng nhập" trước'),
        ),
      );
      return;
    }

    setState(() {
      _isBiometricLoading = true;
    });

    final LocalAuthentication localAuth = LocalAuthentication();

    try {
      final bool canCheck =
          await localAuth.canCheckBiometrics ||
          await localAuth.isDeviceSupported();
      if (!canCheck) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thiết bị không hỗ trợ sinh trắc học')),
        );
        return;
      }

      final bool authenticated = await localAuth.authenticate(
        localizedReason: 'Xác thực để đăng nhập nhanh',
        options: const AuthenticationOptions(biometricOnly: true),
      );

      if (!authenticated) {
        return;
      }

      if (!mounted) return;
      setState(() {
        _rememberMe = true;
        _emailController.text = stored['identifier'] ?? '';
        _passwordController.text = stored['password'] ?? '';
      });

      await _login();
    } on PlatformException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể sử dụng sinh trắc học: ${e.message}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isBiometricLoading = false;
        });
      }
    }
  }
}
