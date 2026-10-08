import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/route_constants.dart';
import '../../../../app/theme/colors.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../../shared/widgets/admin/stat_card.dart';
import '../../../../shared/providers/theme_provider.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import '../../../quiz/presentation/providers/quiz_history_provider.dart';
import '../../../quiz/domain/entities/submission.dart';
import '../../../notifications/presentation/providers/notification_provider.dart';

class StudentDashboardPage extends ConsumerWidget {
  const StudentDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get real stats from quiz history provider
    final historyState = ref.watch(quizHistoryProvider);
    final submissions = historyState.submissions;

    // Calculate real statistics
    final quizzesTaken = submissions.length;
    final avgScore = submissions.isEmpty
        ? 0
        : (submissions.map((s) => s.score).reduce((a, b) => a + b) /
                  submissions.length)
              .round();
    final bestScore = submissions.isEmpty
        ? 0
        : submissions.map((s) => s.score).reduce((a, b) => a > b ? a : b);

    // Get recent quizzes (last 7 days)
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final recentQuizzes = submissions
        .where((s) => s.submittedAt.isAfter(weekAgo))
        .length;

    final stats = {
      'quizzesTaken': quizzesTaken,
      'avgScore': avgScore,
      'bestScore': bestScore,
      'recentQuizzes': recentQuizzes,
    };

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context, ref),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildStatsGrid(context, stats),
                const SizedBox(height: 20),
                _buildQuickActions(context),
                const SizedBox(height: 20),
                _buildRecentActivity(context, submissions),
                // Extra padding for system navigation
                const SizedBox(height: 24),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SliverAppBar(
      expandedHeight: 160, // Increased to prevent overlap with buttons
      pinned: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      elevation: 0,
      automaticallyImplyLeading: false,
      actions: [
        // Notification Bell Icon with Badge
        Consumer(
          builder: (context, ref, child) {
            final notificationState = ref.watch(notificationProvider);
            final unreadCount = notificationState.unreadCount;

            return Stack(
              children: [
                IconButton(
                  icon: Icon(
                    unreadCount > 0
                        ? Icons.notifications_active_rounded
                        : Icons.notifications_outlined,
                    color: isDark
                        ? AppColors.primaryLight
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                  onPressed: () => context.push(RouteConstants.notifications),
                  tooltip: 'Notifications',
                ),
                if (unreadCount > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          width: 1.5,
                        ),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Text(
                        unreadCount > 99 ? '99+' : unreadCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        IconButton(
          icon: Icon(
            isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            color: isDark
                ? AppColors.primaryLight
                : Theme.of(context).colorScheme.onSurface,
          ),
          onPressed: () => ref.read(themeProvider.notifier).toggleTheme(),
        ),
        IconButton(
          icon: Icon(
            Icons.logout_rounded,
            color: Theme.of(context).colorScheme.error,
          ),
          onPressed: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Confirm Logout'),
                content: const Text('Are you sure you want to logout?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.error,
                    ),
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Logout'),
                  ),
                ],
              ),
            );

            if (confirmed == true) {
              ref.read(authProvider.notifier).signOut();
            }
          },
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [AppColors.darkSurfaceVariant, AppColors.darkSurface]
                  : [AppColors.surfaceVariant, AppColors.surface],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Consumer(
                builder: (context, ref, child) {
                  final userAsync = ref.watch(currentUserProvider);
                  final userName = userAsync.when(
                    data: (user) => user?.name ?? 'Student',
                    loading: () => '...',
                    error: (error, stack) => 'Student',
                  );
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkSurface.withValues(alpha: 0.8)
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.2),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).shadowColor.withValues(
                                alpha: isDark ? 0.3 : 0.08,
                              ),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () => context.push(RouteConstants.profile),
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.primary,
                                      AppColors.primaryLight,
                                    ],
                                  ),
                                ),
                                child: CircleAvatar(
                                  radius: 28,
                                  backgroundColor: isDark
                                      ? AppColors.darkSurface
                                      : AppColors.surface,
                                  child: Text(
                                    userName.isNotEmpty
                                        ? userName[0].toUpperCase()
                                        : 'S',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Welcome back,',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                          fontWeight: FontWeight.w500,
                                        ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    userName,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.3,
                                        ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context, Map<String, int> stats) {
    if (stats['quizzesTaken'] == 0) {
      return _buildEmptyProgressSection(context);
    }

    final gridColumns = ResponsiveHelper.getGridColumns(
      context,
      mobile: 2,
      tablet: 4,
      desktop: 4,
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.bar_chart_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Your Progress',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          GridView.count(
            crossAxisCount: gridColumns,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.6,
            children: [
              StatCard(
                title: 'Quizzes Taken',
                value: stats['quizzesTaken']!,
                icon: Icons.quiz_rounded,
                subtitle: 'Total attempts',
                onTap: () => context.push(RouteConstants.quizHistory),
              ),
              StatCard(
                index: 1,
                title: 'Average Score',
                value: stats['avgScore']!,
                icon: Icons.donut_large_rounded,
                color: AppColors.info,
                subtitle: 'Overall performance',
              ),
              StatCard(
                index: 2,
                title: 'Best Score',
                value: stats['bestScore']!,
                icon: Icons.emoji_events_rounded,
                color: AppColors.warning,
                subtitle: 'Personal best',
              ),
              StatCard(
                index: 3,
                title: 'Recent Quizzes',
                value: stats['recentQuizzes']!,
                icon: Icons.history_rounded,
                color: AppColors.success,
                subtitle: 'Last 7 days',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyProgressSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // 2) Top Illustration Area
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 200),
            child: Image.asset(
              'assets/images/stat_card_ill.png',
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 24),

          // 3) Primary Empty-State Message
          Text(
            'You haven’t taken any quizzes yet',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),

          // 4) Secondary Description Text
          Text(
            'Start your first quiz to see progress here.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),

          // 5) Stats Section (Bottom)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
              ),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Responsive layout logic
                final isWide = constraints.maxWidth >= 600;
                final crossAxisCount = isWide ? 4 : 2;
                final childAspectRatio = isWide ? 1.5 : 1.2;

                return GridView.count(
                  crossAxisCount: crossAxisCount,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: childAspectRatio,
                  children: [
                    _buildEmptyStatItem(context, 'Quizzes Taken', '0'),
                    _buildEmptyStatItem(context, 'Best Score', 'N/A'),
                    _buildEmptyStatItem(context, 'Avg Score', 'N/A'),
                    _buildEmptyStatItem(context, 'Streak', '0 days'),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyStatItem(BuildContext context, String label, String value) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            'Quick Actions',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionItem(
                context,
                title: 'Take Quiz',
                icon: Icons.play_arrow_rounded,
                color: AppColors.primary,
                onTap: () => context.push(RouteConstants.quizList),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildQuickActionItem(
                context,
                title: 'History',
                icon: Icons.history_rounded,
                color: AppColors.secondaryLight, // Neutral/Grey for history
                onTap: () => context.push(RouteConstants.quizHistory),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildQuickActionItem(
                context,
                title: 'Leaderboard',
                icon: Icons.leaderboard_rounded,
                color: AppColors.warning,
                onTap: () => context.push(RouteConstants.myLeaderboards),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionItem(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
            ),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).shadowColor.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivity(
    BuildContext context,
    List<Submission> submissions,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Activity',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              TextButton(
                onPressed: () => context.push(RouteConstants.quizHistory),
                child: const Text('View All'),
              ),
            ],
          ),
        ),
        if (submissions.isEmpty)
          Card(
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.history_rounded,
                      size: 48,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No recent activity yet',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => context.push(RouteConstants.quizList),
                      child: const Text('Take your first quiz'),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              // Add subtle glow in dark mode for visibility
              boxShadow: isDark
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: Card(
              margin: EdgeInsets.zero,
              elevation: 0,
              color: Theme.of(context).cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: isDark
                      ? AppColors.primary.withValues(alpha: 0.3)
                      : Theme.of(context).dividerColor.withValues(alpha: 0.1),
                  width: isDark ? 1.5 : 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    ...submissions.take(5).toList().asMap().entries.map((
                      entry,
                    ) {
                      final index = entry.key;
                      final submission = entry.value;
                      final isLast =
                          index ==
                          (submissions.length < 5 ? submissions.length - 1 : 4);

                      return Column(
                        children: [
                          _buildActivityItem(
                            context,
                            icon: Icons.quiz_rounded,
                            title: 'Quiz completed',
                            subtitle:
                                'Score: ${submission.percentage.round()}%',
                            time: _formatDateTime(submission.submittedAt),
                            color: submission.percentage >= 80
                                ? AppColors.success
                                : (submission.percentage >= 60
                                      ? AppColors.warning
                                      : AppColors.error),
                          ),
                          if (!isLast)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Divider(
                                height: 1,
                                color: Theme.of(
                                  context,
                                ).dividerColor.withValues(alpha: 0.1),
                              ),
                            ),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}';
    }
  }

  Widget _buildActivityItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String time,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
