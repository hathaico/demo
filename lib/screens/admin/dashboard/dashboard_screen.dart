import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../../models/models.dart';
import '../../../services/admin_data_service.dart';
import '../../../services/analytics_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    this.onViewAllOrders,
    this.onViewAllProducts,
  });

  final VoidCallback? onViewAllOrders;
  final VoidCallback? onViewAllProducts;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<SalesReport> _salesData = const [];
  List<ProductStats> _productStats = const [];
  List<Order> _recentOrders = const [];
  List<User> _users = const [];
  List<Order> _allOrders = const [];
  bool _isLoading = true;
  String _selectedRange = '7 ngày';
  StreamSubscription<List<Order>>? _ordersSub;
  StreamSubscription<List<User>>? _usersSub;
  bool _ordersLoaded = false;

  @override
  void initState() {
    super.initState();
    _initializeDataStreams();
  }

  @override
  void dispose() {
    _ordersSub?.cancel();
    _usersSub?.cancel();
    super.dispose();
  }

  Future<void> _initializeDataStreams() async {
    setState(() {
      _isLoading = true;
    });

    await _ordersSub?.cancel();
    await _usersSub?.cancel();
    _ordersSub = null;
    _usersSub = null;
    _ordersLoaded = false;

    try {
      await AdminDataService.ensureAdminInitialized();

      _ordersSub = AdminDataService.ordersStream().listen(
        (orders) {
          _allOrders = orders;
          _ordersLoaded = true;
          _recalculateAnalytics();
        },
        onError: (Object error, StackTrace stackTrace) =>
            _handleDataError(error, stackTrace),
      );

      _usersSub = AdminDataService.usersStream().listen(
        (users) {
          _users = users;
          _recalculateAnalytics();
        },
        onError: (Object error, StackTrace stackTrace) =>
            _handleDataError(error, stackTrace),
      );
    } catch (e, stackTrace) {
      _handleDataError(e, stackTrace);
    }
  }

  void _handleDataError(Object error, StackTrace stackTrace) {
    debugPrint('Dashboard data stream failed: $error');
    debugPrintStack(stackTrace: stackTrace);
    if (!mounted) {
      return;
    }

    setState(() {
      _allOrders = const [];
      _recentOrders = const [];
      _salesData = const [];
      _productStats = const [];
      _isLoading = false;
      _ordersLoaded = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Không thể tải dữ liệu dashboard. Vui lòng thử lại.'),
      ),
    );
  }

  void _recalculateAnalytics() {
    if (!mounted) {
      return;
    }

    final int rangeDays = _rangeToDays(_selectedRange);
    final DateTime now = DateTime.now();
    final DateTime start = now.subtract(
      Duration(days: math.max(rangeDays - 1, 0)),
    );

    final List<Order> orders = _allOrders;

    final salesReports = AnalyticsService.buildSalesReports(
      orders: orders,
      users: _users,
      days: rangeDays,
    );

    final productStats = AnalyticsService.buildProductStats(
      orders: orders,
      start: start,
      end: now,
    );

    setState(() {
      _salesData = salesReports;
      _productStats = productStats;
      _recentOrders = orders.take(50).toList();
      _isLoading = !_ordersLoaded;
    });
  }

  int _rangeToDays(String range) {
    switch (range) {
      case '30 ngày':
        return 30;
      case '90 ngày':
        return 90;
      case '1 năm':
        return 365;
      case '7 ngày':
      default:
        return 7;
    }
  }

  @override
  Widget build(BuildContext context) {
    final todayRevenue = _salesData.isNotEmpty ? _salesData.last.revenue : 0.0;
    final todayOrders = _salesData.isNotEmpty ? _salesData.last.orderCount : 0;
    final totalUsers = _users.length;
    final pendingOrders = _allOrders
        .where((o) => o.status == 'Đang xử lý')
        .length;

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2196F3), Color(0xFF21CBF3)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Chào mừng trở lại!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Tổng quan hệ thống HatStyle - ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Quick stats
            const Text(
              'Thống kê nhanh',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            LayoutBuilder(
              builder: (context, constraints) {
                int crossAxisCount = 2;
                if (constraints.maxWidth > 600) {
                  crossAxisCount = 3;
                }
                if (constraints.maxWidth > 900) {
                  crossAxisCount = 4;
                }

                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: crossAxisCount,
                  childAspectRatio: 1.5,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 11,
                  children: [
                    _buildStatCard(
                      'Doanh thu hôm nay',
                      '${todayRevenue.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}đ',
                      Icons.attach_money,
                      Colors.green,
                    ),
                    _buildStatCard(
                      'Đơn hàng hôm nay',
                      todayOrders.toString(),
                      Icons.shopping_cart,
                      Colors.blue,
                    ),
                    _buildStatCard(
                      'Tổng người dùng',
                      totalUsers.toString(),
                      Icons.people,
                      Colors.orange,
                    ),
                    _buildStatCard(
                      'Đơn chờ xử lý',
                      pendingOrders.toString(),
                      Icons.pending_actions,
                      Colors.red,
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 20),

            // Charts section
            const Text(
              'Biểu đồ doanh thu',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.1),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Doanh thu $_selectedRange qua',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      DropdownButton<String>(
                        value: _selectedRange,
                        underline: const SizedBox(),
                        items: ['7 ngày', '30 ngày', '90 ngày', '1 năm'].map((
                          String value,
                        ) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue == null) return;
                          setState(() {
                            _selectedRange = newValue;
                          });
                          _recalculateAnalytics();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 200,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: !_hasRevenueData(_salesData)
                          ? _buildEmptyChartMessage(
                              'Chưa có dữ liệu doanh thu trong kỳ đã chọn',
                            )
                          : _buildSalesChart(_salesData),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Recent orders
            const Text(
              'Đơn hàng gần đây',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.1),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  if (_recentOrders.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Chưa có đơn hàng trong kỳ đã chọn'),
                    )
                  else
                    ..._recentOrders
                        .take(5)
                        .map((order) => _buildOrderItem(order)),
                  if (_recentOrders.length > 5)
                    ListTile(
                      title: const Text('Xem tất cả đơn hàng'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        widget.onViewAllOrders?.call();
                      },
                    ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Top products
            const Text(
              'Sản phẩm bán chạy',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.1),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  if (_productStats.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Chưa có dữ liệu sản phẩm trong kỳ'),
                    )
                  else
                    ..._productStats
                        .take(5)
                        .map((stat) => _buildProductItem(stat)),
                  if (_productStats.length > 5)
                    ListTile(
                      title: const Text('Xem tất cả sản phẩm'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        widget.onViewAllProducts?.call();
                      },
                    ),
                ],
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '+12%',
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildSalesChart(List<SalesReport> data) {
    final List<double> revenueValues = data
        .map(
          (report) => report.revenue.isFinite && report.revenue > 0
              ? report.revenue
              : 0.0,
        )
        .toList();

    if (revenueValues.every((value) => value <= 0)) {
      return _buildEmptyChartMessage(
        'Chưa có dữ liệu doanh thu trong kỳ đã chọn',
      );
    }

    final double maxRevenue = revenueValues.fold(
      0,
      (prev, revenue) => revenue > prev ? revenue : prev,
    );
    final double safeMax = maxRevenue <= 0 ? 1 : maxRevenue;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double textScale = MediaQuery.textScaleFactorOf(context);
        const double bottomSpacing = 8;
        const double baseBottomLabelHeight = 34;

        final double bottomLabelHeight =
            baseBottomLabelHeight * textScale.clamp(1.0, 1.6);
        final double reservedSpace = bottomSpacing + bottomLabelHeight;

        final double barAreaHeight = (constraints.maxHeight - reservedSpace)
            .clamp(36.0, constraints.maxHeight);
        final double computedBarWidth =
            constraints.maxWidth / (data.isEmpty ? 1 : data.length * 1.4);
        final double barWidth = math.min(36, computedBarWidth);

        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (int i = 0; i < data.length; i++)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      SizedBox(
                        height: barAreaHeight,
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeOut,
                            height:
                                barAreaHeight *
                                (revenueValues[i] / safeMax).clamp(0.0, 1.0),
                            width: barWidth,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.blue.shade400,
                                  Colors.lightBlueAccent,
                                ],
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: bottomSpacing),
                      SizedBox(
                        height: bottomLabelHeight,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                '${data[i].date.day}/${data[i].date.month}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                '${data[i].orderCount} đơn',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  bool _hasRevenueData(List<SalesReport> reports) {
    if (reports.isEmpty) return false;
    for (final report in reports) {
      final double revenue = report.revenue.isFinite ? report.revenue : 0.0;
      if (revenue.round() > 0) {
        return true;
      }
    }
    return false;
  }

  Widget _buildEmptyChartMessage(String message) {
    return Center(
      child: Text(
        message,
        style: TextStyle(
          color: Colors.grey.shade600,
          fontSize: 14,
          fontStyle: FontStyle.italic,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildOrderItem(Order order) {
    final Color statusColor = _statusColor(order.status);
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: statusColor,
        child: Text(
          order.id.substring(order.id.length - 2),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text('Đơn hàng #${order.id}'),
      subtitle: Text(
        '${order.totalAmount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}đ - ${order.orderDate.day}/${order.orderDate.month}',
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: statusColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          order.status,
          style: const TextStyle(color: Colors.white, fontSize: 10),
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Đang xử lý':
        return Colors.orange;
      case 'Chờ xác nhận':
        return Colors.grey;
      case 'Đã giao':
        return Colors.green;
      case 'Đã hủy':
        return Colors.red;
      default:
        return Colors.blueGrey;
    }
  }

  Widget _buildProductItem(ProductStats stat) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.style, color: Colors.grey),
      ),
      title: Text(stat.productName),
      subtitle: Text('${stat.purchases} lượt mua'),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${stat.conversionRate.toStringAsFixed(1)}%',
            style: TextStyle(
              color: Colors.green.shade600,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'chuyển đổi',
            style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}
