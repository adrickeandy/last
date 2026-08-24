import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/avatar_view.dart';
import '../../core/widgets/glass_button.dart';
import '../../core/widgets/glass_container.dart';
import '../../core/widgets/skeleton_loader.dart';
import '../../core/widgets/toast_overlay.dart';
import '../../models/post_model.dart';
import '../../models/profile_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/ui_provider.dart';
import '../../services/post_service.dart';
import '../../services/profile_service.dart';
import '../feed/widgets/post_card.dart';

class ProfileScreen extends StatefulWidget {
  final String username;

  const ProfileScreen({super.key, required this.username});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _profileService = ProfileService();
  final _postService = PostService();

  ProfileModel? _profile;
  List<PostModel> _userPosts = [];
  bool _isLoading = true;
  bool _isFollowing = false;
  int _followersCount = 0;
  int _followingCount = 0;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  @override
  void didUpdateWidget(covariant ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.username != widget.username) {
      _loadProfileData();
    }
  }

  Future<void> _loadProfileData() async {
    setState(() => _isLoading = true);

    final currentUser = context.read<AuthProvider>().user;
    final profile = await _profileService.fetchProfileByUsername(widget.username);

    if (profile != null) {
      final posts = await _postService.fetchUserPosts(profile.id, currentUserId: currentUser?.id);
      final counts = await _profileService.fetchFollowCounts(profile.id);

      bool isFollow = false;
      if (currentUser != null && currentUser.id != profile.id) {
        isFollow = await _profileService.isFollowing(currentUser.id, profile.id);
      }

      if (mounted) {
        setState(() {
          _profile = profile;
          _userPosts = posts;
          _followersCount = counts['followers'] ?? 0;
          _followingCount = counts['following'] ?? 0;
          _isFollowing = isFollow;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleFollow() async {
    final auth = context.read<AuthProvider>();
    final currentUser = auth.user;
    if (currentUser == null || _profile == null) {
      ToastOverlay.show(context, 'Sign in to follow users', type: ToastType.info);
      return;
    }

    final next = !_isFollowing;
    setState(() {
      _isFollowing = next;
      _followersCount += (next ? 1 : -1);
    });

    try {
      if (next) {
        await _profileService.followUser(currentUser.id, _profile!.id);
      } else {
        await _profileService.unfollowUser(currentUser.id, _profile!.id);
      }
    } catch (e) {
      setState(() {
        _isFollowing = !next;
        _followersCount += (!next ? 1 : -1);
      });
    }
  }

  Future<void> _handleDirectMessage() async {
    final auth = context.read<AuthProvider>();
    final currentUser = auth.user;
    if (currentUser == null || _profile == null) {
      ToastOverlay.show(context, 'Sign in to send messages', type: ToastType.info);
      return;
    }

    final chat = context.read<ChatProvider>();
    final ui = context.read<UIProvider>();

    await chat.startOrGetDirectChat(currentUser.id, _profile!.id);
    ui.setTab(AppTab.messages);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = context.watch<AuthProvider>();
    final ui = context.read<UIProvider>();
    final isMe = auth.user != null && _profile != null && auth.user!.id == _profile!.id;

    if (_isLoading) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: const Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                SkeletonLoader(height: 200),
                SizedBox(height: 16),
                SkeletonLoader(height: 120),
              ],
            ),
          ),
        ),
      );
    }

    if (_profile == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.person_off_rounded, size: 48, color: AppColors.coral400),
            const SizedBox(height: 12),
            const Text('Profile not found', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 6),
            Text(
              'No student exists with username @${widget.username}',
              style: TextStyle(fontSize: 13, color: isDark ? AppColors.darkInk400 : AppColors.lightInk400),
            ),
          ],
        ),
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Profile Card Header
            GlassContainer(
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Banner Header
                  Container(
                    height: 100,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      gradient: AppColors.bannerGradient,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Avatar + Action button
                        Transform.translate(
                          offset: const Offset(0, -36),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              AvatarView(
                                url: _profile!.avatarUrl,
                                name: _profile!.fullName ?? _profile!.username,
                                size: 72,
                                showRing: true,
                                isVerified: _profile!.isVerified,
                              ),
                              if (isMe)
                                GlassButton(
                                  variant: GlassButtonVariant.secondary,
                                  text: 'Edit profile',
                                  height: 38,
                                  onPressed: () => ui.setTab(AppTab.settings),
                                )
                              else
                                Row(
                                  children: [
                                    GlassButton(
                                      variant: _isFollowing ? GlassButtonVariant.secondary : GlassButtonVariant.primary,
                                      text: _isFollowing ? 'Following' : 'Follow',
                                      height: 38,
                                      onPressed: _toggleFollow,
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      style: IconButton.styleFrom(
                                        backgroundColor: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04),
                                        padding: const EdgeInsets.all(10),
                                      ),
                                      icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                                      onPressed: _handleDirectMessage,
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),

                        // Names & Bio
                        Transform.translate(
                          offset: const Offset(0, -20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _profile!.fullName ?? _profile!.username,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '@${_profile!.username}',
                                style: TextStyle(fontSize: 13, color: isDark ? AppColors.darkInk400 : AppColors.lightInk400),
                              ),
                              if (_profile!.bio != null && _profile!.bio!.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Text(
                                  _profile!.bio!,
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    height: 1.4,
                                    color: isDark ? AppColors.darkInk200 : AppColors.lightInk200,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 14),

                              // Course & Campus info
                              Wrap(
                                spacing: 14,
                                runSpacing: 8,
                                children: [
                                  if (_profile!.course != null && _profile!.course!.isNotEmpty)
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.school_outlined, size: 14, color: AppColors.violet400),
                                        const SizedBox(width: 5),
                                        Text(_profile!.course!, style: const TextStyle(fontSize: 12)),
                                      ],
                                    ),
                                  if (_profile!.campus != null && _profile!.campus!.isNotEmpty)
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.location_on_outlined, size: 14, color: AppColors.coral400),
                                        const SizedBox(width: 5),
                                        Text(_profile!.campus!, style: const TextStyle(fontSize: 12)),
                                      ],
                                    ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Follower & Following stats
                              Row(
                                children: [
                                  RichText(
                                    text: TextSpan(
                                      style: TextStyle(fontSize: 13, color: isDark ? AppColors.darkInk100 : AppColors.lightInk100),
                                      children: [
                                        TextSpan(text: '$_followersCount ', style: const TextStyle(fontWeight: FontWeight.bold)),
                                        TextSpan(text: 'Followers', style: TextStyle(color: isDark ? AppColors.darkInk400 : AppColors.lightInk400)),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  RichText(
                                    text: TextSpan(
                                      style: TextStyle(fontSize: 13, color: isDark ? AppColors.darkInk100 : AppColors.lightInk100),
                                      children: [
                                        TextSpan(text: '$_followingCount ', style: const TextStyle(fontWeight: FontWeight.bold)),
                                        TextSpan(text: 'Following', style: TextStyle(color: isDark ? AppColors.darkInk400 : AppColors.lightInk400)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // User Posts Feed
            if (_userPosts.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                alignment: Alignment.center,
                child: Text(
                  'No posts published yet.',
                  style: TextStyle(fontSize: 13, color: isDark ? AppColors.darkInk400 : AppColors.lightInk400),
                ),
              )
            else
              for (final post in _userPosts) PostCard(key: ValueKey(post.id), post: post),
          ],
        ),
      ),
    );
  }
}
