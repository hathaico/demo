import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
import '../../../firebase_options.dart';
import '../../../models/models.dart';
import '../../../services/firebase_order_service.dart';
import '../../../services/firebase_auth_service.dart';
import '../../../widgets/safe_network_image.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  List<Order> _orders = [];
  bool _loading = true;
  StreamSubscription<Order>? _orderCreatedSub;
  StreamSubscription<List<Order>>? _ordersStreamSub;

  // initState merged further below where we also subscribe to local events.

  Future<void> _loadOrders() async {
    setState(() {
      _loading = true;
    });

    final orders = await FirebaseOrderService.getUserOrders();
    if (mounted) {
      setState(() {
        _orders = orders;
        _loading = false;
      });
    }
  }

  String _formatCurrency(double value) {
    final fmt = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
      decimalDigits: 0,
    );
    return fmt.format(value);
  }

  int _countItems(Order order) {
    return order.items.fold<int>(0, (sum, item) => sum + item.quantity);
  }

  _StatusBadgeStyle _statusBadgeStyle(String status) {
    final String normalized = status.toLowerCase();
    if (normalized.contains('hủy')) {
      return const _StatusBadgeStyle(
        background: Color(0xFFFFEBEE),
        border: Color(0xFFE57373),
        foreground: Color(0xFFD32F2F),
      );
    }
    if (normalized.contains('giao') || normalized.contains('hoàn')) {
      return const _StatusBadgeStyle(
        background: Color(0xFFE8F5E9),
        border: Color(0xFF81C784),
        foreground: Color(0xFF2E7D32),
      );
    }
    if (normalized.contains('chờ') ||
        normalized.contains('xử lý') ||
        normalized.contains('xác nhận') ||
        normalized.contains('đang')) {
      return const _StatusBadgeStyle(
        background: Color(0xFFFFF3E0),
        border: Color(0xFFFFB74D),
        foreground: Color(0xFFEF6C00),
      );
    }
    return const _StatusBadgeStyle(
      background: Color(0xFFE3F2FD),
      border: Color(0xFF64B5F6),
      foreground: Color(0xFF1976D2),
    );
  }

  Widget _buildOrderCard(Order order) {
    final _StatusBadgeStyle badgeStyle = _statusBadgeStyle(order.status);
    final String createdAt = DateFormat(
      'dd/MM/yyyy • HH:mm',
    ).format(order.orderDate);
    final String total = _formatCurrency(order.totalAmount);
    final int productCount = _countItems(order);
    final String itemLabel = productCount == 1
        ? '1 sản phẩm'
        : '$productCount sản phẩm';
    final String paymentDisplay = order.paymentMethod.trim().isEmpty
        ? 'Thanh toán khi nhận'
        : order.paymentMethod.trim();

    final ThemeData theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openDetails(order),
        child: Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Đơn #${order.id}',
                          style:
                              theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ) ??
                              const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 16,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              createdAt,
                              style:
                                  theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.grey.shade600,
                                  ) ??
                                  TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _InfoPill(
                              icon: Icons.shopping_bag_outlined,
                              label: itemLabel,
                            ),
                            _InfoPill(
                              icon: Icons.payments_outlined,
                              label: 'Thanh toán: $paymentDisplay',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: badgeStyle.background,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: badgeStyle.border),
                    ),
                    child: Text(
                      order.status,
                      style: TextStyle(
                        color: badgeStyle.foreground,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Divider(color: Colors.grey.shade200, height: 1),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tổng tiền',
                          style:
                              theme.textTheme.labelMedium?.copyWith(
                                color: Colors.grey.shade600,
                              ) ??
                              TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          total,
                          style:
                              theme.textTheme.titleMedium?.copyWith(
                                color: const Color(0xFF1F40C3),
                                fontWeight: FontWeight.w700,
                              ) ??
                              const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1F40C3),
                              ),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _openDetails(order),
                    icon: const Icon(Icons.remove_red_eye_outlined, size: 18),
                    label: const Text('Chi tiết'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF6C63FF),
                      side: const BorderSide(color: Color(0xFF6C63FF)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),
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

  void _openDetails(Order order) {
    // Open details and await a possible result (e.g. 'canceled') so we can
    // update the list immediately without waiting for Firestore sync.
    Navigator.of(context)
        .push(
          MaterialPageRoute(builder: (_) => OrderDetailsScreen(order: order)),
        )
        .then((res) {
          if (res == 'canceled') {
            // update local list to mark this order as canceled
            final idx = _orders.indexWhere((o) => o.id == order.id);
            if (idx != -1) {
              setState(() {
                _orders[idx] = Order(
                  id: order.id,
                  userId: order.userId,
                  items: order.items,
                  totalAmount: order.totalAmount,
                  status: 'Đã hủy',
                  orderDate: order.orderDate,
                  shippingAddress: order.shippingAddress,
                  paymentMethod: order.paymentMethod,
                );
              });
            }
          }
        });
  }

  @override
  void initState() {
    super.initState();
    // Subscribe to local created-order events so newly-created orders show
    // immediately in this screen without waiting for Firestore sync.
    _orderCreatedSub = FirebaseOrderService.orderCreatedStream.listen((order) {
      final currentUid = FirebaseAuthService.currentUser?.uid;
      if (!mounted) return;
      if (order.userId != currentUid) return;
      final exists = _orders.any((o) => o.id == order.id);
      if (!exists) {
        setState(() {
          _orders.insert(0, order);
        });
      }
    });

    // Also load any pending created orders that were emitted before we
    // subscribed (race avoidance).
    final pending = FirebaseOrderService.consumePendingCreatedOrders();
    if (pending.isNotEmpty) {
      final currentUid = FirebaseAuthService.currentUser?.uid;
      for (var o in pending) {
        if (o.userId == currentUid && !_orders.any((x) => x.id == o.id)) {
          _orders.insert(0, o);
        }
      }
    }
    // Ensure we load the canonical list from Firestore as well.
    _loadOrders();

    // Additionally subscribe to the Firestore stream for user orders so
    // any remote changes (or orders created elsewhere) are reflected in
    // real-time.
    try {
      _ordersStreamSub = FirebaseOrderService.getUserOrdersStream().listen(
        (list) {
          if (!mounted) return;
          setState(() {
            _orders = list;
            _loading = false;
          });
        },
        onError: (err) {
          // Keep old behavior: do not crash, but surface an optional message.
          if (!mounted) return;
          setState(() {
            _loading = false;
          });
          // If Firestore reports a missing index, show a helpful dialog
          final errMsg = err?.toString() ?? 'Lỗi khi tải đơn hàng';
          if (errMsg.contains('requires an index') ||
              errMsg.contains('failed-precondition')) {
            _showIndexDialog(errMsg);
            return;
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi khi tải đơn hàng: $errMsg')),
          );
        },
      );
    } catch (e) {
      // ignore subscription errors
    }
  }

  Future<void> _showIndexDialog(String message) async {
    final projectId = DefaultFirebaseOptions.currentPlatform.projectId;
    final url =
        'https://console.firebase.google.com/project/$projectId/firestore/indexes';

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yêu cầu tạo Index Firestore'),
        content: Text(
          'Firestore yêu cầu một composite index để thực hiện truy vấn.\n\nChi tiết: $message',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Đóng'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final uri = Uri.parse(url);
              try {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              } catch (_) {}
            },
            child: const Text('Mở trang Index'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Đơn hàng của tôi'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOrders,
            tooltip: 'Làm mới',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadOrders,
              child: _orders.isEmpty
                  ? ListView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 120,
                      ),
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 84,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Bạn chưa có đơn hàng nào',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Khi bạn đặt mua sản phẩm, lịch sử đơn hàng sẽ xuất hiện tại đây.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 24),
                        Center(
                          child: ElevatedButton.icon(
                            onPressed: () => Navigator.of(context).maybePop(),
                            icon: const Icon(Icons.shopping_bag_outlined),
                            label: const Text('Tiếp tục mua sắm'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1F40C3),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(26),
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: _orders.length,
                      itemBuilder: (context, index) {
                        final Order order = _orders[index];
                        return _buildOrderCard(order);
                      },
                    ),
            ),
    );
  }

  @override
  void dispose() {
    _orderCreatedSub?.cancel();
    _ordersStreamSub?.cancel();
    super.dispose();
  }
}

