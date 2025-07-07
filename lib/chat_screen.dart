import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vibration/vibration.dart';
import 'view_profile_screen.dart'; // <-- استيراد شاشة عرض الملف الشخصي

class ChatScreen extends StatefulWidget {
  final String conversationId;
  final String recipientId;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.recipientId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  late final Stream<List<Map<String, dynamic>>> _messagesStream;
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _supabase = Supabase.instance.client;

  // --- متغيرات جديدة لحفظ بيانات الطرف الآخر ---
  String _recipientName = '...';
  Map<String, dynamic>? _recipientProfile;

  late final AnimationController _sendButtonAnimationController;

  @override
  void initState() {
    super.initState();
    _messagesStream = _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', widget.conversationId)
        .order('created_at', ascending: false);

    _sendButtonAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      reverseDuration: const Duration(milliseconds: 300),
    );

    _fetchRecipientInfo();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _sendButtonAnimationController.dispose();
    super.dispose();
  }

  // --- دالة محدثة لجلب كل بيانات البروفايل ---
  Future<void> _fetchRecipientInfo() async {
    try {
      final response = await _supabase
          .from('profiles')
          .select() // جلب كل البيانات
          .eq('id', widget.recipientId)
          .single();
      if (mounted) {
        setState(() {
          _recipientProfile = response; // حفظ البروفايل كاملًا
          _recipientName = response['full_name'] ?? 'مستخدم';
        });
      }
    } catch (_) {}
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 50);
    }

    _sendButtonAnimationController
        .forward(from: 0.5)
        .then((_) => _sendButtonAnimationController.reverse());

    final messageToInsert = _messageController.text;
    _messageController.clear();

    try {
      await _supabase.from('messages').insert({
        'conversation_id': widget.conversationId,
        'sender_id': _supabase.auth.currentUser!.id,
        'content': messageToInsert,
      });
    } catch (_) {
      _messageController.text = messageToInsert;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(
          _recipientName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 1,
        // --- إضافة زر عرض الملف الشخصي هنا ---
        actions: [
          if (_recipientProfile != null)
            IconButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        ViewProfileScreen(profileData: _recipientProfile!),
                  ),
                );
              },
              icon: const Icon(Icons.person_outline),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _messagesStream,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final messages = snapshot.data!;
                return Animate(
                  effects: const [FadeEffect()],
                  child: ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.symmetric(vertical: 10.0),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final isMe =
                          message['sender_id'] ==
                          _supabase.auth.currentUser!.id;

                      return MessageBubble(
                            message: message['content'],
                            isMe: isMe,
                          )
                          .animate(delay: (index * 50).ms)
                          .fadeIn(duration: 400.ms)
                          .move(
                            begin: Offset(isMe ? 100 : -100, 0),
                            duration: 500.ms,
                            curve: Curves.easeOutCubic,
                          );
                    },
                  ),
                );
              },
            ),
          ),
          _buildMessageInputBar(),
        ],
      ),
    );
  }

  Widget _buildMessageInputBar() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'اكتب رسالتك...',
                  fillColor: theme.colorScheme.background,
                  filled: true,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 20,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ScaleTransition(
              scale: CurvedAnimation(
                parent: _sendButtonAnimationController,
                curve: Curves.elasticOut,
                reverseCurve: Curves.easeIn,
              ),
              child: GestureDetector(
                onTap: _sendMessage,
                child: CircleAvatar(
                  radius: 24,
                  backgroundColor: theme.colorScheme.primary,
                  child: const Icon(Icons.send, color: Colors.white, size: 24),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MessageBubble extends StatelessWidget {
  final String message;
  final bool isMe;

  const MessageBubble({super.key, required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final alignment = isMe ? Alignment.centerRight : Alignment.centerLeft;
    final color = isMe
        ? theme.colorScheme.primary
        : theme.scaffoldBackgroundColor;
    final textColor = isMe ? Colors.white : theme.colorScheme.onSurface;

    return Align(
      alignment: alignment,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 15),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(24),
            topRight: const Radius.circular(24),
            bottomLeft: isMe
                ? const Radius.circular(24)
                : const Radius.circular(4),
            bottomRight: isMe
                ? const Radius.circular(4)
                : const Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          message,
          style: TextStyle(color: textColor, fontSize: 16, height: 1.4),
        ),
      ),
    );
  }
}
