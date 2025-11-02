import 'package:flutter/material.dart';
import '../user/auth/login_screen.dart';
import 'dashboard/dashboard_screen.dart';
import 'products/admin_products_screen.dart';
import 'orders/admin_orders_screen.dart';
import 'users/admin_users_screen.dart';
import 'reports/admin_reports_screen.dart';
import 'settings/admin_settings_screen.dart';
import 'support/admin_support_screen.dart';
import 'help/admin_help_screen.dart';
import '../../widgets/admin_nav_bar.dart';

class AdminMainScreen extends StatefulWidget {
  const AdminMainScreen({super.key});

  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
  int _selectedIndex = 0;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      DashboardScreen(
        onViewAllOrders: () => _selectTab(2),
        onViewAllProducts: () => _selectTab(1),
      ),
      const AdminProductsScreen(),
      const AdminOrdersScreen(),
      const AdminUsersScreen(),
      const AdminReportsScreen(),
      const AdminSettingsScreen(),
    ];
  }

  final List<String> _titles = [
    'Bảng Điều Khiển',
    'Sản Phẩm',
    'Đơn Hàng',
    'Người Dùng',
    'Báo Cáo',
    'Cài Đặt',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        foregroundColor: const Color.fromARGB(255, 0, 0, 0),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'profile':
                  _showProfileSheet();
                  break;
                case 'logout':
                  _logout();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'profile',
                child: ListTile(
                  leading: Icon(Icons.person),
                  title: Text('Hồ sơ'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: ListTile(
                  leading: Icon(Icons.logout),
                  title: Text('Đăng xuất'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Header
            DrawerHeader(
              decoration: BoxDecoration(
                color: const Color.fromRGBO(255, 255, 255, 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.grey.withOpacity(0.2),
                    child: const Icon(
                      Icons.admin_panel_settings,
                      size: 30,
                      color: Color.fromRGBO(0, 0, 0, 1),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Quản Trị HatStyle',
                    style: TextStyle(
                      color: Color.fromARGB(255, 8, 8, 8),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'admin@hatstyle.com',
                    style: TextStyle(
                      color: Colors.grey.shade700.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            // Menu items
            _buildDrawerItem('Bảng điều khiển', Icons.dashboard, 0),
            _buildDrawerItem('Sản phẩm', Icons.inventory, 1),
            _buildDrawerItem('Đơn hàng', Icons.shopping_cart, 2),
            _buildDrawerItem('Người dùng', Icons.people, 3),
            _buildDrawerItem('Báo cáo', Icons.analytics, 4),
            _buildDrawerItem('Cài đặt', Icons.settings, 5),

            const Divider(),

            // Additional menu items
            ListTile(
              leading: const Icon(Icons.support_agent),
              title: const Text('Hỗ trợ'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdminSupportScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.help),
              title: const Text('Trợ giúp'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdminHelpScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: _selectedIndex < 4
          ? Theme(
              data: Theme.of(context).copyWith(
                textTheme: Theme.of(context).textTheme.copyWith(
                  bodySmall: const TextStyle(fontSize: 13),
                  bodyMedium: const TextStyle(fontSize: 13),
                ),
              ),
              child: AdminNavBar(
                currentIndex: _selectedIndex,
                onTap: (index) {
                  _selectTab(index);
                },
              ),
            )
          : null, // Ẩn bottom navigation khi ở Reports hoặc Settings
    );
  }

  Widget _buildDrawerItem(String title, IconData icon, int index) {
    return ListTile(
      leading: Icon(
        icon,
        color: _selectedIndex == index
            ? Colors.red.shade600
            : Colors.grey.shade700,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: _selectedIndex == index
              ? Colors.red.shade600
              : Colors.grey.shade700,
          fontWeight: _selectedIndex == index
              ? FontWeight.bold
              : FontWeight.normal,
        ),
      ),
      selected: _selectedIndex == index,
      selectedTileColor: Colors.red.shade50,
      onTap: () {
        _selectTab(index);
        Navigator.pop(context);
      },
    );
  }

  void _selectTab(int index) {
    if (_selectedIndex == index) return;
    setState(() {
      _selectedIndex = index;
    });
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }

  void _showProfileSheet() {
    const String displayName = 'Quản trị HatStyle';
    const String email = 'admin@hatstyle.com';
    const String role = 'Quản trị viên cấp cao';
    const String phone = '+84 906 000 888';

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          top: 24,
          left: 24,
          right: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.red.shade100,
                  child: const Icon(
                    Icons.admin_panel_settings,
                    color: Colors.red,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        displayName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        role,
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(height: 1),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.email_outlined),
              title: const Text('Email'),
              subtitle: const Text(email),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.phone_outlined),
              title: const Text('Số điện thoại'),
              subtitle: const Text(phone),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.security_outlined),
              title: const Text('Quyền hạn'),
              subtitle: const Text(
                'Toàn quyền quản trị hệ thống, sản phẩm, đơn hàng và người dùng.',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.settings_outlined),
                    label: const Text('Cài đặt tài khoản'),
                    onPressed: () {
                      Navigator.pop(context);
                      _selectTab(5);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.logout, size: 18),
                    label: const Text('Đăng xuất'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      _logout();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
