import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:deal/core/app_localizations.dart';
import 'package:deal/core/models/chat_message_model.dart';
import 'package:deal/core/models/product_model.dart';
import 'package:deal/services/firebase/chat_service.dart';
import 'package:deal/services/firebase/firestore_service.dart';
import 'package:deal/services/firebase/seller_profile_service.dart';
import 'package:deal/widgets/app_header_actions.dart';
import 'package:deal/widgets/chat_safety_notice.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class BuyerChatPage extends StatefulWidget {
  const BuyerChatPage({super.key});

  @override
  State<BuyerChatPage> createState() => _BuyerChatPageState();
}

class _BuyerChatPageState extends State<BuyerChatPage> {
  String _sellerName = 'Seller';
  String? _loadedSellerId;
  String? _chatId;
  String? _buyerId;
  bool _isPreparingChat = true;
  String? _chatError;
  String? _preparedProductId;
  Future<void> _prepareChat(Product property) async {
    final temporaryBuyerIdentityFailed = AppStrings.of(context, 'temporary_buyer_identity_failed');
    final chatPreparationFailed = AppStrings.of(context, 'chat_preparation_failed');

    try {
      User? user = FirebaseAuth.instance.currentUser;

      user ??= (await FirebaseAuth.instance.signInAnonymously()).user;

      if (user == null) {
        throw StateError(temporaryBuyerIdentityFailed);
      }

      final chatId = await ChatService.getOrCreateChat(
        productId: property.id,
        buyerId: user.uid,
        sellerId: property.sellerId,
      );
      debugPrint('NEW CHAT ID: $chatId');
      if (!mounted) return;

      setState(() {
        _chatId = chatId;
        _buyerId = user!.uid;
        _isPreparingChat = false;
        _chatError = null;
      });
    } catch (e, stackTrace) {
      debugPrint('CHAT PREPARE ERROR: $e');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      setState(() {
        _isPreparingChat = false;
        _chatError = chatPreparationFailed;
      });
    }
  }

  Future<void> _loadSellerProfile(Product property) async {
    final defaultSellerName = AppStrings.of(context, 'seller_default_name');

    if (property.sellerId.isEmpty) return;
    if (_loadedSellerId == property.sellerId) return;

    _loadedSellerId = property.sellerId;

    try {
      final profile = await SellerProfileService.getProfile(property.sellerId);

      if (!mounted || profile == null) return;

      setState(() {
        _sellerName = profile.username.isNotEmpty ? profile.username : defaultSellerName;
      });
    } catch (_) {
      // نحتفظ بالعنوان الافتراضي.
    }
  }

  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final property = ModalRoute.of(context)?.settings.arguments as Product?;

    if (property == null) return;

    _loadSellerProfile(property);

    if (_preparedProductId != property.id) {
      _preparedProductId = property.id;
      _isPreparingChat = true;
      _chatId = null;
      _chatError = null;

      _prepareChat(property);
    }
  }

  @override
  Widget build(BuildContext context) {
    final property = ModalRoute.of(context)?.settings.arguments as Product?;
    final chatId = _chatId;
    final currentUserId = _buyerId ?? '';

    return Scaffold(
      appBar: AppBar(title: Text(_sellerName), actions: const [AppHeaderActions()]),
      body: Column(
        children: [
          const ChatSafetyNotice(),
          Expanded(
            child: _isPreparingChat
                ? const Center(child: CircularProgressIndicator())
                : _chatError != null
                ? Center(
                    child: TextButton.icon(
                      onPressed: () {
                        if (property == null) return;

                        setState(() {
                          _isPreparingChat = true;
                          _chatError = null;
                        });

                        _prepareChat(property);
                      },
                      icon: const Icon(Icons.refresh),
                      label: Text(_chatError!),
                    ),
                  )
                : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirestoreService.watchMessages(chatId!),
                    builder: (context, snapshot) {
                      final messages = snapshot.data?.docs ?? const [];

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (messages.isEmpty) {
                        return Center(
                          child: Text(AppStrings.of(context, 'messages_no_messages_yet')),
                        );
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
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    message.text,
                                    style: TextStyle(
                                      color: messageColor,
                                      fontSize: 15,
                                      height: 1.4,
                                    ),
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
                      if (_chatId == null || _buyerId == null) return;

                      final temporaryBuyerIdentityFailed = AppStrings.of(
                        context,
                        'temporary_buyer_identity_failed',
                      );
                      final sendMessageFailed = AppStrings.of(context, 'send_message_failed');
                      final buyerLabel = AppStrings.of(context, 'buyer_label');
                      final messenger = ScaffoldMessenger.maybeOf(context);

                      try {
                        User? user = FirebaseAuth.instance.currentUser;
                        if (user == null) {
                          final credential = await FirebaseAuth.instance.signInAnonymously();
                          user = credential.user;
                        }

                        if (user == null) {
                          throw FirebaseAuthException(
                            code: 'auth-null-user',
                            message: temporaryBuyerIdentityFailed,
                          );
                        }

                        final senderId = user.uid;
                        final senderName = user.displayName?.trim().isNotEmpty == true
                            ? user.displayName!
                            : (user.email?.split('@').first ?? buyerLabel);

                        await FirestoreService.addChatMessage(
                          chatId: _chatId!,
                          message: {
                            'text': text,
                            'senderId': senderId,
                            'senderName': senderName,
                            'isFromBuyer': true,
                          },
                        );
                        _controller.clear();
                      } on FirebaseException catch (e) {
                        if (mounted && messenger != null) {
                          messenger.showSnackBar(
                            SnackBar(content: Text(e.message ?? sendMessageFailed)),
                          );
                        }
                      } catch (_) {
                        if (mounted && messenger != null) {
                          messenger.showSnackBar(SnackBar(content: Text(sendMessageFailed)));
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
