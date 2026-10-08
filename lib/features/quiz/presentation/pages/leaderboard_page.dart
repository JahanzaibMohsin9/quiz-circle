import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/colors.dart';
import '../../../../shared/widgets/common/shimmer_loading.dart';
import '../../../../shared/widgets/common/error_state_widget.dart';
import '../../../../shared/widgets/common/empty_state_widget.dart';
import '../../../../shared/widgets/common/animated_counter.dart';
import '../providers/leaderboard_provider.dart';
import '../../../../features/authentication/presentation/providers/auth_provider.dart';

class LeaderboardPage extends ConsumerWidget {
  final String quizId;
  final String quizTitle;

  const LeaderboardPage({
    super.key,
    required this.quizId,
    required this.quizTitle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaderboardState = ref.watch(leaderboardProviderForQuiz(quizId));
    final topScore = ref.watch(topScoreProvider(quizId));

    return Scaffold(
      appBar: AppBar(
        title: Text('$quizTitle - Leaderboard'),

        actions: [
          IconButton(
            onPressed: () => ref
                .read(leaderboardProvider(quizId).notifier)
                .refreshLeaderboard(),
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildBody(context, ref, leaderboardState, topScore),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    LeaderboardState state,
    int? topScore,
  ) {
    if (state.isLoading) {
      return Column(
        children: [
          // Shimmer for top score card
          const Card(
            margin: EdgeInsets.all(16),
            elevation: 4,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  ShimmerLoading.circular(width: 32),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShimmerLoading.text(width: 80),
                        SizedBox(height: 8),
                        ShimmerLoading.text(width: 120),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Shimmer for leaderboard list
          for (int i = 0; i < 5; i++) const ShimmerListTile(),
        ],
      );
    }

    if (state.errorMessage != null) {
      return ErrorStateWidget(
        message: state.errorMessage!,
        errorType: ErrorType.server,
        onRetry: () =>
            ref.read(leaderboardProvider(quizId).notifier).refreshLeaderboard(),
      );
    }

    if (state.leaderboard.isEmpty) {
      return const EmptyStateWidget.leaderboard();
    }

    return Column(
      children: [
        if (topScore != null) _buildTopScoreCard(context, topScore),
        Expanded(child: _buildLeaderboardList(context, state.leaderboard)),
      ],
    );
  }

  Widget _buildTopScoreCard(BuildContext context, int topScore) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.gold.withValues(alpha: 0.1),
              Theme.of(context).colorScheme.surface,
            ],
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.emoji_events_rounded,
                color: AppColors.gold,
                size: 32,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Top Score',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  AnimatedCounter(
                    value: topScore,
                    duration: const Duration(milliseconds: 1500),
                    textStyle: Theme.of(context).textTheme.headlineMedium
                        ?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.gold,
                        ),
                    suffix: ' points',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaderboardList(
    BuildContext context,
    List<Map<String, dynamic>> leaderboard,
  ) {
    return SafeArea(
      bottom: true,
      child: ListView.builder(
        padding: const EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: 24, // Extra padding for system navigation
        ),
        itemCount: leaderboard.length,
        itemBuilder: (context, index) {
          final entry = leaderboard[index];
          final rank = index + 1;
          final name = entry['name'] as String;
          final score = entry['score'] as int;
          final percentage = entry['percentage'] as double;
          final timeTaken = entry['timeTakenSeconds'] as int;

          // Get current user ID from auth provider
          return Consumer(
            builder: (context, ref, _) {
              final authState = ref.watch(authProvider);
              final isCurrentUser = entry['userId'] == authState.userId;

              return AnimatedLeaderboardEntry(
                entry: entry,
                rank: rank,
                name: name,
                score: score,
                percentage: percentage,
                timeTaken: timeTaken,
                isCurrentUser: isCurrentUser,
                index: index,
              );
            },
          );
        },
      ),
    );
  }
}

class AnimatedLeaderboardEntry extends StatefulWidget {
  final Map<String, dynamic> entry;
  final int rank;
  final String name;
  final int score;
  final double percentage;
  final int timeTaken;
  final bool isCurrentUser;
  final int index;

  const AnimatedLeaderboardEntry({
    super.key,
    required this.entry,
    required this.rank,
    required this.name,
    required this.score,
    required this.percentage,
    required this.timeTaken,
    required this.isCurrentUser,
    required this.index,
  });

  @override
  State<AnimatedLeaderboardEntry> createState() =>
      _AnimatedLeaderboardEntryState();
}

class _AnimatedLeaderboardEntryState extends State<AnimatedLeaderboardEntry>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    // Start animation with staggered delay
    Future.delayed(Duration(milliseconds: widget.index * 100), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: widget.isCurrentUser ? 8 : 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: widget.isCurrentUser
                ? const BorderSide(color: AppColors.gold, width: 2)
                : BorderSide.none,
          ),
          color: widget.isCurrentUser
              ? AppColors.gold.withValues(alpha: 0.1)
              : null,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 8,
            ),
            leading: CircleAvatar(
              backgroundColor: _getRankColor(widget.rank),
              child: Text(
                '${widget.rank}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.name,
                    style: TextStyle(
                      fontWeight: widget.isCurrentUser
                          ? FontWeight.bold
                          : FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
                if (widget.isCurrentUser)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.gold,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'YOU',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            subtitle: Row(
              children: [
                Icon(
                  Icons.access_time_rounded,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  _formatTime(widget.timeTaken),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${widget.percentage.toStringAsFixed(1)}%',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  '(${widget.entry['correctAnswersCount'] ?? 0}/${widget.entry['totalQuestions'] ?? 0})',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                if (widget.rank <= 3) ...[
                  const SizedBox(height: 4),
                  Icon(
                    _getRankIcon(widget.rank),
                    color: AppColors.gold,
                    size: 20,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getRankColor(int rank) {
    if (rank == 1) return AppColors.gold;
    if (rank == 2) return AppColors.silver;
    if (rank == 3) return AppColors.bronze;
    if (rank <= 10) return AppColors.info;
    return AppColors.quizNeutral;
  }

  IconData _getRankIcon(int rank) {
    switch (rank) {
      case 1:
        return Icons.looks_one;
      case 2:
        return Icons.looks_two;
      case 3:
        return Icons.looks_3;
      default:
        return Icons.emoji_events;
    }
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes}m ${remainingSeconds}s';
  }
}
