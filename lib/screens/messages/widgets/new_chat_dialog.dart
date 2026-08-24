import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/avatar_view.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../core/widgets/glass_text_field.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../models/profile_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/chat_provider.dart';
import '../../../services/profile_service.dart';

class NewChatDialog extends StatefulWidget {
  const NewChatDialog({super.key});

  static Future<void> show(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (ctx) => const NewChatDialog(),
    );
  }

  @override
  State<NewChatDialog> createState() => _NewChatDialogState();
}

class _NewChatDialogState extends State<NewChatDialog> {
  final _profileService = ProfileService();
  final _searchController = TextEditingController();
  List<ProfileModel> _searchResults = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _isLoading = true);
    final results = await _profileService.searchProfiles(query);
    final myId = context.read<AuthProvider>().user?.id;

    if (mounted) {
      setState(() {
        _searchResults = results.where((p) => p.id != myId).toList();
        _isLoading = false;
      });
    }
  }

  Future<void> _startChatWith(ProfileModel other) async {
    final auth = context.read<AuthProvider>();
    final user = auth.user;
    if (user == null) return;

    final chat = context.read<ChatProvider>();
    Navigator.of(context).pop();
    await chat.startOrGetDirectChat(user.id, other.id);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440, maxHeight: 500),
        child: GlassContainer(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('New Message', style: Theme.of(context).textTheme.titleMedium),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              GlassTextField(
                controller: _searchController,
                hintText: 'Search people by username or name…',
                prefixIcon: const Icon(Icons.search_rounded, size: 18),
                onChanged: _handleSearch,
                autofocus: true,
              ),
              const SizedBox(height: 14),

              Expanded(
                child: _isLoading
                    ? ListView.separated(
                        itemCount: 4,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, __) => const SkeletonLoader(height: 48),
                      )
                    : _searchResults.isEmpty
                        ? Center(
                            child: Text(
                              _searchController.text.isEmpty
                                  ? 'Type a name or username to search'
                                  : 'No students found matching query',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? AppColors.darkInk400 : AppColors.lightInk400,
                              ),
                            ),
                          )
                        : ListView.separated(
                            itemCount: _searchResults.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 4),
                            itemBuilder: (context, i) {
                              final p = _searchResults[i];
                              return ListTile(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                hoverColor: isDark
                                    ? Colors.white.withOpacity(0.04)
                                    : Colors.black.withOpacity(0.04),
                                leading: AvatarView(
                                  url: p.avatarUrl,
                                  name: p.fullName ?? p.username,
                                  size: 34,
                                ),
                                title: Text(
                                  p.fullName ?? p.username,
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  '@${p.username}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? AppColors.darkInk400 : AppColors.lightInk400,
                                  ),
                                ),
                                onTap: () => _startChatWith(p),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