class _StatusBadgeStyle {
  const _StatusBadgeStyle({
    required this.background,
    required this.border,
    required this.foreground,
  });

  final Color background;
  final Color border;
  final Color foreground;
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade700),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 180),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class OrderDetailsScreen extends StatefulWidget {
  final Order order;

  const OrderDetailsScreen({super.key, required this.order});

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  bool _loading = false;

  Future<void> _cancelOrder() async {
    final order = widget.order;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận hủy đơn'),
        content: const Text('Bạn có chắc muốn hủy đơn này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _loading = true);
    try {
      final res = await FirebaseOrderService.cancelOrder(order.id);
      setState(() => _loading = false);
      if (res['success'] == true) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Đã hủy đơn hàng')));
        Navigator.of(context).pop('canceled');
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: ${res['error']}')));
      }
    } catch (e) {
      setState(() => _loading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi khi hủy đơn: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết đơn hàng'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Mã đơn hàng: ${order.id}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('Trạng thái: ${order.status}'),
              const SizedBox(height: 8),
              Text(
                'Ngày đặt: ${DateFormat('dd/MM/yyyy HH:mm').format(order.orderDate)}',
              ),
              const SizedBox(height: 12),
              const Text(
                'Sản phẩm',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...order.items.map(
                (it) => ListTile(
                  leading: it.productImage.isNotEmpty
                      ? SafeNetworkImage(
                          imageUrl: it.productImage,
                          width: 52,
                          height: 52,
                          fit: BoxFit.cover,
                        )
                      : const SizedBox(width: 52, height: 52),
                  title: Text(it.productName),
                  subtitle: Text(
                    'Số lượng: ${it.quantity} - ${NumberFormat.currency(locale: "vi_VN", symbol: "đ", decimalDigits: 0).format(it.price)}',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Địa chỉ giao hàng',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(order.shippingAddress),
              const SizedBox(height: 12),
              const Text(
                'Phương thức thanh toán',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(order.paymentMethod),
              const SizedBox(height: 16),
              if (order.status != 'Đã giao' && order.status != 'Đã hủy')
                ElevatedButton(
                  onPressed: _cancelOrder,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('Hủy đơn'),
                ),
            ],
          ),
          if (_loading)
            const Positioned.fill(
              child: ColoredBox(
                color: Color.fromRGBO(0, 0, 0, 0.3),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }
}
