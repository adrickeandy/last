import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/glass_container.dart';
import '../../core/widgets/skeleton_loader.dart';
import '../../models/admin_models.dart';
import '../../services/admin_service.dart';

class AdminLogsTab extends StatefulWidget {
  const AdminLogsTab({super.key});

  @override
  State<AdminLogsTab> createState() => _AdminLogsTabState();
}

class _AdminLogsTabState extends State<AdminLogsTab> {
  final _adminService = AdminService();
  List<AdminLogModel> _logs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    final list = await _adminService.fetchAdminLogs();
    if (mounted) {
      setState(() {
        _logs = list;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: 4,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, __) => const SkeletonLoader(height: 48),
      );
    }

    if (_logs.isEmpty) {
      return Center(
        child: Text(
          'No admin activity logs recorded yet.',
          style: TextStyle(fontSize: 13, color: isDark ? AppColors.darkInk400 : AppColors.lightInk400),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: _logs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final log = _logs[i];

        return GlassContainer(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.violet500.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.history_edu_rounded, size: 16, color: AppColors.violet400),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      log.action,
                      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
                    ),
                    if (log.targetType != null)
                      Text(
                        'Target: ${log.targetType} (${log.targetId ?? 'N/A'})',
                        style: TextStyle(fontSize: 11.5, color: isDark ? AppColors.darkInk400 : AppColors.lightInk400),
                      ),
                  ],
                ),
              ),
              Text(
                AppFormatters.timeAgo(log.createdAt),
                style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkInk500 : AppColors.lightInk500),
              ),
            ],
          ),
        );
      },
    );
  }
}
