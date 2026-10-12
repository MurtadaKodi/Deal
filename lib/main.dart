import 'package:deal/Seller/pages/add_product_page.dart';
import 'package:deal/Seller/pages/seller_dashboard_page.dart';
import 'package:deal/Seller/pages/seller_login_page.dart';
import 'package:deal/Seller/pages/seller_profile_page.dart';
import 'package:deal/Seller/pages/seller_register_page.dart';
import 'package:deal/buyer/pages/buyer_chat_page.dart';
import 'package:deal/buyer/pages/buyer_listings_page.dart';
import 'package:deal/core/app_localizations.dart';
import 'package:deal/core/app_settings.dart';
import 'package:deal/core/theme.dart';
import 'package:deal/pages/splash_page.dart';
import 'package:deal/role_selection_page.dart';
import 'package:deal/services/firebase/firebase_initializer.dart';
import 'package:deal/services/firebase/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await FirebaseInitializer.initialize();
  await NotificationService.initialize();

  runApp(const DealApp());
}

class DealApp extends StatefulWidget {
  const DealApp({super.key});

  @override
  State<DealApp> createState() => _DealAppState();
}

class _DealAppState extends State<DealApp> {
  final AppSettingsController _settings = AppSettingsController();

  @override
  void dispose() {
    _settings.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppSettingsScope(
      notifier: _settings,
      child: Builder(
        builder: (context) {
          final settings = AppSettingsScope.of(context)!;

          return MaterialApp(
            title: 'Deal',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: settings.themeMode,
            locale: settings.locale,
            supportedLocales: const [Locale('ar'), Locale('en')],
            localizationsDelegates: [
              AppStrings.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            initialRoute: '/',
            routes: {
              '/': (context) => const SplashPage(),
              '/role-selection': (context) => const RoleSelectionPage(),
              '/buyer-listings': (context) => const BuyerListingsPage(),
              '/buyer-chat': (context) => const BuyerChatPage(),
              '/seller-login': (context) => const SellerLoginPage(),
              '/seller-dashboard': (context) => const SellerDashboardPage(),
              '/seller-add-product': (context) => const AddProductPage(),
              '/seller-register': (context) => const SellerRegisterPage(),
              '/seller-profile': (context) => const SellerProfilePage(),
            },
          );
        },
      ),
    );
  }
}
