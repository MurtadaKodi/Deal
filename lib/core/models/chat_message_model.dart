import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  ChatMessage({
    required this.id,
    required this.text,
    required this.senderId,
    required this.senderName,
    required this.createdAt,
    this.isFromBuyer = false,
  });

  final String id;
  final String text;
  final String senderId;
  final String senderName;
  final DateTime? createdAt;
  final bool isFromBuyer;

  factory ChatMessage.fromMap(Map<String, dynamic> map, {String? id}) {
    final timestamp = map['createdAt'];

    return ChatMessage(
      id: id ?? map['id']?.toString() ?? '',
      text: map['text']?.toString() ?? '',
      senderId: map['senderId']?.toString() ?? '',
      senderName: map['senderName']?.toString() ?? '',
      createdAt: timestamp is Timestamp
          ? timestamp.toDate()
          : timestamp is DateTime
          ? timestamp
          : null,
      isFromBuyer: map['isFromBuyer'] == true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'senderId': senderId,
      'senderName': senderName,
      'isFromBuyer': isFromBuyer,
    };
  }
}
