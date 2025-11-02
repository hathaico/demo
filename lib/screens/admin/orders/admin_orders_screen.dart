import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/models.dart';
import '../../../services/admin_data_service.dart';
import 'dart:async';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  final List<Order> _orders = [];
  StreamSubscription<List<Order>>? _ordersSub;
  String _selectedStatus = 'Tất cả';
  final TextEditingController _searchController = TextEditingController();
  DateTime? _startDateFilter;
  DateTime? _endDateFilter;

  final List<String> _statuses = ['Tất cả', 'Đang xử lý', 'Đã giao', 'Đã hủy'];

  @override
  void dispose() {
    _ordersSub?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Subscribe to orders stream from Firestore so admin sees user-created orders
    _ordersSub = AdminDataService.ordersStream().listen((orders) {
      setState(() {
        _orders.clear();
        _orders.addAll(orders);
      });
    });
    AdminDataService.ensureAdminInitialized();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Quản lý đơn hàng'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and status filter
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm đơn hàng...',
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
                    itemCount: _statuses.length,
                    itemBuilder: (context, index) {
                      final status = _statuses[index];
                      final isSelected = _selectedStatus == status;

                      return Container(
                        margin: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(
                            status,
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
                              _selectedStatus = status;
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

          // Orders list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _getFilteredOrders().length,
              itemBuilder: (context, index) {
                final order = _getFilteredOrders()[index];
                return _buildOrderCard(order);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Order order) {
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
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(order.status),
          child: Text(
            order.id.substring(order.id.length - 2),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          'Đơn hàng #${order.id}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${order.orderDate.day}/${order.orderDate.month}/${order.orderDate.year} - ${order.orderDate.hour}:${order.orderDate.minute.toString().padLeft(2, '0')}',
            ),
            const SizedBox(height: 4),
            Text(
              '${order.totalAmount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}đ',
              style: TextStyle(
                color: Colors.blue.shade600,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getStatusColor(order.status),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            order.status,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Customer info
                const Text(
                  'Thông tin khách hàng',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text('ID: ${order.userId}'),
                Text('Địa chỉ: ${order.shippingAddress}'),
                Text('Thanh toán: ${order.paymentMethod}'),

                const SizedBox(height: 16),

                // Order items
                const Text(
                  'Sản phẩm',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                ...order.items.map(
                  (item) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(8),
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
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Icon(Icons.style, color: Colors.grey),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.productName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                'Số lượng: ${item.quantity}',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${item.price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}đ',
                          style: TextStyle(
                            color: Colors.blue.shade600,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Order actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _updateOrderStatus(order),
                        icon: const Icon(Icons.edit),
                        label: const Text('Cập nhật trạng thái'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _viewOrderDetails(order),
                        icon: const Icon(Icons.visibility),
                        label: const Text('Chi tiết'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Đang xử lý':
        return Colors.orange;
      case 'Đã giao':
        return Colors.green;
      case 'Đã hủy':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  List<Order> _getFilteredOrders() {
    final searchQuery = _searchController.text.toLowerCase().trim();
    return _orders.where((order) {
      final matchesSearch = searchQuery.isEmpty
          ? true
          : order.id.toLowerCase().contains(searchQuery) ||
                order.userId.toLowerCase().contains(searchQuery) ||
                order.shippingAddress.toLowerCase().contains(searchQuery);

      final matchesStatus =
          _selectedStatus == 'Tất cả' || order.status == _selectedStatus;

      final matchesDate = _isWithinSelectedRange(order.orderDate);

      return matchesSearch && matchesStatus && matchesDate;
    }).toList();
  }

  bool _isWithinSelectedRange(DateTime date) {
    if (_startDateFilter == null && _endDateFilter == null) {
      return true;
    }

    final DateTime normalized = DateTime(date.year, date.month, date.day);

    if (_startDateFilter != null) {
      final DateTime start = DateTime(
        _startDateFilter!.year,
        _startDateFilter!.month,
        _startDateFilter!.day,
      );
      if (normalized.isBefore(start)) {
        return false;
      }
    }

    if (_endDateFilter != null) {
      final DateTime end = DateTime(
        _endDateFilter!.year,
        _endDateFilter!.month,
        _endDateFilter!.day,
      );
      if (normalized.isAfter(end)) {
        return false;
      }
    }

    return true;
  }

  String _formatDate(DateTime? date) {
    if (date == null) {
      return 'Chưa chọn';
    }
    return DateFormat('dd/MM/yyyy').format(date);
  }

  void _showFilterDialog() {
    final TextEditingController startController = TextEditingController(
      text: _startDateFilter != null ? _formatDate(_startDateFilter) : '',
    );
    final TextEditingController endController = TextEditingController(
      text: _endDateFilter != null ? _formatDate(_endDateFilter) : '',
    );

    DateTime? tempStart = _startDateFilter;
    DateTime? tempEnd = _endDateFilter;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> pickStart() async {
              final DateTime initial = tempStart ?? DateTime.now();
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: initial.isAfter(DateTime.now())
                    ? DateTime.now()
                    : initial,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (picked != null) {
                setModalState(() {
                  tempStart = picked;
                  if (tempEnd != null && tempEnd!.isBefore(picked)) {
                    tempEnd = picked;
                    endController.text = _formatDate(tempEnd);
                  }
                  startController.text = _formatDate(tempStart);
                });
              }
            }

            Future<void> pickEnd() async {
              final DateTime initial = tempEnd ?? tempStart ?? DateTime.now();
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: initial.isAfter(DateTime.now())
                    ? DateTime.now()
                    : initial,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (picked != null) {
                setModalState(() {
                  tempEnd = picked;
                  if (tempStart != null && tempStart!.isAfter(picked)) {
                    tempStart = picked;
                    startController.text = _formatDate(tempStart);
                  }
                  endController.text = _formatDate(tempEnd);
                });
              }
            }

            return AlertDialog(
              title: const Text('Bộ lọc đơn hàng'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Lọc theo ngày'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: pickStart,
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Từ ngày',
                                border: OutlineInputBorder(),
                              ),
                              child: Text(
                                startController.text.isEmpty
                                    ? 'Chưa chọn'
                                    : startController.text,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: InkWell(
                            onTap: pickEnd,
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Đến ngày',
                                border: OutlineInputBorder(),
                              ),
                              child: Text(
                                endController.text.isEmpty
                                    ? 'Chưa chọn'
                                    : endController.text,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text('Lọc theo giá trị đơn hàng'),
                    const SizedBox(height: 8),
                    Row(
                      children: const [
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              labelText: 'Từ',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              labelText: 'Đến',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Hủy'),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _startDateFilter = null;
                      _endDateFilter = null;
                    });
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã đặt lại bộ lọc ngày')),
                    );
                  },
                  child: const Text('Đặt lại'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _startDateFilter = tempStart;
                      _endDateFilter = tempEnd;
                    });
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã áp dụng bộ lọc ngày')),
                    );
                  },
                  child: const Text('Áp dụng'),
                ),
              ],
            );
          },
        );
      },
    ).whenComplete(() {
      startController.dispose();
      endController.dispose();
    });
  }

  void _updateOrderStatus(Order order) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Cập nhật trạng thái đơn hàng'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Đơn hàng: #${order.id}'),
              const SizedBox(height: 12),
              const Text('Chọn trạng thái mới:'),
              const SizedBox(height: 8),
              ...['Đang xử lý', 'Đã giao', 'Đã hủy'].map((status) {
                return ListTile(
                  title: Text(status),
                  leading: Icon(
                    status == 'Đang xử lý'
                        ? Icons.hourglass_empty
                        : status == 'Đã giao'
                        ? Icons.check_circle
                        : Icons.cancel,
                    color: _getStatusColor(status),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    final scaffold = ScaffoldMessenger.of(context);
                    scaffold.showSnackBar(
                      const SnackBar(
                        content: Text('Đang cập nhật trạng thái...'),
                      ),
                    );
                    try {
                      await AdminDataService.updateOrderStatus(
                        order.id,
                        status,
                      );
                      scaffold.showSnackBar(
                        SnackBar(
                          content: Text('Đã cập nhật trạng thái: $status'),
                        ),
                      );
                    } catch (e) {
                      scaffold.showSnackBar(
                        SnackBar(content: Text('Lỗi cập nhật trạng thái: $e')),
                      );
                    }
                  },
                );
              }),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng'),
            ),
          ],
        );
      },
    );
  }

  void _viewOrderDetails(Order order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Chi tiết đơn hàng #${order.id}'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ID khách hàng: ${order.userId}'),
              Text(
                'Ngày đặt: ${order.orderDate.day}/${order.orderDate.month}/${order.orderDate.year}',
              ),
              Text('Địa chỉ giao hàng: ${order.shippingAddress}'),
              Text('Phương thức thanh toán: ${order.paymentMethod}'),
              Text('Trạng thái: ${order.status}'),
              const SizedBox(height: 16),
              const Text(
                'Sản phẩm:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ...order.items.map(
                (item) => Text('• ${item.productName} x${item.quantity}'),
              ),
              const SizedBox(height: 16),
              Text(
                'Tổng cộng: ${order.totalAmount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}đ',
                style: const TextStyle(fontWeight: FontWeight.bold),
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
}
