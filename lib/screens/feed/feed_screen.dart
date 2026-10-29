import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/skeleton_loader.dart';
import '../../providers/auth_provider.dart';
import '../../providers/feed_provider.dart';
import 'widgets/create_post_card.dart';
import 'widgets/post_card.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().user;
      context.read<FeedProvider>().loadFeed(user?.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final feed = context.watch<FeedProvider>();
    final posts = feed.feedPosts;
    final isLoading = feed.isLoadingFeed;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: RefreshIndicator(
          onRefresh: () async {
            final user = context.read<AuthProvider>().user;
            await context.read<FeedProvider>().loadFeed(user?.id);
          },
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            children: [
              if (feed.isOffline)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.lime500.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.lime500.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.cloud_off_rounded, size: 16, color: AppColors.lime500),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "You're offline — showing saved posts. We'll sync when you're back.",
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.darkInk200 : AppColors.lightInk200,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Composer
              const CreatePostCard(),
              const SizedBox(height: 20),

              // Posts List or Skeletons
              if (isLoading) ...[
                const SkeletonLoader(height: 140, margin: EdgeInsets.only(bottom: 16)),
                const SkeletonLoader(height: 220, margin: EdgeInsets.only(bottom: 16)),
                const SkeletonLoader(height: 140, margin: EdgeInsets.only(bottom: 16)),
              ] else if (posts.isEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(40),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkBg900.withOpacity(0.5) : Colors.white70,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? AppColors.darkGlassBorder : AppColors.lightGlassBorder,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.dynamic_feed_rounded,
                        size: 48,
                        color: isDark ? AppColors.darkInk500 : AppColors.lightInk500,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No posts yet',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Be the first to share something with your campus community.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? AppColors.darkInk400 : AppColors.lightInk400,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                for (final post in posts) PostCard(key: ValueKey(post.id), post: post),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
