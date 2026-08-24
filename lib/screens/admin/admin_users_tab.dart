import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/avatar_view.dart';
import '../../core/widgets/glass_button.dart';
import '../../core/widgets/glass_container.dart';
import '../../core/widgets/skeleton_loader.dart';
import '../../core/widgets/toast_overlay.dart';
import '../../models/profile_model.dart';
import '../../services/admin_service.dart';

class AdminUsersTab extends StatefulWidget {
  const AdminUsersTab({super.key});

  @override
  State<AdminUsersTab> createState() => _AdminUsersTabState();
}

class _AdminUsersTabState extends State<AdminUsersTab> {
  final _adminService = AdminService();
  List<ProfileModel> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final list = await _adminService.fetchAllUsers();
    if (mounted) {
      setState(() {
        _users = list;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleBan(ProfileModel user) async {
    final next = !user.isBanned;
    setState(() {
      final index = _users.indexWhere((u) => u.id == user.id);
      if (index != -1) _users[index] = user.copyWith(isBanned: next);
    });

    try {
      await _adminService.toggleBanUser(user.id, next);
      ToastOverlay.show(context, next ? 'User banned' : 'User unbanned', type: ToastType.info);
    } catch (e) {
      print('[AdminUsersTab] error: $e');
    }
  }

  Future<void> _toggleVerify(ProfileModel user) async {
    final next = !user.isVerified;
    setState(() {
      final index = _users.indexWhere((u) => u.id == user.id);
      if (index != -1) _users[index] = user.copyWith(isVerified: next);
    });

    try {
      await _adminService.toggleVerifyUser(user.id, next);
      ToastOverlay.show(context, next ? 'User verified' : 'Verification removed', type: ToastType.success);
    } catch (e) {
      print('[AdminUsersTab] error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: 6,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, __) => const SkeletonLoader(height: 56),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: _users.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final u = _users[i];

        return GlassContainer(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              AvatarView(
                url: u.avatarUrl,
                name: u.fullName ?? u.username,
                size: 38,
                isVerified: u.isVerified,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          u.fullName ?? u.username,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        if (u.isAdmin) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.violet500.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'ADMIN',
                              style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: AppColors.violet400),
                            ),
                          ),
                        ],
                        if (u.isBanned) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.coral500.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'BANNED',
                              style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: AppColors.coral400),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      '@${u.username} · ${u.campus ?? 'No campus'}',
                      style: TextStyle(fontSize: 11.5, color: isDark ? AppColors.darkInk400 : AppColors.lightInk400),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  GlassButton(
                    variant: u.isVerified ? GlassButtonVariant.secondary : GlassButtonVariant.ghost,
                    text: u.isVerified ? 'Verified' : 'Verify',
                    icon: Icons.check_circle_outline,
                    height: 34,
                    onPressed: () => _toggleVerify(u),
                  ),
                  const SizedBox(width: 8),
                  GlassButton(
                    variant: u.isBanned ? GlassButtonVariant.primary : GlassButtonVariant.danger,
                    text: u.isBanned ? 'Unban' : 'Ban',
                    height: 34,
                    onPressed: () => _toggleBan(u),
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
