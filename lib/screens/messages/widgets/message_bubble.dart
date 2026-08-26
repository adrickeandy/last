import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/avatar_view.dart';
import '../../../models/message_model.dart';
import '../../../providers/chat_provider.dart';

class MessageBubble extends StatefulWidget {
  final MessageModel message;
  final bool isMe;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
  });

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  bool _isRetrying = false;

  Future<void> _handleRetry() async {
    if (_isRetrying) return;
    setState(() => _isRetrying = true);
    final chat = context.read<ChatProvider>();
    final ok = await chat.retryMessage(widget.message.id);
    if (mounted) {
      setState(() => _isRetrying = false);
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Still no connection - will retry again')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final message = widget.message;
    final isMe = widget.isMe;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            AvatarView(
              url: message.sender?.avatarUrl,
              name: message.sender?.fullName ?? message.sender?.username ?? '?',
              size: 28,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Opacity(
              // Same convention as PostCard/CommentSectionWidget: dim a
              // bubble that hasn't reached the server yet.
              opacity: message.isPending ? 0.7 : 1.0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isMe
                      ? AppColors.violet500
                      : (isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06)),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isMe ? 16 : 4),
                    bottomRight: Radius.circular(isMe ? 4 : 16),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.content,
                      style: TextStyle(
                        fontSize: 13.5,
                        color: isMe
                            ? Colors.white
                            : (isDark ? AppColors.darkInk100 : AppColors.lightInk100),
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (message.isPending)
                      InkWell(
                        onTap: _handleRetry,
                        borderRadius: BorderRadius.circular(6),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_isRetrying)
                              SizedBox(
                                width: 9,
                                height: 9,
                                child: CircularProgressIndicator(
                                  strokeWidth: 1.3,
                                  color: isMe ? Colors.white.withOpacity(0.85) : AppColors.lime500,
                                ),
                              )
                            else
                              Icon(
                                Icons.refresh_rounded,
                                size: 11,
                                color: isMe ? Colors.white.withOpacity(0.85) : AppColors.lime500,
                              ),
                            const SizedBox(width: 3),
                            Text(
                              _isRetrying ? 'Sending…' : 'Not sent · tap to retry',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w600,
                                color: isMe ? Colors.white.withOpacity(0.85) : AppColors.lime500,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Text(
                        AppFormatters.timeAgo(message.createdAt),
                        style: TextStyle(
                          fontSize: 9.5,
                          color: isMe
                              ? Colors.white.withOpacity(0.7)
                              : (isDark ? AppColors.darkInk500 : AppColors.lightInk500),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
