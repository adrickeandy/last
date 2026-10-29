import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_container.dart';
import '../../core/widgets/skeleton_loader.dart';
import '../../core/widgets/toast_overlay.dart';
import '../../models/admin_models.dart';
import '../../services/admin_service.dart';

class AdminFlagsTab extends StatefulWidget {
  const AdminFlagsTab({super.key});

  @override
  State<AdminFlagsTab> createState() => _AdminFlagsTabState();
}

class _AdminFlagsTabState extends State<AdminFlagsTab> {
  final _adminService = AdminService();
  List<FeatureFlagModel> _flags = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFlags();
  }

  Future<void> _loadFlags() async {
    final list = await _adminService.fetchFeatureFlags();
    if (mounted) {
      setState(() {
        _flags = list;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleFlag(FeatureFlagModel flag) async {
    final next = !flag.enabled;
    setState(() {
      final index = _flags.indexWhere((f) => f.key == flag.key);
      if (index != -1) {
        _flags[index] = FeatureFlagModel(
          key: flag.key,
          enabled: next,
          description: flag.description,
          updatedBy: flag.updatedBy,
          updatedAt: DateTime.now().toIso8601String(),
        );
      }
    });

    try {
      await _adminService.updateFeatureFlag(flag.key, next);
      ToastOverlay.show(context, '${flag.key} set to $next', type: ToastType.info);
    } catch (e) {
      print('[AdminFlagsTab] error: $e');
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
        itemBuilder: (_, __) => const SkeletonLoader(height: 56),
      );
    }

    if (_flags.isEmpty) {
      return Center(
        child: Text(
          'No feature flags configured.',
          style: TextStyle(fontSize: 13, color: isDark ? AppColors.darkInk400 : AppColors.lightInk400),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: _flags.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final flag = _flags[i];

        return GlassContainer(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      flag.key,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    if (flag.description != null)
                      Text(
                        flag.description!,
                        style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkInk400 : AppColors.lightInk400),
                      ),
                  ],
                ),
              ),
              Switch(
                value: flag.enabled,
                activeColor: AppColors.violet500,
                onChanged: (_) => _toggleFlag(flag),
              ),
            ],
          ),
        );
      },
    );
  }
}
