import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

class PostCard extends StatefulWidget {
  final PostModel post;

  const PostCard({super.key, required this.post});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  bool _showComments = false;

  void _handleLike() {
    final auth = context.read<AuthProvider>();
    final user = auth.user;
    if (user == null) {
      ToastOverlay.show(context, 'Sign in to like posts', type: ToastType.info);
      return;
    }

    final feed = context.read<FeedProvider>();
    feed.toggleLike(widget.post.id, user.id);
  }

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
    final ui = context.read<UIProvider>();
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
                  onTap: () {
                    if (post.author?.username != null) {
                      ui.openProfile(post.author!.username);
                    }
                  },
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
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.lime500.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 8,
                                  height: 8,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 1.5,
                                    color: AppColors.lime500,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Sending…',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.lime500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (!post.isConfession && post.author?.username != null)
                      Text(
                        '@${post.author!.username}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.darkInk400 : AppColors.lightInk400,
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
            Container(
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
                        Text(
                          post.videoUrl!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11, color: AppColors.violet300),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
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
                        post.likedByMe ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
                        size: 18,
                        color: post.likedByMe ? AppColors.coral500 : (isDark ? AppColors.darkInk300 : AppColors.lightInk300),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        post.likeCount.toString(),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: post.likedByMe ? AppColors.coral500 : (isDark ? AppColors.darkInk300 : AppColors.lightInk300),
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

              // Share
              IconButton(
                icon: const Icon(Icons.share_outlined, size: 18),
                tooltip: 'Share link',
                onPressed: () {
                  ToastOverlay.show(context, 'Post link copied to clipboard!', type: ToastType.info);
                },
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
