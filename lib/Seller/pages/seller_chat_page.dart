import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:deal/core/app_localizations.dart';
import 'package:deal/core/models/chat_message_model.dart';
import 'package:deal/core/models/product_model.dart';
import 'package:deal/services/firebase/firestore_service.dart';
import 'package:deal/services/firebase/seller_profile_service.dart';
import 'package:deal/widgets/app_header_actions.dart';
import 'package:deal/widgets/chat_safety_notice.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SellerChatPage extends StatefulWidget {
  const SellerChatPage({required this.product, required this.chatId, super.key});

  final Product product;
  final String chatId;

  @override
  State<SellerChatPage> createState() => _SellerChatPageState();
}

class _SellerChatPageState extends State<SellerChatPage> {
  final TextEditingController _controller = TextEditingController();

  String _sellerName = 'Seller';

  @override
  void initState() {
    super.initState();
    _loadSellerProfile();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadSellerProfile() async {
    final defaultSellerName = AppStrings.of(context, 'seller_default_name');
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    try {
      final profile = await SellerProfileService.getProfile(user.uid);

      if (!mounted || profile == null) return;

      setState(() {
        _sellerName = profile.username.isNotEmpty ? profile.username : defaultSellerName;
      });
    } catch (_) {
      // نحتفظ بالاسم الافتراضي.
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final currentUserId = currentUser?.uid ?? 'seller_guest';

    return Scaffold(
      appBar: AppBar(title: Text(widget.product.title), actions: const [AppHeaderActions()]),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F6F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              AppStrings.of(context, 'chat_buyer_title'),
              style: const TextStyle(
                color: Color(0xFF12324A),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const ChatSafetyNotice(),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirestoreService.watchMessages(widget.chatId),
              builder: (context, snapshot) {
                final messages = snapshot.data?.docs ?? const [];

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (messages.isEmpty) {
                  return Center(child: Text(AppStrings.of(context, 'messages_no_messages_yet')));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = ChatMessage.fromMap(
                      messages[index].data(),
                      id: messages[index].id,
                    );
                    final isMe = message.senderId == currentUserId;
                    final isDark = Theme.of(context).brightness == Brightness.dark;

                    final bubbleColor = isMe
                        ? const Color(0xFF2A9D8F)
                        : isDark
                        ? const Color(0xFF1E293B)
                        : const Color(0xFFE8EEF3);

                    final messageColor = isMe
                        ? Colors.white
                        : isDark
                        ? Colors.white
                        : const Color(0xFF12324A);

                    final timeColor = isMe
                        ? Colors.white70
                        : isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF7A8CA3);
                    final sentAt = message.createdAt != null
                        ? TimeOfDay.fromDateTime(message.createdAt!).format(context)
                        : '';

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 280),
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: bubbleColor,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(18),
                            topRight: const Radius.circular(18),
                            bottomLeft: Radius.circular(isMe ? 18 : 4),
                            bottomRight: Radius.circular(isMe ? 4 : 18),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              message.text,
                              style: TextStyle(color: messageColor, fontSize: 15, height: 1.4),
                            ),

                            if (sentAt.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(sentAt, style: TextStyle(color: timeColor, fontSize: 10)),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: Colors.white,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: AppStrings.of(context, 'message_hint'),
                        filled: true,
                        fillColor: const Color(0xFFF3F6F9),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FloatingActionButton(
                    onPressed: () async {
                      final text = _controller.text.trim();
                      if (text.isEmpty) return;

                      final mustLoginFirst = AppStrings.of(context, 'must_login_first');
                      final sendMessageFailedDetail = AppStrings.of(
                        context,
                        'send_message_failed_detail',
                      );
                      final messenger = ScaffoldMessenger.maybeOf(context);

                      try {
                        final user = FirebaseAuth.instance.currentUser;
                        if (user == null) {
                          throw FirebaseAuthException(
                            code: 'auth-required',
                            message: mustLoginFirst,
                          );
                        }

                        await FirestoreService.addChatMessage(
                          chatId: widget.chatId,
                          message: {
                            'text': text,
                            'senderId': user.uid,
                            'senderName': _sellerName,
                            'isFromBuyer': false,
                          },
                        );

                        _controller.clear();
                      } catch (e) {
                        if (mounted && messenger != null) {
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                '$sendMessageFailedDetail: ${e is FirebaseException ? e.message ?? e.code : e}',
                              ),
                            ),
                          );
                        }
                      }
                    },
                    backgroundColor: const Color(0xFF2A9D8F),
                    child: const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
