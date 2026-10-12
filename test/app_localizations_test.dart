import 'package:deal/core/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('English locale returns English strings', () {
    expect(AppStrings.forLocale(const Locale('en'), 'role_select_title'), 'Choose account type');
  });
}
