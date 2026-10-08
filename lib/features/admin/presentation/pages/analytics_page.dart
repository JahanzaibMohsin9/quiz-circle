import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/analytics_provider.dart';
import '../widgets/analytics_card.dart';
import '../widgets/analytics_chart.dart';
import '../../domain/entities/analytics.dart';

class AnalyticsPage extends ConsumerStatefulWidget {
  const AnalyticsPage({super.key});

  @override
  ConsumerState<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends ConsumerState<AnalyticsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateRange _selectedDateRange = DateRange.month;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(analyticsProvider.notifier)
          .refreshAllAnalytics(dateRange: _selectedDateRange);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final analyticsState = ref.watch(analyticsProvider);
    final systemAnalytics = analyticsState.systemAnalytics;
    final topUsers = analyticsState.topUsers;
    final topQuizzes = analyticsState.topQuizzes;
    final isLoading = analyticsState.isLoading;
    final error = analyticsState.error;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Performance'),
            Tab(text: 'Users'),
          ],
        ),
        actions: [
          PopupMenuButton<DateRange>(
            icon: const Icon(Icons.date_range),
            onSelected: (DateRange range) {
              setState(() {
                _selectedDateRange = range;
              });
              ref
                  .read(analyticsProvider.notifier)
                  .refreshAllAnalytics(dateRange: range);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: DateRange.today, child: Text('Today')),
              const PopupMenuItem(
                value: DateRange.week,
                child: Text('This Week'),
              ),
              const PopupMenuItem(
                value: DateRange.month,
                child: Text('This Month'),
              ),
              const PopupMenuItem(
                value: DateRange.quarter,
                child: Text('This Quarter'),
              ),
              const PopupMenuItem(
                value: DateRange.year,
                child: Text('This Year'),
              ),
              const PopupMenuItem(
                value: DateRange.all,
                child: Text('All Time'),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref
                  .read(analyticsProvider.notifier)
                  .refreshAllAnalytics(dateRange: _selectedDateRange);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (analyticsState.isFromCache)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              color: Colors.orange.withValues(alpha: 0.15),
              child: Row(
                children: [
                  const Icon(
                    Icons.offline_pin_rounded,
                    size: 18,
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Viewing offline data',
                          style: TextStyle(
                            color: Colors.orange,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (analyticsState.lastSyncTime != null)
                          Text(
                            'Last synced: ${_formatTimeAgo(analyticsState.lastSyncTime!)}',
                            style: TextStyle(
                              color: Colors.orange.withValues(alpha: 0.8),
                              fontSize: 11,
                            ),
                          ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      ref
                          .read(analyticsProvider.notifier)
                          .refreshAllAnalytics(dateRange: _selectedDateRange);
                    },
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Sync Now'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.orange,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(systemAnalytics, isLoading, error),
                _buildPerformanceTab(topQuizzes, isLoading, error),
                _buildUsersTab(topUsers, isLoading, error),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(
    SystemAnalytics? analytics,
    bool isLoading,
    String? error,
  ) {
    if (error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 64, color: Colors.red[400]),
            const SizedBox(height: 16),
            Text(error, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref
                    .read(analyticsProvider.notifier)
                    .refreshAllAnalytics(dateRange: _selectedDateRange);
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (analytics == null && isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (analytics == null) {
      return const Center(child: Text('No analytics data available'));
    }

    return RefreshIndicator(
      onRefresh: () => ref
          .read(analyticsProvider.notifier)
          .refreshAllAnalytics(dateRange: _selectedDateRange),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overview Cards
            Row(
              children: [
                Expanded(
                  child: AnalyticsCard(
                    title: 'Total Users',
                    value: analytics.totalUsers.toString(),
                    icon: Icons.people,
                    iconColor: Colors.blue,
                    isLoading: isLoading,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: AnalyticsCard(
                    title: 'Total Quizzes',
                    value: analytics.totalQuizzes.toString(),
                    icon: Icons.quiz,
                    iconColor: Colors.green,
                    isLoading: isLoading,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: AnalyticsCard(
                    title: 'Total Submissions',
                    value: analytics.totalSubmissions.toString(),
                    icon: Icons.assignment_turned_in,
                    iconColor: Colors.orange,
                    isLoading: isLoading,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: AnalyticsCard(
                    title: 'Avg. Score',
                    value: analytics.averageScore.toStringAsFixed(1),
                    icon: Icons.trending_up,
                    iconColor: Colors.purple,
                    isLoading: isLoading,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Active Users
            AnalyticsOverviewCard(
              title: 'Active Users',
              child: Row(
                children: [
                  Expanded(
                    child: MetricChip(
                      label: 'Today',
                      value: analytics.activeUsersToday.toString(),
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: MetricChip(
                      label: 'This Week',
                      value: analytics.activeUsersThisWeek.toString(),
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: MetricChip(
                      label: 'This Month',
                      value: analytics.activeUsersThisMonth.toString(),
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // User Role Distribution
            AnalyticsOverviewCard(
              title: 'User Role Distribution',
              child: AnalyticsPieChart(
                title: '',
                data: analytics.userRoleDistribution.entries.map((entry) {
                  final total = analytics.userRoleDistribution.values.fold(
                    0,
                    (sum, count) => sum + count,
                  );
                  return AnalyticsPieData(
                    label: _capitalize(entry.key),
                    value: (entry.value / total) * 100,
                    color: entry.key == 'admin' ? Colors.red : Colors.blue,
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Monthly Analytics
            AnalyticsOverviewCard(
              title: 'Monthly Trends',
              child: AnalyticsLineChart(
                title: 'New Users & Quiz Attempts',
                data: analytics.monthlyAnalytics.map((monthly) {
                  return ChartData(
                    label: _formatMonth(monthly.month),
                    value: monthly.newUsers.toDouble(),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceTab(
    List<QuizAnalytics>? quizzes,
    bool isLoading,
    String? error,
  ) {
    if (error != null) {
      return _buildErrorWidget(error);
    }

    if (quizzes == null && isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (quizzes == null || quizzes.isEmpty) {
      return const Center(child: Text('No quiz performance data available'));
    }

    return RefreshIndicator(
      onRefresh: () => ref
          .read(analyticsProvider.notifier)
          .refreshAllAnalytics(dateRange: _selectedDateRange),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Top Performing Quizzes',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...quizzes.map(
              (quiz) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: AnalyticsOverviewCard(
                  title: quiz.quizTitle,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: MetricChip(
                              label: 'Attempts',
                              value: quiz.totalAttempts.toString(),
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: MetricChip(
                              label: 'Participants',
                              value: quiz.totalParticipants.toString(),
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: MetricChip(
                              label: 'Completion Rate',
                              value:
                                  '${quiz.completionRate.toStringAsFixed(1)}%',
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      AnalyticsProgressIndicator(
                        value: quiz.averagePercentage / 100,
                        label:
                            'Average Score: ${quiz.averagePercentage.toStringAsFixed(1)}%',
                      ),
                      const SizedBox(height: 16),
                      AnalyticsBarChart(
                        title: 'Daily Performance',
                        data: quiz.dailyAnalytics.map((daily) {
                          return ChartData(
                            label: _formatDate(daily.date),
                            value: daily.averageScore,
                          );
                        }).toList(),
                        showGrid: false,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsersTab(
    List<UserAnalytics>? users,
    bool isLoading,
    String? error,
  ) {
    if (error != null) {
      return _buildErrorWidget(error);
    }

    if (users == null && isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (users == null || users.isEmpty) {
      return const Center(child: Text('No user performance data available'));
    }

    return RefreshIndicator(
      onRefresh: () => ref
          .read(analyticsProvider.notifier)
          .refreshAllAnalytics(dateRange: _selectedDateRange),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Top Performing Users',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...users.asMap().entries.map((entry) {
              final index = entry.key;
              final user = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: AnalyticsOverviewCard(
                  title: '${index + 1}. ${user.userName}',
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: MetricChip(
                              label: 'Quizzes Taken',
                              value: user.totalQuizzesTaken.toString(),
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: MetricChip(
                              label: 'Total Score',
                              value: user.totalScore.toString(),
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: MetricChip(
                              label: 'Avg. Score',
                              value:
                                  '${user.averagePercentage.toStringAsFixed(1)}%',
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      AnalyticsProgressIndicator(
                        value: user.averagePercentage / 100,
                        label:
                            'Performance: ${user.averagePercentage.toStringAsFixed(1)}%',
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Last activity: ${user.lastActivity != null ? _formatDateTime(user.lastActivity!) : 'No activity'}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error, size: 64, color: Colors.red[400]),
          const SizedBox(height: 16),
          Text(error, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              ref
                  .read(analyticsProvider.notifier)
                  .refreshAllAnalytics(dateRange: _selectedDateRange);
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  String _formatMonth(DateTime date) {
    return '${date.month}/${date.year}';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}';
  }

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return "${text[0].toUpperCase()}${text.substring(1).toLowerCase()}";
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return '$minutes ${minutes == 1 ? 'minute' : 'minutes'} ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return '$days ${days == 1 ? 'day' : 'days'} ago';
    } else {
      return _formatDateTime(dateTime);
    }
  }
}
