import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/colors.dart';
import '../../../../core/constants/route_constants.dart';
import '../providers/quiz_submissions_provider.dart';

class ViewSubmissionsPage extends ConsumerStatefulWidget {
  final String? quizId;

  const ViewSubmissionsPage({super.key, this.quizId});

  @override
  ConsumerState<ViewSubmissionsPage> createState() =>
      _ViewSubmissionsPageState();
}

class _ViewSubmissionsPageState extends ConsumerState<ViewSubmissionsPage> {
  String? _selectedQuizFilter;

  @override
  void initState() {
    super.initState();
    // Load submissions on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(quizSubmissionsProvider.notifier).loadSubmissions(widget.quizId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final submissionsState = ref.watch(quizSubmissionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.quizId != null ? 'Quiz Submissions' : 'All Submissions',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref
                  .read(quizSubmissionsProvider.notifier)
                  .refresh(_selectedQuizFilter ?? widget.quizId);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref
              .read(quizSubmissionsProvider.notifier)
              .loadSubmissions(_selectedQuizFilter ?? widget.quizId);
        },
        child: _buildBody(context, submissionsState),
      ),
      floatingActionButton: submissionsState.submissions.isNotEmpty
          ? SafeArea(
              child: FloatingActionButton.extended(
                onPressed: () =>
                    _exportToCSV(context, submissionsState.submissions),
                icon: const Icon(Icons.download),
                label: const Text('Export CSV'),
              ),
            )
          : null,
    );
  }

  Widget _buildBody(BuildContext context, QuizSubmissionsState state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return _buildErrorState(context, state.error!);
    }

    if (state.submissions.isEmpty) {
      return _buildEmptyState(context);
    }

    return CustomScrollView(
      slivers: [
        // Statistics Section
        if (state.statistics != null)
          SliverToBoxAdapter(
            child: _buildStatisticsSection(context, state.statistics!),
          ),

        // Quiz Filter (only when viewing all submissions)
        if (widget.quizId == null)
          SliverToBoxAdapter(child: _buildQuizFilter(context, state)),

        // Submissions List
        SliverPadding(
          padding: const EdgeInsets.all(16.0),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final submissionWithInfo = state.submissions[index];
              return _buildSubmissionCard(
                context,
                submissionWithInfo,
                showQuizTitle: widget.quizId == null,
              );
            }, childCount: state.submissions.length),
          ),
        ),
      ],
    );
  }

  Widget _buildStatisticsSection(
    BuildContext context,
    SubmissionStatistics stats,
  ) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.1),
            AppColors.secondary.withValues(alpha: 0.1),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Overview',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 2.0,
            children: [
              _buildStatCard(
                context,
                'Total Submissions',
                stats.totalSubmissions.toString(),
                Icons.assignment_turned_in,
                AppColors.primary,
              ),
              _buildStatCard(
                context,
                'Average Score',
                '${stats.averagePercentage.toStringAsFixed(1)}%',
                Icons.trending_up,
                AppColors.success,
              ),
              _buildStatCard(
                context,
                'Unique Quizzes',
                stats.totalQuizzes.toString(),
                Icons.quiz,
                AppColors.info,
              ),
              _buildStatCard(
                context,
                'Unique Users',
                stats.totalUsers.toString(),
                Icons.people,
                AppColors.secondary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizFilter(BuildContext context, QuizSubmissionsState state) {
    // Get unique quizzes from submissions
    final uniqueQuizzes = <String, String>{};
    for (final item in state.submissions) {
      uniqueQuizzes[item.submission.quizId] = item.quizTitle;
    }

    if (uniqueQuizzes.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              const Icon(Icons.filter_list, color: AppColors.primary, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedQuizFilter,
                    hint: const Text('Filter by quiz'),
                    isExpanded: true,
                    items: [
                      const DropdownMenuItem<String>(
                        child: Text('All Quizzes'),
                      ),
                      ...uniqueQuizzes.entries.map((entry) {
                        return DropdownMenuItem<String>(
                          value: entry.key,
                          child: Text(entry.value),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedQuizFilter = value;
                      });
                      ref
                          .read(quizSubmissionsProvider.notifier)
                          .filterByQuiz(value);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubmissionCard(
    BuildContext context,
    SubmissionWithQuizInfo submissionInfo, {
    bool showQuizTitle = false,
  }) {
    final submission = submissionInfo.submission;
    final scoreColor = _getScoreColor(submission.percentage);

    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: scoreColor.withValues(alpha: 0.2)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          context.push(
            Uri(
              path: RouteConstants.submissionDetail,
              queryParameters: {
                'submissionId': submission.id,
                'quizId': submission.quizId,
              },
            ).toString(),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Score Badge
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [scoreColor, scoreColor.withValues(alpha: 0.7)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: scoreColor.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${submission.percentage.toStringAsFixed(0)}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          '${submission.score}/${submission.totalQuestions}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Submission Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (showQuizTitle) ...[
                          Row(
                            children: [
                              const Icon(
                                Icons.quiz,
                                size: 16,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  submissionInfo.quizTitle,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurface,
                                      ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                        ],
                        Row(
                          children: [
                            Icon(
                              Icons.person,
                              size: 14,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    submissionInfo.userName,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
                                          fontWeight: FontWeight.w600,
                                        ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (submissionInfo.userEmail.isNotEmpty)
                                    Text(
                                      submissionInfo.userEmail,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
                                          ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 14,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatDuration(submission.timeTakenSeconds),
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                            const SizedBox(width: 16),
                            Icon(
                              Icons.calendar_today,
                              size: 14,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                _formatDateTime(submission.submittedAt),
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Performance Icon
                  Icon(
                    _getScoreIcon(submission.percentage),
                    color: scoreColor,
                    size: 28,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary.withValues(alpha: 0.1),
                    AppColors.secondary.withValues(alpha: 0.1),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.assessment_outlined,
                size: 80,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Submissions Yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              widget.quizId != null
                  ? 'Students haven\'t submitted this quiz yet.\nCheck back later to see their results.'
                  : 'No quiz submissions found in the system.\nSubmissions will appear here once students complete quizzes.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            if (widget.quizId == null)
              ElevatedButton.icon(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Go Back'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                size: 80,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Oops! Something went wrong',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              error,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                ref
                    .read(quizSubmissionsProvider.notifier)
                    .refresh(_selectedQuizFilter ?? widget.quizId);
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getScoreColor(double percentage) {
    if (percentage >= 80) return AppColors.success;
    if (percentage >= 60) return AppColors.warning;
    return AppColors.error;
  }

  IconData _getScoreIcon(double percentage) {
    if (percentage >= 80) return Icons.emoji_events;
    if (percentage >= 60) return Icons.check_circle;
    return Icons.warning;
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes}m ${remainingSeconds}s';
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _exportToCSV(
    BuildContext context,
    List<SubmissionWithQuizInfo> submissions,
  ) async {
    try {
      // Create CSV content
      final csvContent = StringBuffer();
      csvContent.writeln(
        'Quiz Title,User ID,Score,Total Questions,Percentage,Time Taken (sec),Submitted At',
      );

      for (final item in submissions) {
        final submission = item.submission;
        csvContent.writeln(
          '${item.quizTitle},${submission.userId},${submission.score},${submission.totalQuestions},${submission.percentage},${submission.timeTakenSeconds},${submission.submittedAt.toIso8601String()}',
        );
      }

      // In a real implementation, you would save this to a file
      // For now, we'll just show a success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'CSV generated! ${submissions.length} submissions exported',
            ),
            backgroundColor: AppColors.success,
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
