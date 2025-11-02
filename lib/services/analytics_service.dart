import 'dart:collection';
import 'dart:math';

import '../models/models.dart';

class AnalyticsService {
  const AnalyticsService._();

  static List<SalesReport> buildSalesReports({
    required List<Order> orders,
    required List<User> users,
    int days = 7,
  }) {
    if (days <= 0) return const <SalesReport>[];

    final DateTime today = _normalizeDate(DateTime.now());
    final DateTime startDate = _normalizeDate(
      today.subtract(Duration(days: days - 1)),
    );

    final SplayTreeMap<DateTime, _DailyAggregate> aggregates =
        SplayTreeMap<DateTime, _DailyAggregate>();
    for (int i = 0; i < days; i++) {
      final date = startDate.add(Duration(days: i));
      aggregates[date] = _DailyAggregate();
    }

    for (final order in orders) {
      final DateTime orderDate = _normalizeDate(order.orderDate);
      if (orderDate.isBefore(startDate) || orderDate.isAfter(today)) {
        continue;
      }
      aggregates[orderDate]?.addOrder(order);
    }

    for (final user in users) {
      final DateTime joinDay = _normalizeDate(user.joinDate);
      if (joinDay.isBefore(startDate) || joinDay.isAfter(today)) {
        continue;
      }
      aggregates[joinDay]?.addNewUser();
    }

    return aggregates.entries
        .map(
          (entry) => SalesReport(
            date: entry.key,
            revenue: entry.value.revenue,
            orderCount: entry.value.orderCount,
            newUsers: entry.value.newUsers,
          ),
        )
        .toList();
  }

  static List<ProductStats> buildProductStats({
    required List<Order> orders,
    DateTime? start,
    DateTime? end,
  }) {
    final DateTime? safeStart = start != null ? _normalizeDate(start) : null;
    final DateTime? safeEnd = end != null ? _normalizeDate(end) : null;
    final Map<String, _ProductAggregate> aggregates = {};

    for (final order in orders) {
      if (!_isWithinRange(order.orderDate, safeStart, safeEnd)) {
        continue;
      }
      final Set<String> countedInOrder = <String>{};
      for (final item in order.items) {
        final agg = aggregates.putIfAbsent(
          item.productId,
          () => _ProductAggregate(name: item.productName),
        );
        agg.purchases += item.quantity;
        agg.revenue += item.price * item.quantity;
        if (countedInOrder.add(item.productId)) {
          agg.orderAppearances += 1;
        }
      }
    }

    if (aggregates.isEmpty) return const <ProductStats>[];

    return aggregates.entries.map((entry) {
      final agg = entry.value;
      final int estimatedViews = max(
        agg.purchases + agg.orderAppearances * 5,
        agg.purchases,
      );
      final double conversionRate = estimatedViews == 0
          ? 0
          : (agg.purchases / estimatedViews) * 100;
      return ProductStats(
        productId: entry.key,
        productName: agg.name,
        views: estimatedViews,
        purchases: agg.purchases,
        conversionRate: double.parse(conversionRate.toStringAsFixed(1)),
      );
    }).toList()..sort((a, b) => b.purchases.compareTo(a.purchases));
  }

  static double totalRevenue(
    List<Order> orders, {
    DateTime? start,
    DateTime? end,
  }) {
    final DateTime? safeStart = start != null ? _normalizeDate(start) : null;
    final DateTime? safeEnd = end != null ? _normalizeDate(end) : null;
    return orders
        .where((order) => _isWithinRange(order.orderDate, safeStart, safeEnd))
        .fold(0.0, (sum, order) => sum + order.totalAmount);
  }

  static int totalOrders(List<Order> orders, {DateTime? start, DateTime? end}) {
    final DateTime? safeStart = start != null ? _normalizeDate(start) : null;
    final DateTime? safeEnd = end != null ? _normalizeDate(end) : null;
    return orders
        .where((order) => _isWithinRange(order.orderDate, safeStart, safeEnd))
        .length;
  }

