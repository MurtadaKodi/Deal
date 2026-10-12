class SellerAuthService {
  static bool login({required String username, required String password}) {
    final cleanUsername = username.trim();
    final cleanPassword = password.trim();

    return cleanUsername.isNotEmpty && cleanPassword.isNotEmpty;
  }
}
