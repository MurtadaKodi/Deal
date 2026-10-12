import 'package:deal/core/app_localizations.dart';
import 'package:flutter/material.dart';

class ChatSafetyNotice extends StatelessWidget {
  const ChatSafetyNotice({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final title = AppStrings.of(context, 'security_notice_title');
    final body = AppStrings.of(context, 'security_notice_body');

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF263445)
            : const Color(0xFFFFF8E7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? const Color(0xFF8A7040)
              : const Color(0xFFE8D6A4),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.shield_outlined,
            color: Color(0xFFD49A28),
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF73551B),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  body,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.6,
                    color: isDark ? const Color(0xFFE2D5B8) : const Color(0xFF80652F),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}