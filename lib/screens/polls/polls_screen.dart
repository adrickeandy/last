import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_button.dart';
import '../../core/widgets/skeleton_loader.dart';
import '../../core/widgets/toast_overlay.dart';
import '../../models/poll_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/poll_service.dart';
import 'widgets/create_poll_dialog.dart';
import 'widgets/poll_card_widget.dart';

class PollsScreen extends StatefulWidget {
  const PollsScreen({super.key});

  @override
  State<PollsScreen> createState() => _PollsScreenState();
}

class _PollsScreenState extends State<PollsScreen> {
  final _pollService = PollService();
  List<PollModel> _polls = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPolls();
  }

  Future<void> _loadPolls() async {
    final user = context.read<AuthProvider>().user;
    final list = await _pollService.fetchPolls(currentUserId: user?.id);
    if (mounted) {
      setState(() {
        _polls = list;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = context.watch<AuthProvider>();

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: RefreshIndicator(
          onRefresh: _loadPolls,
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
                      Text('Campus Polls', style: Theme.of(context).textTheme.titleLarge),
                      Text(
                        'Vote on campus debates, decisions, and trending topics.',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: isDark ? AppColors.darkInk400 : AppColors.lightInk400,
                        ),
                      ),
                    ],
                  ),
                  GlassButton(
                    variant: GlassButtonVariant.primary,
                    text: 'Create poll',
                    icon: Icons.add_rounded,
                    height: 38,
                    onPressed: () {
                      if (auth.user == null) {
                        ToastOverlay.show(context, 'Sign in to create a poll', type: ToastType.info);
                        return;
                      }
                      CreatePollDialog.show(
                        context,
                        onCreated: (newPoll) {
                          setState(() => _polls.insert(0, newPoll));
                        },
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Polls list
              if (_isLoading) ...[
                const SkeletonLoader(height: 140, margin: EdgeInsets.only(bottom: 14)),
                const SkeletonLoader(height: 140, margin: EdgeInsets.only(bottom: 14)),
              ] else if (_polls.isEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(40),
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      const Icon(Icons.bar_chart_rounded, size: 48, color: AppColors.violet400),
                      const SizedBox(height: 12),
                      const Text('No active polls right now', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(
                        'Create a poll to hear what other students think.',
                        style: TextStyle(fontSize: 12.5, color: isDark ? AppColors.darkInk400 : AppColors.lightInk400),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                for (final poll in _polls) PollCardWidget(key: ValueKey(poll.id), poll: poll),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
