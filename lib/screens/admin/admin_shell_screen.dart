import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import 'admin_dashboard_tab.dart';
import 'admin_flags_tab.dart';
import 'admin_logs_tab.dart';
import 'admin_posts_tab.dart';
import 'admin_reports_tab.dart';
import 'admin_users_tab.dart';

class AdminShellScreen extends StatefulWidget {
  const AdminShellScreen({super.key});

  @override
  State<AdminShellScreen> createState() => _AdminShellScreenState();
}

class _AdminShellScreenState extends State<AdminShellScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = context.watch<AuthProvider>();

    if (!auth.isAdmin) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.shield_outlined, size: 56, color: AppColors.coral500),
            const SizedBox(height: 16),
            const Text('Admin Access Denied', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(
              'Your account does not have administrative privileges.',
              style: TextStyle(fontSize: 13, color: isDark ? AppColors.darkInk400 : AppColors.lightInk400),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Tab Bar
        Container(
          height: 48,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isDark ? AppColors.darkGlassBorder : AppColors.lightGlassBorder,
              ),
            ),
          ),
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: AppColors.violet400,
            unselectedLabelColor: isDark ? AppColors.darkInk400 : AppColors.lightInk400,
            indicatorColor: AppColors.violet500,
            indicatorSize: TabBarIndicatorSize.label,
            labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            unselectedLabelStyle: const TextStyle(fontSize: 13),
            tabs: const [
              Tab(text: 'Dashboard'),
              Tab(text: 'Users'),
              Tab(text: 'Posts'),
              Tab(text: 'Reports'),
              Tab(text: 'Feature Flags'),
              Tab(text: 'Audit Logs'),
            ],
          ),
        ),

        // Tab Views
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              AdminDashboardTab(),
              AdminUsersTab(),
              AdminPostsTab(),
              AdminReportsTab(),
              AdminFlagsTab(),
              AdminLogsTab(),
            ],
          ),
        ),
      ],
    );
  }
}
