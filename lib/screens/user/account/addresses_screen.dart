import 'package:flutter/material.dart';
import '../../../services/firebase_user_service.dart';
import '../../../models/models.dart';

class AddressesScreen extends StatefulWidget {
  const AddressesScreen({super.key});

  @override
  State<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends State<AddressesScreen> {
  final List<Address> _addresses = [];
  bool _loading = true;

  // Controllers per-modal are created locally when needed.

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    setState(() => _loading = true);
    final addrs = await FirebaseUserService.getCurrentUserAddresses();
    if (!mounted) return;
    setState(() {
      _addresses.clear();
      _addresses.addAll(addrs);
      _loading = false;
    });
  }

  Future<void> _saveAddresses() async {
    setState(() => _loading = true);
    final res = await FirebaseUserService.saveCurrentUserAddresses(_addresses);
    if (!mounted) return;
    setState(() => _loading = false);

    if (res['success'] == true) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã lưu địa chỉ')));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi: ${res['error']}')));
    }
  }

  void _addAddress() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final streetCtrl = TextEditingController();
    final wardCtrl = TextEditingController();
    final districtCtrl = TextEditingController();
    final cityCtrl = TextEditingController();
    bool isDefault = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Thêm địa chỉ',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                      const Text('Đặt làm địa chỉ mặc định'),
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
                              for (int i = 0; i < _addresses.length; i++) {
                                final cur = _addresses[i];
                                _addresses[i] = Address(
                                  id: cur.id,
                                  name: cur.name,
                                  phone: cur.phone,
                                  street: cur.street,
                                  ward: cur.ward,
                                  district: cur.district,
                                  city: cur.city,
                                  isDefault: false,
                                );
                              }
                            }

                            setState(() => _addresses.insert(0, addr));
                            Navigator.pop(context);
                            await _saveAddresses();
                          },
                          child: const Text('Thêm'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _editAddress(int index) {
    final existing = _addresses[index];
    final nameCtrl = TextEditingController(text: existing.name);
    final phoneCtrl = TextEditingController(text: existing.phone);
    final streetCtrl = TextEditingController(text: existing.street);
    final wardCtrl = TextEditingController(text: existing.ward);
    final districtCtrl = TextEditingController(text: existing.district);
    final cityCtrl = TextEditingController(text: existing.city);
    bool isDefault = existing.isDefault;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Chỉnh sửa địa chỉ',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                      const Text('Đặt làm địa chỉ mặc định'),
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
                            final updated = Address(
                              id: existing.id,
                              name: nameCtrl.text.trim(),
                              phone: phoneCtrl.text.trim(),
                              street: streetCtrl.text.trim(),
                              ward: wardCtrl.text.trim(),
                              district: districtCtrl.text.trim(),
                              city: cityCtrl.text.trim(),
                              isDefault: isDefault,
                            );

                            if (isDefault) {
                              for (int i = 0; i < _addresses.length; i++) {
                                final cur = _addresses[i];
                                _addresses[i] = Address(
                                  id: cur.id,
                                  name: cur.name,
                                  phone: cur.phone,
                                  street: cur.street,
                                  ward: cur.ward,
                                  district: cur.district,
                                  city: cur.city,
                                  isDefault: false,
                                );
                              }
                            }

                            setState(() => _addresses[index] = updated);
                            Navigator.pop(context);
                            await _saveAddresses();
                          },
                          child: const Text('Lưu'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _removeAddress(int index) async {
    _addresses.removeAt(index);
    await _saveAddresses();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Đã xóa địa chỉ')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Địa chỉ giao hàng'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _addAddress),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _addresses.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Bạn chưa có địa chỉ giao hàng nào.'),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _addAddress,
                    child: const Text('Thêm địa chỉ'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _addresses.length,
              itemBuilder: (context, index) {
                final a = _addresses[index];
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
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: a.isDefault
                            ? Colors.green.withOpacity(0.1)
                            : Colors.grey.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.location_on,
                        color: a.isDefault
                            ? Colors.green
                            : Colors.grey.shade700,
                        size: 20,
                      ),
                    ),
                    title: Row(
                      children: [
                        Expanded(child: Text('${a.name} - ${a.phone}')),
                        if (a.isDefault)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.shade600,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Mặc định',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                    subtitle: Text(
                      '${a.street}, ${a.ward}, ${a.district}, ${a.city}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          tooltip: 'Chỉnh sửa',
                          onPressed: () => _editAddress(index),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          tooltip: 'Xóa',
                          onPressed: () async {
                            final ok = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Xác nhận xóa'),
                                content: const Text(
                                  'Bạn có chắc muốn xóa địa chỉ này?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('Hủy'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text('Xóa'),
                                  ),
                                ],
                              ),
                            );
                            if (ok != true) return;
                            _removeAddress(index);
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
}
