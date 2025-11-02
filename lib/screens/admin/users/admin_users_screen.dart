import 'package:flutter/material.dart';
import '../../../models/models.dart';
import '../../../services/admin_data_service.dart';
import 'dart:async';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final List<User> _users = [];
  StreamSubscription<List<User>>? _usersSub;
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'Tất cả';

  final List<String> _filters = [
    'Tất cả',
    'Hoạt động',
    'Bị khóa',
    'Mới đăng ký',
  ];

  @override
  void dispose() {
    _usersSub?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Subscribe to users stream from Firestore so admin UI shows existing users
    _usersSub = AdminDataService.usersStream().listen((users) {
      setState(() {
        _users.clear();
        _users.addAll(users);
      });
    });
    // Ensure admin initialization meta exists
    AdminDataService.ensureAdminInitialized();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Column(
        children: [
          // Search and filter
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm người dùng...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (value) => setState(() {}),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _filters.length,
                    itemBuilder: (context, index) {
                      final filter = _filters[index];
                      final isSelected = _selectedFilter == filter;

                      return Container(
                        margin: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(
                            filter,
                            style: TextStyle(
                              color: isSelected
                                  ? const Color(0xFF0B57D0)
                                  : Colors.grey.shade800,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                            ),
                          ),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedFilter = filter;
                            });
                          },
                          backgroundColor: isSelected
                              ? Colors.white
                              : const Color(0xFFF2F2F2),
                          selectedColor: const Color(0xFFD6E8FF),
                          showCheckmark: true,
                          checkmarkColor: const Color(0xFF0B57D0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: isSelected
                                  ? const Color(0xFF0B57D0)
                                  : Colors.black,
                              width: 1.2,
                            ),
                          ),
                          side: BorderSide.none,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Users list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _getFilteredUsers().length,
              itemBuilder: (context, index) {
                final user = _getFilteredUsers()[index];
                return _buildUserCard(user);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addUser,
        backgroundColor: Colors.red.shade600,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildUserCard(User user) {
    final displayName = user.fullName.trim().isNotEmpty
        ? user.fullName.trim()
        : (user.username.trim().isNotEmpty
              ? user.username.trim()
              : user.email.trim());
    final String initial = displayName.isNotEmpty
        ? displayName[0].toUpperCase()
        : '?';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: user.isActive ? Colors.green : Colors.red,
          child: Text(
            initial,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          displayName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.email),
            const SizedBox(height: 4),
            Row(
              children: [
                Flexible(
                  child: Text(
                    '${user.totalOrders} đơn hàng',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 16),
                Flexible(
                  child: Text(
                    '${user.totalSpent.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}đ',
                    style: TextStyle(
                      color: Colors.blue.shade600,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'view':
                _viewUserDetails(user);
                break;
              case 'edit':
                _editUser(user);
                break;
              case 'block':
                _toggleUserStatus(user);
                break;
              case 'orders':
                _viewUserOrders(user);
                break;
              case 'delete':
                _deleteUser(user);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'view',
              child: ListTile(
                leading: Icon(Icons.visibility),
                title: Text('Xem chi tiết'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'edit',
              child: ListTile(
                leading: Icon(Icons.edit),
                title: Text('Chỉnh sửa'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'orders',
              child: ListTile(
                leading: Icon(Icons.shopping_cart),
                title: Text('Đơn hàng'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            PopupMenuItem(
              value: 'block',
              child: ListTile(
                leading: Icon(
                  user.isActive ? Icons.block : Icons.check_circle,
                  color: user.isActive ? Colors.red : Colors.green,
                ),
                title: Text(
                  user.isActive ? 'Khóa tài khoản' : 'Mở khóa',
                  style: TextStyle(
                    color: user.isActive ? Colors.red : Colors.green,
                  ),
                ),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text(
                  'Xóa người dùng',
                  style: TextStyle(color: Colors.red),
                ),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<User> _getFilteredUsers() {
    return _users.where((user) {
      final searchQuery = _searchController.text.toLowerCase();
      final matchesSearch =
          user.fullName.toLowerCase().contains(searchQuery) ||
          user.email.toLowerCase().contains(searchQuery) ||
          user.phone.contains(searchQuery);

      bool matchesFilter = true;
      switch (_selectedFilter) {
        case 'Hoạt động':
          matchesFilter = user.isActive;
          break;
        case 'Bị khóa':
          matchesFilter = !user.isActive;
          break;
        case 'Mới đăng ký':
          matchesFilter = DateTime.now().difference(user.joinDate).inDays <= 7;
          break;
      }

      return matchesSearch && matchesFilter;
    }).toList();
  }

  void _addUser() {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final usernameCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Thêm người dùng mới',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Họ và tên',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: emailCtrl,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: phoneCtrl,
                decoration: const InputDecoration(
                  labelText: 'Số điện thoại',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: usernameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Tên đăng nhập',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('Hủy'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final name = nameCtrl.text.trim();
                        final email = emailCtrl.text.trim();
                        final phone = phoneCtrl.text.trim();
                        final usernameInput = usernameCtrl.text.trim();

                        String? error;
                        final emailRegex = RegExp(
                          r"^[^@\s]+@[^@\s]+\.[^@\s]+$",
                        );
                        if (name.isEmpty) {
                          error = 'Vui lòng nhập họ và tên';
                        } else if (email.isEmpty ||
                            !emailRegex.hasMatch(email)) {
                          error = 'Email không hợp lệ';
                        } else if (phone.isEmpty || phone.length < 9) {
                          error = 'Số điện thoại không hợp lệ';
                        }

                        if (error != null) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text(error)));
                          return;
                        }

                        final resolvedUsername = usernameInput.isEmpty
                            ? (email.contains('@')
                                  ? email.split('@').first
                                  : email)
                            : usernameInput;

                        final data = {
                          'fullName': name,
                          'email': email,
                          'phone': phone,
                          'username': resolvedUsername,
                          'isActive': true,
                          'totalOrders': 0,
                          'totalSpent': 0,
                        };
                        Navigator.pop(context);
                        try {
                          await AdminDataService.addUser(data);
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Thêm người dùng thành công'),
                            ),
                          );
                        } catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Lỗi thêm người dùng: $e')),
                          );
                        }
                      },
                      child: const Text('Thêm'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _viewUserDetails(User user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Chi tiết người dùng'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Họ tên: ${user.fullName}'),
              Text('Email: ${user.email}'),
              Text('Số điện thoại: ${user.phone}'),
              Text('Tên đăng nhập: ${user.username}'),
              Text(
                'Ngày tham gia: ${user.joinDate.day}/${user.joinDate.month}/${user.joinDate.year}',
              ),
              Text('Trạng thái: ${user.isActive ? 'Hoạt động' : 'Bị khóa'}'),
              Text('Tổng đơn hàng: ${user.totalOrders}'),
              Text(
                'Tổng chi tiêu: ${user.totalSpent.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}đ',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _editUser(User user) {
    final nameCtrl = TextEditingController(text: user.fullName);
    final emailCtrl = TextEditingController(text: user.email);
    final phoneCtrl = TextEditingController(text: user.phone);
    final usernameCtrl = TextEditingController(text: user.username);
    final passwordCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        bool obscurePassword = true;
        return StatefulBuilder(
          builder: (context, modalSetState) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Chỉnh sửa thông tin người dùng',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Họ và tên',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: emailCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: phoneCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Số điện thoại',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: usernameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Tên đăng nhập',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F2FF),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE0D5FF)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Đổi mật khẩu',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.deepPurple.shade400,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const SizedBox(height: 10),
                        TextField(
                          controller: passwordCtrl,
                          obscureText: obscurePassword,
                          decoration: InputDecoration(
                            hintText: 'Mật khẩu mới',
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: Color(0xFFE0D5FF),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: Colors.deepPurple.shade300,
                                width: 1.5,
                              ),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                obscurePassword
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () {
                                modalSetState(() {
                                  obscurePassword = !obscurePassword;
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Hủy'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            final name = nameCtrl.text.trim();
                            final email = emailCtrl.text.trim();
                            final phone = phoneCtrl.text.trim();
                            final username = usernameCtrl.text.trim();
                            final newPassword = passwordCtrl.text.trim();

                            String? error;
                            final emailRegex = RegExp(
                              r"^[^@\s]+@[^@\s]+\.[^@\s]+$",
                            );
                            if (name.isEmpty) {
                              error = 'Vui lòng nhập họ và tên';
                            } else if (email.isEmpty ||
                                !emailRegex.hasMatch(email)) {
                              error = 'Email không hợp lệ';
                            } else if (phone.isEmpty || phone.length < 9) {
                              error = 'Số điện thoại không hợp lệ';
                            } else if (newPassword.isNotEmpty &&
                                newPassword.length < 6) {
                              error = 'Mật khẩu phải có ít nhất 6 ký tự';
                            }

                            if (error != null) {
                              ScaffoldMessenger.of(
                                context,
                              ).showSnackBar(SnackBar(content: Text(error)));
                              return;
                            }

                            final data = {
                              'fullName': name,
                              'email': email,
                              'phone': phone,
                              'username': username,
                            };

                            Navigator.pop(context);
                            try {
                              await AdminDataService.updateUser(
                                user.id,
                                data,
                                newPassword: newPassword.isNotEmpty
                                    ? newPassword
                                    : null,
                              );
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Cập nhật thông tin thành công',
                                  ),
                                ),
                              );
                            } catch (e) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Lỗi cập nhật: $e')),
                              );
                            }
                          },
                          child: const Text('Cập nhật'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _toggleUserStatus(User user) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(user.isActive ? 'Khóa tài khoản' : 'Mở khóa tài khoản'),
        content: Text(
          user.isActive
              ? 'Bạn có chắc chắn muốn khóa tài khoản của ${user.fullName}?'
              : 'Bạn có chắc chắn muốn mở khóa tài khoản của ${user.fullName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await AdminDataService.updateUserStatus(
                  user.id,
                  !user.isActive,
                );
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      user.isActive
                          ? 'Đã khóa tài khoản'
                          : 'Đã mở khóa tài khoản',
                    ),
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Lỗi thay đổi trạng thái: $e')),
                );
              }
            },
            child: Text(
              user.isActive ? 'Khóa' : 'Mở khóa',
              style: TextStyle(
                color: user.isActive ? Colors.red : Colors.green,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _viewUserOrders(User user) {
    showDialog<void>(
      context: context,
      builder: (context) => FutureBuilder<List<Order>>(
        future: AdminDataService.getOrdersForUser(user.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AlertDialog(
              content: SizedBox(
                height: 80,
                child: Center(child: CircularProgressIndicator()),
              ),
            );
          }
          if (snapshot.hasError) {
            return AlertDialog(
              title: const Text('Lỗi'),
              content: Text('Không thể tải đơn hàng: ${snapshot.error}'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Đóng'),
                ),
              ],
            );
          }

          final orders = snapshot.data ?? <Order>[];
          return AlertDialog(
            title: Text('Đơn hàng của ${user.fullName} (${orders.length})'),
            content: SizedBox(
              width: double.maxFinite,
              child: orders.isEmpty
                  ? const Text('Không có đơn hàng')
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: orders.length,
                      itemBuilder: (context, i) {
                        final o = orders[i];
                        return ListTile(
                          title: Text('#${o.id} - ${o.status}'),
                          subtitle: Text(
                            '${o.totalAmount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}đ',
                          ),
                        );
                      },
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Đóng'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _deleteUser(User user) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa người dùng'),
        content: Text(
          'Bạn có chắc chắn muốn xóa người dùng "${user.fullName.isNotEmpty ? user.fullName : user.email}"?\n'
          'Thao tác này chỉ xóa hồ sơ trong Firestore và không xóa tài khoản Firebase Auth (nếu có).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await AdminDataService.deleteUser(user.id);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã xóa người dùng'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Lỗi xóa người dùng: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
