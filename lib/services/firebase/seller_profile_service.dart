import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:deal/Seller/models/seller_profile.dart';
import 'package:deal/core/constants/countries.dart';

class SellerProfileService {
  static FirebaseFirestore get _firestore =>
      FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>>
      get _sellers =>
          _firestore.collection('sellers');

  static Future<void> createProfile({
    required String uid,
    required String username,
  }) async {
    final normalizedUsername =
        username.trim().toLowerCase();

    await _sellers.doc(uid).set({
      'username': normalizedUsername,
      'phone': '',
      'countryCode': DealCountries.defaultCountryCode,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<SellerProfile?> getProfile(
    String uid,
  ) async {
    final doc = await _sellers.doc(uid).get();

    if (!doc.exists) {
      return null;
    }

    return SellerProfile.fromFirestore(doc);
  }

  static Future<void> updateProfile({
    required String uid,
    required String phone,
    required String countryCode,
  }) async {
    await _sellers.doc(uid).update({
      'phone': phone.trim(),
      'countryCode': countryCode,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}