import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/avatar_view.dart';
import '../../core/widgets/built_by_footer.dart';
import '../../core/widgets/glass_button.dart';
import '../../core/widgets/glass_container.dart';
import '../../core/widgets/skeleton_loader.dart';
import '../../core/widgets/toast_overlay.dart';
import '../../core/widgets/image_lightbox_dialog.dart';
import '../../models/post_model.dart';
import '../../models/profile_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/ui_provider.dart';
import '../../services/post_service.dart';
import '../../services/profile_media_service.dart';
import '../../services/profile_service.dart';
import '../feed/widgets/post_card.dart';

class ProfileScreen extends StatefulWidget {
  final String username;

  const ProfileScreen({
    super.key,
    required this.username,
  });

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
  bool _isUploadingCover = false;
  bool _isOpeningChat = false;

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
    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      final currentUser =
          context.read<AuthProvider>().user;

      final profile =
          await _profileService.fetchProfileByUsername(
        widget.username,
      );

      if (profile != null) {
        final posts = await _postService.fetchUserPosts(
          profile.id,
          currentUserId: currentUser?.id,
        );

        final counts =
            await _profileService.fetchFollowCounts(
          profile.id,
        );

        bool isFollow = false;

        if (currentUser != null &&
            currentUser.id != profile.id) {
          isFollow =
              await _profileService.isFollowing(
            currentUser.id,
            profile.id,
          );
        }

        if (mounted) {
          setState(() {
            _profile = profile;
            _userPosts = posts;
            _followersCount =
                counts['followers'] ?? 0;
            _followingCount =
                counts['following'] ?? 0;
            _isFollowing = isFollow;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } catch (e, st) {
      debugPrint(
        'Profile load failed: $e\n$st',
      );

      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _toggleFollow() async {
    final auth = context.read<AuthProvider>();
    final currentUser = auth.user;

    if (currentUser == null || _profile == null) {
      ToastOverlay.show(
        context,
        'Sign in to follow users',
        type: ToastType.info,
      );
      return;
    }

    final next = !_isFollowing;

    setState(() {
      _isFollowing = next;
      _followersCount += next ? 1 : -1;
    });

    try {
      if (next) {
        await _profileService.followUser(
          currentUser.id,
          _profile!.id,
        );
      } else {
        await _profileService.unfollowUser(
          currentUser.id,
          _profile!.id,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isFollowing = !next;
          _followersCount += !next ? 1 : -1;
        });
      }
    }
  }

  /// Opens (or creates) the private 1-to-1 chat with this person and jumps
  /// straight into it.
  Future<void> _handleDirectMessage() async {
    if (_isOpeningChat) return;

    final auth = context.read<AuthProvider>();
    final currentUser = auth.user;

    if (currentUser == null || _profile == null) {
      ToastOverlay.show(
        context,
        'Sign in to send messages',
        type: ToastType.info,
      );
      return;
    }

    final chat = context.read<ChatProvider>();
    final ui = context.read<UIProvider>();

    setState(() => _isOpeningChat = true);

    try {
      await chat.startOrGetDirectChat(
        currentUser.id,
        _profile!.id,
      );

      ui.setTab(AppTab.messages);
      // Phone layout shows one pane at a time: open the chat itself, not
      // just the conversation list.
      ui.setChatOpen(true);
    } catch (e) {
      debugPrint('Could not open chat: $e');
      if (mounted) {
        ToastOverlay.show(
          context,
          'Could not open the chat. Please try again.',
          type: ToastType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isOpeningChat = false);
    }
  }

  /// Lets the signed-in user pick a new cover (background) photo.
  Future<void> _changeCover() async {
    final auth = context.read<AuthProvider>();
    final user = auth.user;
    if (user == null || _isUploadingCover) return;

    setState(() => _isUploadingCover = true);

    try {
      final url = await ProfileMediaService().pickAndSaveCover(user.id);

      if (url != null) {
        await auth.refreshProfile();
        if (mounted) {
          setState(() => _profile = _profile?.copyWith(coverUrl: url));
          ToastOverlay.show(
            context,
            'Cover photo updated!',
            type: ToastType.success,
          );
        }
      }
    } on ProfileMediaException catch (e) {
      if (mounted) {
        ToastOverlay.show(context, e.message, type: ToastType.error);
      }
    } catch (e) {
      debugPrint('Cover upload failed: $e');
      if (mounted) {
        ToastOverlay.show(
          context,
          'Could not update cover photo',
          type: ToastType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingCover = false);
    }
  }

  Widget _buildBanner(bool isMe) {
    final cover = _profile!.coverUrl;
    final hasCover = cover != null && cover.trim().isNotEmpty;

    const gradientFallback = DecoratedBox(
      decoration: BoxDecoration(gradient: AppColors.bannerGradient),
    );

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(20),
        topRight: Radius.circular(20),
      ),
      child: SizedBox(
        height: 130,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (hasCover)
              GestureDetector(
                onTap: () => ImageLightboxDialog.show(context, [cover!]),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: CachedNetworkImage(
                    imageUrl: cover!,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => gradientFallback,
                    errorWidget: (_, __, ___) => gradientFallback,
                  ),
                ),
              )
            else
              gradientFallback,

            // Only on your own profile: change the cover photo.
            if (isMe)
              Positioned(
                right: 10,
                bottom: 10,
                child: Material(
                  color: Colors.black.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: _isUploadingCover ? null : _changeCover,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_isUploadingCover)
                            const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          else
                            const Icon(
                              Icons.photo_camera_outlined,
                              size: 15,
                              color: Colors.white,
                            ),
                          const SizedBox(width: 6),
                          Text(
                            hasCover ? 'Change cover' : 'Add cover',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _openProfilePicture() {
    final avatarUrl = _profile?.avatarUrl;

    if (avatarUrl == null ||
        avatarUrl.trim().isEmpty) {
      return;
    }

    ImageLightboxDialog.show(
      context,
      [avatarUrl],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    final auth =
        context.watch<AuthProvider>();

    final ui = context.read<UIProvider>();

    final isMe =
        auth.user != null &&
        _profile != null &&
        auth.user!.id == _profile!.id;

    if (_isLoading) {
      return Center(
        child: ConstrainedBox(
          constraints:
              const BoxConstraints(maxWidth: 620),
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
            const Icon(
              Icons.person_off_rounded,
              size: 48,
              color: AppColors.coral400,
            ),
            const SizedBox(height: 12),
            const Text(
              'Profile not found',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'No student exists with username @${widget.username}',
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? AppColors.darkInk400
                    : AppColors.lightInk400,
              ),
            ),
          ],
        ),
      );
    }

    final hasProfilePicture =
        _profile!.avatarUrl != null &&
        _profile!.avatarUrl!.trim().isNotEmpty;

    return Center(
      child: ConstrainedBox(
        constraints:
            const BoxConstraints(maxWidth: 620),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ============================================================
            // PROFILE CARD
            // ============================================================

            GlassContainer(
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  // ========================================================
                  // BANNER
                  // ========================================================

                  _buildBanner(isMe),

                  Padding(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        // ==================================================
                        // AVATAR + ACTION BUTTON
                        // ==================================================

                        Transform.translate(
                          offset:
                              const Offset(0, -36),
                          child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment
                                    .spaceBetween,
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .end,
                            children: [
                              Tooltip(
                                message:
                                    hasProfilePicture
                                        ? 'View profile picture'
                                        : '',
                                child: AvatarView(
                                  url: _profile!
                                      .avatarUrl,
                                  name: _profile!
                                          .fullName ??
                                      _profile!
                                          .username,
                                  size: 72,
                                  showRing: true,
                                  isVerified:
                                      _profile!
                                          .isVerified,
                                  onTap:
                                      hasProfilePicture
                                          ? _openProfilePicture
                                          : null,
                                ),
                              ),

                              if (isMe)
                                GlassButton(
                                  variant:
                                      GlassButtonVariant
                                          .secondary,
                                  text:
                                      'Edit profile',
                                  height: 38,
                                  onPressed: () =>
                                      ui.setTab(
                                    AppTab.settings,
                                  ),
                                )
                              else
                                Row(
                                  children: [
                                    GlassButton(
                                      variant: _isFollowing
                                          ? GlassButtonVariant
                                              .secondary
                                          : GlassButtonVariant
                                              .primary,
                                      text: _isFollowing
                                          ? 'Following'
                                          : 'Follow',
                                      height: 38,
                                      onPressed:
                                          _toggleFollow,
                                    ),
                                    const SizedBox(
                                        width: 8),
                                    if (MediaQuery.of(context)
                                            .size
                                            .width >=
                                        480)
                                      GlassButton(
                                        variant:
                                            GlassButtonVariant
                                                .secondary,
                                        text: 'Message',
                                        icon: Icons
                                            .chat_bubble_outline_rounded,
                                        height: 38,
                                        isLoading:
                                            _isOpeningChat,
                                        onPressed:
                                            _handleDirectMessage,
                                      )
                                    else
                                      IconButton(
                                        tooltip:
                                            'Send message',
                                        style: IconButton
                                            .styleFrom(
                                          backgroundColor: isDark
                                              ? Colors.white
                                                  .withOpacity(
                                                      0.06)
                                              : Colors.black
                                                  .withOpacity(
                                                      0.04),
                                          padding:
                                              const EdgeInsets
                                                  .all(10),
                                        ),
                                        icon: _isOpeningChat
                                            ? const SizedBox(
                                                width: 18,
                                                height: 18,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth:
                                                      2,
                                                ),
                                              )
                                            : const Icon(
                                                Icons
                                                    .chat_bubble_outline_rounded,
                                                size: 18,
                                              ),
                                        onPressed:
                                            _handleDirectMessage,
                                      ),
                                  ],
                                ),
                            ],
                          ),
                        ),

                        // ==================================================
                        // NAME / BIO
                        // ==================================================

                        Transform.translate(
                          offset:
                              const Offset(0, -20),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                            children: [
                              Text(
                                _profile!.fullName ??
                                    _profile!.username,
                                style:
                                    const TextStyle(
                                  fontSize: 18,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),

                              Text(
                                '@${_profile!.username}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark
                                      ? AppColors
                                          .darkInk400
                                      : AppColors
                                          .lightInk400,
                                ),
                              ),

                              if (_profile!.bio !=
                                      null &&
                                  _profile!.bio!
                                      .isNotEmpty) ...[
                                const SizedBox(
                                    height: 10),
                                Text(
                                  _profile!.bio!,
                                  style:
                                      TextStyle(
                                    fontSize: 13.5,
                                    height: 1.4,
                                    color: isDark
                                        ? AppColors
                                            .darkInk200
                                        : AppColors
                                            .lightInk200,
                                  ),
                                ),
                              ],

                              const SizedBox(
                                  height: 14),

                              // =================================================
                              // COURSE / CAMPUS
                              // =================================================

                              Wrap(
                                spacing: 14,
                                runSpacing: 8,
                                children: [
                                  if (_profile!
                                              .course !=
                                          null &&
                                      _profile!.course!
                                          .isNotEmpty)
                                    Row(
                                      mainAxisSize:
                                          MainAxisSize
                                              .min,
                                      children: [
                                        const Icon(
                                          Icons
                                              .school_outlined,
                                          size: 14,
                                          color:
                                              AppColors
                                                  .violet400,
                                        ),
                                        const SizedBox(
                                            width: 5),
                                        Text(
                                          _profile!
                                              .course!,
                                          style:
                                              const TextStyle(
                                            fontSize:
                                                12,
                                          ),
                                        ),
                                      ],
                                    ),

                                  if (_profile!
                                              .campus !=
                                          null &&
                                      _profile!.campus!
                                          .isNotEmpty)
                                    Row(
                                      mainAxisSize:
                                          MainAxisSize
                                              .min,
                                      children: [
                                        const Icon(
                                          Icons
                                              .location_on_outlined,
                                          size: 14,
                                          color:
                                              AppColors
                                                  .coral400,
                                        ),
                                        const SizedBox(
                                            width: 5),
                                        Text(
                                          _profile!
                                              .campus!,
                                          style:
                                              const TextStyle(
                                            fontSize:
                                                12,
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),

                              const SizedBox(
                                  height: 16),

                              // =================================================
                              // FOLLOW COUNTS
                              // =================================================

                              Row(
                                children: [
                                  RichText(
                                    text:
                                        TextSpan(
                                      style:
                                          TextStyle(
                                        fontSize:
                                            13,
                                        color: isDark
                                            ? AppColors
                                                .darkInk100
                                            : AppColors
                                                .lightInk100,
                                      ),
                                      children: [
                                        TextSpan(
                                          text:
                                              '$_followersCount ',
                                          style:
                                              const TextStyle(
                                            fontWeight:
                                                FontWeight
                                                    .bold,
                                          ),
                                        ),
                                        TextSpan(
                                          text:
                                              'Followers',
                                          style:
                                              TextStyle(
                                            color: isDark
                                                ? AppColors
                                                    .darkInk400
                                                : AppColors
                                                    .lightInk400,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(
                                      width: 16),

                                  RichText(
                                    text:
                                        TextSpan(
                                      style:
                                          TextStyle(
                                        fontSize:
                                            13,
                                        color: isDark
                                            ? AppColors
                                                .darkInk100
                                            : AppColors
                                                .lightInk100,
                                      ),
                                      children: [
                                        TextSpan(
                                          text:
                                              '$_followingCount ',
                                          style:
                                              const TextStyle(
                                            fontWeight:
                                                FontWeight
                                                    .bold,
                                          ),
                                        ),
                                        TextSpan(
                                          text:
                                              'Following',
                                          style:
                                              TextStyle(
                                            color: isDark
                                                ? AppColors
                                                    .darkInk400
                                                : AppColors
                                                    .lightInk400,
                                          ),
                                        ),
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

            // ============================================================
            // USER POSTS
            // ============================================================

            if (_userPosts.isEmpty)
              Container(
                padding:
                    const EdgeInsets.all(32),
                alignment:
                    Alignment.center,
                child: Text(
                  'No posts published yet.',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? AppColors.darkInk400
                        : AppColors.lightInk400,
                  ),
                ),
              )
            else
              for (final post in _userPosts)
                PostCard(
                  key: ValueKey(post.id),
                  post: post,
                ),

            const BuiltByFooter(),
          ],
        ),
      ),
    );
  }
}
