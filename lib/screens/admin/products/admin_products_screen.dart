import 'package:flutter/material.dart';
import '../../../models/models.dart';
import '../../../services/firebase_product_service.dart';
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
  int _currentPage = 0;
  final int _itemsPerPage = 8;

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
      final products = await FirebaseProductService.getAllProducts();
      setState(() {
        _products = products;
        _isLoading = false;
        _currentPage = 0;
      });
    } catch (e) {
      debugPrint('Error loading products: $e');
      setState(() {
        _products = [];
        _isLoading = false;
        _currentPage = 0;
      });
    }
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
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _currentPage = 0;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (value) => setState(() {
                    _currentPage = 0;
                  }),
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
                          label: Text(
                            category,
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
                              _selectedCategory = category;
                              _currentPage = 0;
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

          // Products list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Builder(
                    builder: (context) {
                      final filteredProducts = _getFilteredProducts();
                      if (filteredProducts.isEmpty) {
                        return Center(
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
                                style: TextStyle(color: Colors.grey.shade500),
                              ),
                            ],
                          ),
                        );
                      }

                      final totalPages =
                          (filteredProducts.length / _itemsPerPage).ceil();
                      int safePage = _currentPage;
                      if (safePage >= totalPages) {
                        safePage = totalPages - 1;
                      }
                      if (safePage < 0) {
                        safePage = 0;
                      }
                      if (safePage != _currentPage) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (!mounted) return;
                          setState(() {
                            _currentPage = safePage;
                          });
                        });
                      }

                      final pagedProducts = filteredProducts
                          .skip(safePage * _itemsPerPage)
                          .take(_itemsPerPage)
                          .toList();

                      return Column(
                        children: [
                          Expanded(
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: pagedProducts.length,
                              itemBuilder: (context, index) {
                                final product = pagedProducts[index];
                                return _buildProductCard(product);
                              },
                            ),
                          ),
                          if (totalPages > 1)
                            _buildPaginationControls(
                              currentPage: safePage,
                              totalPages: totalPages,
                              totalItems: filteredProducts.length,
                            ),
                        ],
                      );
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
          style: const TextStyle(fontWeight: FontWeight.w600),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: product.stock <= 0 ? Colors.red : Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Còn ${product.stock}',
                    style: const TextStyle(color: Colors.white, fontSize: 10),
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
      final matchesSearch =
          product.name.toLowerCase().contains(searchQuery) ||
          product.brand.toLowerCase().contains(searchQuery);

      final matchesCategory =
          _selectedCategory == 'Tất cả' ||
          product.category == _selectedCategory;

      return matchesSearch && matchesCategory;
    }).toList();
  }

  Widget _buildPaginationControls({
    required int currentPage,
    required int totalPages,
    required int totalItems,
  }) {
    final int startItem = currentPage * _itemsPerPage + 1;
    final int endItem = (startItem + _itemsPerPage - 1) > totalItems
        ? totalItems
        : startItem + _itemsPerPage - 1;
    final bool canGoBack = currentPage > 0;
    final bool canGoForward = currentPage < totalPages - 1;

    final Color baseBg = const Color(0xFFD6E8FF);
    final Color pressedBg = const Color(0xFFBFD9FF);
    final Color textColor = const Color(0xFF0B57D0);

    ButtonStyle pagingStyle =
        ElevatedButton.styleFrom(
          backgroundColor: baseBg,
          foregroundColor: textColor,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ).copyWith(
          backgroundColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.disabled)) {
              return baseBg.withOpacity(0.45);
            }
            if (states.contains(MaterialState.pressed)) {
              return pressedBg;
            }
            return baseBg;
          }),
          foregroundColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.disabled)) {
              return textColor.withOpacity(0.4);
            }
            return textColor;
          }),
          iconColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.disabled)) {
              return textColor.withOpacity(0.4);
            }
            return textColor;
          }),
        );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Hiển thị $startItem-$endItem trong $totalItems sản phẩm',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: canGoBack
                    ? () => setState(() {
                        _currentPage = currentPage - 1;
                      })
                    : null,
                icon: const Icon(Icons.chevron_left, size: 18),
                label: const Text('Trước'),
                style: pagingStyle,
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: canGoForward
                    ? () => setState(() {
                        _currentPage = currentPage + 1;
                      })
                    : null,
                label: const Text('Sau'),
                icon: const Icon(Icons.chevron_right, size: 18),
                style: pagingStyle,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _addProduct() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddProductScreen()),
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
                Map<String, dynamic> result =
                    await FirebaseProductService.deleteProduct(product.id);

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
      Map<String, dynamic> result = await FirebaseProductService.addProduct(
        duplicatedProduct,
      );

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
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
      );
    }
  }
}
