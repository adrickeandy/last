import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/avatar_view.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../models/club_model.dart';
import '../../../models/profile_model.dart';
import '../../../services/club_service.dart';

/// Shows a club's member roster. Tapping a member closes the dialog and
/// returns that member's profile - same contract as NewChatDialog
/// (referenced in messages_screen.dart): the dialog only picks, the caller
/// (ClubsScreen) does the actual "start chat" network call so it can show
/// its own error toast if that fails.
class ClubMembersDialog extends StatefulWidget {
  final ClubModel club;
  final String? currentUserId;

  const ClubMembersDialog({
    super.key,
    required this.club,
    this.currentUserId,
  });

  static Future<ProfileModel?> show(BuildContext context, ClubModel club, {String? currentUserId}) {
    return showDialog<ProfileModel>(
      context: context,
      builder: (_) => ClubMembersDialog(club: club, currentUserId: currentUserId),
    );
  }

  @override
  State<ClubMembersDialog> createState() => _ClubMembersDialogState();
}

class _ClubMembersDialogState extends State<ClubMembersDialog> {
  final _clubService = ClubService();
  List<ProfileModel> _members = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final members = await _clubService.fetchClubMembers(widget.club.id);
      if (mounted) {
        setState(() {
          _members = members;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Could not load members';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: isDark ? AppColors.darkBg900 : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 520),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '${widget.club.name} · Members',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Tap anyone to start a direct message.',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.darkInk400 : AppColors.lightInk400,
                ),
              ),
              const SizedBox(height: 14),
              Flexible(
                child: _isLoading
                    ? Column(
                        children: List.generate(
                          4,
                          (i) => const Padding(
                            padding: EdgeInsets.symmetric(vertical: 6),
                            child: SkeletonLoader(height: 48),
                          ),
                        ),
                      )
                    : _error != null
                        ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: Center(
                              child: Text(
                                _error!,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? AppColors.darkInk400 : AppColors.lightInk400,
                                ),
                              ),
                            ),
                          )
                        : _members.isEmpty
                            ? Padding(
                                padding: const EdgeInsets.symmetric(vertical: 20),
                                child: Center(
                                  child: Text(
                                    'No members yet.',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isDark ? AppColors.darkInk400 : AppColors.lightInk400,
                                    ),
                                  ),
                                ),
                              )
                            : ListView.separated(
                                shrinkWrap: true,
                                itemCount: _members.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 2),
                                itemBuilder: (context, i) {
                                  final member = _members[i];
                                  final isMe = member.id == widget.currentUserId;
                                  return ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                                    leading: AvatarView(
                                      url: member.avatarUrl,
                                      name: member.fullName ?? member.username,
                                      size: 38,
                                    ),
                                    title: Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            member.fullName ?? member.username,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                        if (member.isVerified) ...[
                                          const SizedBox(width: 4),
                                          const Icon(Icons.check_circle_rounded, size: 13, color: AppColors.violet400),
                                        ],
                                      ],
                                    ),
                                    subtitle: Text(
                                      '@${member.username}',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        color: isDark ? AppColors.darkInk400 : AppColors.lightInk400,
                                      ),
                                    ),
                                    trailing: isMe
                                        ? Text(
                                            'You',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: isDark ? AppColors.darkInk500 : AppColors.lightInk500,
                                            ),
                                          )
                                        : const Icon(Icons.chat_bubble_outline_rounded, size: 16, color: AppColors.violet400),
                                    onTap: isMe ? null : () => Navigator.of(context).pop(member),
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
