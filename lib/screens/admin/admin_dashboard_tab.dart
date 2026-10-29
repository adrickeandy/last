import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_container.dart';
import '../../core/widgets/skeleton_loader.dart';
import '../../services/admin_service.dart';

class AdminDashboardTab extends StatefulWidget {
  const AdminDashboardTab({super.key});

  @override
  State<AdminDashboardTab> createState() => _AdminDashboardTabState();
}

class _AdminDashboardTabState extends State<AdminDashboardTab> {
  final _adminService = AdminService();
  Map<String, int>? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final stats = await _adminService.fetchAdminStats();
    if (mounted) {
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cards = [
      {'key': 'users', 'label': 'Total Users', 'icon': Icons.people_alt_rounded, 'color': AppColors.violet400},
      {'key': 'posts', 'label': 'Published Posts', 'icon': Icons.article_rounded, 'color': AppColors.lime400},
      {'key': 'openReports', 'label': 'Open Reports', 'icon': Icons.flag_rounded, 'color': AppColors.coral400},
      {'key': 'bannedUsers', 'label': 'Banned Users', 'icon': Icons.block_rounded, 'color': AppColors.coral500},
      {'key': 'messages', 'label': 'Messages Sent', 'icon': Icons.chat_rounded, 'color': AppColors.violet300},
    ];

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Stats Grid
        if (_isLoading)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.3,
            ),
            itemCount: 5,
            itemBuilder: (_, __) => const SkeletonLoader(height: 90),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.25,
            ),
            itemCount: cards.length,
            itemBuilder: (context, i) {
              final c = cards[i];
              final count = _stats?[c['key'] as String] ?? 0;
              final color = c['color'] as Color;

              return GlassContainer(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(c['icon'] as IconData, size: 22, color: color),
                    const SizedBox(height: 8),
                    Text(
                      count.toString(),
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      c['label'] as String,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? AppColors.darkInk400 : AppColors.lightInk400,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        const SizedBox(height: 24),

        // Quick Actions & Overview Notice
        GlassContainer(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.shield_outlined, color: AppColors.violet400, size: 20),
                  const SizedBox(width: 8),
                  Text('Moderation & Security Console', style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Use the tabs above to manage registered students, moderate flagged content, inspect reported items, toggle dynamic platform features, and audit administrative activity logs.',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  color: isDark ? AppColors.darkInk300 : AppColors.lightInk300,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
