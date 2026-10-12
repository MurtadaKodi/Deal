import 'package:deal/core/app_settings.dart';
import 'package:flutter/material.dart';

class AppHeaderActions extends StatelessWidget {
  const AppHeaderActions({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.of(context);
    if (settings == null) return const SizedBox.shrink();

    final isDark = settings.themeMode == ThemeMode.dark;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: isDark ? 'الوضع الليلي' : 'الوضع النهاري',
          onPressed: settings.toggleTheme,
          icon: Icon(isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded),
        ),
        const SizedBox(width: 4),
        TextButton.icon(
          onPressed: settings.toggleLanguage,
          icon: const Icon(Icons.language_rounded),
          label: Text(settings.locale.languageCode == 'en' ? 'العربية' : 'English'),
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
