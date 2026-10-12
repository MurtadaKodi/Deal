import 'package:flutter/material.dart';

class ProductCategory {
  final String name;
  final IconData icon;
  final Color color;

  const ProductCategory({required this.name, required this.icon, required this.color});
}

class ProductCategories {
  ProductCategories._();

  static const String all = 'الكل';

  static const Map<String, String> _arabicNames = {
    all: 'الكل',
    'أثاث': 'أثاث',
    'هواتف': 'هواتف',
    'إلكترونيات': 'إلكترونيات',
    'منزلية': 'منزلية',
    'عقارات': 'عقارات',
    'سيارات': 'سيارات',
    'حيوانات أليفة': 'حيوانات أليفة',
    'أخرى': 'أخرى',
  };

  static const Map<String, String> _englishNames = {
    all: 'All',
    'أثاث': 'Furniture',
    'هواتف': 'Phones',
    'إلكترونيات': 'Electronics',
    'منزلية': 'Home',
    'عقارات': 'Properties',
    'سيارات': 'Cars',
    'حيوانات أليفة': 'Pets',
    'أخرى': 'Other',
  };

  static const List<ProductCategory> categories = [
    ProductCategory(name: 'أثاث', icon: Icons.chair_rounded, color: Color(0xFF1F7A8C)),
    ProductCategory(name: 'هواتف', icon: Icons.phone_android_rounded, color: Color(0xFF1F7A8C)),
    ProductCategory(name: 'إلكترونيات', icon: Icons.devices_rounded, color: Color(0xFF2A9D8F)),
    ProductCategory(name: 'منزلية', icon: Icons.home_rounded, color: Color(0xFF457B9D)),
    ProductCategory(name: 'عقارات', icon: Icons.apartment_rounded, color: Color(0xFF8E44AD)),
    ProductCategory(name: 'سيارات', icon: Icons.directions_car_rounded, color: Color(0xFFE76F51)),
    ProductCategory(name: 'حيوانات أليفة', icon: Icons.pets_rounded, color: Color(0xFF6A994E)),
    ProductCategory(name: 'أخرى', icon: Icons.category_rounded, color: Color(0xFF6B7280)),
  ];

  static List<String> get items => categories.map((category) => category.name).toList();

  static List<String> get withAll => [all, ...items];

  static String localizedName(String value, Locale locale) {
    final names = locale.languageCode == 'ar' ? _arabicNames : _englishNames;
    return names[value] ?? value;
  }
}
