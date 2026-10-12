import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ChatService {
  ChatService._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static String buildChatId({required String productId, required String buyerId}) {
    return '${productId}_$buyerId';
  }

  static Future<String> getOrCreateChat({
    required String productId,
    required String buyerId,
    required String sellerId,
  }) async {
    if (productId.isEmpty || buyerId.isEmpty || sellerId.isEmpty) {
      throw ArgumentError('بيانات المحادثة غير مكتملة');
    }

    if (buyerId == sellerId) {
      throw ArgumentError('لا يمكن إنشاء محادثة مع نفسك');
    }

    final chatId = buildChatId(productId: productId, buyerId: buyerId);

    final chatRef = _db.collection('chats').doc(chatId);

    try {
      await _db.runTransaction((transaction) async {
        final snapshot = await transaction.get(chatRef);

        if (snapshot.exists) {
          final data = snapshot.data() ?? {};

          if (data['productId'] != productId ||
              data['buyerId'] != buyerId ||
              data['sellerId'] != sellerId) {
            throw StateError('بيانات المحادثة غير متطابقة');
          }

          return;
        }

        transaction.set(chatRef, {
          'productId': productId,
          'buyerId': buyerId,
          'sellerId': sellerId,
          'participants': [buyerId, sellerId],
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'lastMessage': '',
        });
      });
    } on FirebaseException catch (e) {
  debugPrint('CHAT FIREBASE ERROR CODE: ${e.code}');
  debugPrint('CHAT FIREBASE ERROR MESSAGE: ${e.message}');
  rethrow;
} catch (e, stackTrace) {
  debugPrint('CHAT TRANSACTION ERROR: $e');
  debugPrintStack(stackTrace: stackTrace);
  rethrow;
}

    return chatId;
  }
}
