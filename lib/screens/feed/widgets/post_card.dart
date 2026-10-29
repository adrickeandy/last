import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
<<<<<<< HEAD
import 'package:url_launcher/url_launcher.dart';
=======
>>>>>>> a8ccd1b20499cc86d195494c3467701f9cec5386
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/avatar_view.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../core/widgets/image_lightbox_dialog.dart';
import '../../../core/widgets/toast_overlay.dart';
import '../../../models/post_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/feed_provider.dart';
import '../../../providers/ui_provider.dart';
import 'comment_bottom_sheet.dart';
<<<<<<< HEAD
import 'post_actions.dart';
=======
>>>>>>> a8ccd1b20499cc86d195494c3467701f9cec5386

class PostCard extends StatefulWidget {
  final PostModel post;

  const PostCard({super.key, required this.post});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  bool _showComments = false;
  bool _isRetrying = false;

  // This card tracks its own like state so it works wherever it is shown
  // (feed, profile page, ...), not only for posts held by FeedProvider.
  late bool _liked = widget.post.likedByMe;
  late int _likeCount = widget.post.likeCount;
  bool _likeBusy = false;

  @override
  void didUpdateWidget(covariant PostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Pick up fresh server data (pull-to-refresh, background sync) - but
    // never clobber the optimistic state while a like request is in flight.
    if (!_likeBusy &&
        (oldWidget.post.likedByMe != widget.post.likedByMe ||
            oldWidget.post.likeCount != widget.post.likeCount ||
            oldWidget.post.id != widget.post.id)) {
      _liked = widget.post.likedByMe;
      _likeCount = widget.post.likeCount;
    }
  }

  Future<void> _handleLike() async {
    final auth = context.read<AuthProvider>();
    final user = auth.user;
    if (user == null) {
      ToastOverlay.show(context, 'Sign in to like posts', type: ToastType.info);
      return;
    }
    if (_likeBusy || widget.post.isPending) return;

    final feed = context.read<FeedProvider>();
    final wantLiked = !_liked;
    final previousLiked = _liked;
    final previousCount = _likeCount;

    // Show the change instantly.
    final optimisticCount = previousCount + (wantLiked ? 1 : -1);
    setState(() {
      _likeBusy = true;
      _liked = wantLiked;
      _likeCount = optimisticCount < 0 ? 0 : optimisticCount;
    });

    final result = await feed.setLike(widget.post.id, user.id, wantLiked);
    if (!mounted) return;

    setState(() {
      _likeBusy = false;
      if (result.success) {
        // Use the real total so everyone sees the same number.
        if (result.serverLikeCount != null) _likeCount = result.serverLikeCount!;
      } else {
        _liked = previousLiked;
        _likeCount = previousCount;
      }
    });

    if (!result.success) {
      ToastOverlay.show(context, 'Could not update like. Try again.', type: ToastType.error);
    }
  }

  void _openAuthorProfile() {
    final username = widget.post.author?.username;
    if (widget.post.isConfession || username == null) return;
    context.read<UIProvider>().openProfile(username);
  }

