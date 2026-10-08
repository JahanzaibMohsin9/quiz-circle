import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/route_constants.dart';
import '../../../../app/theme/colors.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../../shared/widgets/admin/stat_card.dart';
import '../../../../shared/widgets/common/shimmer_loading.dart';
import '../../../../shared/widgets/admin/admin_navigation_drawer.dart';
import '../providers/analytics_provider.dart';
import '../providers/recent_activity_provider.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import '../../domain/entities/analytics.dart';
import '../../domain/entities/recent_activity.dart';
import '../../../notifications/presentation/providers/notification_provider.dart';

class AdminDashboardPage extends ConsumerWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch analytics state
    final analyticsState = ref.watch(analyticsProvider);
    final systemAnalytics = analyticsState.systemAnalytics;

    // Watch recent activity state
    final recentActivityState = ref.watch(recentActivityProvider);

    // Load analytics and recent activity on first build
    ref.listen(analyticsProvider, (previous, next) {});

    if (systemAnalytics == null && !analyticsState.isLoading) {
      Future.microtask(() {
        ref.read(analyticsProvider.notifier).loadSystemAnalytics();
      });
    }
    if (recentActivityState.activities.isEmpty &&
        !recentActivityState.isLoading) {
      Future.microtask(() {
        ref.read(recentActivityProvider.notifier).loadRecentActivity();
      });
    }

    return Scaffold(
      drawer: const AdminNavigationDrawer(),
      body: RefreshIndicator(
        displacement: 100,
        color: AppColors.primary,
        onRefresh: () async {
          await Future.wait([
            ref.read(analyticsProvider.notifier).refreshAllAnalytics(),
            ref.read(recentActivityProvider.notifier).loadRecentActivity(),
          ]);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            _buildAppBar(context, ref),
            if (analyticsState.isFromCache || recentActivityState.isFromCache)
              SliverToBoxAdapter(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 16,
                  ),
                  color: AppColors.warning.withValues(alpha: 0.1),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.offline_pin_rounded,
                        size: 16,
                        color: AppColors.warning,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        analyticsState.lastSyncTime != null
                            ? 'Offline - Last synced ${_getTimeAgo(analyticsState.lastSyncTime!)}'
                            : 'Viewing offline data',
                        style: const TextStyle(
                          color: AppColors.warning,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  if (analyticsState.isLoading && systemAnalytics == null)
                    _buildLoadingState(context)
                  else if (analyticsState.error != null &&
                      systemAnalytics == null)
                    _buildErrorState(context, ref, analyticsState.error!),
                ]),
              ),
            ),
            if (!analyticsState.isLoading || systemAnalytics != null)
              if (analyticsState.error == null || systemAnalytics != null)
                _buildStatsGridSliver(context, systemAnalytics),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 12),
                  _buildQuickActions(context),
                  const SizedBox(height: 20),
                  _buildRecentActivity(context, ref, recentActivityState),
                  // Extra padding for system navigation
                  const SizedBox(height: 24),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final userName = userAsync.when(
      data: (user) => user?.name ?? 'Admin',
      loading: () => '...',
      error: (error, stack) => 'Admin',
    );

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SliverAppBar(
      expandedHeight: 180, // Increased for premium header
      pinned: true,
      elevation: 0,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      leading: Builder(
        builder: (context) => IconButton(
          icon: Icon(
            Icons.menu_rounded,
            color: isDark
                ? AppColors.primary
                : Theme.of(context).colorScheme.onSurface,
            size: 28,
          ),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      actions: [
        Consumer(
          builder: (context, ref, child) {
            final unreadCount = ref.watch(unreadCountProvider);
            return Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.notifications_none_rounded,
                    color: isDark
                        ? AppColors.primary
                        : Theme.of(context).colorScheme.onSurface,
                    size: 26,
                  ),
                  onPressed: () {
                    context.push(RouteConstants.notifications);
                  },
                ),
                if (unreadCount > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Theme.of(context).cardColor,
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        unreadCount > 99 ? '99+' : unreadCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          height: 1.0,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(width: 8),
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: InkWell(
            onTap: () => context.push(RouteConstants.adminProfile),
            borderRadius: BorderRadius.circular(20),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primary.withValues(alpha: 0.2),
              child: Text(
                userName.isNotEmpty ? userName[0].toUpperCase() : 'A',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.surface,
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 20,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isDark
                            ? [
                                AppColors.darkSurfaceVariant,
                                AppColors.darkSurface,
                              ]
                            : [AppColors.surfaceVariant, AppColors.surface],
                      ),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(24),
                        bottomRight: Radius.circular(24),
                      ),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.dashboard_customize_rounded,
                            color: AppColors.primary,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Admin Dashboard',
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                      letterSpacing: 0.5,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Manage your platform',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w500,
                                    ),
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
          ),
        ),
      ),
    );
  }

  Widget _buildStatsGridSliver(
    BuildContext context,
    SystemAnalytics? systemAnalytics,
  ) {
    final gridColumns = ResponsiveHelper.getGridColumns(
      context,
      mobile: 2,
      tablet: 4,
      desktop: 4,
    );

    final totalQuizzes = systemAnalytics?.totalQuizzes ?? 0;
    final totalUsers = systemAnalytics?.totalUsers ?? 0;
    final totalSubmissions = systemAnalytics?.totalSubmissions ?? 0;
    final activeQuizzes = systemAnalytics?.topPerformingQuizzes.length ?? 0;

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 12),
            child: Text(
              'Overview',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),

          GridView.count(
            crossAxisCount: gridColumns,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.4,
            children: [
              StatCard(
                title: 'Total Quizzes',
                value: totalQuizzes,
                icon: Icons.quiz_rounded,
                onTap: () => context.push(RouteConstants.manageQuizzes),
              ),
              StatCard(
                title: 'Total Users',
                value: totalUsers,
                icon: Icons.people_rounded,
                color: AppColors.secondaryLight,
                onTap: () => context.push(RouteConstants.manageUsers),
                index: 1,
              ),
              StatCard(
                title: 'Submissions',
                value: totalSubmissions,
                icon: Icons.assignment_turned_in_rounded,
                color: AppColors.success,
                onTap: () => context.push(RouteConstants.viewSubmissions),
                index: 2,
              ),
              StatCard(
                title: 'Active',
                value: activeQuizzes,
                icon: Icons.play_circle_outline_rounded,
                color: AppColors.info,
                index: 3,
              ),
            ],
          ),
        ]),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 12),
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
              child: DashboardActionItem(
                title: 'Create Quiz',
                icon: Icons.add_circle_rounded,
                color: AppColors.primary,
                onTap: () => context.push(RouteConstants.createQuiz),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DashboardActionItem(
                title: 'Analytics',
                icon: Icons.analytics_rounded,
                color: AppColors.info,
                onTap: () => context.push(RouteConstants.analytics),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DashboardActionItem(
                title: 'Users',
                icon: Icons.manage_accounts_rounded,
                color: AppColors.accent, // Gold
                onTap: () => context.push(RouteConstants.manageUsers),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentActivity(
    BuildContext context,
    WidgetRef ref,
    RecentActivityState state,
  ) {
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
              IconButton(
                onPressed: () =>
                    ref.read(recentActivityProvider.notifier).refresh(),
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh',
              ),
            ],
          ),
        ),
        if (state.isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: CircularProgressIndicator(),
            ),
          )
        else if (state.errorMessage != null)
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: AppColors.error,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    state.errorMessage!,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () =>
                        ref.read(recentActivityProvider.notifier).refresh(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          )
        else if (state.activities.isEmpty)
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Center(
                child: Column(
                  children: [
                    const Icon(
                      Icons.inbox_outlined,
                      size: 64,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No recent activity',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
              ),
            ),
            elevation: 0,
            color: Theme.of(context).cardColor,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  for (int i = 0; i < state.activities.length; i++) ...[
                    _buildActivityItem(context, activity: state.activities[i]),
                    if (i < state.activities.length - 1)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Divider(
                          color: Theme.of(
                            context,
                          ).dividerColor.withValues(alpha: 0.1),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildActivityItem(
    BuildContext context, {
    required RecentActivity activity,
  }) {
    IconData icon;
    Color color;

    switch (activity.type) {
      case ActivityType.quizCreated:
        icon = Icons.quiz_rounded;
        color = AppColors.primary;
        break;
      case ActivityType.userRegistered:
        icon = Icons.person_add_rounded;
        color = AppColors.success;
        break;
      case ActivityType.quizSubmission:
        icon = Icons.assignment_turned_in_rounded;
        color = AppColors.info;
        break;
    }
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
                  activity.title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  activity.subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Text(
            activity.getRelativeTime(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    final gridColumns = ResponsiveHelper.getGridColumns(
      context,
      mobile: 2,
      tablet: 4,
      desktop: 4,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(
            'Overview',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: gridColumns,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.2,
          ),
          itemCount: 4,
          itemBuilder: (context, index) {
            return Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: Theme.of(
                    context,
                  ).colorScheme.outline.withValues(alpha: 0.1),
                ),
              ),
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ShimmerLoading.circular(width: 40),
                      SizedBox(height: 16),
                      ShimmerLoading.text(width: 80),
                      SizedBox(height: 8),
                      ShimmerLoading.text(width: 60),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref, String error) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 16),
          child: Text(
            'Overview',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: AppColors.error.withValues(alpha: 0.3)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 64,
                  color: AppColors.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Failed to load analytics',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  error,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    ref.read(analyticsProvider.notifier).loadSystemAnalytics();
                  },
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
