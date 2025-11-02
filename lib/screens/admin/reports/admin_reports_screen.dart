import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../models/models.dart';
import '../../../services/admin_data_service.dart';
import '../../../services/analytics_service.dart';
import '../../../services/firebase_product_service.dart';

const LinearGradient _dashboardBarGradient = LinearGradient(
  colors: [Color(0xFF42A5F5), Color(0xFF40C4FF)],
  begin: Alignment.bottomCenter,
  end: Alignment.topCenter,
);

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _ChartLegendItem extends StatelessWidget {
  const _ChartLegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final TextStyle legendStyle =
        Theme.of(
          context,
        ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600) ??
        const TextStyle(fontSize: 12, fontWeight: FontWeight.w600);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: legendStyle),
      ],
    );
  }
}

class _RevenueChartCanvas extends StatelessWidget {
  const _RevenueChartCanvas({required this.data, required this.barGradient});

  final List<SalesReport> data;
  final LinearGradient barGradient;

  @override
  Widget build(BuildContext context) {
    final TextStyle axisStyle =
        Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Colors.grey.shade600,
          fontSize: 10,
        ) ??
        TextStyle(color: Colors.grey.shade600, fontSize: 10);

    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          size: Size(constraints.maxWidth, constraints.maxHeight),
          painter: _RevenueChartPainter(
            data: data,
            axisLabelStyle: axisStyle,
            barGradient: barGradient,
            rateColor: const Color(0xFFF28E2B),
          ),
        );
      },
    );
  }
}

class _RevenueChartPainter extends CustomPainter {
  _RevenueChartPainter({
    required this.data,
    required this.axisLabelStyle,
    required this.barGradient,
    required this.rateColor,
  });