  Future<void> _handleRetry() async {
    if (_isRetrying) return;
    setState(() => _isRetrying = true);
    final feed = context.read<FeedProvider>();
    final ok = await feed.retryPost(widget.post.id);
    if (mounted) {
      setState(() => _isRetrying = false);
      if (!ok) {
        ToastOverlay.show(context, 'Still no connection - will retry again', type: ToastType.info);
      }
    }
  }

<<<<<<< HEAD
  /// Opens the attached video (uploaded file or older pasted link) in the
  /// device's video player / browser.
  Future<void> _playVideo() async {
    final uri = Uri.tryParse(widget.post.videoUrl ?? '');
    var ok = false;
    if (uri != null) {
      ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    if (!ok && mounted) {
      ToastOverlay.show(context, 'Could not open video', type: ToastType.error);
    }
  }

=======
>>>>>>> a8ccd1b20499cc86d195494c3467701f9cec5386
  void _handleDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkBg900,
        title: const Text('Delete Post?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.coral500),
            onPressed: () {
              Navigator.of(ctx).pop();
              final feed = context.read<FeedProvider>();
              feed.deletePost(widget.post.id);
              ToastOverlay.show(context, 'Post deleted', type: ToastType.success);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = context.watch<AuthProvider>();
    final post = widget.post;
    final isAuthor = auth.user?.id == post.authorId;

    return GlassContainer(
      padding: const EdgeInsets.all(18),
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Avatar, Name, Verified, Date, More Menu
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (!post.isConfession)
                AvatarView(
                  url: post.author?.avatarUrl,
                  name: post.author?.fullName ?? post.author?.username ?? '?',
                  size: 40,
                  onTap: _openAuthorProfile,
                )
              else
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.coral500.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_outline_rounded,
                    color: AppColors.coral400,
                    size: 20,
                  ),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: GestureDetector(
                            onTap: post.isConfession ? null : _openAuthorProfile,
                            child: MouseRegion(
                              cursor: post.isConfession
                                  ? SystemMouseCursors.basic
                                  : SystemMouseCursors.click,
                              child: Text(
                                post.isConfession
                                    ? 'Anonymous Student'
                                    : (post.author?.fullName ?? post.author?.username ?? 'Student'),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (!post.isConfession && (post.author?.isVerified ?? false)) ...[
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.check_circle_rounded,
                            size: 14,
                            color: AppColors.violet400,
                          ),
                        ],
                        const SizedBox(width: 6),
                        Text(
                          '· ${AppFormatters.timeAgo(post.createdAt)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.darkInk400 : AppColors.lightInk400,
                          ),
                        ),
                        if (post.isPending) ...[
                          const SizedBox(width: 6),
                          // Tappable: forces an immediate retry instead of
                          // waiting for the next automatic loadFeed() pass.
                          InkWell(
                            borderRadius: BorderRadius.circular(6),
                            onTap: _handleRetry,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.lime500.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (_isRetrying)
                                    SizedBox(
                                      width: 8,
                                      height: 8,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 1.5,
                                        color: AppColors.lime500,
                                      ),
                                    )
                                  else
                                    Icon(Icons.refresh_rounded, size: 10, color: AppColors.lime500),
                                  const SizedBox(width: 4),
                                  Text(
                                    _isRetrying ? 'Sending…' : 'Not sent · tap to retry',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.lime500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (!post.isConfession && post.author?.username != null)
                      GestureDetector(
                        onTap: _openAuthorProfile,
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: Text(
                            '@${post.author!.username}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.darkInk400 : AppColors.lightInk400,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (isAuthor)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_horiz_rounded, size: 20),
                  onSelected: (val) {
                    if (val == 'delete') _handleDelete();
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline_rounded, color: AppColors.coral400, size: 18),
                          SizedBox(width: 8),
                          Text('Delete post', style: TextStyle(color: AppColors.coral400, fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // Content
          if (post.content != null && post.content!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              post.content!,
              style: TextStyle(
                fontSize: 14.5,
                height: 1.45,
                color: isDark ? AppColors.darkInk100 : AppColors.lightInk100,
              ),
            ),
          ],

          // Images Gallery Grid
          if (post.imageUrls.isNotEmpty) ...[
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: _buildImageGallery(post.imageUrls),
            ),
          ],

          // Video Attached Player / Banner
          if (post.videoUrl != null && post.videoUrl!.isNotEmpty) ...[
            const SizedBox(height: 14),
<<<<<<< HEAD
            InkWell(
              onTap: _playVideo,
              borderRadius: BorderRadius.circular(14),
              child: Container(
=======
            Container(
>>>>>>> a8ccd1b20499cc86d195494c3467701f9cec5386
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? AppColors.darkGlassBorder : AppColors.lightGlassBorder,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.violet500.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.play_arrow_rounded, color: AppColors.violet400, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Video attachment',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
<<<<<<< HEAD
                        const Text(
                          'Tap to play',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 11, color: AppColors.violet300),
=======
                        Text(
                          post.videoUrl!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11, color: AppColors.violet300),
>>>>>>> a8ccd1b20499cc86d195494c3467701f9cec5386
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
<<<<<<< HEAD
            ),
=======
>>>>>>> a8ccd1b20499cc86d195494c3467701f9cec5386
          ],

          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 10),

          // Action Buttons: Like, Comment, Share
          Row(
            children: [
              // Like
              InkWell(
                onTap: _handleLike,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Row(
                    children: [
                      Icon(
                        _liked ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
                        size: 18,
                        color: _liked ? AppColors.coral500 : (isDark ? AppColors.darkInk300 : AppColors.lightInk300),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _likeCount.toString(),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: _liked ? AppColors.coral500 : (isDark ? AppColors.darkInk300 : AppColors.lightInk300),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Comment
              InkWell(
                onTap: () => setState(() => _showComments = !_showComments),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Row(
                    children: [
                      Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 17,
                        color: _showComments ? AppColors.violet400 : (isDark ? AppColors.darkInk300 : AppColors.lightInk300),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        post.commentCount.toString(),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: _showComments ? AppColors.violet400 : (isDark ? AppColors.darkInk300 : AppColors.lightInk300),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),

<<<<<<< HEAD
              // Forward: pick a person, open the chat, drop the post in it
              IconButton(
                icon: const Icon(Icons.shortcut_rounded, size: 19),
                tooltip: 'Forward',
                onPressed: () => PostActions.forward(context, post),
              ),

              // Share: copies the post (text + media links) to the clipboard
              IconButton(
                icon: const Icon(Icons.share_outlined, size: 18),
                tooltip: 'Share (copy post)',
                onPressed: () => PostActions.share(context, post),
=======
              // Share
              IconButton(
                icon: const Icon(Icons.share_outlined, size: 18),
                tooltip: 'Share link',
                onPressed: () {
                  ToastOverlay.show(context, 'Post link copied to clipboard!', type: ToastType.info);
                },
>>>>>>> a8ccd1b20499cc86d195494c3467701f9cec5386
              ),
            ],
          ),

          // Comments Section Dropdown
          if (_showComments) CommentSectionWidget(postId: post.id),
        ],
      ),
    );
  }

  Widget _buildImageGallery(List<String> images) {
    if (images.length == 1) {
      return GestureDetector(
        onTap: () => ImageLightboxDialog.show(context, images, 0),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: CachedNetworkImage(
            imageUrl: images[0],
            fit: BoxFit.cover,
            height: 280,
            width: double.infinity,
            placeholder: (context, url) => Container(color: Colors.black12, height: 280),
          ),
        ),
      );
    } else if (images.length == 2) {
      return Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => ImageLightboxDialog.show(context, images, 0),
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: CachedNetworkImage(
                  imageUrl: images[0],
                  fit: BoxFit.cover,
                  height: 180,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: GestureDetector(
              onTap: () => ImageLightboxDialog.show(context, images, 1),
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: CachedNetworkImage(
                  imageUrl: images[1],
                  fit: BoxFit.cover,
                  height: 180,
                ),
              ),
            ),
          ),
        ],
      );
    } else {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
          childAspectRatio: 1.5,
        ),
        itemCount: images.length.clamp(0, 4),
        itemBuilder: (context, i) {
          return GestureDetector(
            onTap: () => ImageLightboxDialog.show(context, images, i),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: CachedNetworkImage(
                imageUrl: images[i],
                fit: BoxFit.cover,
              ),
            ),
          );
        },
      );
    }
  }
}
