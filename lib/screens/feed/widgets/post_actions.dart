import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/toast_overlay.dart';
import '../../../models/forwarded_post.dart';
import '../../../models/post_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/chat_provider.dart';
import '../../../providers/ui_provider.dart';
import '../../messages/widgets/new_chat_dialog.dart';

/// The two "send this post somewhere" actions, shared by every place a post is
/// shown (feed, profile, confessions) so they all behave identically.
class PostActions {
  PostActions._();

  /// The plain text copied by the Share button.
  static String shareText(PostModel post) {
    final buffer = StringBuffer();

    if (post.isConfession) {
      buffer.writeln('Anonymous confession on Plateau High Zone:');
    } else {
      final name = post.author?.fullName ?? post.author?.username;
      final handle = post.author?.username;
      if (name != null) {
        buffer.write(name);
        if (handle != null && handle != name) buffer.write(' (@$handle)');
        buffer.writeln(' on Plateau High Zone:');
      } else {
        buffer.writeln('Post on Plateau High Zone:');
      }
    }

    final content = (post.content ?? '').trim();
    if (content.isNotEmpty) buffer.writeln(content);
    for (final url in post.imageUrls) {
      buffer.writeln(url);
    }
    if (post.videoUrl != null && post.videoUrl!.isNotEmpty) {
      buffer.writeln(post.videoUrl);
    }

    return buffer.toString().trim();
  }

  /// Share: copies the post (text + media links) to the clipboard.
  static Future<void> share(BuildContext context, PostModel post) async {
    await Clipboard.setData(ClipboardData(text: shareText(post)));
    if (context.mounted) {
      ToastOverlay.show(context, 'Post copied to clipboard', type: ToastType.success);
    }
  }

  /// Forward: pick a person (same search as "New message"), open the chat with
  /// them and drop the post into it.
  static Future<void> forward(BuildContext context, PostModel post) async {
    final me = context.read<AuthProvider>().user;
    if (me == null) {
      ToastOverlay.show(context, 'Sign in to forward posts', type: ToastType.info);
      return;
    }

    // Grab everything we need from the context BEFORE awaiting anything.
    final chat = context.read<ChatProvider>();
    final ui = context.read<UIProvider>();

    final target = await NewChatDialog.show(context, title: 'Forward to…');
    if (target == null) return;

    if (target.id == me.id) {
      if (context.mounted) {
        ToastOverlay.show(context, 'Pick someone else to forward to', type: ToastType.info);
      }
      return;
    }

    try {
      // Finds the existing 1-to-1 chat or creates it, and makes it the active one.
      await chat.startOrGetDirectChat(me.id, target.id);

      // Open the chat first so the person sees it straight away (phones show
      // one pane at a time, so the chat itself has to be opened too).
      ui.setTab(AppTab.messages);
      ui.setChatOpen(true);

      // Goes through the normal offline-first send path: the bubble appears
      // instantly and is retried automatically if there is no connection.
      await chat.sendMessage(
        senderId: me.id,
        content: ForwardedPost.fromPost(post).encode(),
      );
    } catch (e) {
      debugPrint('[PostActions] forward failed: $e');
      if (context.mounted) {
        ToastOverlay.show(context, 'Could not forward the post. Please try again.', type: ToastType.error);
      }
    }
  }
}