  final List<SalesReport> data;
  final TextStyle axisLabelStyle;
  final LinearGradient barGradient;
  final Color rateColor;
  static const int _gridLines = 4;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty || size.width <= 0 || size.height <= 0) {
      return;
    }

    const EdgeInsets padding = EdgeInsets.fromLTRB(48, 16, 56, 40);
    final double chartWidth = size.width - padding.left - padding.right;
    final double chartHeight = size.height - padding.top - padding.bottom;
    if (chartWidth <= 0 || chartHeight <= 0) {
      return;
    }

    final double maxRevenue = data
        .map(
          (report) => report.revenue.isFinite && report.revenue > 0
              ? report.revenue
              : 0.0,
        )
        .fold(0.0, math.max);

    if (maxRevenue <= 0) {
      return;
    }

    final int maxOrders = data
        .map((report) => report.orderCount > 0 ? report.orderCount : 0)
        .fold(0, math.max);
    final bool hasOrderData = maxOrders > 0;

    final double baseY = size.height - padding.bottom;
    final Paint axisPaint = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 1;
    final Paint gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..strokeWidth = 1;

    // Draw axes
    canvas.drawLine(
      Offset(padding.left, padding.top),
      Offset(padding.left, baseY),
      axisPaint,
    );
    canvas.drawLine(
      Offset(padding.left, baseY),
      Offset(size.width - padding.right, baseY),
      axisPaint,
    );

    final TextPainter textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    for (int i = 0; i <= _gridLines; i++) {
      final double ratio = i / _gridLines;
      final double y = padding.top + chartHeight - (ratio * chartHeight);

      if (i > 0 && i < _gridLines) {
        canvas.drawLine(
          Offset(padding.left, y),
          Offset(size.width - padding.right, y),
          gridPaint,
        );
      }

      final double tickValue = maxRevenue * ratio;
      textPainter
        ..text = TextSpan(
          text: _formatRevenueTick(tickValue),
          style: axisLabelStyle,
        )
        ..textAlign = TextAlign.right
        ..layout();
      textPainter.paint(
        canvas,
        Offset(
          padding.left - textPainter.width - 8,
          y - textPainter.height / 2,
        ),
      );

      if (hasOrderData) {
        final double percent = ratio * 100;
        textPainter
          ..text = TextSpan(
            text: '${percent.toStringAsFixed(0)}%',
            style: axisLabelStyle,
          )
          ..textAlign = TextAlign.left
          ..layout();
        textPainter.paint(
          canvas,
          Offset(size.width - padding.right + 8, y - textPainter.height / 2),
        );
      }
    }

    final double groupWidth = chartWidth / data.length;
    final double barWidth = groupWidth * 0.55;
    final List<Offset> ratePoints = <Offset>[];

    for (int i = 0; i < data.length; i++) {
      final SalesReport report = data[i];
      final double revenue = report.revenue.isFinite && report.revenue > 0
          ? report.revenue
          : 0.0;
      final double revenueRatio = (revenue / maxRevenue).clamp(0.0, 1.0);
      final double barHeight = revenueRatio * chartHeight;
      final double centerX = padding.left + groupWidth * (i + 0.5);

      if (barHeight > 0) {
        final Rect barRect = Rect.fromLTWH(
          centerX - (barWidth / 2),
          baseY - barHeight,
          barWidth,
          barHeight,
        );
        final RRect roundedBar = RRect.fromRectAndRadius(
          barRect,
          const Radius.circular(6),
        );
        final Paint barPaint = Paint()
          ..shader = barGradient.createShader(barRect);
        canvas.drawRRect(roundedBar, barPaint);
      }

      final String dateLabel = _formatDateLabel(report.date);
      textPainter
        ..text = TextSpan(text: dateLabel, style: axisLabelStyle)
        ..textAlign = TextAlign.center
        ..layout(maxWidth: groupWidth);
      if (_shouldPaintLabel(i, data.length)) {
        textPainter.paint(
          canvas,
          Offset(centerX - (textPainter.width / 2), baseY + 6),
        );
      }

      if (hasOrderData) {
        final int safeOrders = report.orderCount > 0 ? report.orderCount : 0;
        final double rateRatio = safeOrders / maxOrders;
        final double rateY =
            padding.top + chartHeight - (rateRatio * chartHeight);
        ratePoints.add(Offset(centerX, rateY));
      }
    }

    if (hasOrderData && ratePoints.isNotEmpty) {
      final Paint linePaint = Paint()
        ..color = rateColor
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      final Path ratePath = Path()
        ..moveTo(ratePoints.first.dx, ratePoints.first.dy);
      for (int i = 1; i < ratePoints.length; i++) {
        ratePath.lineTo(ratePoints[i].dx, ratePoints[i].dy);
      }
      canvas.drawPath(ratePath, linePaint);

      final Paint markerPaint = Paint()..color = rateColor;
      for (final Offset point in ratePoints) {
        canvas.drawCircle(point, 3, markerPaint);
      }
    }
  }

  bool _shouldPaintLabel(int index, int total) {
    if (total <= 10) {
      return true;
    }
    final int stride = (total / 10).ceil();
    return index % stride == 0;
  }

  String _formatRevenueTick(double value) {
    if (value >= 1000000) {
      final double millions = value / 1000000;
      return millions % 1 == 0
          ? '${millions.toStringAsFixed(0)}M'
          : '${millions.toStringAsFixed(1)}M';
    }
    if (value >= 1000) {
      final double thousands = value / 1000;
      return thousands % 1 == 0
          ? '${thousands.toStringAsFixed(0)}K'
          : '${thousands.toStringAsFixed(1)}K';
    }
    return value.round().toString();
  }

  String _formatDateLabel(DateTime date) {
    final String day = date.day.toString().padLeft(2, '0');
    final String month = date.month.toString().padLeft(2, '0');
    return '$day/$month';
  }

  @override
  bool shouldRepaint(covariant _RevenueChartPainter oldDelegate) {
    if (oldDelegate.data.length != data.length) {
      return true;
    }
    for (int i = 0; i < data.length; i++) {
      final SalesReport current = data[i];
      final SalesReport previous = oldDelegate.data[i];
      if (current.date != previous.date ||
          current.revenue != previous.revenue ||
          current.orderCount != previous.orderCount) {
        return true;
      }
    }
    return oldDelegate.axisLabelStyle != axisLabelStyle ||
        oldDelegate.barGradient != barGradient ||
        oldDelegate.rateColor != rateColor;
  }
}

