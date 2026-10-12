
import 'package:deal/core/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class DealAboutPage extends StatelessWidget {
  const DealAboutPage({super.key});

  // ضع روابطك المعتمدة هنا قبل النشر.
  static const String supportEmail = 'official.dealapp@gmail.com';
  static const String privacyPolicyUrl = 'https://mrtadaresume.me/pages/deal-privacy.html';
  static const String personalWebsiteUrl =
      'https://mrtadaresume.me/';

  Future<void> _openLink(
    BuildContext context,
    Uri uri,
  ) async {
    try {
      final opened = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!opened && context.mounted) {
        _showError(context);
      }
    } catch (_) {
      if (context.mounted) {
        _showError(context);
      }
    }
  }

  void _showError(BuildContext context) {
    final isArabic =
        Localizations.localeOf(context).languageCode == 'ar';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isArabic
              ? 'تعذر فتح الرابط'
              : 'Unable to open the link',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.of(context);
    final isArabic =
        (settings?.locale.languageCode ??
            Localizations.localeOf(context).languageCode) ==
        'ar';

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isArabic ? 'حول التطبيق' : 'About Deal',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 12),

          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.asset(
                'assets/branding/deal-logo1.png',
                width: 180,
                height: 180,
                fit: BoxFit.contain,
              ),
            ),
          ),

          Center(
            child: Text(
              'Version 1.0.0',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),

          const SizedBox(height: 48),

          Text(
            isArabic
                ? 'Deal منصة إلكترونية لعرض المنتجات '
                  'واكتشاف الإعلانات والتواصل المباشر '
                  'بين المشترين والبائعين.'
                : 'Deal is a marketplace platform '
                  'for browsing listings and connecting '
                  'buyers directly with sellers.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              height: 1.7,
            ),
          ),

          const SizedBox(height: 30),
          const Divider(),

          ListTile(
            leading: const Icon(Icons.email_outlined),
            title: Text(
              isArabic ? 'البريد الإلكتروني' : 'Contact email',
            ),
            subtitle: Text(
              supportEmail.isEmpty
                  ? (isArabic
                      ? 'سيُضاف قبل النشر'
                      : 'To be added before release')
                  : supportEmail,
            ),
            trailing: const Icon(Icons.open_in_new_rounded),
            enabled: supportEmail.isNotEmpty,
            onTap: supportEmail.isEmpty
                ? null
                : () => _openLink(
                      context,
                      Uri(
                        scheme: 'mailto',
                        path: supportEmail,
                      ),
                    ),
          ),

          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: Text(
              isArabic ? 'سياسة الخصوصية' : 'Privacy Policy',
            ),
            subtitle: Text(
              isArabic
                  ? 'الاطلاع على سياسة خصوصية Deal'
                  : 'Read the Deal Privacy Policy',
            ),
            trailing: const Icon(Icons.open_in_new_rounded),
            enabled: privacyPolicyUrl.isNotEmpty,
            onTap: privacyPolicyUrl.isEmpty
                ? null
                : () => _openLink(
                      context,
                      Uri.parse(privacyPolicyUrl),
                    ),
          ),

          ListTile(
            leading: const Icon(Icons.language_rounded),
            title: Text(
              isArabic ? 'الموقع الشخصي' : 'Developer website',
            ),
            subtitle: const Text('mrtadaresume.me'),
            trailing: const Icon(Icons.open_in_new_rounded),
            onTap: () => _openLink(
              context,
              Uri.parse(personalWebsiteUrl),
            ),
          ),

          const SizedBox(height: 32),

          Center(
            child: Text(
              '© 2026 Deal',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
