import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../../../models/models.dart';
import '../../../services/firebase_product_service.dart';
import '../../../services/product_cache_service.dart';
import '../../../widgets/safe_network_image.dart';
import '../../../widgets/shimmer_placeholder.dart';
import 'product_detail_screen.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'Tất cả';
  String _selectedSort = 'Mặc định';
  final Set<String> _selectedBrands = <String>{};
  final Set<String> _selectedColors = <String>{};
  double? _minPriceFilter;
  double? _maxPriceFilter;

  final List<String> _categories = [
    'Tất cả',
    'Nón Snapback',
    'Nón Bucket',
    'Nón Fedora',
    'Nón Beanie',
    'Nón Trucker',
    'Nón Baseball',
  ];

  final List<String> _sortOptions = [
    'Mặc định',
    'Giá thấp đến cao',
    'Giá cao đến thấp',
    'Đánh giá cao nhất',
    'Mới nhất',
  ];

  final List<String> _brandOptions = const [
    'HatStyle',
    'Urban Style',
    'Classic',
    'Sporty',
    'Cozy',
    'Retro',
  ];

  final List<String> _colorOptions = const [
    'Đen',
    'Trắng',
    'Xanh Navy',
    'Xám',
    'Nâu',
    'Camo',
  ];

  @override
  void initState() {
    super.initState();
    // Load cached products first for fast startup
    try {
      final cached = ProductCacheService.getCachedProducts();
      if (cached.isNotEmpty) {
        _products.addAll(cached);
      }
    } catch (_) {}

    _loadFirstPage();

    // listen to search input with debounce
    _searchController.addListener(_onSearchChanged);
  }

  Timer? _searchDebounce;

  void _onSearchChanged() {
    if (_searchDebounce?.isActive ?? false) _searchDebounce!.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      // Reload products when search changes
      _loadFirstPage();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Sản Phẩm'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterBottomSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm sản phẩm...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {}); // Trigger rebuild
                  },
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) => setState(() {}), // Trigger rebuild
            ),
          ),

          // Category filter
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16),
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
                      // Reload products when category changes so server-side filter is applied
                      _loadFirstPage();
                    },
                    backgroundColor: Colors.white,
                    selectedColor: Colors.blue.shade100,
                    checkmarkColor: Colors.blue.shade600,
                  ),
                );
              },
            ),
          ),

          // Sort and count
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Sản phẩm',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
                DropdownButton<String>(
                  value: _selectedSort,
                  underline: const SizedBox(),
                  items: _sortOptions.map((String option) {
                    return DropdownMenuItem<String>(
                      value: option,
                      child: Text(option),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedSort = newValue!;
                    });
                    // Reload products when sort changes so server-side ordering is applied
                    _loadFirstPage();
                  },
                ),
              ],
            ),
          ),

          // Products grid (paginated)
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await _refreshProducts();
              },
              child: LayoutBuilder(
                builder: (context, constraints) {
                  int crossAxisCount = 2;
                  if (constraints.maxWidth > 600) {
                    crossAxisCount = 3;
                  }
                  if (constraints.maxWidth > 900) {
                    crossAxisCount = 4;
                  }

                  final filteredProducts = _getFilteredProducts(_products);

                  if (_isLoading && _products.isEmpty) {
                    // show grid shimmer while initial load is in progress
                    return ShimmerGridView(
                      count: crossAxisCount * 4,
                      crossAxisCount: crossAxisCount,
                      childAspectRatio: 0.7,
                    );
                  }

                  if (filteredProducts.isEmpty) {
                    return SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: SizedBox(
                        height: constraints.maxHeight,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Không tìm thấy sản phẩm',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Hãy thử tìm kiếm với từ khóa khác',
                                style: TextStyle(color: Colors.grey.shade500),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  return NotificationListener<ScrollNotification>(
                    onNotification: (notification) {
                      if (notification is ScrollEndNotification &&
                          _scrollController.position.extentAfter < 300 &&
                          !_isLoading &&
                          _hasMore) {
                        _loadMore();
                      }
                      return false;
                    },
                    child: GridView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        childAspectRatio: 0.7,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: filteredProducts.length + (_hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index < filteredProducts.length) {
                          final product = filteredProducts[index];
                          return _buildProductCard(product);
                        }
                        // loader item
                        return const Center(child: CircularProgressIndicator());
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Pagination state
  final ScrollController _scrollController = ScrollController();
  final List<HatProduct> _products = [];
  DocumentSnapshot? _lastDoc;
  bool _isLoading = false;
  bool _hasMore = true;

  Future<void> _loadFirstPage() async {
    _products.clear();
    _lastDoc = null;
    _hasMore = true;
    await _loadMore();
  }

  Future<void> _refreshProducts() async {
    _products.clear();
    _lastDoc = null;
    _hasMore = true;
    await _loadMore();
  }

  Future<void> _loadMore() async {
    if (!_hasMore) return;
    setState(() => _isLoading = true);
    // Determine server-side ordering based on selected sort
    String orderByField = 'createdAt';
    bool descending = true;
    switch (_selectedSort) {
      case 'Giá thấp đến cao':
        orderByField = 'price';
        descending = false;
        break;
      case 'Giá cao đến thấp':
        orderByField = 'price';
        descending = true;
        break;
      case 'Đánh giá cao nhất':
        orderByField = 'rating';
        descending = true;
        break;
      case 'Mới nhất':
        orderByField = 'createdAt';
        descending = true;
        break;
      default:
        orderByField = 'createdAt';
        descending = true;
    }

    final res = await FirebaseProductService.getProductsPage(
      limit: 24,
      startAfterDoc: _lastDoc,
      orderByField: orderByField,
      descending: descending,
      category: _selectedCategory == 'Tất cả' ? null : _selectedCategory,
      search: _searchController.text.trim().isEmpty
          ? null
          : _searchController.text.trim(),
    );
    final List<HatProduct> fetched = List<HatProduct>.from(
      res['products'] ?? [],
    );
    final DocumentSnapshot? last = res['lastDoc'] as DocumentSnapshot?;

    setState(() {
      _products.addAll(fetched);
      _lastDoc = last;
      _isLoading = false;
      if (fetched.isEmpty || last == null) {
        _hasMore = false;
      }
    });

    // Persist full cached list so next app launch shows something
    try {
      await ProductCacheService.cacheProducts(_products);
    } catch (_) {}
  }

  List<HatProduct> _getFilteredProducts(List<HatProduct> allProducts) {
    List<HatProduct> filtered = List.from(allProducts);

    // Filter by category
    if (_selectedCategory != 'Tất cả') {
      filtered = filtered
          .where((product) => product.category == _selectedCategory)
          .toList();
    }

    // Filter by search text
    if (_searchController.text.isNotEmpty) {
      final searchText = _searchController.text.toLowerCase();
      filtered = filtered.where((product) {
        return product.name.toLowerCase().contains(searchText) ||
            product.brand.toLowerCase().contains(searchText) ||
            product.description.toLowerCase().contains(searchText);
      }).toList();
    }

    if (_minPriceFilter != null) {
      filtered = filtered
          .where((product) => product.price >= _minPriceFilter!)
          .toList();
    }

    if (_maxPriceFilter != null) {
      filtered = filtered
          .where((product) => product.price <= _maxPriceFilter!)
          .toList();
    }

    if (_selectedBrands.isNotEmpty) {
      final Set<String> normalizedBrands = _selectedBrands
          .map((brand) => brand.toLowerCase())
          .toSet();
      filtered = filtered
          .where(
            (product) => normalizedBrands.contains(product.brand.toLowerCase()),
          )
          .toList();
    }

    if (_selectedColors.isNotEmpty) {
      final Set<String> normalizedSelectedColors = _selectedColors
          .map((c) => c.toLowerCase())
          .toSet();
      filtered = filtered.where((product) {
        final Iterable<String> productColors = product.colors.isEmpty
            ? const Iterable<String>.empty()
            : product.colors.map((c) => c.toLowerCase());
        return productColors.any(normalizedSelectedColors.contains);
      }).toList();
    }

    // Sort products
    switch (_selectedSort) {
      case 'Giá thấp đến cao':
        filtered.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'Giá cao đến thấp':
        filtered.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'Đánh giá cao nhất':
        filtered.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'Mới nhất':
        // Assuming products with higher ID are newer
        filtered.sort((a, b) => int.parse(b.id).compareTo(int.parse(a.id)));
        break;
      default:
        // Default sort - no change
        break;
    }

    return filtered;
  }

  Widget _buildProductCard(HatProduct product) {
    final bool isOutOfStock = product.stock <= 0;
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(product: product),
          ),
        );
      },
      child: Container(
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
            // Product image
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  color: Colors.grey.shade100,
                ),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                      child: SafeNetworkImage(
                        imageUrl: product.imageUrl,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        placeholderText: product.name,
                      ),
                    ),
                    if (isOutOfStock)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.55),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'Hết hàng',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    if (product.isHot)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'HOT',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Product info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.brand,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            '${product.price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}đ',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isOutOfStock
                                  ? Colors.grey.shade500
                                  : Colors.blue.shade600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.star,
                              size: 12,
                              color: Colors.amber.shade600,
                            ),
                            Text(
                              '${product.rating}',
                              style: const TextStyle(fontSize: 10),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterBottomSheet() {
    final TextEditingController minController = TextEditingController(
      text: _minPriceFilter != null ? _minPriceFilter!.toStringAsFixed(0) : '',
    );
    final TextEditingController maxController = TextEditingController(
      text: _maxPriceFilter != null ? _maxPriceFilter!.toStringAsFixed(0) : '',
    );

    final Set<String> tempBrands = Set<String>.from(_selectedBrands);
    final Set<String> tempColors = Set<String>.from(_selectedColors);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Bộ lọc',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    'Khoảng giá',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: minController,
                          decoration: const InputDecoration(
                            labelText: 'Từ',
                            hintText: '0',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: maxController,
                          decoration: const InputDecoration(
                            labelText: 'Đến',
                            hintText: '1000000',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  const Text(
                    'Thương hiệu',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _brandOptions.map((brand) {
                      final bool isSelected = tempBrands.contains(brand);
                      return FilterChip(
                        label: Text(brand),
                        selected: isSelected,
                        onSelected: (selected) {
                          setModalState(() {
                            if (selected) {
                              tempBrands.add(brand);
                            } else {
                              tempBrands.remove(brand);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 16),

                  const Text(
                    'Màu sắc',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _colorOptions.map((color) {
                      final bool isSelected = tempColors.contains(color);
                      return FilterChip(
                        label: Text(color),
                        selected: isSelected,
                        onSelected: (selected) {
                          setModalState(() {
                            if (selected) {
                              tempColors.add(color);
                            } else {
                              tempColors.remove(color);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _selectedBrands.clear();
                              _selectedColors.clear();
                              _minPriceFilter = null;
                              _maxPriceFilter = null;
                            });
                            Navigator.pop(context);
                          },
                          child: const Text('Đặt lại'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _selectedBrands
                                ..clear()
                                ..addAll(tempBrands);
                              _selectedColors
                                ..clear()
                                ..addAll(tempColors);
                              _minPriceFilter = _parsePrice(minController.text);
                              _maxPriceFilter = _parsePrice(maxController.text);
                              if (_minPriceFilter != null &&
                                  _maxPriceFilter != null &&
                                  _minPriceFilter! > _maxPriceFilter!) {
                                final double temp = _minPriceFilter!;
                                _minPriceFilter = _maxPriceFilter;
                                _maxPriceFilter = temp;
                              }
                            });
                            Navigator.pop(context);
                          },
                          child: const Text('Áp dụng'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      minController.dispose();
      maxController.dispose();
    });
  }

  double? _parsePrice(String value) {
    final String trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    final String sanitized = trimmed
        .replaceAll(RegExp(r'[đ\s]'), '')
        .replaceAll('.', '')
        .replaceAll(',', '');

    if (sanitized.isEmpty) {
      return null;
    }

    return double.tryParse(sanitized);
  }
}
