import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/avatar_view.dart';
import '../../../core/widgets/glass_text_field.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../core/widgets/toast_overlay.dart';
import '../../../models/comment_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/feed_provider.dart';

class CommentSectionWidget extends StatefulWidget {
  final String postId;

  const CommentSectionWidget({super.key, required this.postId});

  @override
  State<CommentSectionWidget> createState() => _CommentSectionWidgetState();
}

class _CommentSectionWidgetState extends State<CommentSectionWidget> {
  final _commentController = TextEditingController();
  List<CommentModel> _comments = [];
  bool _isLoading = true;
  // Comment ids currently being retried, so each row can show its own
  // small spinner instead of one big loading state for the whole list.
  final Set<String> _retryingIds = {};

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    final feed = context.read<FeedProvider>();
    // Returns the cached list instantly (offline-safe) and kicks off a
    // background refresh - see FeedProvider.getComments.
    final list = await feed.getComments(widget.postId);
    if (mounted) {
      setState(() {
        _comments = list;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleAddComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final auth = context.read<AuthProvider>();
    final user = auth.user;
    final profile = auth.profile;
    if (user == null) {
      ToastOverlay.show(context, 'Sign in to comment', type: ToastType.error);
      return;
    }

    // Local-first: this returns immediately with a pending comment, it
    // does not wait for the network - the comment appears in the list
    // right away, offline or not.
    final feed = context.read<FeedProvider>();
    final comment = await feed.addComment(
      postId: widget.postId,
      authorId: user.id,
      content: text,
      authorProfile: profile,
    );

    if (mounted) {
      _commentController.clear();
      setState(() {
        _comments.add(comment);
      });
    }
  }

  Future<void> _handleRetryComment(CommentModel comment) async {
    if (_retryingIds.contains(comment.id)) return;
    setState(() => _retryingIds.add(comment.id));

    final feed = context.read<FeedProvider>();
    final ok = await feed.retryComment(widget.postId, comment.id);

    if (mounted) {
      setState(() => _retryingIds.remove(comment.id));
      if (ok) {
        // Re-read from cache so this row picks up the server-confirmed
        // comment (real id, etc.) instead of staying "pending" forever.
        _loadComments();
      } else {
        ToastOverlay.show(context, 'Still no connection - will retry again', type: ToastType.info);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = context.watch<AuthProvider>();
    final profile = auth.profile;

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkGlassBorder : AppColors.lightGlassBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Comments list
          if (_isLoading)
            Column(
              children: List.generate(
                2,
                (i) => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: SkeletonLoader(height: 36),
                ),
              ),
            )
          else if (_comments.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Center(
                child: Text(
                  'No comments yet. Start the conversation!',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.darkInk400 : AppColors.lightInk400,
                  ),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _comments.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final c = _comments[i];
                final isRetrying = _retryingIds.contains(c.id);
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AvatarView(
                      url: c.author?.avatarUrl,
                      name: c.author?.fullName ?? c.author?.username ?? '?',
                      size: 26,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Opacity(
                        // Slightly dim a comment that hasn't reached the
                        // server yet, same idea as PostCard's pending badge.
                        opacity: c.isPending ? 0.7 : 1.0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    c.author?.username ?? 'anonymous',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (c.isPending)
                                    InkWell(
                                      onTap: () => _handleRetryComment(c),
                                      borderRadius: BorderRadius.circular(6),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (isRetrying)
                                            SizedBox(
                                              width: 9,
                                              height: 9,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 1.3,
                                                color: AppColors.lime500,
                                              ),
                                            )
                                          else
                                            Icon(Icons.refresh_rounded, size: 11, color: AppColors.lime500),
                                          const SizedBox(width: 3),
                                          Text(
                                            isRetrying ? 'Sending…' : 'Retry',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.lime500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  else
                                    Text(
                                      AppFormatters.timeAgo(c.createdAt),
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        color: isDark ? AppColors.darkInk500 : AppColors.lightInk500,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                c.content,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? AppColors.darkInk200 : AppColors.lightInk200,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),

          const SizedBox(height: 12),

          // Add Comment Input
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              AvatarView(
                url: profile?.avatarUrl,
                name: profile?.fullName ?? profile?.username,
                size: 28,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GlassTextField(
                  controller: _commentController,
                  hintText: 'Write a comment…',
                  onSubmitted: (_) => _handleAddComment(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.send_rounded, size: 18, color: AppColors.violet400),
                onPressed: _handleAddComment,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