class _CustomerSummary {
  final String userId;
  final String displayName;
  final int orders;
  final double spent;

  const _CustomerSummary({
    required this.userId,
    required this.displayName,
    required this.orders,
    required this.spent,
  });
}

class _CategorySummary {
  final String category;
  final double revenue;
  final int orders;
  final int units;

  const _CategorySummary({
    required this.category,
    required this.revenue,
    required this.orders,
    required this.units,
  });
}

class _PaymentSummary {
  final String method;
  final int count;

  const _PaymentSummary({required this.method, required this.count});
}

class _CategoryAggregate {
  double revenue = 0;
  int orders = 0;
  int units = 0;
}

class _AdminReportsScreenState extends State<AdminReportsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String _selectedPeriod = '7 ngày';

  List<Order> _orders = const [];
  List<User> _users = const [];
  List<HatProduct> _products = const [];
  List<SalesReport> _salesData = const [];
  List<ProductStats> _productStats = const [];
  List<_CategorySummary> _categoryPerformance = const <_CategorySummary>[];
  List<_PaymentSummary> _paymentBreakdown = const <_PaymentSummary>[];

  Map<int, int> _ordersByHour = const {};
  Map<String, int> _ordersByStatus = const {};

  DateTime? _rangeStart;
  DateTime? _rangeEnd;

  double _totalRevenue = 0;
  int _totalOrders = 0;
  double _averageOrderValue = 0;
  int _newUsers = 0;
  double _repeatPurchaseRate = 0;
  double _averageItemsPerOrder = 0;

  bool _isLoading = true;

  StreamSubscription<List<Order>>? _ordersSub;
  StreamSubscription<List<User>>? _usersSub;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initDataStreams();
  }

  @override
  void dispose() {
    _ordersSub?.cancel();
    _usersSub?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initDataStreams() async {
    setState(() {
      _isLoading = true;
    });

    await _ordersSub?.cancel();
    await _usersSub?.cancel();

    _ordersSub = AdminDataService.ordersStream().listen((orders) {
      _orders = orders;
      _rebuildAnalytics();
    }, onError: (error, stackTrace) => _handleStreamError(error, stackTrace));

    _usersSub = AdminDataService.usersStream().listen((users) {
      _users = users;
      _rebuildAnalytics();
    }, onError: (error, stackTrace) => _handleStreamError(error, stackTrace));

    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      final products = await FirebaseProductService.getAllProducts();
      if (!mounted) return;
      setState(() {
        _products = products;
      });
      _rebuildAnalytics();
    } catch (error, stackTrace) {
      debugPrint('Failed to load products for reports: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  void _handleStreamError(Object error, StackTrace stackTrace) {
    debugPrint('Reports stream error: $error');
    debugPrintStack(stackTrace: stackTrace);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Không thể tải dữ liệu báo cáo. Vui lòng thử lại.'),
      ),
    );
    setState(() {
      _isLoading = false;
    });
  }

  void _rebuildAnalytics() {
    if (!mounted) {
      return;
    }

    final int rangeDays = _rangeToDays(_selectedPeriod);
    final DateTime today = DateTime.now();
    final DateTime start = DateTime(
      today.year,
      today.month,
      today.day,
    ).subtract(Duration(days: rangeDays - 1));

    final salesReports = AnalyticsService.buildSalesReports(
      orders: _orders,
      users: _users,
      days: rangeDays,
    );

    final productStats = AnalyticsService.buildProductStats(
      orders: _orders,
      start: start,
      end: today,
    );

    final totalRevenue = AnalyticsService.totalRevenue(
      _orders,
      start: start,
      end: today,
    );
    final totalOrders = AnalyticsService.totalOrders(
      _orders,
      start: start,
      end: today,
    );
    final averageOrderValue = AnalyticsService.averageOrderValue(
      _orders,
      start: start,
      end: today,
    );
    final newUsers = AnalyticsService.newUsersCount(
      _users,
      start: start,
      end: today,
    );
    final repeatPurchaseRate = AnalyticsService.repeatPurchaseRate(
      _orders,
      start: start,
      end: today,
    );
    final averageItemsPerOrder = AnalyticsService.averageItemsPerOrder(
      _orders,
      start: start,
      end: today,
    );
    final ordersByHour = AnalyticsService.ordersByHour(
      _orders,
      start: start,
      end: today,
    );
    final ordersByStatus = AnalyticsService.ordersByStatus(
      _orders,
      start: start,
      end: today,
    );

    final List<Order> filteredOrders = _orders
        .where((order) => _isDateWithinRange(order.orderDate, start, today))
        .toList();

    final Map<String, HatProduct> productLookup = {
      for (final product in _products) product.id: product,
    };

    final Map<String, _CategoryAggregate> categoryAggregates = {};
    final Map<String, int> paymentCounts = {};

    for (final order in filteredOrders) {
      final String method = order.paymentMethod.trim().isEmpty
          ? 'Khác'
          : order.paymentMethod.trim();
      paymentCounts[method] = (paymentCounts[method] ?? 0) + 1;

      final Set<String> categoriesInOrder = <String>{};
      for (final item in order.items) {
        final HatProduct? product = productLookup[item.productId];
        final String rawCategory = product?.category ?? item.productName;
        final String category = rawCategory.trim().isEmpty
            ? 'Khác'
            : rawCategory.trim();
        final _CategoryAggregate aggregate = categoryAggregates.putIfAbsent(
          category,
          () => _CategoryAggregate(),
        );
        aggregate.revenue += item.price * item.quantity;
        aggregate.units += item.quantity;
        categoriesInOrder.add(category);
      }

      for (final category in categoriesInOrder) {
        final _CategoryAggregate? aggregate = categoryAggregates[category];
        if (aggregate != null) {
          aggregate.orders += 1;
        }
      }
    }

    final List<_CategorySummary> categoryPerformance =
        categoryAggregates.entries
            .map(
              (entry) => _CategorySummary(
                category: entry.key,
                revenue: entry.value.revenue,
                orders: entry.value.orders,
                units: entry.value.units,
              ),
            )
            .toList()
          ..sort((a, b) => b.revenue.compareTo(a.revenue));

    final List<_PaymentSummary> paymentBreakdown =
        paymentCounts.entries
            .map(
              (entry) => _PaymentSummary(method: entry.key, count: entry.value),
            )
            .toList()
          ..sort((a, b) => b.count.compareTo(a.count));

    setState(() {
      _salesData = salesReports;
      _productStats = productStats;
      _totalRevenue = totalRevenue;
      _totalOrders = totalOrders;
      _averageOrderValue = averageOrderValue;
      _newUsers = newUsers;
      _repeatPurchaseRate = repeatPurchaseRate;
      _averageItemsPerOrder = averageItemsPerOrder;
      _ordersByHour = ordersByHour;
      _ordersByStatus = ordersByStatus;
      _categoryPerformance = categoryPerformance;
      _paymentBreakdown = paymentBreakdown;
      _rangeStart = start;
      _rangeEnd = today;
      _isLoading = false;
    });
  }

  int _rangeToDays(String period) {
    switch (period) {
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

  bool _isDateWithinRange(DateTime date, DateTime start, DateTime end) {
    final DateTime normalized = DateTime(date.year, date.month, date.day);
    return !normalized.isBefore(start) && !normalized.isAfter(end);
  }

  void _onPeriodChanged(String period) {
    if (_selectedPeriod == period) return;
    setState(() {
      _selectedPeriod = period;
    });
    _rebuildAnalytics();
  }

  String _formatCurrency(double value) {
    final intValue = value.round();
    final regex = RegExp(r'(\d)(?=(\d{3})+(?!\d))');
    final formatted = intValue.toString().replaceAllMapped(
      regex,
      (match) => '${match[1]},',
    );
    return '$formattedđ';
  }

  String _formatInt(num value) {
    final regex = RegExp(r'(\d)(?=(\d{3})+(?!\d))');
    return value.round().toString().replaceAllMapped(
      regex,
      (match) => '${match[1]},',
    );
  }

  double _calculateGrowthPercentage() {
    if (_salesData.length < 2) return 0;
    final double first = _salesData.first.revenue;
    final double last = _salesData.last.revenue;
    if (first == 0) {
      return last == 0 ? 0 : 100;
    }
    return ((last - first) / first) * 100;
  }

  Widget _buildRevenueChart(List<SalesReport> data) {
    if (data.isEmpty) {
      return const SizedBox.shrink();
    }

    final List<SalesReport> ordered = List<SalesReport>.from(data)
      ..sort((a, b) => a.date.compareTo(b.date));

    final bool hasRevenue = ordered.any(
      (report) => report.revenue.isFinite && report.revenue > 0,
    );

    if (!hasRevenue) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            _ChartLegendItem(color: Color(0xFF42A5F5), label: 'Doanh số'),
            _ChartLegendItem(color: Color(0xFFF28E2B), label: 'Tỷ lệ đơn hàng'),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _RevenueChartCanvas(
            data: ordered,
            barGradient: _dashboardBarGradient,
          ),
        ),
      ],
    );
  }

  Widget _buildNewUsersChart(List<SalesReport> data) {
    if (data.isEmpty || data.every((report) => !(report.newUsers > 0))) {
      return const SizedBox.shrink();
    }

    final int maxNewUsers = data.fold<int>(
      0,
      (maxValue, report) =>
          report.newUsers > maxValue ? report.newUsers : maxValue,
    );
    final double safeMax = maxNewUsers <= 0 ? 1 : maxNewUsers.toDouble();

    return LayoutBuilder(
      builder: (context, constraints) {
        final double barWidth =
            constraints.maxWidth / (data.isEmpty ? 1 : data.length * 1.6);
        final bool showAllDateLabels = data.length <= 12;
        final int labelStride = showAllDateLabels
            ? 1
            : math.max(1, (data.length / 10).ceil());

        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(data.length, (index) {
            final SalesReport report = data[index];
            final double ratio = (report.newUsers / safeMax).clamp(0.0, 1.0);
            final bool hasValue = report.newUsers > 0;
            final bool showLabel =
                showAllDateLabels ||
                index % labelStride == 0 ||
                index == data.length - 1;

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    SizedBox(
                      height: 20,
                      child: hasValue
                          ? FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                _formatInt(report.newUsers),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          width: barWidth,
                          height: constraints.maxHeight * ratio,
                          decoration: BoxDecoration(
                            gradient: _dashboardBarGradient,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 32,
                      child: showLabel
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '${report.date.day}/${report.date.month}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildOrdersByHourChart() {
    final List<MapEntry<int, int>> data =
        _ordersByHour.entries.where((entry) => entry.value > 0).toList()
          ..sort((a, b) => a.key.compareTo(b.key));

    if (data.isEmpty) {
      return const Center(child: Text('Chưa có dữ liệu giờ cao điểm'));
    }

    final int maxCount = data.fold<int>(
      0,
      (maxValue, entry) => entry.value > maxValue ? entry.value : maxValue,
    );
    final double safeMax = maxCount <= 0 ? 1 : maxCount.toDouble();

    return LayoutBuilder(
      builder: (context, constraints) {
        final double barWidth =
            constraints.maxWidth / (data.isEmpty ? 1 : data.length * 1.6);
        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: data.map((entry) {
            final double ratio = (entry.value / safeMax).clamp(0.0, 1.0);
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    SizedBox(
                      height: 18,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(_formatInt(entry.value)),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Expanded(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          width: barWidth,
                          height: constraints.maxHeight * ratio,
                          decoration: BoxDecoration(
                            gradient: _dashboardBarGradient,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text('${entry.key}h', style: const TextStyle(fontSize: 11)),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
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

  Widget _buildCategoryBreakdown() {
    if (_categoryPerformance.isEmpty) {
      return _buildEmptyChartMessage('Chưa có dữ liệu doanh thu theo danh mục');
    }

    final double totalRevenue = _categoryPerformance.fold<double>(
      0,
      (sum, summary) => sum + summary.revenue,
    );

    return Column(
      children: _categoryPerformance.take(6).map((summary) {
        final double ratio = totalRevenue == 0
            ? 0
            : (summary.revenue / totalRevenue).clamp(0.0, 1.0);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      summary.category,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${summary.orders} đơn • ${summary.units} sản phẩm',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatCurrency(summary.revenue),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: 140,
                    height: 6,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: ratio,
                        backgroundColor: Colors.grey.shade200,
                        color: Colors.blue.shade400,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPaymentDistribution() {
    if (_paymentBreakdown.isEmpty) {
      return _buildEmptyChartMessage('Chưa có dữ liệu phương thức thanh toán');
    }

    final int totalPayments = _paymentBreakdown.fold<int>(
      0,
      (sum, summary) => sum + summary.count,
    );

    return Column(
      children: _paymentBreakdown.map((summary) {
        final double ratio = totalPayments == 0
            ? 0
            : (summary.count / totalPayments).clamp(0.0, 1.0);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  summary.method,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 140,
                height: 6,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: ratio,
                    backgroundColor: Colors.grey.shade200,
                    color: Colors.teal.shade400,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${(ratio * 100).toStringAsFixed(1)}%',
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 12),
              Text(_formatInt(summary.count)),
            ],
          ),
        );
      }).toList(),
    );
  }

  List<_CustomerSummary> _buildTopCustomers({int limit = 5}) {
    if (_orders.isEmpty) {
      return const [];
    }

    final DateTime? start = _rangeStart;
    final DateTime? end = _rangeEnd;

    final Map<String, double> spendByUser = {};
    final Map<String, int> ordersByUser = {};

    for (final order in _orders) {
      final userId = order.userId;
      if (userId.isEmpty) continue;
      if (start != null &&
          end != null &&
          !_isDateWithinRange(order.orderDate, start, end)) {
        continue;
      }
      spendByUser[userId] = (spendByUser[userId] ?? 0) + order.totalAmount;
      ordersByUser[userId] = (ordersByUser[userId] ?? 0) + 1;
    }

    if (spendByUser.isEmpty) {
      return const [];
    }

    final Map<String, User> userLookup = {
      for (final user in _users) user.id: user,
    };

    final List<_CustomerSummary> summaries = spendByUser.entries.map((entry) {
      final User? user = userLookup[entry.key];
      final String displayName = _resolveDisplayName(user);

      return _CustomerSummary(
        userId: entry.key,
        displayName: displayName,
        orders: ordersByUser[entry.key] ?? 0,
        spent: entry.value,
      );
    }).toList();

    summaries.sort((a, b) => b.spent.compareTo(a.spent));

    if (summaries.length <= limit) {
      return summaries;
    }
    return summaries.sublist(0, limit);
  }

  String _resolveDisplayName(User? user) {
    if (user == null) {
      return '';
    }

    final List<String> candidates = [
      user.fullName.trim(),
      user.username.trim(),
      user.email.trim(),
    ];

    for (final candidate in candidates) {
      if (candidate.isNotEmpty) {
        return candidate;
      }
    }

    return '';
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'đang xử lý':
        return Colors.orange;
      case 'chờ xác nhận':
        return Colors.grey;
      case 'đã giao':
        return Colors.green;
      case 'đã hủy':
        return Colors.red;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Báo cáo thống kê'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color.fromRGBO(0, 0, 0, 1),
          labelColor: const Color.fromARGB(255, 0, 0, 0),
          unselectedLabelColor: const Color.fromRGBO(0, 0, 0, 1),
          tabs: const [
            Tab(text: 'Doanh thu'),
            Tab(text: 'Người dùng'),
            Tab(text: 'Sản phẩm'),
            Tab(text: 'Hành vi'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _exportReport,
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSalesTab(),
          _buildUsersTab(),
          _buildProductsTab(),
          _buildBehaviorTab(),
        ],
      ),
    );
  }

  Widget _buildSalesTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final String growthText =
        '${_calculateGrowthPercentage() >= 0 ? '+' : ''}${_calculateGrowthPercentage().toStringAsFixed(1)}%';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary cards
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Tổng doanh thu',
                  _formatCurrency(_totalRevenue),
                  Icons.attach_money,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  'Tổng đơn hàng',
                  _formatInt(_totalOrders),
                  Icons.shopping_cart,
                  Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Giá trị TB/đơn',
                  _formatCurrency(_averageOrderValue),
                  Icons.trending_up,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  'Tăng trưởng',
                  growthText,
                  Icons.show_chart,
                  _calculateGrowthPercentage() >= 0
                      ? Colors.purple
                      : Colors.red,
                  trendText: null,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Revenue chart
          Container(
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildChartHeader('Doanh thu'),
                const SizedBox(height: 16),
                SizedBox(height: 240, child: _buildRevenueChart(_salesData)),
              ],
            ),
          ),

          const SizedBox(height: 22),

          // Top products by revenue
          Container(
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sản phẩm bán chạy',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                if (_productStats.isEmpty)
                  _buildEmptyChartMessage(
                    'Chưa có dữ liệu sản phẩm trong kỳ này',
                  )
                else
                  ..._productStats
                      .take(5)
                      .map((stat) => _buildProductStatItem(stat)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final int totalUsers = _users.length;
    final int activeUsers = _users.where((user) => user.isActive).length;
    final double avgOrdersPerUser = totalUsers == 0
        ? 0
        : _totalOrders / totalUsers;
    final List<_CustomerSummary> topCustomers = _buildTopCustomers(limit: 5);
    final bool hasNewUserData = _salesData.any((report) => report.newUsers > 0);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User stats
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Tổng người dùng',
                  totalUsers.toString(),
                  Icons.people,
                  Colors.blue,
                  trendText: _newUsers > 0 ? '+$_newUsers' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  'Người dùng hoạt động',
                  activeUsers.toString(),
                  Icons.person,
                  Colors.green,
                  trendText: totalUsers == 0
                      ? null
                      : '${(activeUsers / totalUsers * 100).toStringAsFixed(0)}%',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Người dùng mới',
                  _newUsers.toString(),
                  Icons.person_add,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  'Đơn/người dùng',
                  avgOrdersPerUser.toStringAsFixed(2),
                  Icons.assignment_turned_in,
                  Colors.purple,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // User growth chart
          Container(
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildChartHeader(
                  'Tăng trưởng người dùng',
                  includePeriod: false,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: hasNewUserData
                      ? _buildNewUsersChart(_salesData)
                      : _buildEmptyChartMessage(
                          'Chưa ghi nhận người dùng mới trong giai đoạn này',
                        ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Top customers
          Container(
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Khách hàng giá trị nhất',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                if (topCustomers.isEmpty)
                  _buildEmptyChartMessage(
                    'Chưa có dữ liệu khách hàng trong kỳ này',
                  )
                else
                  ...topCustomers.map(
                    (summary) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue.shade100,
                        child: Text(
                          summary.displayName.isNotEmpty
                              ? summary.displayName.substring(0, 1)
                              : '#',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(
                        summary.displayName.isEmpty
                            ? 'Khách ${summary.userId}'
                            : summary.displayName,
                      ),
                      subtitle: Text(
                        '${summary.orders} đơn - ${_formatCurrency(summary.spent)}',
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final int totalProducts = _products.length;
    final int lowStockProducts = _products
        .where((product) => product.stock < 10)
        .length;
    final double avgRating = totalProducts == 0
        ? 0
        : _products.fold<double>(0, (sum, p) => sum + p.rating) / totalProducts;
    final double avgConversion = _productStats.isEmpty
        ? 0
        : _productStats.fold<double>(
                0,
                (sum, stat) => sum + stat.conversionRate,
              ) /
              _productStats.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product stats
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Tổng sản phẩm',
                  totalProducts.toString(),
                  Icons.inventory,
                  Colors.blue,
                  trendText: _productStats.isEmpty
                      ? null
                      : '${_productStats.length} sản phẩm bán',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  'Sắp hết hàng',
                  lowStockProducts.toString(),
                  Icons.warning,
                  Colors.orange,
                  trendText: null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Đánh giá TB',
                  avgRating.toStringAsFixed(1),
                  Icons.star,
                  Colors.amber,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  'Tỷ lệ chuyển đổi',
                  '${avgConversion.toStringAsFixed(1)}%',
                  Icons.trending_up,
                  Colors.green,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Product performance
          Container(
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Hiệu suất sản phẩm',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                if (_productStats.isEmpty)
                  _buildEmptyChartMessage('Chưa có dữ liệu hiệu suất sản phẩm')
                else
                  ..._productStats.take(10).map(_buildProductPerformanceItem),
              ],
            ),
          ),

          const SizedBox(height: 20),

          Container(
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Doanh thu theo danh mục',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildCategoryBreakdown(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBehaviorTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Behavior stats
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Đơn trong kỳ',
                  _formatInt(_totalOrders),
                  Icons.receipt_long,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  'Doanh thu',
                  _formatCurrency(_totalRevenue),
                  Icons.attach_money,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'SP/đơn TB',
                  _averageItemsPerOrder.toStringAsFixed(1),
                  Icons.shopping_bag,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  'Tỷ lệ mua lại',
                  '${_repeatPurchaseRate.toStringAsFixed(1)}%',
                  Icons.loop,
                  Colors.purple,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Status distribution
          Container(
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Phân bố trạng thái đơn hàng',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                if (_ordersByStatus.isEmpty)
                  _buildEmptyChartMessage('Chưa có dữ liệu trạng thái đơn hàng')
                else
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: _ordersByStatus.entries.map((entry) {
                      final Color chipColor = _statusColor(entry.key);
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: chipColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: '${entry.key}: ',
                                style: TextStyle(
                                  color: chipColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              TextSpan(
                                text: _formatInt(entry.value),
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          Container(
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Phương thức thanh toán',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _buildPaymentDistribution(),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Peak hours chart
          Container(
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Giờ cao điểm',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 220,
                  child: _ordersByHour.values.every((count) => count == 0)
                      ? _buildEmptyChartMessage('Chưa có dữ liệu giờ cao điểm')
                      : _buildOrdersByHourChart(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartHeader(String baseTitle, {bool includePeriod = true}) {
    final String displayTitle = includePeriod
        ? '$baseTitle $_selectedPeriod qua'
        : baseTitle;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            displayTitle,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        DropdownButton<String>(
          value: _selectedPeriod,
          underline: const SizedBox(),
          items: ['7 ngày', '30 ngày', '90 ngày', '1 năm']
              .map(
                (String value) => DropdownMenuItem<String>(
                  value: value,
                  child: Text(
                    value,
                    style: const TextStyle(color: Colors.black, fontSize: 14),
                  ),
                ),
              )
              .toList(),
          onChanged: (String? newValue) {
            if (newValue == null) return;
            _onPeriodChanged(newValue);
          },
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color, {
    String? trendText,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 24),
              if (trendText != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    trendText,
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

  Widget _buildProductStatItem(ProductStats stat) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.style, color: Colors.grey),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stat.productName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  '${stat.purchases} đơn • ${stat.views} lượt xem',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            '${stat.conversionRate.toStringAsFixed(1)}%',
            style: TextStyle(
              color: Colors.green.shade600,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductPerformanceItem(ProductStats stat) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.style, color: Colors.grey),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stat.productName,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        '${stat.views} lượt xem',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Flexible(
                      child: Text(
                        '${stat.purchases} lượt mua',
                        style: TextStyle(
                          color: Colors.blue.shade600,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
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
                'conversion',
                style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _exportReport() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xuất báo cáo'),
        content: const Text('Chọn định dạng xuất báo cáo'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Xuất PDF thành công')),
              );
            },
            child: const Text('PDF'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Xuất Excel thành công')),
              );
            },
            child: const Text('Excel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
        ],
      ),
    );
  }
}
