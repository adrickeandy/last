import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/glass_container.dart';
import '../../core/widgets/skeleton_loader.dart';
import '../../providers/feed_provider.dart';
import '../feed/widgets/create_post_card.dart';

class ConfessionsScreen extends StatefulWidget {
  const ConfessionsScreen({super.key});

  @override
  State<ConfessionsScreen> createState() => _ConfessionsScreenState();
}

class _ConfessionsScreenState extends State<ConfessionsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FeedProvider>().loadConfessions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final feed = context.watch<FeedProvider>();
    final confessions = feed.confessions;
    final isLoading = feed.isLoadingConfessions;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: RefreshIndicator(
          onRefresh: () async {
            await context.read<FeedProvider>().loadConfessions();
          },
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.coral500.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.lock_outline_rounded,
                      color: AppColors.coral400,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Campus Confessions',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        'Posts here never show your name or avatar to anyone.',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.darkInk400 : AppColors.lightInk400,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Confession Composer
              const CreatePostCard(isConfession: true),
              const SizedBox(height: 20),

              // Confessions Stream
              if (isLoading) ...[
                const SkeletonLoader(height: 100, margin: EdgeInsets.only(bottom: 14)),
                const SkeletonLoader(height: 120, margin: EdgeInsets.only(bottom: 14)),
                const SkeletonLoader(height: 90, margin: EdgeInsets.only(bottom: 14)),
              ] else if (confessions.isEmpty) ...[
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
                      const Icon(Icons.lock_outline_rounded, size: 40, color: AppColors.coral400),
                      const SizedBox(height: 12),
                      const Text(
                        'No confessions yet',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Yours could be the first. Drop an anonymous confession above.',
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
                for (final c in confessions)
                  GlassContainer(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c.content ?? '',
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.45,
                            color: isDark ? AppColors.darkInk100 : AppColors.lightInk100,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.lock_outline_rounded, size: 13, color: AppColors.coral400),
                            const SizedBox(width: 4),
                            Text(
                              'Anonymous · ${AppFormatters.timeAgo(c.createdAt)}',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? AppColors.darkInk500 : AppColors.lightInk500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
