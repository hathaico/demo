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
                      children: const [
                        SizedBox(height: 40),
                        Center(child: Text('Bạn chưa có đơn hàng nào')),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _orders.length,
                      itemBuilder: (context, index) {
                        final order = _orders[index];
                        // Improved card layout: status pill, formatted date/price and clear action button.
                        return InkWell(
                          onTap: () => _openDetails(order),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.06),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  'Đơn #${order.id}',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 6,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color:
                                                      order.status == 'Đã giao'
                                                      ? Colors.green
                                                      : (order.status ==
                                                                'Đã hủy'
                                                            ? Colors.red
                                                            : Colors.orange),
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                ),
                                                child: Text(
                                                  order.status,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            '${DateFormat('dd/MM/yyyy HH:mm').format(order.orderDate)}',
                                            style: TextStyle(
                                              color: Colors.grey.shade600,
                                              fontSize: 13,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            _formatCurrency(order.totalAmount),
                                            style: TextStyle(
                                              color: Colors.blue.shade700,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    OutlinedButton.icon(
                                      onPressed: () => _openDetails(order),
                                      icon: const Icon(
                                        Icons.visibility,
                                        size: 16,
                                      ),
                                      label: const Text('Chi tiết'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
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
