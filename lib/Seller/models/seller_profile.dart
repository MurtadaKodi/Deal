import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:deal/core/constants/countries.dart';

class SellerProfile {
  final String id;
  final String username;
  final String phone;
  final String countryCode;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const SellerProfile({
    required this.id,
    required this.username,
    required this.phone,
    required this.countryCode,
    this.createdAt,
    this.updatedAt,
  });

  factory SellerProfile.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};

    return SellerProfile(
      id: doc.id,
      username: data['username'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      countryCode:
          data['countryCode'] as String? ??
          DealCountries.defaultCountryCode,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}