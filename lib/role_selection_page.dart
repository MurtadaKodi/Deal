import 'package:deal/core/app_localizations.dart';
import 'package:deal/core/app_settings.dart';
import 'package:deal/core/constants/countries.dart';
import 'package:deal/widgets/app_header_actions.dart';
import 'package:deal/widgets/role_card.dart';
import 'package:flutter/material.dart';

class RoleSelectionPage extends StatelessWidget {
  const RoleSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final titleColor = isDark ? Colors.white : const Color(0xFF12324A);

    final subtitleColor = isDark
        ? const Color(0xFFB7C2D0)
        : const Color(0xFF6B7A90);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 12,
        title: Builder(
          builder: (context) {
            final settings = AppSettingsScope.of(context)!;
            final selected = settings.selectedCountry;
            final isArabic = settings.locale.languageCode == 'ar';

            return PopupMenuButton<String>(
              tooltip: isArabic ? 'اختيار الدولة' : 'Select country',
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
                        Text(
                          country.flag,
                          style: const TextStyle(fontSize: 22),
                        ),
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
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(selected.flag, style: const TextStyle(fontSize: 22)),
                    const SizedBox(width: 6),
                    Text(
                      isArabic ? selected.nameAr : selected.nameEn,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(Icons.keyboard_arrow_down_rounded),
                  ],
                ),
              ),
            );
          },
        ),
        actions: const [AppHeaderActions()],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              const Spacer(),

              Image.asset(
                'assets/branding/deal_logo.png',
                width: 150,
                height: 150,
                fit: BoxFit.contain,
              ),

              const SizedBox(height: 32),

              Text(
                AppStrings.of(context, 'role_select_title'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: titleColor,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                AppStrings.of(context, 'role_select_subtitle'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.6,
                  color: subtitleColor,
                ),
              ),

              const SizedBox(height: 36),

              Row(
                children: [
                  Expanded(
                    child: RoleCard(
                      title: AppStrings.of(context, 'seller'),
                      description: AppStrings.of(context, 'seller_card_desc'),
                      icon: Icons.storefront_rounded,
                      color: const Color(0xFF25899A),
                      onTap: () {
                        Navigator.pushNamed(context, '/seller-login');
                      },
                    ),
                  ),

                  const SizedBox(width: 16),

                  Expanded(
                    child: RoleCard(
                      title: AppStrings.of(context, 'buyer'),
                      description: AppStrings.of(context, 'buyer_card_desc'),
                      icon: Icons.shopping_bag_rounded,
                      color: const Color(0xFF2A9D8F),
                      onTap: () {
                        Navigator.pushNamed(context, '/buyer-listings');
                      },
                    ),
                  ),
                ],
              ),

              const Spacer(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
