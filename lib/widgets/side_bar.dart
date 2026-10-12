
import 'package:deal/core/app_localizations.dart';
import 'package:deal/core/app_settings.dart';
import 'package:deal/pages/about.dart';
import 'package:flutter/material.dart';

class AppSideBar extends StatelessWidget {
  const AppSideBar({super.key});

  @override
  Widget build(BuildContext context) {
    final locale =
        AppSettingsScope.of(context)?.locale ??
        Localizations.maybeLocaleOf(context) ??
        const Locale('ar');

    final isArabic = locale.languageCode == 'ar';

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF1F7A8C),
                  Color(0xFF2A9D8F),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text(
                  'Deal',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  isArabic
                      ? 'اعرض منتجاتك وتواصل مباشرة'
                      : 'Discover, sell and connect',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home_rounded),
            title: Text(AppStrings.of(context, 'main')),
            onTap: () => Navigator.pushNamedAndRemoveUntil(
              context,
              '/',
              (route) => false,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.apartment_rounded),
            title: Text(AppStrings.of(context, 'buyer')),
            onTap: () =>
                Navigator.pushNamed(context, '/buyer-listings'),
          ),
          ListTile(
            leading: const Icon(Icons.storefront_rounded),
            title: Text(AppStrings.of(context, 'seller')),
            onTap: () =>
                Navigator.pushNamed(context, '/seller-login'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline_rounded),
            title: Text(isArabic ? 'حول التطبيق' : 'About'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => const DealAboutPage(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
