import 'package:deal/Seller/models/seller_profile.dart';
import 'package:deal/core/app_localizations.dart';
import 'package:deal/core/constants/countries.dart';
import 'package:deal/services/firebase/seller_profile_service.dart';
import 'package:deal/widgets/header.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SellerProfilePage extends StatefulWidget {
  const SellerProfilePage({super.key});

  @override
  State<SellerProfilePage> createState() => _SellerProfilePageState();
}

class _SellerProfilePageState extends State<SellerProfilePage> {
  final _phoneController = TextEditingController();
  String _selectedCountryCode = DealCountries.defaultCountryCode;

  SellerProfile? _profile;

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      return;
    }

    try {
      final profile = await SellerProfileService.getProfile(user.uid);

      if (!mounted) return;

      _profile = profile;
      _phoneController.text = profile?.phone ?? '';

      _selectedCountryCode = profile?.countryCode ?? DealCountries.defaultCountryCode;

      setState(() => _isLoading = false);
    } catch (_) {
      if (!mounted) return;

      setState(() => _isLoading = false);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppStrings.of(context, 'profile_load_failed'))));
    }
  }

  Future<void> _save() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    final phone = _phoneController.text.trim();

    setState(() => _isSaving = true);

    try {
      await SellerProfileService.updateProfile(
        uid: user.uid,
        phone: phone,
        countryCode: _selectedCountryCode,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppStrings.of(context, 'profile_saved'))));
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppStrings.of(context, 'profile_save_failed'))));
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _requestAccountDeletion() async {
    final uri = Uri.parse('https://mrtadaresume.me/pages/deal-delete-account.html');

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تعذر فتح صفحة طلب حذف الحساب')));
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedCountry = DealCountries.byCode(_selectedCountryCode);
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.of(context, 'profile_title')), centerTitle: true),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _profile == null
            ? Center(child: Text(AppStrings.of(context, 'profile_not_found')))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const DealHeader(showSubtitle: false),

                    const SizedBox(height: 28),

                    Container(
                      width: double.infinity,
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.of(context, 'username'),
                            style: const TextStyle(
                              color: Color(0xFF6B7A90),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),

                          const SizedBox(height: 6),

                          Row(
                            children: [
                              const Icon(Icons.person_outline_rounded, color: Color(0xFF1F7A8C)),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _profile!.username,
                                  style: const TextStyle(
                                    color: Color(0xFF12324A),
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          OutlinedButton.icon(
                            onPressed: _requestAccountDeletion,
                            icon: const Icon(Icons.delete_outline_rounded),
                            label: const Text('طلب حذف الحساب'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                            ),
                          ),

                          const SizedBox(height: 24),
                          DropdownButtonFormField<String>(
                            initialValue: _selectedCountryCode,
                            decoration: InputDecoration(
                              labelText: AppStrings.of(context, 'country'),
                              prefixIcon: const Icon(Icons.public_rounded),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                            ),
                            items: DealCountries.items.map((country) {
                              return DropdownMenuItem<String>(
                                value: country.code,
                                child: Text('${country.flag}  ${country.nameAr}'),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value == null) return;

                              setState(() {
                                _selectedCountryCode = value;
                              });
                            },
                          ),

                          const SizedBox(height: 18),
                          TextField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            style: const TextStyle(
                              color: Color(0xFF12324A),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              labelText: AppStrings.of(context, 'phone_number'),
                              prefixIcon: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.phone_outlined),
                                    const SizedBox(width: 8),
                                    Text(
                                      selectedCountry.phoneCode,
                                      style: const TextStyle(fontWeight: FontWeight.w700),
                                    ),
                                  ],
                                ),
                              ),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                            ),
                          ),

                          const SizedBox(height: 22),

                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isSaving ? null : _save,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1F7A8C),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: _isSaving
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'حفظ التعديلات',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    Text(
                      'يمكن تعديل رقم الهاتف في أي وقت',
                      style: TextStyle(
                        color: isDark ? Colors.white70 : const Color(0xFF6B7A90),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
