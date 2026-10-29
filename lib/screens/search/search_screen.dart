import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/avatar_view.dart';
import '../../core/widgets/glass_container.dart';
import '../../core/widgets/glass_text_field.dart';
import '../../core/widgets/skeleton_loader.dart';
import '../../models/profile_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ui_provider.dart';
import '../../services/profile_service.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  final _profileService = ProfileService();
  Timer? _debounceTimer;
  List<ProfileModel> _results = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _results = [];
        _isLoading = false;
      });
      return;
    }

    // Hidden admin trigger (blueprint §24): typing this exact command opens
    // the Admin Dashboard for admins only. Non-admins fall straight through
    // to a completely normal search below — there is no branch, message, or
    // delay that would let anyone tell this string is special.
    if (query.trim().toLowerCase() == 'campusx-admin') {
      final isAdmin = context.read<AuthProvider>().isAdmin;
      if (isAdmin) {
        context.read<UIProvider>().setTab(AppTab.admin);
        return;
      }
    }

    _debounceTimer = Timer(const Duration(milliseconds: 350), () async {
      setState(() => _isLoading = true);
      final list = await _profileService.searchProfiles(query.trim());
      if (mounted) {
        setState(() {
          _results = list;
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ui = context.read<UIProvider>();
    final myId = context.watch<AuthProvider>().user?.id;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Search Input Field
            GlassTextField(
              controller: _searchController,
              hintText: 'Search people by name or username…',
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              onChanged: _onSearchChanged,
              autofocus: true,
            ),
            const SizedBox(height: 20),

            // Results List
            if (_isLoading) ...[
              const SkeletonLoader(height: 64, margin: EdgeInsets.only(bottom: 10)),
              const SkeletonLoader(height: 64, margin: EdgeInsets.only(bottom: 10)),
              const SkeletonLoader(height: 64, margin: EdgeInsets.only(bottom: 10)),
            ] else if (_searchController.text.trim().isNotEmpty && _results.isEmpty) ...[
              Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Text(
                    'No one matches "${_searchController.text}"',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? AppColors.darkInk400 : AppColors.lightInk400,
                    ),
                  ),
                ),
              ),
            ] else if (_results.isNotEmpty) ...[
              for (final p in _results)
                GlassContainer(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  onTap: () => ui.openProfile(p.username),
                  child: Row(
                    children: [
                      AvatarView(
                        url: p.avatarUrl,
                        name: p.fullName ?? p.username,
                        size: 44,
                        isVerified: p.isVerified,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.fullName ?? p.username,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '@${p.username}',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? AppColors.darkInk400 : AppColors.lightInk400,
                              ),
                            ),
                            if (p.bio != null && p.bio!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  p.bio!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? AppColors.darkInk300 : AppColors.lightInk300,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.chevron_right_rounded, size: 20, color: Colors.white38),
                    ],
                  ),
                ),
            ] else ...[
              Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Text(
                    'Find students and classmates across university faculties and clubs.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? AppColors.darkInk400 : AppColors.lightInk400,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