  static double averageOrderValue(
    List<Order> orders, {
    DateTime? start,
    DateTime? end,
  }) {
    final double revenue = totalRevenue(orders, start: start, end: end);
    final int orderCount = totalOrders(orders, start: start, end: end);
    return orderCount == 0 ? 0 : revenue / orderCount;
  }

  static int newUsersCount(
    List<User> users, {
    required DateTime start,
    required DateTime end,
  }) {
    final DateTime safeStart = _normalizeDate(start);
    final DateTime safeEnd = _normalizeDate(end);
    return users
        .where((u) => _isWithinRange(u.joinDate, safeStart, safeEnd))
        .length;
  }

  static Map<int, int> ordersByHour(
    List<Order> orders, {
    DateTime? start,
    DateTime? end,
  }) {
    final DateTime? safeStart = start != null ? _normalizeDate(start) : null;
    final DateTime? safeEnd = end != null ? _normalizeDate(end) : null;
    final Map<int, int> counts = {for (int h = 0; h < 24; h++) h: 0};
    for (final order in orders) {
      if (!_isWithinRange(order.orderDate, safeStart, safeEnd)) continue;
      final int hour = order.orderDate.hour;
      counts[hour] = (counts[hour] ?? 0) + 1;
    }
    return counts;
  }

  static double averageItemsPerOrder(
    List<Order> orders, {
    DateTime? start,
    DateTime? end,
  }) {
    final DateTime? safeStart = start != null ? _normalizeDate(start) : null;
    final DateTime? safeEnd = end != null ? _normalizeDate(end) : null;
    final Iterable<Order> filtered = orders.where(
      (order) => _isWithinRange(order.orderDate, safeStart, safeEnd),
    );
    int totalItems = 0;
    int countedOrders = 0;
    for (final order in filtered) {
      totalItems += order.items.fold<int>(
        0,
        (sum, item) => sum + item.quantity,
      );
      countedOrders += 1;
    }
    return countedOrders == 0 ? 0 : totalItems / countedOrders;
  }

  static double repeatPurchaseRate(
    List<Order> orders, {
    DateTime? start,
    DateTime? end,
  }) {
    final DateTime? safeStart = start != null ? _normalizeDate(start) : null;
    final DateTime? safeEnd = end != null ? _normalizeDate(end) : null;
    final Map<String, int> orderCountsByUser = {};
    for (final order in orders) {
      if (!_isWithinRange(order.orderDate, safeStart, safeEnd)) continue;
      if (order.userId.isEmpty) continue;
      orderCountsByUser[order.userId] =
          (orderCountsByUser[order.userId] ?? 0) + 1;
    }
    if (orderCountsByUser.isEmpty) return 0;
    final int repeatUsers = orderCountsByUser.values
        .where((count) => count > 1)
        .length;
    final int totalUsers = orderCountsByUser.length;
    return (repeatUsers / totalUsers) * 100;
  }

  static Map<String, int> ordersByStatus(
    List<Order> orders, {
    DateTime? start,
    DateTime? end,
  }) {
    final DateTime? safeStart = start != null ? _normalizeDate(start) : null;
    final DateTime? safeEnd = end != null ? _normalizeDate(end) : null;
    final Map<String, int> counts = {};
    for (final order in orders) {
      if (!_isWithinRange(order.orderDate, safeStart, safeEnd)) continue;
      final status = order.status.isEmpty ? 'Khác' : order.status;
      counts[status] = (counts[status] ?? 0) + 1;
    }
    return counts;
  }

  static DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static bool _isWithinRange(DateTime value, DateTime? start, DateTime? end) {
    final DateTime normalized = _normalizeDate(value);
    if (start != null && normalized.isBefore(start)) return false;
    if (end != null && normalized.isAfter(end)) return false;
    return true;
  }
}

class _DailyAggregate {
  double revenue = 0;
  int orderCount = 0;
  int newUsers = 0;

  void addOrder(Order order) {
    revenue += order.totalAmount;
    orderCount += 1;
  }

  void addNewUser() {
    newUsers += 1;
  }
}

class _ProductAggregate {
  _ProductAggregate({required this.name});

  final String name;
  int purchases = 0;
  double revenue = 0;
  int orderAppearances = 0;
}
