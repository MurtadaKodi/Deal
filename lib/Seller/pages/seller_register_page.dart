import 'package:deal/core/app_localizations.dart';
import 'package:deal/services/firebase/auth_service.dart';
import 'package:deal/services/firebase/local/seller_preferences_service.dart';
import 'package:deal/services/firebase/seller_profile_service.dart';
import 'package:deal/widgets/header.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SellerRegisterPage extends StatefulWidget {
  const SellerRegisterPage({super.key});

  @override
  State<SellerRegisterPage> createState() => _SellerRegisterPageState();
}

class _SellerRegisterPageState extends State<SellerRegisterPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final username = _usernameController.text.trim().toLowerCase();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (username.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      _showMessage(AppStrings.of(context, 'please_fill_all_fields'));
      return;
    }

    if (username.length < 3) {
      _showMessage(AppStrings.of(context, 'username_too_short'));
      return;
    }

    final usernameRegex = RegExp(r'^[a-z0-9._]+$');

    if (!usernameRegex.hasMatch(username)) {
      _showMessage(AppStrings.of(context, 'username_invalid'));
      return;
    }

    if (password.length < 6) {
      _showMessage(AppStrings.of(context, 'password_too_short'));
      return;
    }

    if (password != confirmPassword) {
      _showMessage(AppStrings.of(context, 'password_mismatch'));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final credential = await DealAuthService.createSellerAccount(
        username: username,
        password: password,
      );

      final uid = credential.user!.uid;

      await SellerProfileService.createProfile(uid: uid, username: username);

      await SellerPreferencesService.saveUsername(username);
      if (!mounted) return;

      Navigator.pushNamedAndRemoveUntil(context, '/seller-dashboard', (route) => false);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      String message;

      switch (e.code) {
        case 'email-already-in-use':
          message = AppStrings.of(context, 'username_in_use');
          break;

        case 'weak-password':
          message = AppStrings.of(context, 'weak_password');
          break;

        case 'invalid-email':
          message = AppStrings.of(context, 'invalid_username');
          break;

        default:
          message = AppStrings.of(context, 'account_creation_failed');
      }

      _showMessage(message);
    } catch (_) {
      if (!mounted) return;

      _showMessage(AppStrings.of(context, 'registration_error'));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const DealHeader(),

                const SizedBox(height: 28),

                Text(
                  AppStrings.of(context, 'seller_register_title'),
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF12324A),
                  ),
                ),

                const SizedBox(height: 24),

                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 24,
                        offset: const Offset(0, 14),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      TextField(
                        controller: _usernameController,
                        autocorrect: false,
                        enableSuggestions: false,
                        textInputAction: TextInputAction.next,
                        style: const TextStyle(
                          color: Color(0xFF12324A),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          labelText: AppStrings.of(context, 'username'),
                          prefixIcon: const Icon(Icons.person_outline_rounded),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                        ),
                      ),

                      const SizedBox(height: 16),

                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.next,
                        style: const TextStyle(
                          color: Color(0xFF12324A),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          labelText: AppStrings.of(context, 'password'),
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          suffixIcon: IconButton(
                            tooltip: _obscurePassword
                                ? AppStrings.of(context, 'show_password')
                                : AppStrings.of(context, 'hide_password'),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                          ),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                        ),
                      ),

                      const SizedBox(height: 16),

                      TextField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        style: const TextStyle(
                          color: Color(0xFF12324A),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        onSubmitted: (_) => _isLoading ? null : _register(),
                        decoration: InputDecoration(
                          labelText: AppStrings.of(context, 'confirm_password'),
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          suffixIcon: IconButton(
                            tooltip: _obscureConfirmPassword
                                ? AppStrings.of(context, 'show_password')
                                : AppStrings.of(context, 'hide_password'),
                            onPressed: () {
                              setState(() {
                                _obscureConfirmPassword = !_obscureConfirmPassword;
                              });
                            },
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                          ),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                        ),
                      ),

                      const SizedBox(height: 22),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _register,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1F7A8C),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  AppStrings.of(context, 'create_account'),
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(AppStrings.of(context, 'already_have_account')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
