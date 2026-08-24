import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_button.dart';
import '../../core/widgets/glass_container.dart';
import '../../core/widgets/skeleton_loader.dart';
import '../../core/widgets/toast_overlay.dart';
import '../../models/club_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/club_service.dart';
import 'widgets/create_club_dialog.dart';

class ClubsScreen extends StatefulWidget {
  const ClubsScreen({super.key});

  @override
  State<ClubsScreen> createState() => _ClubsScreenState();
}

class _ClubsScreenState extends State<ClubsScreen> {
  final _clubService = ClubService();
  List<ClubModel> _clubs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadClubs();
  }

  Future<void> _loadClubs() async {
    final user = context.read<AuthProvider>().user;
    final list = await _clubService.fetchClubs(currentUserId: user?.id);
    if (mounted) {
      setState(() {
        _clubs = list;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleJoin(ClubModel club) async {
    final auth = context.read<AuthProvider>();
    final user = auth.user;
    if (user == null) {
      ToastOverlay.show(context, 'Sign in to join clubs', type: ToastType.info);
      return;
    }

    final isJoined = club.isMember;
    final nextJoined = !isJoined;
    final nextCount = club.memberCount + (nextJoined ? 1 : -1);

    setState(() {
      final index = _clubs.indexWhere((c) => c.id == club.id);
      if (index != -1) {
        _clubs[index] = club.copyWith(
          isMember: nextJoined,
          memberCount: nextCount < 0 ? 0 : nextCount,
        );
      }
    });

    try {
      if (isJoined) {
        await _clubService.leaveClub(club.id, user.id);
        ToastOverlay.show(context, 'Left ${club.name}', type: ToastType.info);
      } else {
        await _clubService.joinClub(club.id, user.id);
        ToastOverlay.show(context, 'Joined ${club.name}!', type: ToastType.success);
      }
    } catch (e) {
      // Revert on error
      setState(() {
        final index = _clubs.indexWhere((c) => c.id == club.id);
        if (index != -1) _clubs[index] = club;
      });
      ToastOverlay.show(context, 'Could not update membership', type: ToastType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = context.watch<AuthProvider>();

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820),
        child: RefreshIndicator(
          onRefresh: _loadClubs,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Clubs & Societies', style: Theme.of(context).textTheme.titleLarge),
                      Text(
                        'Find your people — coding, debate, sports, and creative arts.',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: isDark ? AppColors.darkInk400 : AppColors.lightInk400,
                        ),
                      ),
                    ],
                  ),
                  GlassButton(
                    variant: GlassButtonVariant.primary,
                    text: 'New club',
                    icon: Icons.add_rounded,
                    height: 38,
                    onPressed: () {
                      if (auth.user == null) {
                        ToastOverlay.show(context, 'Sign in to start a club', type: ToastType.info);
                        return;
                      }
                      CreateClubDialog.show(
                        context,
                        onCreated: (newClub) {
                          setState(() => _clubs.insert(0, newClub));
                        },
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Clubs Grid
              if (_isLoading)
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.5,
                  ),
                  itemCount: 4,
                  itemBuilder: (_, __) => const SkeletonLoader(height: 140),
                )
              else if (_clubs.isEmpty)
                Container(
                  padding: const EdgeInsets.all(40),
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      const Icon(Icons.groups_rounded, size: 48, color: AppColors.violet400),
                      const SizedBox(height: 12),
                      const Text('No clubs created yet', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(
                        'Start the first campus club by clicking "New club".',
                        style: TextStyle(fontSize: 12.5, color: isDark ? AppColors.darkInk400 : AppColors.lightInk400),
                      ),
                    ],
                  ),
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.45,
                  ),
                  itemCount: _clubs.length,
                  itemBuilder: (context, i) {
                    final club = _clubs[i];
                    return GlassContainer(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: AppColors.violet500.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.groups_rounded, color: AppColors.violet400, size: 22),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      club.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      '${club.memberCount} members',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        color: isDark ? AppColors.darkInk400 : AppColors.lightInk400,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Expanded(
                            child: Text(
                              club.description ?? 'No description provided.',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12.5,
                                color: isDark ? AppColors.darkInk300 : AppColors.lightInk300,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          GlassButton(
                            width: double.infinity,
                            height: 36,
                            variant: club.isMember ? GlassButtonVariant.secondary : GlassButtonVariant.primary,
                            text: club.isMember ? 'Joined' : 'Join Club',
                            onPressed: () => _toggleJoin(club),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
