import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/models.dart';
import '../../../services/firebase_user_service.dart';
import '../../../services/firebase_order_service.dart';
import '../../../services/cart_service.dart';
import '../user_main_screen.dart';
import '../../../widgets/safe_network_image.dart';

class CheckoutScreen extends StatefulWidget {
  final List<CartItem> items;
  final bool isQuickBuy; // true nếu là mua ngay, false nếu từ giỏ hàng

  const CheckoutScreen({
    super.key,
    required this.items,
    this.isQuickBuy = false,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  List<Address> _savedAddresses = [];
  Address? _selectedAddress;

  String _selectedPaymentMethod = 'Thanh toán khi nhận hàng (COD)';
  String _promoCode = '';
  bool _promoApplied = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSavedAddresses();
  }

  Future<void> _loadSavedAddresses() async {
    try {
      final addrs = await FirebaseUserService.getCurrentUserAddresses();
      if (!mounted) return;
      setState(() {
        _savedAddresses = addrs;
        // auto-select default address if available
        if (_savedAddresses.isNotEmpty) {
          _selectedAddress = _savedAddresses.firstWhere(
            (a) => a.isDefault,
            orElse: () => _savedAddresses.first,
          );

          if (_selectedAddress != null) {
            _nameController.text = _selectedAddress!.name;
            _phoneController.text = _selectedAddress!.phone;
            _addressController.text =
                '${_selectedAddress!.street}, ${_selectedAddress!.ward}, ${_selectedAddress!.district}, ${_selectedAddress!.city}';
          }
        }
      });
    } catch (e) {
      // ignore
    }
  }

  void _chooseAddress() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          Future<void> setDefault(Address a) async {
            // update local list to mark default and persist
            for (int i = 0; i < _savedAddresses.length; i++) {
              _savedAddresses[i] = Address(
                id: _savedAddresses[i].id,
                name: _savedAddresses[i].name,
                phone: _savedAddresses[i].phone,
                street: _savedAddresses[i].street,
                ward: _savedAddresses[i].ward,
                district: _savedAddresses[i].district,
                city: _savedAddresses[i].city,
                isDefault: _savedAddresses[i].id == a.id,
              );
            }
            // persist
            await FirebaseUserService.saveCurrentUserAddresses(_savedAddresses);
            if (!mounted) return;
            setState(() {
              _selectedAddress = _savedAddresses.firstWhere(
                (x) => x.id == a.id,
                orElse: () => _savedAddresses.first,
              );
              _nameController.text = _selectedAddress!.name;
              _phoneController.text = _selectedAddress!.phone;
              _addressController.text =
                  '${_selectedAddress!.street}, ${_selectedAddress!.ward}, ${_selectedAddress!.district}, ${_selectedAddress!.city}';
            });
            setModalState(() {});
          }

          Future<void> quickAdd() async {
            final nameCtrl = TextEditingController();
            final phoneCtrl = TextEditingController();
            final streetCtrl = TextEditingController();
            final wardCtrl = TextEditingController();
            final districtCtrl = TextEditingController();
            final cityCtrl = TextEditingController();
            bool isDefault = false;

            await showModalBottomSheet(
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
                    children: [
                      const Text(
                        'Thêm địa chỉ mới',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Tên người nhận',
                          border: OutlineInputBorder(),
                        ),
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
                        controller: streetCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Đường, số nhà',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: wardCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Phường/Xã',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: districtCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Quận/Huyện',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: cityCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Tỉnh/Thành phố',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Checkbox(
                            value: isDefault,
                            onChanged: (v) =>
                                setModalState(() => isDefault = v ?? false),
                          ),
                          const SizedBox(width: 8),
                          const Text('Đặt làm mặc định'),
                        ],
                      ),
                      const SizedBox(height: 12),
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
                                final addr = Address(
                                  id: DateTime.now().millisecondsSinceEpoch
                                      .toString(),
                                  name: nameCtrl.text.trim(),
                                  phone: phoneCtrl.text.trim(),
                                  street: streetCtrl.text.trim(),
                                  ward: wardCtrl.text.trim(),
                                  district: districtCtrl.text.trim(),
                                  city: cityCtrl.text.trim(),
                                  isDefault: isDefault,
                                );

                                if (addr.street.isEmpty) return;

                                if (isDefault) {
                                  for (
                                    int i = 0;
                                    i < _savedAddresses.length;
                                    i++
                                  ) {
                                    _savedAddresses[i] = Address(
                                      id: _savedAddresses[i].id,
                                      name: _savedAddresses[i].name,
                                      phone: _savedAddresses[i].phone,
                                      street: _savedAddresses[i].street,
                                      ward: _savedAddresses[i].ward,
                                      district: _savedAddresses[i].district,
                                      city: _savedAddresses[i].city,
                                      isDefault: false,
                                    );
                                  }
                                }

                                setState(() => _savedAddresses.insert(0, addr));
                                await FirebaseUserService.saveCurrentUserAddresses(
                                  _savedAddresses,
                                );
                                if (!mounted) return;
                                setState(() {
                                  _selectedAddress = addr;
                                  _nameController.text = addr.name;
                                  _phoneController.text = addr.phone;
                                  _addressController.text =
                                      '${addr.street}, ${addr.ward}, ${addr.district}, ${addr.city}';
                                });
                                Navigator.pop(context);
                                setModalState(() {});
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

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Text(
                      'Chọn địa chỉ',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (_savedAddresses.isEmpty)
                    ListTile(
                      title: const Text('Bạn chưa có địa chỉ nào'),
                      trailing: TextButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          await quickAdd();
                        },
                        child: const Text('Thêm'),
                      ),
                    ),
                  ..._savedAddresses.map((a) {
                    return ListTile(
                      title: Text('${a.name} - ${a.phone}'),
                      subtitle: Text(
                        '${a.street}, ${a.ward}, ${a.district}, ${a.city}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              a.isDefault ? Icons.star : Icons.star_border,
                              color: a.isDefault ? Colors.orange : null,
                            ),
                            tooltip: 'Đặt làm mặc định',
                            onPressed: () async {
                              await setDefault(a);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.check),
                            tooltip: 'Chọn địa chỉ này',
                            onPressed: () {
                              setState(() {
                                _selectedAddress = a;
                                _nameController.text = a.name;
                                _phoneController.text = a.phone;
                                _addressController.text =
                                    '${a.street}, ${a.ward}, ${a.district}, ${a.city}';
                              });
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      ),
                      onTap: () {
                        setState(() {
                          _selectedAddress = a;
                          _nameController.text = a.name;
                          _phoneController.text = a.phone;
                          _addressController.text =
                              '${a.street}, ${a.ward}, ${a.district}, ${a.city}';
                        });
                        Navigator.pop(context);
                      },
                    );
                  }),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.add_location_alt),
                    title: const Text('Thêm địa chỉ mới'),
                    onTap: () async {
                      await quickAdd();
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.manage_accounts),
                    title: const Text('Quản lý địa chỉ'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/account/addresses');
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalAmount = widget.items.fold<double>(
      0.0,
      (sum, item) => sum + (item.product.price * item.quantity),
    );
    final discountAmount = _promoApplied ? totalAmount * 0.1 : 0.0;
    final shippingFee = 30000.0; // Phí vận chuyển
    final finalAmount = totalAmount - discountAmount + shippingFee;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Thanh Toán'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Order Summary
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Đơn hàng',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...widget.items.map(
                            (item) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                children: [
                                  Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: SafeNetworkImage(
                                      imageUrl: item.product.imageUrl,
                                      fit: BoxFit.cover,
                                      placeholderText: item.product.name,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.product.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          '${item.selectedColor} - x${item.quantity}',
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '${(item.product.price * item.quantity).toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}đ',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Shipping Information
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Thông tin nhận hàng',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          // If user has saved addresses, show the selected one with option to change
                          if (_savedAddresses.isNotEmpty) ...[
                            Card(
                              color: Colors.grey.shade50,
                              child: ListTile(
                                title: Text(
                                  _selectedAddress != null
                                      ? '${_selectedAddress!.name} - ${_selectedAddress!.phone}'
                                      : 'Chọn địa chỉ',
                                ),
                                subtitle: Text(
                                  _selectedAddress != null
                                      ? '${_selectedAddress!.street}, ${_selectedAddress!.ward}, ${_selectedAddress!.district}, ${_selectedAddress!.city}'
                                      : '',
                                ),
                                trailing: TextButton(
                                  onPressed: _chooseAddress,
                                  child: const Text('Thay đổi'),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],

                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Họ tên *',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Vui lòng nhập họ tên';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _phoneController,
                            decoration: const InputDecoration(
                              labelText: 'Số điện thoại *',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Vui lòng nhập số điện thoại';
                              }
                              if (value.length < 10) {
                                return 'Số điện thoại không hợp lệ';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _addressController,
                            decoration: const InputDecoration(
                              labelText: 'Địa chỉ nhận hàng *',
                              border: OutlineInputBorder(),
                              hintText:
                                  'Số nhà, tên đường, quận/huyện, tỉnh/thành phố',
                            ),
                            maxLines: 2,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Vui lòng nhập địa chỉ nhận hàng';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Promo Code
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Mã giảm giá',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  decoration: InputDecoration(
                                    hintText: 'Nhập mã giảm giá',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    enabled: !_promoApplied,
                                  ),
                                  onChanged: (value) {
                                    _promoCode = value;
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton(
                                onPressed: _promoApplied
                                    ? null
                                    : () {
                                        if (_promoCode.toUpperCase() ==
                                            'WELCOME10') {
                                          setState(() {
                                            _promoApplied = true;
                                          });
                                          HapticFeedback.lightImpact();
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Áp dụng mã giảm giá 10% thành công!',
                                              ),
                                              backgroundColor: Colors.green,
                                            ),
                                          );
                                        } else if (_promoCode.isNotEmpty) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Mã giảm giá không hợp lệ',
                                              ),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      },
                                child: const Text('Áp dụng'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Payment Method
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Phương thức thanh toán',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          RadioListTile(
                            title: const Text('Thanh toán khi nhận hàng (COD)'),
                            value: 'Thanh toán khi nhận hàng (COD)',
                            groupValue: _selectedPaymentMethod,
                            onChanged: (value) {
                              setState(() {
                                _selectedPaymentMethod = value!;
                              });
                            },
                          ),
                          RadioListTile(
                            title: const Text('Ví điện tử Momo'),
                            value: 'Ví điện tử Momo',
                            groupValue: _selectedPaymentMethod,
                            onChanged: (value) {
                              setState(() {
                                _selectedPaymentMethod = value!;
                              });
                            },
                          ),
                          RadioListTile(
                            title: const Text('Chuyển khoản ngân hàng'),
                            value: 'Chuyển khoản ngân hàng',
                            groupValue: _selectedPaymentMethod,
                            onChanged: (value) {
                              setState(() {
                                _selectedPaymentMethod = value!;
                              });
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Order Summary Total
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Column(
                        children: [
                          _buildSummaryRow('Tạm tính', totalAmount),
                          _buildSummaryRow(
                            'Giảm giá',
                            -discountAmount,
                            isDiscount: true,
                          ),
                          _buildSummaryRow('Phí vận chuyển', shippingFee),
                          const Divider(height: 24),
                          _buildSummaryRow(
                            'Tổng cộng',
                            finalAmount,
                            isTotal: true,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: _isLoading ? null : _placeOrder,
          icon: const Icon(Icons.shopping_bag),
          label: Text(
            'Đặt hàng (${finalAmount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}đ)',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade600,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    double amount, {
    bool isDiscount = false,
    bool isTotal = false,
  }) {
    Color textColor = isDiscount
        ? Colors.green
        : (isTotal ? Colors.red.shade600 : Colors.black);
    double fontSize = isTotal ? 18 : 14;
    FontWeight fontWeight = isTotal ? FontWeight.bold : FontWeight.normal;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: fontWeight,
              color: textColor,
            ),
          ),
          Text(
            '${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}đ',
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: fontWeight,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Convert CartItem to OrderItem
      List<OrderItem> orderItems = widget.items.map((cartItem) {
        return OrderItem(
          productId: cartItem.product.id,
          productName: cartItem.product.name,
          productImage: cartItem.product.imageUrl,
          price: cartItem.product.price,
          quantity: cartItem.quantity,
        );
      }).toList();

      // Calculate final amount
      final totalAmount = widget.items.fold<double>(
        0.0,
        (sum, item) => sum + (item.product.price * item.quantity),
      );
      final discountAmount = _promoApplied ? totalAmount * 0.1 : 0.0;
      final shippingFee = 30000.0;
      final finalAmount = totalAmount - discountAmount + shippingFee;

      // Create order in Firestore
      Map<String, dynamic> result = await FirebaseOrderService.createOrder(
        items: orderItems,
        totalAmount: finalAmount,
        shippingAddress: _addressController.text.trim(),
        paymentMethod: _selectedPaymentMethod,
      );

      if (result['success'] == true) {
        final String orderId = result['orderId'] ?? '';
        // Clear cart if this is from cart
        if (!widget.isQuickBuy) {
          await CartService.clearCart();
        }

        HapticFeedback.heavyImpact();

        if (mounted) {
          HapticFeedback.heavyImpact();

          // Show a brief confirmation and immediately navigate to Orders screen
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Đặt hàng thành công — Mã: $orderId')),
          );

          // Show confirmation and return the user to Products screen so they can continue shopping
          // Wait a short moment so the SnackBar is visible before navigating.
          await Future.delayed(const Duration(milliseconds: 700));

          if (mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const UserMainScreen()),
              (route) => false,
            );
          }
        }
      } else {
        throw Exception(result['error'] ?? 'Lỗi đặt hàng');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
