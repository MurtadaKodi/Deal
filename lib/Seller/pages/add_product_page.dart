import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:deal/core/app_localizations.dart';
import 'package:deal/core/constants/countries.dart';
import 'package:deal/core/constants/product_categories.dart';
import 'package:deal/core/models/product_model.dart';
import 'package:deal/services/firebase/firestore_service.dart';
import 'package:deal/services/firebase/seller_profile_service.dart';
import 'package:deal/services/firebase/storage_service.dart';
import 'package:deal/widgets/app_header_actions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key, this.product});

  final Product? product;

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _categoryController = TextEditingController(text: ProductCategories.all);
  final _locationController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final List<XFile> _selectedImages = [];
  bool _isSaving = false;

  bool get _isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final p = widget.product!;
      _titleController.text = p.title;
      _descriptionController.text = p.description;
      _priceController.text = p.price;
      _categoryController.text = p.category;
      _locationController.text = p.location;
      _imageUrlController.text = p.imageUrl;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _categoryController.dispose();
    _locationController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final images = await _picker.pickMultiImage(imageQuality: 80);
    if (images.isEmpty) return;

    setState(
      () => _selectedImages
        ..clear()
        ..addAll(images),
    );
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw FirebaseException(
          plugin: 'firebase_auth',
          code: 'auth-required',
          message: 'يجب تسجيل الدخول كـ بائع أولاً',
        );
      }
      final sellerProfile = await SellerProfileService.getProfile(user.uid);

      if (sellerProfile == null) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'seller-profile-not-found',
          message: 'لم يتم العثور على الملف الشخصي للبائع',
        );
      }

      final sellerCountry = DealCountries.byCode(sellerProfile.countryCode);

      List<String> imageUrls = [];
      final manualImageUrl = _imageUrlController.text.trim();

      if (_selectedImages.isNotEmpty) {
        imageUrls = await StorageService.uploadProductImages(
          folder: 'products',
          files: _selectedImages,
        );
      } else if (_isEditing && widget.product != null) {
        imageUrls = [...widget.product!.imageUrls];
        if (widget.product!.imageUrl.isNotEmpty && !imageUrls.contains(widget.product!.imageUrl)) {
          imageUrls.add(widget.product!.imageUrl);
        }
      } else if (manualImageUrl.isNotEmpty) {
        imageUrls = [manualImageUrl];
      }

      final primaryImageUrl = imageUrls.isNotEmpty
          ? imageUrls.first
          : (manualImageUrl.isNotEmpty ? manualImageUrl : '');

      if (primaryImageUrl.isEmpty) {
        imageUrls = [
          'https://images.unsplash.com/photo-1505693416388-ac5ce068fe85?auto=format&fit=crop&w=900&q=80',
        ];
      }

      final productData = {
        'title': _titleController.text.trim(),
        'category': _categoryController.text.trim().isEmpty
            ? 'عام'
            : _categoryController.text.trim(),
        'location': _locationController.text.trim(),
        'price': _priceController.text.trim(),

        // Country & currency
        'countryCode': sellerCountry.code,
        'currencyCode': sellerCountry.currencyCode,

        'imageUrl': imageUrls.first,
        'imageUrls': imageUrls,
        'description': _descriptionController.text.trim(),
        'sellerName': sellerProfile.username,
        'sellerPhone': sellerProfile.phone,
        'sellerId': user.uid,
      };

      if (_isEditing && widget.product != null) {
        await FirestoreService.updateListing(widget.product!.id, productData);
      } else {
        await FirestoreService.addListing({
          ...productData,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? AppStrings.of(context, 'product_updated_successfully')
                : AppStrings.of(context, 'product_added_successfully'),
          ),
        ),
      );

      Navigator.pop(context, true);
    } on FirebaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${AppStrings.of(context, 'failed_to_save')}: ${e.message ?? AppStrings.of(context, 'firebase_settings_check')}',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppStrings.of(context, 'could_not_save_product')}: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? AppStrings.of(context, 'edit') : AppStrings.of(context, 'add_product'),
        ),
        actions: const [AppHeaderActions()],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.of(context, 'product_data'),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF12324A),
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _titleController,
                  validator: (value) => value == null || value.trim().isEmpty
                      ? AppStrings.of(context, 'enter_product_title')
                      : null,
                  decoration: _inputDecoration(AppStrings.of(context, 'product_title')),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 4,
                  validator: (value) => value == null || value.trim().isEmpty
                      ? AppStrings.of(context, 'enter_product_description')
                      : null,
                  decoration: _inputDecoration(AppStrings.of(context, 'product_description')),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _priceController,
                        keyboardType: TextInputType.number,
                        validator: (value) => value == null || value.trim().isEmpty
                            ? AppStrings.of(context, 'enter_product_price')
                            : null,
                        decoration: _inputDecoration(AppStrings.of(context, 'product_price')),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: ProductCategories.withAll.contains(_categoryController.text)
                            ? _categoryController.text
                            : ProductCategories.withAll.first,
                        decoration: _inputDecoration(AppStrings.of(context, 'product_category')),
                        items: ProductCategories.withAll
                            .map(
                              (category) => DropdownMenuItem<String>(
                                value: category,
                                child: Text(
                                  ProductCategories.localizedName(
                                    category,
                                    Localizations.localeOf(context),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            _categoryController.text = value;
                          }
                        },
                        validator: (value) => value == null || value.trim().isEmpty
                            ? AppStrings.of(context, 'choose_category')
                            : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _locationController,
                  validator: (value) => value == null || value.trim().isEmpty
                      ? AppStrings.of(context, 'enter_product_location')
                      : null,
                  decoration: _inputDecoration(AppStrings.of(context, 'product_location')),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: _pickImages,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.photo_library_rounded, color: Color(0xFF1F7A8C)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _selectedImages.isEmpty
                                ? AppStrings.of(context, 'select_product_images')
                                : '${_selectedImages.length} ${AppStrings.of(context, 'images_selected')}',
                            style: const TextStyle(color: Color(0xFF12324A)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_selectedImages.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _selectedImages
                        .map(
                          (image) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEAF3F7),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              image.name,
                              style: const TextStyle(fontSize: 12, color: Color(0xFF12324A)),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
                const SizedBox(height: 16),
                TextFormField(
                  controller: _imageUrlController,
                  decoration: _inputDecoration(AppStrings.of(context, 'primary_image_url_hint')),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _saveProduct,
                    icon: const Icon(Icons.check_rounded),
                    label: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(AppStrings.of(context, 'save_product')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1F7A8C),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF1F7A8C), width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }
}
