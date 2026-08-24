import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/avatar_view.dart';
import '../../core/widgets/glass_button.dart';
import '../../core/widgets/glass_container.dart';
import '../../core/widgets/skeleton_loader.dart';
import '../../core/widgets/toast_overlay.dart';
import '../../models/post_model.dart';
import '../../services/admin_service.dart';
import '../../services/post_service.dart';

class AdminPostsTab extends StatefulWidget {
  const AdminPostsTab({super.key});

  @override
  State<AdminPostsTab> createState() => _AdminPostsTabState();
}

class _AdminPostsTabState extends State<AdminPostsTab> {
  final _adminService = AdminService();
  final _postService = PostService();
  List<PostModel> _posts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    final list = await _adminService.fetchRecentPosts();
    if (mounted) {
      setState(() {
        _posts = list;
        _isLoading = false;
      });
    }
  }

  Future<void> _deletePost(String postId) async {
    setState(() => _posts.removeWhere((p) => p.id == postId));
    try {
      await _postService.deletePost(postId);
      ToastOverlay.show(context, 'Post removed by admin', type: ToastType.success);
    } catch (e) {
      print('[AdminPostsTab] error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: 4,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, __) => const SkeletonLoader(height: 80),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: _posts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final p = _posts[i];

        return GlassContainer(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AvatarView(
                url: p.author?.avatarUrl,
                name: p.author?.fullName ?? p.author?.username ?? 'Student',
                size: 36,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          p.author?.fullName ?? p.author?.username ?? 'Anonymous',
                          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '· ${AppFormatters.timeAgo(p.createdAt)}',
                          style: TextStyle(fontSize: 11.5, color: isDark ? AppColors.darkInk400 : AppColors.lightInk400),
                        ),
                        if (p.isConfession) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppColors.coral500.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('Confession', style: TextStyle(fontSize: 9.5, color: AppColors.coral400)),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      p.content ?? (p.imageUrls.isNotEmpty ? '[Image attachment]' : '[No text]'),
                      style: TextStyle(fontSize: 13, color: isDark ? AppColors.darkInk200 : AppColors.lightInk200),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          '${p.likeCount} likes · ${p.commentCount} comments · ${p.imageUrls.length} images',
                          style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkInk500 : AppColors.lightInk500),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              GlassButton(
                variant: GlassButtonVariant.danger,
                text: 'Remove',
                icon: Icons.delete_outline_rounded,
                height: 34,
                onPressed: () => _deletePost(p.id),
              ),
            ],
          ),
        );
      },
    );
  }
}
