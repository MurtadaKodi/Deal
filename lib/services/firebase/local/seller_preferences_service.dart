import 'package:shared_preferences/shared_preferences.dart';

class SellerPreferencesService {
  static const String _usernameKey = 'seller_username';

  static Future<void> saveUsername(String username) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      _usernameKey,
      username.trim().toLowerCase(),
    );
  }

  static Future<String?> getUsername() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString(_usernameKey);
  }

  static Future<void> clearUsername() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_usernameKey);
  }
}