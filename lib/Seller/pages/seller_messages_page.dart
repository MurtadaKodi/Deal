import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:deal/Seller/pages/seller_chat_page.dart';
import 'package:deal/core/app_localizations.dart';
import 'package:deal/core/models/chat_message_model.dart';
import 'package:deal/core/models/product_model.dart';
import 'package:deal/services/firebase/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SellerMessagesPage extends StatefulWidget {
  const SellerMessagesPage({super.key, this.productId});

  final String? productId;

  @override
  State<SellerMessagesPage> createState() => _SellerMessagesPageState();
}

class _ChatThread {
  _ChatThread({
    required this.chatId,
    required this.buyerId,
    required this.product,
    required this.messages,
  });

  final String chatId;
  final String buyerId;
  final Product product;
  final List<ChatMessage> messages;
}

class _SellerMessagesPageState extends State<SellerMessagesPage> {
  late Future<List<_ChatThread>> _threadsFuture;

  @override
  void initState() {
    super.initState();
    _refreshThreads();
  }

  void _refreshThreads() {
    _threadsFuture = _loadThreads();
  }

  Future<List<_ChatThread>> _loadThreads() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    final listingsSnapshot = await FirestoreService.getListingsBySeller(user.uid);

    final products = {
      for (final doc in listingsSnapshot.docs) doc.id: Product.fromMap(doc.data(), id: doc.id),
    };

    final chatsSnapshot = await FirebaseFirestore.instance
        .collection('chats')
        .where('sellerId', isEqualTo: user.uid)
        .get();

    final threads = <_ChatThread>[];

    for (final chatDoc in chatsSnapshot.docs) {
      final data = chatDoc.data();
      final productId = data['productId'] as String?;
      final buyerId = data['buyerId'] as String?;
      if (widget.productId != null && productId != widget.productId) {
        continue;
      }

      if (productId == null || buyerId == null) continue;

      final product = products[productId];
      if (product == null) continue;

      final messagesSnapshot = await FirestoreService.getMessages(chatDoc.id);

      final messages = messagesSnapshot.docs
          .map((doc) => ChatMessage.fromMap(doc.data(), id: doc.id))
          .toList();

      if (messages.isEmpty) continue;

      threads.add(
        _ChatThread(chatId: chatDoc.id, buyerId: buyerId, product: product, messages: messages),
      );
    }

    threads.sort((a, b) {
      final aTime = a.messages.first.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);

      final bTime = b.messages.first.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);

      return bTime.compareTo(aTime);
    });

    return threads;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.of(context, 'buyer_chats_all'))),
      body: FutureBuilder<List<_ChatThread>>(
        future: _threadsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(AppStrings.of(context, 'conversations_load_failed')),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: () {
                      setState(_refreshThreads);
                    },
                    icon: const Icon(Icons.refresh),
                    label: Text(AppStrings.of(context, 'retry')),
                  ),
                ],
              ),
            );
          }

          final threads = snapshot.data ?? const <_ChatThread>[];

          if (threads.isEmpty) {
            return Center(child: Text(AppStrings.of(context, 'no_conversations_yet')));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: threads.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final thread = threads[index];
              final lastMessage = thread.messages.first;
              final lastText = lastMessage.text;

              return Card(
                child: ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      thread.product.imageUrl,
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const Icon(Icons.image_not_supported),
                    ),
                  ),
                  title: Text(thread.product.title),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${AppStrings.of(context, 'buyer_label')}: ${thread.buyerId.substring(0, thread.buyerId.length > 8 ? 8 : thread.buyerId.length)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(lastText, maxLines: 2, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A9D8F),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${thread.messages.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            SellerChatPage(product: thread.product, chatId: thread.chatId),
                      ),
                    );

                    if (mounted) {
                      setState(_refreshThreads);
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
