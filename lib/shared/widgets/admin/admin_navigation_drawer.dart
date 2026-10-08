import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/route_constants.dart';
import '../../../app/theme/colors.dart';
import '../../../shared/providers/theme_provider.dart';
import '../../../features/authentication/presentation/providers/auth_provider.dart';

class AdminNavigationDrawer extends ConsumerWidget {
  const AdminNavigationDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentPath = GoRouterState.of(context).uri.path;
    final currentUser = ref.watch(currentUserProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final userName = currentUser.when(
      data: (user) => user?.name ?? 'Admin',
      loading: () => 'Admin',
      error: (_, _) => 'Admin',
    );

    final userEmail = currentUser.when(
      data: (user) => user?.email ?? '',
      loading: () => '',
      error: (_, _) => '',
    );

    return Drawer(
      width: 300,
      child: Container(
        color: Theme.of(context).colorScheme.surface,
        child: Column(
          children: [
            _buildDrawerHeader(context, userName, userEmail),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                children: [
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.dashboard_rounded,
                    title: 'Dashboard',
                    route: RouteConstants.adminDashboard,
                    isSelected: currentPath == RouteConstants.adminDashboard,
                  ),
                  const SizedBox(height: 8),
                  _buildSectionHeader(context, 'Quiz Management'),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.add_circle_outline_rounded,
                    title: 'Create Quiz',
                    route: RouteConstants.createQuiz,
                    isSelected: currentPath == RouteConstants.createQuiz,
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.quiz_outlined,
                    title: 'Manage Quizzes',
                    route: RouteConstants.manageQuizzes,
                    isSelected: currentPath == RouteConstants.manageQuizzes,
                  ),
                  const SizedBox(height: 8),
                  _buildSectionHeader(context, 'User Management'),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.people_outline_rounded,
                    title: 'Manage Users',
                    route: RouteConstants.manageUsers,
                    isSelected: currentPath == RouteConstants.manageUsers,
                  ),
                  const SizedBox(height: 8),
                  _buildSectionHeader(context, 'Analytics & Reports'),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.assignment_outlined,
                    title: 'Submissions',
                    route: RouteConstants.viewSubmissions,
                    isSelected: currentPath == RouteConstants.viewSubmissions,
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.analytics_outlined,
                    title: 'Analytics',
                    route: RouteConstants.analytics,
                    isSelected: currentPath == RouteConstants.analytics,
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.leaderboard_outlined,
                    title: 'Global Leaderboard',
                    route: RouteConstants.globalLeaderboard,
                    isSelected: currentPath == RouteConstants.globalLeaderboard,
                  ),
                  const SizedBox(height: 8),
                  _buildSectionHeader(context, 'Communication'),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.campaign_outlined,
                    title: 'Create Announcement',
                    route: RouteConstants.createAnnouncement,
                    isSelected:
                        currentPath == RouteConstants.createAnnouncement,
                  ),
                  const SizedBox(height: 8),
                  _buildSectionHeader(context, 'Preferences'),
                  ListTile(
                    leading: Icon(
                      isDark
                          ? Icons.light_mode_rounded
                          : Icons.dark_mode_rounded,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      size: 22,
                    ),
                    title: Text(
                      isDark ? 'Light Mode' : 'Dark Mode',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    trailing: Switch(
                      value: isDark,
                      onChanged: (value) {
                        ref.read(themeProvider.notifier).toggleTheme();
                      },
                      thumbColor: WidgetStateProperty.resolveWith<Color>(
                        (states) => states.contains(WidgetState.selected)
                            ? AppColors.primary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: _buildDrawerItem(
                context: context,
                icon: Icons.logout_rounded,
                title: 'Logout',
                onTap: () async {
                  final authNotifier = ref.read(authProvider.notifier);
                  Navigator.pop(context); // Close drawer first
                  final confirmed = await _showLogoutConfirmation(context);
                  if (confirmed == true) {
                    await authNotifier.signOut();
                    // Navigate to login page after logout
                    // The router redirect will also handle this, but we do it explicitly for immediate feedback
                    if (context.mounted) {
                      context.go(RouteConstants.login);
                    }
                  }
                },
                isDestructive: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerHeader(
    BuildContext context,
    String userName,
    String userEmail,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primary.withValues(alpha: 0.85),
            AppColors.secondary,
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const CircleAvatar(
                  radius: 36,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.admin_panel_settings_rounded,
                    size: 36,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                userName,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              if (userEmail.isNotEmpty)
                Text(
                  userEmail,
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onPrimary.withValues(alpha: 0.9),
                    fontSize: 13,
                    letterSpacing: 0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.onPrimary.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Administrator',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: isDark
              ? AppColors.primary.withValues(alpha: 0.9)
              : AppColors.primaryDark,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    String? route,
    VoidCallback? onTap,
    bool isSelected = false,
    bool isDestructive = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = isDestructive
        ? colorScheme.error
        : isSelected
        ? colorScheme.primary
        : colorScheme.onSurfaceVariant;

    final bgColor = isSelected
        ? colorScheme.primary.withValues(alpha: 0.12)
        : Colors.transparent;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: color, size: 22),
        title: Text(
          title,
          style: TextStyle(
            color: color,
            fontSize: 15,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            letterSpacing: 0.2,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        dense: true,
        visualDensity: VisualDensity.compact,
        onTap:
            onTap ??
            () {
              Navigator.pop(context);
              if (route != null) {
                context.push(route);
              }
            },
      ),
    );
  }

  Future<bool?> _showLogoutConfirmation(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              Icons.logout_rounded,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(width: 12),
            const Text('Confirm Logout'),
          ],
        ),
        content: const Text(
          'Are you sure you want to logout?',
          style: TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
