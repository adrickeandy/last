import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/avatar_view.dart';
<<<<<<< HEAD
import '../../core/widgets/doodle_background.dart';
=======
>>>>>>> a8ccd1b20499cc86d195494c3467701f9cec5386
import '../../core/widgets/glass_button.dart';
import '../../core/widgets/glass_container.dart';
import '../../core/widgets/skeleton_loader.dart';
import '../../core/widgets/toast_overlay.dart';
import '../../models/profile_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/ui_provider.dart';
import 'widgets/chat_thread.dart';
import 'widgets/new_chat_dialog.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  /// Below this width the phone layout is used (one pane at a time).
  static const double _phoneBreakpoint = 720;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().user;
      if (user != null) {
        context.read<ChatProvider>().loadConversations(user.id);
      }
    });
  }

  // The dialog only returns who was picked. This screen (which stays
  // mounted, unlike the dialog it just closed) does the real network call
  // and can safely show a toast if it fails.
  Future<void> _openNewChatDialog() async {
    final selected = await NewChatDialog.show(context);
    if (selected == null) return;
    await _startChatWith(selected);
  }

  Future<void> _startChatWith(ProfileModel other) async {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    final chat = context.read<ChatProvider>();
    final ui = context.read<UIProvider>();

    try {
      await chat.startOrGetDirectChat(user.id, other.id);
      // Phone: jump straight into the new chat.
      if (mounted) ui.setChatOpen(true);
    } catch (e) {
      if (mounted) {
        ToastOverlay.show(
          context,
          'Could not start chat: $e',
          type: ToastType.error,
        );
      }
    }
  }

  void _onConversationTap(String conversationId) {
    context.read<ChatProvider>().selectConversation(conversationId);
    // On desktop this flag is ignored; on phones it switches to the chat.
    context.read<UIProvider>().setChatOpen(true);
  }

  @override
  Widget build(BuildContext context) {
    final isPhone = MediaQuery.of(context).size.width < _phoneBreakpoint;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chat = context.watch<ChatProvider>();
    final ui = context.watch<UIProvider>();
    final activeConv = chat.activeConversation;

    // ------------------------------------------------------------------
    // PHONE: one pane at a time. List by default; chat when one is open.
    // (System Back / the arrow in the chat header return to the list —
    // handled by the shell via UIProvider.isChatOpen.)
    // ------------------------------------------------------------------
    if (isPhone) {
      if (ui.isChatOpen && activeConv != null) {
        return ChatThread(
          key: ValueKey(activeConv.id),
          conversation: activeConv,
          onBack: () => ui.setChatOpen(false),
        );
      }
      return _buildConversationList(context, chat, isDark);
    }

    // ------------------------------------------------------------------
    // PC / TABLET: list on the left, chat on the right (original layout)
    // ------------------------------------------------------------------
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: GlassContainer(
            padding: EdgeInsets.zero,
            child: Row(
              children: [
                // Left Pane: Conversations List
                Container(
                  width: 300,
                  decoration: BoxDecoration(
                    border: Border(
                      right: BorderSide(
                        color: isDark ? AppColors.darkGlassBorder : AppColors.lightGlassBorder,
                      ),
                    ),
                  ),
                  child: _buildConversationList(context, chat, isDark),
                ),

                // Right Pane: Active Thread or Placeholder
                Expanded(
                  child: activeConv != null
                      ? ChatThread(key: ValueKey(activeConv.id), conversation: activeConv)
                      : _buildEmptyChatPlaceholder(context, isDark),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Conversation list (shared by PC left pane and the phone list screen)
  // ---------------------------------------------------------------------
  Widget _buildConversationList(BuildContext context, ChatProvider chat, bool isDark) {
    final conversations = chat.conversations;
    final isLoading = chat.isLoadingConversations;

    return Column(
      children: [
        // Header with New Message action
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Messages',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              IconButton(
                tooltip: 'New message',
                icon: const Icon(Icons.edit_note_rounded, size: 22),
                onPressed: _openNewChatDialog,
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // Conversations ListView
        Expanded(
          child: isLoading
              ? ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: 4,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, __) => const SkeletonLoader(height: 52),
                )
              : conversations.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline_rounded,
                              size: 36,
                              color: isDark ? AppColors.darkInk500 : AppColors.lightInk500,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'No conversations yet',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? AppColors.darkInk400 : AppColors.lightInk400,
                              ),
                            ),
                            const SizedBox(height: 12),
                            GlassButton(
                              variant: GlassButtonVariant.secondary,
                              text: 'Start chat',
                              height: 34,
                              onPressed: _openNewChatDialog,
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: conversations.length,
                      itemBuilder: (context, i) {
                        final c = conversations[i];
                        final isSelected = c.id == chat.activeConversationId;
                        final other = c.otherProfile;
                        final name = other?.fullName ?? other?.username ?? c.title ?? 'Direct message';

                        return ListTile(
                          selected: isSelected,
                          selectedTileColor: isDark
                              ? Colors.white.withOpacity(0.06)
                              : Colors.black.withOpacity(0.04),
                          hoverColor: isDark
                              ? Colors.white.withOpacity(0.03)
                              : Colors.black.withOpacity(0.02),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                          leading: AvatarView(
                            url: other?.avatarUrl,
                            name: name,
                            size: 38,
                          ),
                          title: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isDark ? AppColors.darkInk100 : AppColors.lightInk100,
                            ),
                          ),
                          subtitle: other?.username != null
                              ? Text(
                                  '@${other!.username}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: isDark ? AppColors.darkInk400 : AppColors.lightInk400,
                                  ),
                                )
                              : null,
                          onTap: () => _onConversationTap(c.id),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------
  // "Select a conversation" placeholder (PC only)
  // ---------------------------------------------------------------------
  Widget _buildEmptyChatPlaceholder(BuildContext context, bool isDark) {
<<<<<<< HEAD
    return Stack(
      fit: StackFit.expand,
      children: [
        const Positioned.fill(child: DoodleBackground()),
        _buildEmptyChatPlaceholderContent(context, isDark),
      ],
    );
  }

  Widget _buildEmptyChatPlaceholderContent(BuildContext context, bool isDark) {
=======
>>>>>>> a8ccd1b20499cc86d195494c3467701f9cec5386
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.violet500.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.chat_bubble_outline_rounded,
              color: AppColors.violet400,
              size: 28,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Select a conversation',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            'Choose a classmate from the list or start a new chat.',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.darkInk400 : AppColors.lightInk400,
            ),
          ),
          const SizedBox(height: 20),
          GlassButton(
            variant: GlassButtonVariant.primary,
            text: 'New message',
            icon: Icons.edit_note_rounded,
            onPressed: _openNewChatDialog,
          ),
        ],
      ),
    );
  }
}
