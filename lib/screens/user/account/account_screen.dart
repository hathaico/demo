import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import '../../../models/models.dart';
import '../../../services/firebase_auth_service.dart';
import '../../../services/firebase_user_service.dart';
import '../../../services/firebase_order_service.dart';
import '../wishlist/wishlist_screen.dart';
import '../auth/login_screen.dart';
import '../orders/orders_screen.dart';
import 'addresses_screen.dart';
import 'user_settings_screen.dart';
import '../support/user_support_screen.dart';
import '../help/user_help_screen.dart';
import '../notifications/notifications_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  static const String _defaultSeenOrdersKey = 'account_seen_orders_default';
  User? _currentUser;
  List<Order> _orders = [];
  StreamSubscription? _authSub;
  StreamSubscription<List<Order>>? _ordersSub;
  StreamSubscription<Order>? _orderCreatedSub;
  String _seenOrdersKey = _defaultSeenOrdersKey;
  Set<String> _seenOrderIds = <String>{};
  int _unseenOrderCount = 0;

  String _prefKeyForUserId(String? userId) {
    final String fallbackId = FirebaseAuthService.currentUser?.uid ?? '';
    final String effective =
        ((userId?.isNotEmpty ?? false) ? userId! : fallbackId).trim();
    if (effective.isEmpty || effective == 'default') {
      return _defaultSeenOrdersKey;
    }
    return 'account_seen_orders_$effective';
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();

    // Reload user data when auth state changes
    _authSub = FirebaseAuthService.authStateChanges.listen((_) {
      _loadUserData();
    });

    // Orders stream subscription is started after we load user data so we
    // subscribe with the correct userId (avoids subscribing to an empty
    // Stream.value([]) if user wasn't signed in yet).

    // Listen for locally emitted created orders so we can show them immediately
    _orderCreatedSub = FirebaseOrderService.orderCreatedStream.listen((order) {
      // Only add if it belongs to current user and isn't already present
      if (!mounted) return;
      if (_currentUser == null) return;
      if (order.userId != _currentUser!.id) return;
      final exists = _orders.any((o) => o.id == order.id);
      if (!exists) {
        setState(() {
          _orders.insert(0, order);
          final Set<String> currentIds = _orders
              .map((o) => o.id)
              .where((id) => id.isNotEmpty)
              .toSet();
          final Set<String> filteredSeen = _seenOrderIds.intersection(
            currentIds,
          );
          _seenOrderIds = filteredSeen;
          _unseenOrderCount = currentIds.difference(filteredSeen).length;
        });
      }
    });
  }

  void _subscribeOrdersStream() {
    // Cancel any existing subscription
    _ordersSub?.cancel();

    // Start a fresh subscription (FirebaseOrderService returns an empty
    // stream if user is not signed in). We keep the latest orders in _orders.
    _ordersSub = FirebaseOrderService.getUserOrdersStream().listen((orders) {
      if (!mounted) return;
      final Set<String> currentIds = orders
          .map((o) => o.id)
          .where((id) => id.isNotEmpty)
          .toSet();
      final Set<String> filteredSeen = _seenOrderIds.intersection(currentIds);
      final int unseen = currentIds.difference(filteredSeen).length;
      setState(() {
        _orders = orders;
        _seenOrderIds = filteredSeen;
        _unseenOrderCount = unseen;
      });
    });
  }

  Future<void> _loadUserData() async {
    try {
      // Lấy thông tin người dùng hiện tại
      User? user = await FirebaseUserService.getCurrentUser();

      // Lấy đơn hàng của người dùng
      List<Order> orders = await FirebaseOrderService.getUserOrders();
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String prefKey = _prefKeyForUserId(
        user?.id ?? FirebaseAuthService.currentUser?.uid,
      );
      final Set<String> currentIds = orders
          .map((o) => o.id)
          .where((id) => id.isNotEmpty)
          .toSet();
      final List<String> storedList = prefs.getStringList(prefKey) ?? const [];
      final Set<String> storedSeen = storedList
          .where((id) => currentIds.contains(id))
          .toSet();
      final int unseen = currentIds.difference(storedSeen).length;

      final User normalizedUser =
          user ??
          User(
            id: 'default',
            fullName: 'Người dùng',
            email: 'user@example.com',
            phone: '',
            username: 'user',
            joinDate: DateTime.now(),
            totalOrders: 0,
            totalSpent: 0,
          );

      if (!mounted) return;

      setState(() {
        _currentUser = normalizedUser;
        _orders = orders.isNotEmpty ? orders : [];
        _seenOrdersKey = prefKey;
        _seenOrderIds = storedSeen;
        _unseenOrderCount = unseen;
      });

      await prefs.setStringList(prefKey, storedSeen.toList());
      // Consume any pending created orders that were emitted before this
      // screen subscribed. This ensures newly-created orders are visible
      // immediately even if the UI was created after order creation.
      final pending = FirebaseOrderService.consumePendingCreatedOrders();
      if (pending.isNotEmpty) {
        for (var o in pending) {
          if (o.userId == _currentUser?.id &&
              !_orders.any((x) => x.id == o.id)) {
            if (!mounted) break;
            setState(() {
              _orders.insert(0, o);
              final Set<String> ids = _orders
                  .map((order) => order.id)
                  .where((id) => id.isNotEmpty)
                  .toSet();
              final Set<String> filteredSeen = _seenOrderIds.intersection(ids);
              _seenOrderIds = filteredSeen;
              _unseenOrderCount = ids.difference(filteredSeen).length;
            });
          }
        }
      }
      // Ensure the orders stream is subscribed using the latest auth state.
      _subscribeOrdersStream();
    } catch (e) {
      // Fallback về dữ liệu mặc định
      if (!mounted) return;
      setState(() {
        _currentUser = User(
          id: 'default',
          fullName: 'Người dùng',
          email: 'user@example.com',
          phone: '',
          username: 'user',
          joinDate: DateTime.now(),
          totalOrders: 0,
          totalSpent: 0,
        );
        _orders = [];
        _seenOrdersKey = _defaultSeenOrdersKey;
        _seenOrderIds = <String>{};
        _unseenOrderCount = 0;
      });
      // If load failed, still attempt to (re)subscribe so UI can update on auth
      // changes.
      _subscribeOrdersStream();
    }
  }

  Future<void> _logout() async {
    try {
      await FirebaseAuthService.signOut();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    } catch (e) {
      // Fallback logout
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _ordersSub?.cancel();
    _orderCreatedSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: CustomScrollView(
        slivers: [
          // Profile header
          SliverAppBar(
            // add topPadding so gradient starts below status bar
            expandedHeight: 90 + topPadding,
            pinned: true,
            backgroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Padding(
                padding: EdgeInsets.only(top: topPadding),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.blue.shade400, Colors.pink.shade400],
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        15,
                        8,
                        15,
                        21,
                      ), // giảm padding
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 28,
                                backgroundColor: Colors.white.withOpacity(0.2),
                                child: Text(
                                  (_currentUser?.fullName ?? 'U')[0],
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _currentUser?.fullName ?? 'Người dùng',
                                      style: const TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      _currentUser?.email ??
                                          'email@example.com',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.white.withOpacity(0.9),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: _editProfile,
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Account stats
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
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
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      'Đơn hàng',
                      _orders.length.toString(),
                      Icons.shopping_bag,
                      Colors.blue,
                    ),
                  ),
                  Container(width: 1, height: 40, color: Colors.grey.shade200),
                  Expanded(
                    child: _buildStatItem(
                      'Tổng chi',
                      '${(_currentUser?.totalSpent ?? 0).toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}đ',
                      Icons.payments,
                      Colors.green,
                    ),
                  ),
                  Container(width: 1, height: 40, color: Colors.grey.shade200),
                  Expanded(
                    child: _buildStatItem(
                      'Thành viên',
                      '${DateTime.now().difference(_currentUser?.joinDate ?? DateTime.now()).inDays} ngày',
                      Icons.calendar_today,
                      Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Menu items
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
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
              child: Column(
                children: [
                  // Custom ListTile to show badge with number of orders
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.receipt_long,
                        color: Colors.blue,
                        size: 20,
                      ),
                    ),
                    title: const Text('Đơn hàng của tôi'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_unseenOrderCount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: Colors.red.shade600,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _unseenOrderCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        const Icon(Icons.arrow_forward_ios, size: 16),
                      ],
                    ),
                    onTap: _showOrders,
                  ),
                  _buildMenuItem(
                    'Danh sách yêu thích',
                    Icons.favorite,
                    Colors.red,
                    () => _showWishlist(),
                  ),
                  _buildMenuItem(
                    'Địa chỉ giao hàng',
                    Icons.location_on,
                    Colors.green,
                    () => _showAddresses(),
                  ),
                  _buildMenuItem(
                    'Thông báo',
                    Icons.notifications,
                    Colors.orange,
                    () => _showNotifications(),
                  ),
                  _buildMenuItem(
                    'Hỗ trợ',
                    Icons.support_agent,
                    Colors.purple,
                    () => _showSupport(),
                  ),
                  _buildMenuItem(
                    'Trợ giúp',
                    Icons.help,
                    Colors.teal,
                    () => _showHelp(),
                  ),
                  _buildMenuItem(
                    'Cài đặt',
                    Icons.settings,
                    Colors.grey,
                    () => _showSettings(),
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 20)),

          // Logout button
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout),
                  label: const Text('Đăng xuất'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildMenuItem(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  void _editProfile() {
    final fullNameController = TextEditingController(
      text: _currentUser?.fullName ?? '',
    );
    final phoneController = TextEditingController(
      text: _currentUser?.phone ?? '',
    );
    final usernameController = TextEditingController(
      text: _currentUser?.username ?? '',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Chỉnh sửa thông tin',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            TextField(
              decoration: const InputDecoration(
                labelText: 'Họ và tên',
                border: OutlineInputBorder(),
              ),
              controller: fullNameController,
            ),
            const SizedBox(height: 12),

            TextField(
              decoration: const InputDecoration(
                labelText: 'Số điện thoại',
                border: OutlineInputBorder(),
              ),
              controller: phoneController,
            ),
            const SizedBox(height: 12),

            TextField(
              decoration: const InputDecoration(
                labelText: 'Tên đăng nhập',
                border: OutlineInputBorder(),
              ),
              controller: usernameController,
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  try {
                    Map<String, dynamic> result =
                        await FirebaseUserService.updateUserProfile(
                          fullName: fullNameController.text.trim(),
                          phone: phoneController.text.trim(),
                          username: usernameController.text.trim(),
                        );

                    Navigator.pop(context);

                    if (result['success'] == true) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Cập nhật thông tin thành công'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      // Reload user data
                      _loadUserData();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Lỗi: ${result['error']}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } catch (e) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Lỗi: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: const Text('Lưu thay đổi'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _markOrdersAsSeen() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final Set<String> ids = _orders
        .map((o) => o.id)
        .where((id) => id.isNotEmpty)
        .toSet();
    await prefs.setStringList(_seenOrdersKey, ids.toList());
    if (!mounted) return;
    setState(() {
      _seenOrderIds = ids;
      _unseenOrderCount = 0;
    });
  }

  void _showOrders() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const OrdersScreen()),
    ).then((_) {
      _markOrdersAsSeen();
    });
  }

  void _showWishlist() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const WishlistScreen()),
    );
  }

  void _showAddresses() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddressesScreen()),
    );
  }

  void _showNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NotificationsScreen()),
    );
  }

  void _showSupport() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const UserSupportScreen()),
    );
  }

  void _showHelp() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const UserHelpScreen()),
    );
  }

  void _showSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const UserSettingsScreen()),
    );
  }
}
