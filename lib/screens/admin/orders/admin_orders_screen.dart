import 'package:flutter/material.dart';
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
                          label: Text(status),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedStatus = status;
                            });
                          },
                          backgroundColor: Colors.white,
                          selectedColor: Colors.red.shade100,
                          checkmarkColor: Colors.red.shade600,
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
    return _orders.where((order) {
      final searchQuery = _searchController.text.toLowerCase();
      final matchesSearch =
          order.id.toLowerCase().contains(searchQuery) ||
          order.userId.toLowerCase().contains(searchQuery);

      final matchesStatus =
          _selectedStatus == 'Tất cả' || order.status == _selectedStatus;

      return matchesSearch && matchesStatus;
    }).toList();
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bộ lọc đơn hàng'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Lọc theo ngày'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Từ ngày',
                      border: OutlineInputBorder(),
                    ),
                    readOnly: true,
                    onTap: () async {
                      await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      // TODO: Handle date selection
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Đến ngày',
                      border: OutlineInputBorder(),
                    ),
                    readOnly: true,
                    onTap: () async {
                      await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      // TODO: Handle date selection
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Lọc theo giá trị đơn hàng'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Từ',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
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
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Áp dụng bộ lọc')));
            },
            child: const Text('Áp dụng'),
          ),
        ],
      ),
    );
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
