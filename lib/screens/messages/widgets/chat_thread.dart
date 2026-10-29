import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/attachment_picker.dart';
import '../../../core/widgets/attachment_widgets.dart';
import '../../../core/widgets/avatar_view.dart';
<<<<<<< HEAD
import '../../../core/widgets/doodle_background.dart';
=======
>>>>>>> a8ccd1b20499cc86d195494c3467701f9cec5386
import '../../../core/widgets/glass_text_field.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../core/widgets/toast_overlay.dart';
import '../../../models/attachment_model.dart';
import '../../../models/conversation_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/chat_provider.dart';
import '../../../providers/ui_provider.dart';
import '../../../services/storage_service.dart';
import 'message_bubble.dart';

class ChatThread extends StatefulWidget {
  final ConversationModel conversation;

  /// Phone layout: shows a back arrow in the header that returns to the
  /// conversation list. Null on desktop (list is always visible).
  final VoidCallback? onBack;

  const ChatThread({super.key, required this.conversation, this.onBack});

  @override
  State<ChatThread> createState() => _ChatThreadState();
}

class _ChatThreadState extends State<ChatThread> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _storageService = StorageService();

  // File chosen with the paperclip but not sent yet.
  PickedAttachment? _pendingFile;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    // A chat opened from somewhere with a suggested first message (e.g.
    // Contact Seller on a marketplace listing) arrives pre-filled.
    final draft = context.read<ChatProvider>().takeDraft();
    if (draft != null && draft.isNotEmpty) {
      _messageController.text = draft;
      _messageController.selection =
          TextSelection.collapsed(offset: draft.length);
    }
  }

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

  Future<void> _pickFile() async {
    final file = await AttachmentPicker.pick(context);
    if (file != null && mounted) {
      setState(() => _pendingFile = file);
    }
  }

  Future<void> _handleSend() async {
    if (_isUploading) return;

    final text = _messageController.text.trim();
    final file = _pendingFile;
    if (text.isEmpty && file == null) return;

    final auth = context.read<AuthProvider>();
    final user = auth.user;
    if (user == null) return;

    final chat = context.read<ChatProvider>();

    // Upload first, so the message that gets queued/retried is just a small
    // text row that already points at the file.
    AttachmentInfo? uploaded;
    if (file != null) {
      setState(() => _isUploading = true);
      try {
        uploaded = await _storageService.uploadAttachment(
          userId: user.id,
          file: file,
        );
      } catch (e) {
        print('[ChatThread] attachment upload failed: $e');
        if (mounted) {
          setState(() => _isUploading = false);
          ToastOverlay.show(
            context,
            'Could not upload the file. Check your connection and try again.',
            type: ToastType.error,
          );
        }
        return;
      }
    }

    // If the user switched to another conversation while the file was
    // uploading, this thread is gone - do not send into the wrong chat.
    if (!mounted) return;

    chat.sendMessage(senderId: user.id, content: text, attachment: uploaded);
    _messageController.clear();
    setState(() {
      _pendingFile = null;
      _isUploading = false;
    });
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
    final isGroup = widget.conversation.isGroup;

    final other = widget.conversation.otherProfile;
    // For a group (club) chat, otherProfile is always null (see the fix in
    // MessageService.fetchConversations), so this correctly falls through
    // to the conversation's own title - the club name - rather than ever
    // showing a random member's name here.
    final title = other?.fullName ?? other?.username ?? widget.conversation.title ?? 'Direct Message';

    _scrollToBottom();

<<<<<<< HEAD
    // Doodle wallpaper sits behind the whole thread (DMs and club chats).
    return Stack(
      fit: StackFit.expand,
      children: [
        const Positioned.fill(child: DoodleBackground()),
        Column(
=======
    return Column(
>>>>>>> a8ccd1b20499cc86d195494c3467701f9cec5386
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
              if (widget.onBack != null) ...[
                IconButton(
                  tooltip: 'Back',
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: widget.onBack,
                  visualDensity: VisualDensity.compact,
                ),
                const SizedBox(width: 4),
              ],
              if (isGroup)
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.violet500.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.groups_rounded, size: 18, color: AppColors.violet400),
                )
              else
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    if (isGroup)
                      Text(
                        'Club group chat',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? AppColors.darkInk400 : AppColors.lightInk400,
                        ),
                      )
                    else if (other?.username != null)
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
                        isGroup ? 'Say hello to $title!' : 'Say hello to $title!',
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
                        return MessageBubble(message: msg, isMe: isMe, isGroup: isGroup);
                      },
                    ),
        ),

        // Message Composer (SafeArea keeps it clear of the phone's gesture bar)
        SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: isDark ? AppColors.darkGlassBorder : AppColors.lightGlassBorder,
                ),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_pendingFile != null) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 320),
                      child: PendingAttachmentChip(
                        file: _pendingFile!,
                        isUploading: _isUploading,
                        onRemove: () => setState(() => _pendingFile = null),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: GlassTextField(
                        controller: _messageController,
                        hintText: 'Type a message…',
                        onSubmitted: (_) => _handleSend(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            Icons.attach_file_rounded,
                            size: 19,
                            color: isDark ? AppColors.darkInk400 : AppColors.lightInk400,
                          ),
                          splashRadius: 18,
                          tooltip: 'Attach a file',
                          onPressed: _isUploading ? null : _pickFile,
                        ),
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
                      onPressed: _isUploading ? null : _handleSend,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
<<<<<<< HEAD
        ),
      ],
=======
>>>>>>> a8ccd1b20499cc86d195494c3467701f9cec5386
    );
  }
}
