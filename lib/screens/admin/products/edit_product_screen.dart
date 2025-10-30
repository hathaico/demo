import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../models/models.dart';
import '../../../services/firebase_product_service.dart';
import '../../../services/image_base64_service.dart';

class EditProductScreen extends StatefulWidget {
  final HatProduct product;

  const EditProductScreen({super.key, required this.product});

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _colorController = TextEditingController();
  final List<String> _selectedColors = [];
  final _materialController = TextEditingController();

  String _selectedCategory = 'Nón Snapback';
  String _selectedGender = 'Unisex';
  String _selectedSeason = 'Quanh năm';
  bool _isHot = false;
  bool _isLoading = false;

  File? _selectedImage;
  String? _currentImageUrl;

  final List<String> _categories = [
    'Nón Snapback',
    'Nón Bucket',
    'Nón Fedora',
    'Nón Beanie',
    'Nón Trucker',
    'Nón Baseball',
  ];

  final List<String> _genders = ['Nam', 'Nữ', 'Unisex'];
  final List<String> _seasons = ['Xuân', 'Hè', 'Thu', 'Đông', 'Quanh năm'];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    _nameController.text = widget.product.name;
    _brandController.text = widget.product.brand;
    _priceController.text = widget.product.price.toString();
    _stockController.text = widget.product.stock.toString();
    _descriptionController.text = widget.product.description;
    _materialController.text = widget.product.material;
    _selectedCategory = widget.product.category;
    _selectedGender = widget.product.gender;
    _selectedSeason = widget.product.season;
    _isHot = widget.product.isHot;
    _selectedColors.clear();
    _selectedColors.addAll(widget.product.colors);
    _currentImageUrl = widget.product.imageUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _descriptionController.dispose();
    _colorController.dispose();
    _materialController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Chỉnh sửa sản phẩm'),
        backgroundColor: Colors.red.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image upload section
                    _buildImageUploadSection(),

                    const SizedBox(height: 24),

