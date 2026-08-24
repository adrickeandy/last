import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/avatar_view.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../models/conversation_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/chat_provider.dart';
import '../../../providers/ui_provider.dart';
import 'message_bubble.dart';

class ChatThread extends StatefulWidget {
  final ConversationModel conversation;

  const ChatThread({super.key, required this.conversation});

  @override
  State<ChatThread> createState() => _ChatThreadState();
}

class _ChatThreadState extends State<ChatThread> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleSend() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final auth = context.read<AuthProvider>();
    final user = auth.user;
    if (user == null) return;

    final chat = context.read<ChatProvider>();
    chat.sendMessage(senderId: user.id, content: text);
    _messageController.clear();
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chat = context.watch<ChatProvider>();
    final auth = context.watch<AuthProvider>();
    final ui = context.read<UIProvider>();
    final myId = auth.user?.id ?? '';
    final messages = chat.activeMessages;
    final isLoading = chat.isLoadingMessages;

    final other = widget.conversation.otherProfile;
    final title = other?.fullName ?? other?.username ?? widget.conversation.title ?? 'Direct Message';

    _scrollToBottom();

    return Column(
      children: [
        // Thread Header
        Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isDark ? AppColors.darkGlassBorder : AppColors.lightGlassBorder,
              ),
            ),
          ),
          child: Row(
            children: [
              AvatarView(
                url: other?.avatarUrl,
                name: title,
                size: 34,
                onTap: () {
                  if (other?.username != null) {
                    ui.openProfile(other!.username);
                  }
                },
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    if (other?.username != null)
                      Text(
                        '@${other!.username}',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? AppColors.darkInk400 : AppColors.lightInk400,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Message List
        Expanded(
          child: isLoading
              ? ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: 4,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, __) => const SkeletonLoader(height: 44),
                )
              : messages.isEmpty
                  ? Center(
                      child: Text(
                        'Say hello to $title!',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? AppColors.darkInk400 : AppColors.lightInk400,
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      itemCount: messages.length,
                      itemBuilder: (context, i) {
                        final msg = messages[i];
                        final isMe = msg.senderId == myId;
                        return MessageBubble(message: msg, isMe: isMe);
                      },
                    ),
        ),

        // Message Composer
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: isDark ? AppColors.darkGlassBorder : AppColors.lightGlassBorder,
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  style: const TextStyle(fontSize: 13.5),
                  decoration: InputDecoration(
                    hintText: 'Type a message…',
                    hintStyle: TextStyle(
                      fontSize: 13.5,
                      color: isDark ? AppColors.darkInk500 : AppColors.lightInk500,
                    ),
                    filled: true,
                    fillColor: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: isDark ? AppColors.darkGlassBorder : AppColors.lightGlassBorder,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: isDark ? AppColors.darkGlassBorder : AppColors.lightGlassBorder,
                      ),
                    ),
                  ),
                  onSubmitted: (_) => _handleSend(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.violet500,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(10),
                ),
                icon: const Icon(Icons.send_rounded, size: 18),
                onPressed: _handleSend,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
