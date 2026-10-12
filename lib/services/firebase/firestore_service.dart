import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  static FirebaseFirestore get db => FirebaseFirestore.instance;

  static Future<void> addListing(Map<String, dynamic> data) async {
    await db.collection('listings').add({...data, 'createdAt': FieldValue.serverTimestamp()});
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> streamListings() {
    return db.collection('listings').orderBy('createdAt', descending: true).snapshots();
  }

  static Future<QuerySnapshot<Map<String, dynamic>>> getListings() {
    return db.collection('listings').orderBy('createdAt', descending: true).get();
  }

  static Future<QuerySnapshot<Map<String, dynamic>>> getListingsBySeller(String sellerId) {
    return db.collection('listings').where('sellerId', isEqualTo: sellerId).get();
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> streamListingsBySeller(String sellerId) {
    return db.collection('listings').where('sellerId', isEqualTo: sellerId).snapshots();
  }

  static Future<void> updateListing(String listingId, Map<String, dynamic> data) async {
    await db.collection('listings').doc(listingId).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> deleteListing(String listingId) async {
    await db.collection('listings').doc(listingId).delete();
  }

  static Future<void> addChatMessage({
    required String chatId,
    required Map<String, dynamic> message,
  }) async {
    await db.collection('chats').doc(chatId).collection('messages').add({
      ...message,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<QuerySnapshot<Map<String, dynamic>>> getMessages(String chatId) {
    return db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .get();
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> watchMessages(String chatId) {
    return db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots();
  }
}
