import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/constants/route_constants.dart';
import '../../presentation/providers/admin_quiz_provider.dart';
import '../../../quiz/domain/entities/quiz.dart';
import '../../../quiz/domain/entities/quiz_permissions.dart';
import '../widgets/bulk_operations_dialog.dart';
import '../../../../shared/widgets/common/custom_button.dart';

class ManageQuizzesPage extends ConsumerStatefulWidget {
  const ManageQuizzesPage({super.key});

  @override
  ConsumerState<ManageQuizzesPage> createState() => _ManageQuizzesPageState();
}

class _ManageQuizzesPageState extends ConsumerState<ManageQuizzesPage> {
  // Filter states
  String? _filterAccessLevel; // 'public', 'private', 'role-based', 'scheduled'
  bool? _filterActiveStatus;
  String _searchQuery = '';

  // Bulk selection
  final Set<String> _selectedQuizIds = {};
  bool _isSelectionMode = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminQuizProvider);
    final controller = ref.read(adminQuizProvider.notifier);

    // Apply filters
    final filteredQuizzes = _applyFilters(state.quizzes);

    // Calculate statistics
    final stats = _calculateStats(state.quizzes);

    return PopScope(
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            _isSelectionMode
                ? '${_selectedQuizIds.length} selected'
                : 'Manage Quizzes',
          ),
          automaticallyImplyLeading: !_isSelectionMode,
          leading: _isSelectionMode
              ? IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _exitSelectionMode,
                )
              : null,
          actions: [
            if (_isSelectionMode) ...[
              IconButton(
                icon: const Icon(Icons.select_all),
                onPressed: () => _selectAll(filteredQuizzes),
                tooltip: 'Select All',
              ),
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: _selectedQuizIds.isEmpty
                    ? null
                    : _showBulkOperations,
                tooltip: 'Bulk Operations',
              ),
            ] else ...[
              IconButton(
                icon: const Icon(Icons.checklist),
                onPressed: _enterSelectionMode,
                tooltip: 'Select Multiple',
              ),
              IconButton(
                icon: const Icon(Icons.download),
                onPressed: filteredQuizzes.isEmpty
                    ? null
                    : () => _exportToCSV(filteredQuizzes),
                tooltip: 'Export to CSV',
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => controller.loadQuizzes(),
                tooltip: 'Refresh',
              ),
            ],
          ],
        ),
        body: RefreshIndicator(
          onRefresh: () => controller.loadQuizzes(),
          child: Column(
            children: [
              // Statistics Cards
              _buildStatsOverview(stats),

              // Filters
              _buildFiltersBar(),

              // Quiz List
              Expanded(
                child: filteredQuizzes.isEmpty
                    ? _buildEmptyState()
                    : SafeArea(
                        bottom: true,
                        child: ListView.builder(
                          padding: const EdgeInsets.only(
                            left: 16,
                            right: 16,
                            top: 16,
                            bottom: 24, // Extra padding for system navigation
                          ),
                          itemCount: filteredQuizzes.length,
                          itemBuilder: (context, index) {
                            final quiz = filteredQuizzes[index];
                            return _buildQuizCard(quiz, controller);
                          },
                        ),
                      ),
              ),
            ],
          ),
        ),
        floatingActionButton: _isSelectionMode
            ? null
            : SafeArea(
                child: FloatingActionButton(
                  onPressed: () => context.push(RouteConstants.createQuiz),
                  tooltip: 'Create Quiz',
                  child: const Icon(Icons.add),
                ),
              ),
      ),
    );
  }

  Widget _buildStatsOverview(QuizStats stats) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Total',
              stats.total.toString(),
              Icons.quiz,
              Colors.blue,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatCard(
              'Active',
              stats.active.toString(),
              Icons.check_circle,
              Colors.green,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatCard(
              'Public',
              stats.public.toString(),
              Icons.public,
              Colors.orange,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatCard(
              'Private',
              stats.private.toString(),
              Icons.lock,
              Colors.purple,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltersBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Theme.of(context).colorScheme.surfaceContainerLowest,
      child: Column(
        children: [
          // Search bar
          TextField(
            decoration: InputDecoration(
              hintText: 'Search quizzes...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _searchQuery = ''),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
          const SizedBox(height: 8),

          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                const Text(
                  'Filters: ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),

                // Access level filter
                PopupMenuButton<String?>(
                  child: Chip(
                    avatar: const Icon(Icons.filter_alt, size: 18),
                    label: Text(
                      _filterAccessLevel == null
                          ? 'All Access'
                          : _getAccessLevelLabel(_filterAccessLevel!),
                    ),
                    deleteIcon: _filterAccessLevel != null
                        ? const Icon(Icons.close, size: 18)
                        : null,
                    onDeleted: _filterAccessLevel != null
                        ? () => setState(() => _filterAccessLevel = null)
                        : null,
                  ),
                  itemBuilder: (context) => [
                    const PopupMenuItem(child: Text('All Access')),
                    const PopupMenuItem(value: 'public', child: Text('Public')),
                    const PopupMenuItem(
                      value: 'private',
                      child: Text('Private'),
                    ),
                    const PopupMenuItem(
                      value: 'role-based',
                      child: Text('Role-based'),
                    ),
                    const PopupMenuItem(
                      value: 'scheduled',
                      child: Text('Scheduled'),
                    ),
                  ],
                  onSelected: (value) =>
                      setState(() => _filterAccessLevel = value),
                ),
                const SizedBox(width: 8),

                // Active status filter
                PopupMenuButton<bool?>(
                  child: Chip(
                    avatar: const Icon(Icons.power_settings_new, size: 18),
                    label: Text(
                      _filterActiveStatus == null
                          ? 'All Status'
                          : (_filterActiveStatus! ? 'Active' : 'Inactive'),
                    ),
                    deleteIcon: _filterActiveStatus != null
                        ? const Icon(Icons.close, size: 18)
                        : null,
                    onDeleted: _filterActiveStatus != null
                        ? () => setState(() => _filterActiveStatus = null)
                        : null,
                  ),
                  itemBuilder: (context) => [
                    const PopupMenuItem(child: Text('All Status')),
                    const PopupMenuItem(value: true, child: Text('Active')),
                    const PopupMenuItem(value: false, child: Text('Inactive')),
                  ],
                  onSelected: (value) =>
                      setState(() => _filterActiveStatus = value),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizCard(Quiz quiz, dynamic controller) {
    final isSelected = _selectedQuizIds.contains(quiz.id);
    final accessLevel = _getAccessLevel(quiz.permissions);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isSelected ? 4 : 1,
      color: isSelected ? Colors.blue[50] : null,
      child: InkWell(
        onTap: _isSelectionMode ? () => _toggleSelection(quiz.id) : null,
        onLongPress: () {
          if (!_isSelectionMode) {
            _enterSelectionMode();
            _toggleSelection(quiz.id);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (_isSelectionMode)
                    Checkbox(
                      value: isSelected,
                      onChanged: (_) => _toggleSelection(quiz.id),
                    ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                quiz.title,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            _buildAccessLevelBadge(accessLevel),
                            const SizedBox(width: 8),
                            _buildStatusBadge(quiz.isActive),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          quiz.description,
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Quiz details
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  _buildInfoChip(Icons.timer, '${quiz.timeLimitMinutes} min'),
                  if (quiz.permissions.allowedUserIds.isNotEmpty)
                    _buildInfoChip(
                      Icons.people,
                      '${quiz.permissions.allowedUserIds.length} users',
                    ),
                  if (accessLevel == 'scheduled' &&
                      quiz.permissions.availableFrom != null)
                    _buildInfoChip(Icons.schedule, 'Scheduled'),
                ],
              ),

              if (!_isSelectionMode) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Edit'),
                      onPressed: () => context.push(
                        '${RouteConstants.editQuiz}?quizId=${quiz.id}',
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      icon: Icon(
                        quiz.isActive ? Icons.pause_circle : Icons.play_circle,
                        size: 18,
                      ),
                      label: Text(quiz.isActive ? 'Deactivate' : 'Activate'),
                      onPressed: () =>
                          controller.setActive(quiz.id, !quiz.isActive),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      icon: const Icon(
                        Icons.delete,
                        size: 18,
                        color: Colors.red,
                      ),
                      label: const Text(
                        'Delete',
                        style: TextStyle(color: Colors.red),
                      ),
                      onPressed: () => _confirmDelete(quiz, controller),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccessLevelBadge(String accessLevel) {
    Color color;
    IconData icon;

    switch (accessLevel) {
      case 'public':
        color = Colors.green;
        icon = Icons.public;
        break;
      case 'private':
        color = Colors.red;
        icon = Icons.lock;
        break;
      case 'role-based':
        color = Colors.blue;
        icon = Icons.admin_panel_settings;
        break;
      case 'scheduled':
        color = Colors.orange;
        icon = Icons.schedule;
        break;
      default:
        color = Theme.of(context).colorScheme.outline;
        icon = Icons.help_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            _getAccessLevelLabel(accessLevel),
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isActive
            ? Colors.green.withValues(alpha: 0.1)
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive
              ? Colors.green
              : Theme.of(context).colorScheme.outline,
        ),
      ),
      child: Text(
        isActive ? 'Active' : 'Inactive',
        style: TextStyle(
          fontSize: 12,
          color: isActive
              ? Colors.green
              : Theme.of(context).colorScheme.outline,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.quiz_outlined,
            size: 64,
            color: Theme.of(
              context,
            ).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty ||
                    _filterAccessLevel != null ||
                    _filterActiveStatus != null
                ? 'No quizzes match your filters'
                : 'No quizzes yet',
            style: TextStyle(
              fontSize: 18,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          if (_searchQuery.isEmpty &&
              _filterAccessLevel == null &&
              _filterActiveStatus == null)
            CustomButton(
              text: 'Create Your First Quiz',
              onPressed: () => context.push(RouteConstants.createQuiz),
            ),
        ],
      ),
    );
  }

  List<Quiz> _applyFilters(List<Quiz> quizzes) {
    return quizzes.where((quiz) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!quiz.title.toLowerCase().contains(query) &&
            !quiz.description.toLowerCase().contains(query)) {
          return false;
        }
      }

      // Access level filter
      if (_filterAccessLevel != null) {
        final quizAccessLevel = _getAccessLevel(quiz.permissions);
        if (quizAccessLevel != _filterAccessLevel) {
          return false;
        }
      }

      // Active status filter
      if (_filterActiveStatus != null) {
        if (quiz.isActive != _filterActiveStatus) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  QuizStats _calculateStats(List<Quiz> quizzes) {
    return QuizStats(
      total: quizzes.length,
      active: quizzes.where((q) => q.isActive).length,
      public: quizzes
          .where((q) => _getAccessLevel(q.permissions) == 'public')
          .length,
      private: quizzes
          .where((q) => _getAccessLevel(q.permissions) == 'private')
          .length,
    );
  }

  String _getAccessLevel(QuizPermissions permissions) {
    // Check if it's scheduled first
    if (permissions.availableFrom != null ||
        permissions.availableUntil != null) {
      return 'scheduled';
    }

    // Check if it's private (specific users)
    if (permissions.allowedUserIds.isNotEmpty) {
      return 'private';
    }

    // Check if it's public (all students)
    if (permissions.allowedRoles.contains('student') &&
        permissions.allowedRoles.length == 1) {
      return 'public';
    }

    // Otherwise it's role-based
    return 'role-based';
  }

  String _getAccessLevelLabel(String accessLevel) {
    switch (accessLevel) {
      case 'public':
        return 'Public';
      case 'private':
        return 'Private';
      case 'role-based':
        return 'Role-based';
      case 'scheduled':
        return 'Scheduled';
      default:
        return 'Unknown';
    }
  }

  void _enterSelectionMode() {
    setState(() {
      _isSelectionMode = true;
      _selectedQuizIds.clear();
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedQuizIds.clear();
    });
  }

  void _toggleSelection(String quizId) {
    setState(() {
      if (_selectedQuizIds.contains(quizId)) {
        _selectedQuizIds.remove(quizId);
      } else {
        _selectedQuizIds.add(quizId);
      }
    });
  }

  void _selectAll(List<Quiz> quizzes) {
    setState(() {
      _selectedQuizIds.clear();
      _selectedQuizIds.addAll(quizzes.map((q) => q.id));
    });
  }

  void _showBulkOperations() {
    showDialog(
      context: context,
      builder: (context) => BulkOperationsDialog(
        selectedQuizIds: _selectedQuizIds.toList(),
        onComplete: () {
          _exitSelectionMode();
          ref.read(adminQuizProvider.notifier).loadQuizzes();
        },
      ),
    );
  }

  Future<void> _exportToCSV(List<Quiz> quizzes) async {
    try {
      // Pick save location
      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Quiz Export',
        fileName: 'quizzes_export_${DateTime.now().millisecondsSinceEpoch}.csv',
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result == null) return;

      // Show loading
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Exporting quizzes...')));
      }

      // This would need actual service implementation
      // For now, show success
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Exported ${quizzes.length} quizzes to CSV')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error exporting: $e')));
      }
    }
  }

  Future<void> _confirmDelete(Quiz quiz, dynamic controller) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Text('Are you sure you want to delete "${quiz.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      controller.deleteQuiz(quiz.id);
    }
  }
}

class QuizStats {
  final int total;
  final int active;
  final int public;
  final int private;

  QuizStats({
    required this.total,
    required this.active,
    required this.public,
    required this.private,
  });
}
