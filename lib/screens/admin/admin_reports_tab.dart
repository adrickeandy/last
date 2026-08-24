import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/glass_button.dart';
import '../../core/widgets/glass_container.dart';
import '../../core/widgets/skeleton_loader.dart';
import '../../core/widgets/toast_overlay.dart';
import '../../models/admin_models.dart';
import '../../services/admin_service.dart';

class AdminReportsTab extends StatefulWidget {
  const AdminReportsTab({super.key});

  @override
  State<AdminReportsTab> createState() => _AdminReportsTabState();
}

class _AdminReportsTabState extends State<AdminReportsTab> {
  final _adminService = AdminService();
  List<ReportModel> _reports = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    final list = await _adminService.fetchReports();
    if (mounted) {
      setState(() {
        _reports = list;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleResolve(String reportId, String status) async {
    setState(() => _reports.removeWhere((r) => r.id == reportId));
    try {
      await _adminService.resolveReport(reportId, status);
      ToastOverlay.show(context, 'Report marked as $status', type: ToastType.info);
    } catch (e) {
      print('[AdminReportsTab] error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: 3,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, __) => const SkeletonLoader(height: 90),
      );
    }

    if (_reports.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_outline_rounded, size: 48, color: AppColors.lime400),
            const SizedBox(height: 12),
            const Text('No unresolved reports', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 4),
            Text('All flagged community items have been addressed.', style: TextStyle(fontSize: 13, color: isDark ? AppColors.darkInk400 : AppColors.lightInk400)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: _reports.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final r = _reports[i];

        return GlassContainer(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.coral500.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          r.targetType.toUpperCase(),
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.coral400),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Reported by @${r.reporter?.username ?? 'user'}',
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Text(
                    AppFormatters.timeAgo(r.createdAt),
                    style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkInk400 : AppColors.lightInk400),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Reason: ${r.reason}',
                style: TextStyle(fontSize: 13, color: isDark ? AppColors.darkInk100 : AppColors.lightInk100),
              ),
              if (r.post?.content != null) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Post Content: "${r.post!.content}"',
                    style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: isDark ? AppColors.darkInk300 : AppColors.lightInk300),
                  ),
                ),
              ],
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GlassButton(
                    variant: GlassButtonVariant.ghost,
                    text: 'Dismiss',
                    height: 32,
                    onPressed: () => _handleResolve(r.id, 'dismissed'),
                  ),
                  const SizedBox(width: 8),
                  GlassButton(
                    variant: GlassButtonVariant.primary,
                    text: 'Resolve & Remove',
                    height: 32,
                    onPressed: () => _handleResolve(r.id, 'resolved'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