                    // Basic information
                    _buildSectionTitle('Thông tin cơ bản'),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Tên sản phẩm *',
                        border: OutlineInputBorder(),
                        hintText: 'Nhập tên sản phẩm',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập tên sản phẩm';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _brandController,
                      decoration: const InputDecoration(
                        labelText: 'Thương hiệu *',
                        border: OutlineInputBorder(),
                        hintText: 'Nhập thương hiệu',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập thương hiệu';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Mô tả sản phẩm',
                        border: OutlineInputBorder(),
                        hintText: 'Nhập mô tả sản phẩm',
                      ),
                      maxLines: 3,
                    ),

                    const SizedBox(height: 24),

                    // Price and stock
                    _buildSectionTitle('Giá và tồn kho'),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _priceController,
                            decoration: const InputDecoration(
                              labelText: 'Giá (VNĐ) *',
                              border: OutlineInputBorder(),
                              hintText: '0',
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Vui lòng nhập giá';
                              }
                              if (double.tryParse(value) == null) {
                                return 'Giá không hợp lệ';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _stockController,
                            decoration: const InputDecoration(
                              labelText: 'Số lượng *',
                              border: OutlineInputBorder(),
                              hintText: '0',
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Vui lòng nhập số lượng';
                              }
                              if (int.tryParse(value) == null) {
                                return 'Số lượng không hợp lệ';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Category and attributes
                    _buildSectionTitle('Danh mục và thuộc tính'),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _selectedCategory,
                            decoration: const InputDecoration(
                              labelText: 'Danh mục',
                              border: OutlineInputBorder(),
                            ),
                            items: _categories.map((String category) {
                              return DropdownMenuItem<String>(
                                value: category,
                                child: Text(category),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                _selectedCategory = newValue!;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _selectedGender,
                            decoration: const InputDecoration(
                              labelText: 'Giới tính',
                              border: OutlineInputBorder(),
                            ),
                            items: _genders.map((String gender) {
                              return DropdownMenuItem<String>(
                                value: gender,
                                child: Text(gender),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                _selectedGender = newValue!;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _selectedSeason,
                            decoration: const InputDecoration(
                              labelText: 'Mùa vụ',
                              border: OutlineInputBorder(),
                            ),
                            items: _seasons.map((String season) {
                              return DropdownMenuItem<String>(
                                value: season,
                                child: Text(season),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                _selectedSeason = newValue!;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _selectedSeason,
                            decoration: const InputDecoration(
                              labelText: 'Mùa vụ',
                              border: OutlineInputBorder(),
                            ),
                            items: _seasons.map((String season) {
                              return DropdownMenuItem<String>(
                                value: season,
                                child: Text(season),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                _selectedSeason = newValue!;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Màu sắc - Multiple selection
                    _buildColorSelection(),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _materialController,
                      decoration: const InputDecoration(
                        labelText: 'Chất liệu',
                        border: OutlineInputBorder(),
                        hintText: 'Nhập chất liệu',
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Hot product toggle
                    _buildSectionTitle('Cài đặt khác'),
                    const SizedBox(height: 12),

                    SwitchListTile(
                      title: const Text('Sản phẩm hot'),
                      subtitle: const Text('Hiển thị sản phẩm nổi bật'),
                      value: _isHot,
                      onChanged: (bool value) {
                        setState(() {
                          _isHot = value;
                        });
                      },
                      activeColor: Colors.red.shade600,
                    ),

                    const SizedBox(height: 32),

                    // Save button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _saveProduct,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade600,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Cập nhật sản phẩm',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildImageUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Hình ảnh sản phẩm',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),

        Container(
          width: double.infinity,
          height: 200,
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.grey.shade300,
              width: 2,
              style: BorderStyle.solid,
            ),
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey.shade50,
          ),
          child: _selectedImage != null
              ? Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(
                        _selectedImage!,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () {
                            setState(() {
                              _selectedImage = null;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                )
              : _currentImageUrl != null &&
                    _currentImageUrl != 'placeholder_widget'
              ? Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        _currentImageUrl!,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildImagePlaceholder();
                        },
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () {
                            setState(() {
                              _currentImageUrl = null;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                )
              : _buildImagePlaceholder(),
        ),
      ],
    );
  }

  Widget _buildImagePlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.add_photo_alternate_outlined,
          size: 48,
          color: Colors.grey.shade400,
        ),
        const SizedBox(height: 8),
        Text(
          'Chọn hình ảnh sản phẩm',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: _pickImageFromGallery,
              icon: const Icon(Icons.photo_library),
              label: const Text('Thư viện'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: _pickImageFromCamera,
              icon: const Icon(Icons.camera_alt),
              label: const Text('Camera'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi chọn hình ảnh: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi chụp ảnh: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Widget để chọn nhiều màu sắc
  Widget _buildColorSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Màu sắc',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),

        // Hiển thị các màu đã chọn
        if (_selectedColors.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _selectedColors.map((color) {
              return Chip(
                label: Text(color),
                onDeleted: () {
                  setState(() {
                    _selectedColors.remove(color);
                  });
                },
                deleteIcon: const Icon(Icons.close, size: 18),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
        ],

        // Nút thêm màu mới
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _colorController,
                decoration: const InputDecoration(
                  labelText: 'Thêm màu sắc',
                  border: OutlineInputBorder(),
                  hintText: 'Nhập màu sắc (VD: Đỏ, Xanh, Đen)',
                ),
                onFieldSubmitted: (value) {
                  _addColor(value.trim());
                },
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () {
                _addColor(_colorController.text.trim());
              },
              icon: const Icon(Icons.add),
              label: const Text('Thêm'),
            ),
          ],
        ),

        // Danh sách màu phổ biến
        const SizedBox(height: 12),
        const Text(
          'Màu phổ biến:',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ['Đen', 'Trắng', 'Đỏ', 'Xanh', 'Vàng', 'Hồng', 'Xám', 'Nâu']
              .map((color) {
                bool isSelected = _selectedColors.contains(color);
                return FilterChip(
                  label: Text(color),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        if (!_selectedColors.contains(color)) {
                          _selectedColors.add(color);
                        }
                      } else {
                        _selectedColors.remove(color);
                      }
                    });
                  },
                );
              })
              .toList(),
        ),
      ],
    );
  }

  void _addColor(String color) {
    if (color.isNotEmpty && !_selectedColors.contains(color)) {
      setState(() {
        _selectedColors.add(color);
        _colorController.clear();
      });
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String imageData = _currentImageUrl ?? '';

      // Nếu có hình ảnh mới, chuyển đổi thành base64
      if (_selectedImage != null) {
        Map<String, dynamic> convertResult =
            await ImageBase64Service.uploadProductImageAsBase64(
              imageFile: _selectedImage!,
              productId: widget.product.id,
              quality: 85,
              maxSizeInMB: 5,
            );

        if (convertResult['success'] == true) {
          imageData = convertResult['dataUrl'];
          print('Chuyển đổi thành công: ${convertResult['fileSize']} bytes');
        } else {
          print('Convert failed: ${convertResult['error']}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Lỗi chuyển đổi hình ảnh: ${convertResult['error']}',
              ),
              backgroundColor: Colors.red,
            ),
          );
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }

      // Create updated product object
      HatProduct updatedProduct = HatProduct(
        id: widget.product.id,
        name: _nameController.text.trim(),
        brand: _brandController.text.trim(),
        price: double.parse(_priceController.text),
        imageUrl: imageData,
        category: _selectedCategory,
        colors: _selectedColors.isEmpty ? ['Không xác định'] : _selectedColors,
        material: _materialController.text.trim().isEmpty
            ? 'Không xác định'
            : _materialController.text.trim(),
        gender: _selectedGender,
        season: _selectedSeason,
        description: _descriptionController.text.trim().isEmpty
            ? 'Chưa có mô tả'
            : _descriptionController.text.trim(),
        stock: int.parse(_stockController.text),
        rating: widget.product.rating,
        reviewCount: widget.product.reviewCount,
        isHot: _isHot,
      );

      // Update product in Firebase
      Map<String, dynamic> result = await FirebaseProductService.updateProduct(
        widget.product.id,
        updatedProduct,
      );

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cập nhật sản phẩm thành công!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate success
      } else {
        throw Exception(result['error'] ?? 'Lỗi cập nhật sản phẩm');
      }
    } catch (e) {
      print('Error updating product: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
