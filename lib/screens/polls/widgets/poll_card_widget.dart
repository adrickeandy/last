import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../core/widgets/toast_overlay.dart';
import '../../../models/poll_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/poll_service.dart';

class PollCardWidget extends StatefulWidget {
  final PollModel poll;

  const PollCardWidget({super.key, required this.poll});

  @override
  State<PollCardWidget> createState() => _PollCardWidgetState();
}

class _PollCardWidgetState extends State<PollCardWidget> {
  final _pollService = PollService();
  late PollModel _poll;
  bool _isVoting = false;

  @override
  void initState() {
    super.initState();
    _poll = widget.poll;
  }

  Future<void> _handleVote(int optionIndex) async {
    if (_poll.myVoteIndex != null || _isVoting) return;

    final auth = context.read<AuthProvider>();
    final user = auth.user;
    if (user == null) {
      ToastOverlay.show(context, 'Sign in to vote on polls', type: ToastType.info);
      return;
    }

    setState(() {
      _isVoting = true;
      final currentCounts = Map<int, int>.from(_poll.voteResults);
      currentCounts[optionIndex] = (currentCounts[optionIndex] ?? 0) + 1;
      _poll = _poll.copyWith(
        myVoteIndex: optionIndex,
        voteResults: currentCounts,
      );
    });

    try {
      await _pollService.castVote(
        pollId: _poll.id,
        userId: user.id,
        optionIndex: optionIndex,
      );
      ToastOverlay.show(context, 'Vote recorded!', type: ToastType.success);
    } catch (e) {
      print('[PollCardWidget] error: $e');
    } finally {
      if (mounted) setState(() => _isVoting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalVotes = _poll.totalVotes;
    final hasVoted = _poll.myVoteIndex != null;

    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _poll.question,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 14),

          // Options List
          Column(
            children: List.generate(_poll.options.length, (i) {
              final opt = _poll.options[i];
              final voteCount = _poll.voteResults[i] ?? 0;
              final pct = totalVotes > 0 ? (voteCount / totalVotes * 100).round() : 0;
              final isMySelection = _poll.myVoteIndex == i;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: hasVoted ? null : () => _handleVote(i),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isMySelection
                            ? AppColors.violet500
                            : (isDark ? AppColors.darkGlassBorder : AppColors.lightGlassBorder),
                        width: isMySelection ? 1.5 : 1,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Stack(
                      children: [
                        // Progress Bar Fill
                        if (hasVoted)
                          FractionallySizedBox(
                            widthFactor: pct / 100.0,
                            child: Container(
                              decoration: BoxDecoration(
                                color: isMySelection
                                    ? AppColors.violet500.withOpacity(0.35)
                                    : AppColors.violet500.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                opt,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: isMySelection ? FontWeight.bold : FontWeight.normal,
                                  color: isDark ? AppColors.darkInk100 : AppColors.lightInk100,
                                ),
                              ),
                              if (hasVoted)
                                Text(
                                  '$pct%',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.bold,
                                    color: isMySelection ? AppColors.violet400 : (isDark ? AppColors.darkInk300 : AppColors.lightInk300),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),

          const SizedBox(height: 6),
          Text(
            '$totalVotes vote${totalVotes == 1 ? '' : 's'}',
            style: TextStyle(
              fontSize: 11.5,
              color: isDark ? AppColors.darkInk500 : AppColors.lightInk500,
            ),
          ),
        ],
      ),
    );
  }
}
