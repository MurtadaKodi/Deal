import 'package:deal/core/app_localizations.dart';
import 'package:deal/core/constants/countries.dart';
import 'package:deal/core/models/product_model.dart';
import 'package:deal/services/firebase/seller_profile_service.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class PropertyCard extends StatefulWidget {
  const PropertyCard({super.key, required this.property});

  final Product property;

  @override
  State<PropertyCard> createState() => _PropertyCardState();
}

class _PropertyCardState extends State<PropertyCard> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  Future<void> _openWhatsApp(BuildContext context) async {
    try {
      final sellerProfile = await SellerProfileService.getProfile(widget.property.sellerId);

      if (!context.mounted) return;

      if (sellerProfile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.of(context, 'seller_profile_load_failed'))),
        );
        return;
      }

      final country = DealCountries.byCode(sellerProfile.countryCode);

      final localPhone = sellerProfile.phone.replaceAll(RegExp(r'[^0-9]'), '');

      if (localPhone.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppStrings.of(context, 'seller_phone_not_added'))));
        return;
      }

      final phoneCode = country.phoneCode.replaceAll(RegExp(r'[^0-9]'), '');

      final phone = localPhone.startsWith(phoneCode) ? localPhone : '$phoneCode$localPhone';

      final uri = Uri.parse('https://wa.me/$phone');

      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        if (!context.mounted) return;

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppStrings.of(context, 'could_not_open_whatsapp'))));
      }
    } catch (_) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppStrings.of(context, 'seller_profile_load_failed'))));
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final titleColor = isDark ? Colors.white : const Color(0xFF12324A);

    final secondaryColor = isDark ? const Color(0xFFB8C4D4) : const Color(0xFF6B7A90);

    final descriptionColor = isDark ? const Color(0xFFD1D9E6) : const Color(0xFF4D5D72);
    final images = widget.property.imageUrls.isNotEmpty
        ? widget.property.imageUrls
        : (widget.property.imageUrl.isNotEmpty ? [widget.property.imageUrl] : const <String>[]);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 180,
            width: double.infinity,
            child: images.isEmpty
                ? Container(
                    color: const Color(0xFFEAF3F7),
                    child: const Icon(Icons.image_not_supported_rounded, size: 48),
                  )
                : Stack(
                    children: [
                      PageView.builder(
                        controller: _pageController,
                        itemCount: images.length,
                        onPageChanged: (index) => setState(() => _currentPage = index),
                        itemBuilder: (context, index) {
                          final imageUrl = images[index];
                          return GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    _ProductImageViewer(images: images, initialIndex: index),
                              ),
                            ),
                            child: Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return const Center(child: CircularProgressIndicator());
                              },
                              errorBuilder: (context, error, stackTrace) => Container(
                                color: const Color(0xFFEAF3F7),
                                child: const Icon(Icons.image_not_supported_rounded, size: 48),
                              ),
                            ),
                          );
                        },
                      ),
                      if (images.length > 1)
                        Positioned(
                          bottom: 8,
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(images.length, (index) {
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: _currentPage == index ? 12 : 8,
                                height: 8,
                                margin: const EdgeInsets.symmetric(horizontal: 3),
                                decoration: BoxDecoration(
                                  color: _currentPage == index
                                      ? Colors.white
                                      : Colors.white.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              );
                            }),
                          ),
                        ),
                    ],
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        widget.property.title,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: titleColor,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F6F4),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        AppStrings.of(context, 'favorite'),
                        style: const TextStyle(
                          color: Color(0xFF2A9D8F),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 16, color: secondaryColor),
                    const SizedBox(width: 6),
                    Text(
                      widget.property.location,
                      style: TextStyle(
                        fontSize: 13,
                        color: secondaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  widget.property.description,
                  style: TextStyle(height: 1.6, color: descriptionColor),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${widget.property.price} ${widget.property.currencyCode}',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: titleColor,
                      ),
                    ),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _openWhatsApp(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF25D366),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.chat_rounded),
                          label: Text(AppStrings.of(context, 'whatsapp')),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pushNamed(context, '/buyer-chat', arguments: widget.property);
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF1F7A8C),
                            side: const BorderSide(color: Color(0xFF1F7A8C)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.forum_rounded),
                          label: Text(AppStrings.of(context, 'conversation')),
                        ),
                      ],
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
}

/// Full-screen gallery. The selected card image is the initial page.
class _ProductImageViewer extends StatefulWidget {
  const _ProductImageViewer({required this.images, required this.initialIndex});

  final List<String> images;
  final int initialIndex;

  @override
  State<_ProductImageViewer> createState() => _ProductImageViewerState();
}

class _ProductImageViewerState extends State<_ProductImageViewer> {
  late final PageController _controller;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _controller = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('${_index + 1} / ${widget.images.length}'),
      ),
      body: PageView.builder(
        controller: _controller,
        itemCount: widget.images.length,
        onPageChanged: (index) => setState(() => _index = index),
        itemBuilder: (context, index) {
          return InteractiveViewer(
            key: ValueKey(index),
            minScale: 1,
            maxScale: 4,
            child: Center(
              child: Image.network(
                widget.images[index],
                fit: BoxFit.contain,
                width: double.infinity,
                height: double.infinity,
                loadingBuilder: (context, child, progress) =>
                    progress == null ? child : const Center(child: CircularProgressIndicator()),
                errorBuilder: (context, error, stackTrace) => const Center(
                  child: Icon(Icons.image_not_supported_rounded, color: Colors.white70, size: 56),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
