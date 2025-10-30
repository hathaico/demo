import 'package:flutter/material.dart';
import '../../../models/models.dart';
import '../../../services/firebase_product_service.dart';
import '../../../services/firebase_storage_service.dart';
import '../../../widgets/safe_network_image.dart';
import 'add_product_screen.dart';
import 'edit_product_screen.dart';

class AdminProductsScreen extends StatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen> {
  List<HatProduct> _products = [];
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'Tất cả';
  bool _isLoading = true;

  final List<String> _categories = [
    'Tất cả',
    'Nón Snapback',
    'Nón Bucket',
    'Nón Fedora',
    'Nón Beanie',
    'Nón Trucker',
    'Nón Baseball',
  ];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      // Khởi tạo dữ liệu mẫu nếu cần
      // Lấy tất cả sản phẩm từ Firebase
      List<HatProduct> products = await FirebaseProductService.getAllProducts();
      
      setState(() {
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading products: $e');
      // Fallback về dữ liệu mẫu nếu Firebase lỗi
      setState(() {
        _products = [];
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Column(
        children: [
          // Search and filter
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm sản phẩm...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.security),
                          onPressed: _checkStorageRules,
                          tooltip: 'Check Storage Rules',
                        ),
                        IconButton(
                          icon: const Icon(Icons.cloud_upload),
                          onPressed: _testFirebaseStorage,
                          tooltip: 'Test Firebase Storage',
                        ),
                        IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                        ),
                      ],
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (value) => setState(() {}),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      final isSelected = _selectedCategory == category;
                      
                      return Container(
                        margin: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(category),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedCategory = category;
                            });
                          },
                          backgroundColor: Colors.white,
                          selectedColor: Colors.red.shade100,
                          checkmarkColor: const Color.fromARGB(255, 85, 132, 197),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          
          // Products list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _products.where((product) {
                    final searchQuery = _searchController.text.toLowerCase();
                    final matchesSearch = product.name.toLowerCase().contains(searchQuery) ||
                        product.brand.toLowerCase().contains(searchQuery) ||
                        product.category.toLowerCase().contains(searchQuery);
                    
                    final matchesCategory = _selectedCategory == 'Tất cả' ||
                        product.category == _selectedCategory;
                    
                    return matchesSearch && matchesCategory;
                  }).toList().isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inventory_2_outlined,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Chưa có sản phẩm nào',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Nhấn nút + để thêm sản phẩm đầu tiên',
                              style: TextStyle(
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _getFilteredProducts().length,
                        itemBuilder: (context, index) {
                          final product = _getFilteredProducts()[index];
                          return _buildProductCard(product);
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addProduct,
        backgroundColor: Colors.red.shade600,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _checkStorageRules() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đang kiểm tra Storage rules...'),
        backgroundColor: Colors.blue,
      ),
    );

    try {
      Map<String, dynamic> result = await FirebaseStorageService.checkStorageRules();
      
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rules OK: ${result['message']}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rules check failed: ${result['error']}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi check rules: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  void _testFirebaseStorage() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đang test Firebase Storage...'),
        backgroundColor: Colors.blue,
      ),
    );

    try {
      Map<String, dynamic> result = await FirebaseStorageService.testUpload();
      
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Test thành công! URL: ${result['downloadUrl']}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Test thất bại: ${result['error']}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi test: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  Widget _buildProductCard(HatProduct product) {
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
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
          ),
          child: SafeNetworkImage(
            imageUrl: product.imageUrl,
            width: 60,
            height: 60,
            fit: BoxFit.cover,
            placeholderText: product.name,
          ),
        ),
        title: Text(
          product.name,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${product.brand} - ${product.category}'),
            const SizedBox(height: 4),
            Row(
              children: [
                Flexible(
                  child: Text(
                    '${product.price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}đ',
                    style: TextStyle(
                      color: Colors.blue.shade600,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: product.stock < 10 ? Colors.red : Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Còn ${product.stock}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'edit':
                _editProduct(product);
                break;
              case 'delete':
                _deleteProduct(product);
                break;
              case 'duplicate':
                _duplicateProduct(product);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: ListTile(
                leading: Icon(Icons.edit),
                title: Text('Chỉnh sửa'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'duplicate',
              child: ListTile(
                leading: Icon(Icons.copy),
                title: Text('Sao chép'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('Xóa', style: TextStyle(color: Colors.red)),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<HatProduct> _getFilteredProducts() {
    return _products.where((product) {
      final searchQuery = _searchController.text.toLowerCase();
      final matchesSearch = product.name.toLowerCase().contains(searchQuery) ||
          product.brand.toLowerCase().contains(searchQuery);
      
      final matchesCategory = _selectedCategory == 'Tất cả' ||
          product.category == _selectedCategory;
      
      return matchesSearch && matchesCategory;
    }).toList();
  }

  void _addProduct() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddProductScreen(),
      ),
    );
    
    if (result == true) {
      // Reload products after adding
      _loadProducts();
    }
  }

  void _editProduct(HatProduct product) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProductScreen(product: product),
      ),
    );
    
    if (result == true) {
      // Reload products after editing
      _loadProducts();
    }
  }

  void _deleteProduct(HatProduct product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa sản phẩm'),
        content: Text('Bạn có chắc chắn muốn xóa sản phẩm "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              
              try {
                Map<String, dynamic> result = await FirebaseProductService.deleteProduct(product.id);
                
                if (result['success'] == true) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đã xóa sản phẩm'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  // Reload products
                  _loadProducts();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Lỗi xóa sản phẩm: ${result['error']}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Lỗi: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _duplicateProduct(HatProduct product) async {
    // Tạo sản phẩm mới với thông tin từ sản phẩm gốc
    HatProduct duplicatedProduct = HatProduct(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: '${product.name} (Copy)',
      brand: product.brand,
      price: product.price,
      imageUrl: product.imageUrl,
      category: product.category,
      colors: product.colors,
      material: product.material,
      gender: product.gender,
      season: product.season,
      description: product.description,
      stock: product.stock,
      rating: 0.0, // Reset rating cho sản phẩm mới
      reviewCount: 0, // Reset review count
      isHot: false, // Reset hot status
    );

    try {
      Map<String, dynamic> result = await FirebaseProductService.addProduct(duplicatedProduct);
      
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sao chép sản phẩm thành công!'),
            backgroundColor: Colors.green,
          ),
        );
        // Reload products
        _loadProducts();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi sao chép sản phẩm: ${result['error']}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
