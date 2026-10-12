import 'package:deal/Seller/pages/add_product_page.dart';
import 'package:deal/Seller/pages/seller_messages_page.dart';
import 'package:deal/Seller/pages/seller_profile_page.dart';
import 'package:deal/Seller/widgets/seller_summary_card.dart';
import 'package:deal/core/app_localizations.dart';
import 'package:deal/core/constants/product_categories.dart';
import 'package:deal/core/models/product_model.dart';
import 'package:deal/services/firebase/auth_service.dart';
import 'package:deal/services/firebase/firestore_service.dart';
import 'package:deal/services/firebase/notification_service.dart';
import 'package:deal/services/firebase/storage_service.dart';
import 'package:deal/widgets/app_header_actions.dart';
import 'package:deal/widgets/footer.dart';
import 'package:deal/widgets/header.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SellerDashboardPage extends StatefulWidget {
  const SellerDashboardPage({super.key});

  @override
  State<SellerDashboardPage> createState() => _SellerDashboardPageState();
}

class _SellerDashboardPageState extends State<SellerDashboardPage> {
  String _selectedFilter = ProductCategories.all;
  Future<void> _logout(BuildContext context) async {
    final notificationsDisabledError = AppStrings.of(context, 'notifications_disabled_error');
    final notificationsDisconnectWarning = AppStrings.of(
      context,
      'notifications_disconnect_warning',
    );
    final cancelText = AppStrings.of(context, 'cancel');
    final logoutText = AppStrings.of(context, 'logout');

    try {
      await NotificationService.unregisterCurrentDevice();
    } catch (e) {
      debugPrint('FCM cleanup failed: $e');

      if (!context.mounted) return;

      final continueLogout = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(notificationsDisabledError),
          content: Text(notificationsDisconnectWarning),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(cancelText),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(logoutText),
            ),
          ],
        ),
      );

      if (continueLogout != true) return;
    }

    await DealAuthService.signOut();

    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
    }
  }

  bool _notificationsEnabled = false;

  Future<void> _deleteProduct(BuildContext context, Product product) async {
    final productDeleteTitle = AppStrings.of(context, 'product_delete_title');
    final productDeleteConfirm = AppStrings.of(context, 'product_delete_confirm');
    final cancelText = AppStrings.of(context, 'cancel');
    final deleteText = AppStrings.of(context, 'delete');
    final successDeleted = AppStrings.of(context, 'successfully_deleted');
    final couldNotDeleteProductImage = AppStrings.of(context, 'could_not_delete_product_image');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(productDeleteTitle),
        content: Text('$productDeleteConfirm "${product.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(cancelText)),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(deleteText, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final imageUrls = <String>[];
      if (product.imageUrls.isNotEmpty) {
        imageUrls.addAll(product.imageUrls);
      }
      if (product.imageUrl.isNotEmpty && !imageUrls.contains(product.imageUrl)) {
        imageUrls.add(product.imageUrl);
      }

      await StorageService.deleteProductImages(imageUrls);
      await FirestoreService.deleteListing(product.id);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(successDeleted)));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$couldNotDeleteProductImage: $e')));
      }
    }
  }

  List<Product> _sortedProducts(List<Product> products) {
    final sorted = List<Product>.from(products);
    sorted.sort((a, b) {
      final aTime = a.createdAt?.millisecondsSinceEpoch ?? 0;
      final bTime = b.createdAt?.millisecondsSinceEpoch ?? 0;
      return bTime.compareTo(aTime);
    });
    return sorted;
  }

  List<Product> _filteredProducts(List<Product> products, String activeFilter) {
    if (activeFilter == ProductCategories.all) {
      return products;
    }
    return products.where((product) => product.category.trim() == activeFilter).toList();
  }

  List<SellerSummaryCard> _buildSummaryCards(List<Product> products) {
    final counts = <String, int>{
      for (final category in ProductCategories.categories) category.name: 0,
    };

    for (final product in products) {
      final categoryName = product.category.trim();

      if (counts.containsKey(categoryName)) {
        counts[categoryName] = (counts[categoryName] ?? 0) + 1;
      }
    }

    return ProductCategories.categories.map((category) {
      return SellerSummaryCard(
        title: category.name,
        value: '${counts[category.name] ?? 0}',
        color: category.color,
        icon: category.icon,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final headingColor = isDark ? Colors.white : const Color(0xFF12324A);
    return Scaffold(
      appBar: AppBar(
        title: const DealHeader(showSubtitle: false),
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: _notificationsEnabled
                ? AppStrings.of(context, 'notifications_enabled')
                : AppStrings.of(context, 'notifications_disabled'),
            icon: Icon(
              _notificationsEnabled
                  ? Icons.notifications_active
                  : Icons.notifications_active_outlined,
              color: _notificationsEnabled ? Colors.green : null,
            ),
            onPressed: () async {
              final notificationsSuccess = AppStrings.of(context, 'notifications_success');
              final notificationsFailure = AppStrings.of(context, 'notifications_failure');
              final messenger = ScaffoldMessenger.maybeOf(context);

              final success = await NotificationService.testAndroidFcm();

              if (!mounted) return;

              setState(() {
                _notificationsEnabled = success;
              });

              if (messenger == null) return;

              messenger.showSnackBar(
                SnackBar(
                  content: Text(success ? notificationsSuccess : notificationsFailure),
                  backgroundColor: success ? Colors.green : Colors.red,
                  duration: const Duration(seconds: 3),
                ),
              );
            },
          ),

          IconButton(
            tooltip: AppStrings.of(context, 'profile_button'),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SellerProfilePage()));
            },
            icon: const Icon(Icons.account_circle_outlined),
          ),
          const AppHeaderActions(),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.of(context, 'dashboard_title'),
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: headingColor),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pushNamed(context, '/seller-add-product'),
                      icon: const Icon(Icons.add_circle_outline_rounded),
                      label: Text(AppStrings.of(context, 'add_product')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2A9D8F),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SellerMessagesPage()),
                        );
                      },
                      icon: const Icon(Icons.chat_bubble_outline_rounded),
                      label: Text(AppStrings.of(context, 'all_chats')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF12324A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              if (user == null)
                const SizedBox.shrink()
              else
                StreamBuilder(
                  stream: FirestoreService.streamListingsBySeller(user.uid),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    final products = _sortedProducts(
                      (snapshot.data?.docs ?? <dynamic>[])
                          .map((doc) => Product.fromMap(doc.data(), id: doc.id))
                          .toList()
                          .cast<Product>(),
                    );

                    return Column(
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF12324A),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                AppStrings.of(context, 'total_products'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                '${products.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        GridView.count(
                          shrinkWrap: true,
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.5,
                          physics: const NeverScrollableScrollPhysics(),
                          children: _buildSummaryCards(products),
                        ),
                      ],
                    );
                  },
                ),
              const SizedBox(height: 22),
              Text(
                AppStrings.of(context, 'my_products'),
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: headingColor),
              ),
              const SizedBox(height: 10),
              if (user == null)
                Center(child: Text(AppStrings.of(context, 'login_required')))
              else
                StreamBuilder(
                  stream: FirestoreService.streamListingsBySeller(user.uid),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Text('${AppStrings.of(context, 'error_prefix')}${snapshot.error}');
                    }

                    final products = _sortedProducts(
                      (snapshot.data?.docs ?? <dynamic>[])
                          .map((doc) => Product.fromMap(doc.data(), id: doc.id))
                          .toList()
                          .cast<Product>(),
                    );
                    final filteredProducts = _filteredProducts(products, _selectedFilter);

                    return Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedFilter,
                              isExpanded: true,
                              items: ProductCategories.withAll
                                  .map(
                                    (item) => DropdownMenuItem<String>(
                                      value: item,
                                      child: Text(
                                        ProductCategories.localizedName(
                                          item,
                                          Localizations.localeOf(context),
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                if (value == null) return;

                                setState(() {
                                  _selectedFilter = value;
                                });
                              },
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        if (filteredProducts.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Text(AppStrings.of(context, 'no_products_in_category')),
                          )
                        else
                          ListView.separated(
                            physics: const NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            itemCount: filteredProducts.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final property = filteredProducts[index];

                              return Card(
                                child: ListTile(
                                  leading: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      property.imageUrl,
                                      width: 72,
                                      height: 72,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  title: Text(property.title),
                                  subtitle: Text('${property.location} • ${property.price}'),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      StreamBuilder(
                                        stream: FirestoreService.watchMessages(property.id),
                                        builder: (context, snapshot) {
                                          final count = snapshot.data?.docs.length ?? 0;

                                          return Stack(
                                            clipBehavior: Clip.none,
                                            children: [
                                              IconButton(
                                                tooltip: AppStrings.of(context, 'chat'),
                                                onPressed: () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (_) => SellerMessagesPage(
                                                        productId: property.id,
                                                      ),
                                                    ),
                                                  );
                                                },
                                                icon: const Icon(
                                                  Icons.chat_bubble_outline_rounded,
                                                  color: Color(0xFF2A9D8F),
                                                ),
                                              ),
                                              if (count > 0)
                                                Positioned(
                                                  right: -4,
                                                  top: -2,
                                                  child: Container(
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.red,
                                                      borderRadius: BorderRadius.circular(10),
                                                    ),
                                                    constraints: const BoxConstraints(
                                                      minWidth: 18,
                                                      minHeight: 18,
                                                    ),
                                                    child: Text(
                                                      '$count',
                                                      textAlign: TextAlign.center,
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.w700,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          );
                                        },
                                      ),

                                      IconButton(
                                        tooltip: AppStrings.of(context, 'edit'),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => AddProductPage(product: property),
                                            ),
                                          );
                                        },
                                        icon: const Icon(
                                          Icons.edit_outlined,
                                          color: Color(0xFF1F7A8C),
                                        ),
                                      ),

                                      IconButton(
                                        tooltip: AppStrings.of(context, 'delete'),
                                        onPressed: () => _deleteProduct(context, property),
                                        icon: const Icon(
                                          Icons.delete_outline_rounded,
                                          color: Colors.red,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                      ],
                    );
                  },
                ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _logout(context),
                  icon: const Icon(Icons.logout_rounded),
                  label: Text(AppStrings.of(context, 'logout')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF12324A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const AppFooter(),
    );
  }
}
