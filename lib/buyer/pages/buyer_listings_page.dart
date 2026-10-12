import 'package:deal/buyer/services/property_service.dart';
import 'package:deal/buyer/widgets/property_card.dart';
import 'package:deal/core/app_localizations.dart';
import 'package:deal/core/app_settings.dart';
import 'package:deal/core/constants/countries.dart';
import 'package:deal/core/constants/product_categories.dart';
import 'package:deal/core/models/product_model.dart';
import 'package:deal/widgets/app_header_actions.dart';
import 'package:deal/widgets/header.dart';
import 'package:deal/widgets/side_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class BuyerListingsPage extends StatefulWidget {
  const BuyerListingsPage({super.key});
  @override
  State<BuyerListingsPage> createState() => _BuyerListingsPageState();
}

class _BuyerListingsPageState extends State<BuyerListingsPage> {
  String _selectedCategory = 'الكل';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();
  bool _showPriceFilter = false;
  bool _filtersVisible = true;
  late final Future<List<Product>> _productsFuture;

  @override
  void initState() {
    super.initState();
    _productsFuture = PropertyService.getProperties();
  }

  bool _onProductScroll(UserScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical) return false;
    final show = switch (notification.direction) {
      ScrollDirection.forward => true,
      ScrollDirection.reverse => false,
      ScrollDirection.idle => _filtersVisible,
    };
    if (show != _filtersVisible && mounted) {
      setState(() => _filtersVisible = show);
    }
    return false;
  }

  List<Product> _filterProducts(List<Product> products, String countryCode) {
    final query = _searchQuery.trim().toLowerCase();
    final minPrice = double.tryParse(_minPriceController.text.replaceAll(',', '').trim());
    final maxPrice = double.tryParse(_maxPriceController.text.replaceAll(',', '').trim());
    return products.where((product) {
      final matchesCountry = product.countryCode == countryCode;
      final matchesCategory =
          _selectedCategory == ProductCategories.all ||
          product.category.trim() == _selectedCategory;
      final matchesSearch =
          query.isEmpty ||
          product.title.toLowerCase().contains(query) ||
          product.description.toLowerCase().contains(query) ||
          product.location.toLowerCase().contains(query);
      final price = double.tryParse(product.price.replaceAll(',', '').trim());
      final matchesPrice =
          (minPrice == null && maxPrice == null) ||
          (price != null &&
              (minPrice == null || price >= minPrice) &&
              (maxPrice == null || price <= maxPrice));
      return matchesCountry && matchesCategory && matchesSearch && matchesPrice;
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.of(context)!;
    final selectedCountry = settings.selectedCountry;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : const Color(0xFF12324A);
    final secondaryColor = isDark ? const Color(0xFFB8C4D4) : const Color(0xFF6B7A90);
    return Scaffold(
      appBar: AppBar(
        title: const DealHeader(showSubtitle: false),
        centerTitle: false,
        actions: const [AppHeaderActions()],
      ),
      drawer: const AppSideBar(),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedSize(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeInOut,
              alignment: Alignment.topCenter,
              child: _filtersVisible
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.of(context, 'products_title'),
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: titleColor,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          AppStrings.of(context, 'products_subtitle'),
                          style: TextStyle(color: secondaryColor, fontSize: 14),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                onChanged: (value) {
                                  setState(() {
                                    _searchQuery = value;
                                  });
                                },
                                textInputAction: TextInputAction.search,
                                decoration: InputDecoration(
                                  hintText: settings.locale.languageCode == 'ar'
                                      ? 'ابحث عن سيارة، هاتف، أثاث...'
                                      : 'Search cars, phones, furniture...',
                                  prefixIcon: const Icon(Icons.search_rounded),
                                  suffixIcon: _searchQuery.isNotEmpty
                                      ? IconButton(
                                          tooltip: 'مسح البحث',
                                          icon: const Icon(Icons.close_rounded),
                                          onPressed: () {
                                            _searchController.clear();
                                            setState(() {
                                              _searchQuery = '';
                                            });
                                          },
                                        )
                                      : null,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 14,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton.filledTonal(
                              tooltip: settings.locale.languageCode == 'ar'
                                  ? 'فلتر السعر'
                                  : 'Price filter',
                              onPressed: () {
                                setState(() {
                                  _showPriceFilter = !_showPriceFilter;
                                });
                              },
                              icon: Icon(
                                _showPriceFilter ? Icons.filter_alt_rounded : Icons.tune_rounded,
                              ),
                            ),
                          ],
                        ),
                        if (_showPriceFilter) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _minPriceController,
                                  keyboardType: const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                                  onChanged: (_) => setState(() {}),
                                  decoration: InputDecoration(
                                    labelText: settings.locale.languageCode == 'ar'
                                        ? 'السعر من'
                                        : 'Min price',
                                    border: const OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _maxPriceController,
                                  keyboardType: const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                                  onChanged: (_) => setState(() {}),
                                  decoration: InputDecoration(
                                    labelText: settings.locale.languageCode == 'ar'
                                        ? 'السعر إلى'
                                        : 'Max price',
                                    border: const OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              IconButton(
                                tooltip: settings.locale.languageCode == 'ar'
                                    ? 'مسح السعر'
                                    : 'Clear price',
                                icon: const Icon(Icons.close_rounded),
                                onPressed: () {
                                  _minPriceController.clear();
                                  _maxPriceController.clear();
                                  setState(() {});
                                },
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 16),
                        // اختيار الدولة
                        Builder(
                          builder: (context) {
                            final settings = AppSettingsScope.of(context)!;
                            final selected = settings.selectedCountry;
                            final isArabic = settings.locale.languageCode == 'ar';
                            return PopupMenuButton<String>(
                              tooltip: isArabic ? 'تغيير الدولة' : 'Change country',
                              onSelected: (code) async {
                                await settings.setCountry(code);
                              },
                              itemBuilder: (context) {
                                return DealCountries.items.map((country) {
                                  return PopupMenuItem<String>(
                                    value: country.code,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(country.flag, style: const TextStyle(fontSize: 22)),
                                        const SizedBox(width: 10),
                                        Text(isArabic ? country.nameAr : country.nameEn),
                                        if (country.code == settings.countryCode) ...[
                                          const SizedBox(width: 12),
                                          const Icon(
                                            Icons.check_rounded,
                                            size: 18,
                                            color: Color(0xFF2A9D8F),
                                          ),
                                        ],
                                      ],
                                    ),
                                  );
                                }).toList();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Theme.of(context).dividerColor),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.location_on_outlined, size: 20),
                                    const SizedBox(width: 8),
                                    Text(selected.flag, style: const TextStyle(fontSize: 20)),
                                    const SizedBox(width: 6),
                                    Text(
                                      isArabic ? selected.nameAr : selected.nameEn,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        // فلتر الفئات
                        SizedBox(
                          height: 42,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: ProductCategories.withAll.length,
                            separatorBuilder: (_, _) => const SizedBox(width: 8),
                            itemBuilder: (context, index) {
                              final category = ProductCategories.withAll[index];
                              final isSelected = category == _selectedCategory;
                              final displayName = ProductCategories.localizedName(
                                category,
                                settings.locale,
                              );

                              return ChoiceChip(
                                label: Text(displayName),
                                selected: isSelected,
                                onSelected: (_) {
                                  setState(() {
                                    _selectedCategory = category;
                                  });
                                },
                                selectedColor: const Color(0xFF1F7A8C),
                                backgroundColor: Colors.white,
                                labelStyle: TextStyle(
                                  color: isSelected ? Colors.white : const Color(0xFF12324A),
                                  fontWeight: FontWeight.w600,
                                ),
                                side: BorderSide(
                                  color: isSelected
                                      ? const Color(0xFF1F7A8C)
                                      : const Color(0xFFE2E8F0),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                showCheckmark: false,
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 18),
                      ],
                    )
                  : Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: TextButton.icon(
                        onPressed: () => setState(() => _filtersVisible = true),
                        icon: const Icon(Icons.expand_more_rounded),
                        label: Text(
                          settings.locale.languageCode == 'ar'
                              ? 'إظهار البحث والفلاتر'
                              : 'Show search and filters',
                        ),
                      ),
                    ),
            ),
            Expanded(
              child: FutureBuilder<List<Product>>(
                future: _productsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return const Center(child: Text('تعذر تحميل الإعلانات'));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(child: Text(AppStrings.of(context, 'no_products')));
                  }
                  final products = _filterProducts(snapshot.data!, selectedCountry.code);
                  if (products.isEmpty) {
                    return Center(
                      child: Text(
                        settings.locale.languageCode == 'ar'
                            ? 'لا توجد إعلانات مطابقة في ${selectedCountry.nameAr}'
                            : 'No matching listings in ${selectedCountry.nameEn}',
                        style: const TextStyle(color: Color(0xFF6B7A90), fontSize: 15),
                      ),
                    );
                  }
                  return NotificationListener<UserScrollNotification>(
                    onNotification: _onProductScroll,
                    child: ListView.separated(
                      itemCount: products.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        return PropertyCard(property: products[index]);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
