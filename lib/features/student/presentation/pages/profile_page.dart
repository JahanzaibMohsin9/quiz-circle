import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/route_constants.dart';
import '../../../../app/theme/colors.dart';
import '../../../../shared/widgets/common/animated_counter.dart';
import '../../../../shared/widgets/common/custom_button.dart';
import '../../../../shared/widgets/common/shimmer_loading.dart';
import '../../../../shared/widgets/common/error_state_widget.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import '../providers/profile_provider.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(authProvider);
    final profileState = ref.watch(profileProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.primary,
        foregroundColor: isDark ? AppColors.primary : Colors.white,
        iconTheme: IconThemeData(
          color: isDark ? AppColors.primary : Colors.white,
        ),
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: isDark ? AppColors.primary : Colors.white,
          letterSpacing: 0.3,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _showEditProfileDialog(context, ref),
          ),
        ],
      ),
      body: profileState.when(
        data: (user, quizzesTaken) => SafeArea(
          bottom: true,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Profile Header with gradient background
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: AppColors.primaryGradient,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Theme.of(context).colorScheme.onPrimary,
                                width: 3,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 50,
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.onPrimary.withValues(alpha: 0.2),
                              child: Text(
                                user.name.isNotEmpty
                                    ? user.name[0].toUpperCase()
                                    : 'U',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onPrimary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            user.name,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                          Text(
                            user.email,
                            style: TextStyle(
                              fontSize: 16,
                              color: Theme.of(
                                context,
                              ).colorScheme.onPrimary.withValues(alpha: 0.7),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.onPrimary.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              user.role.name.toUpperCase(),
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Stats Section with AnimatedCounter
                  Text(
                    'Quiz Statistics',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),

                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white,
                            AppColors.primary.withValues(alpha: 0.05),
                          ],
                        ),
                      ),
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          _buildAnimatedStatRow(
                            context,
                            'Total Score',
                            user.totalScore ?? 0,
                            Icons.scoreboard_rounded,
                            AppColors.primary,
                          ),
                          const Divider(),
                          _buildAnimatedStatRow(
                            context,
                            'Average Score',
                            (user.averagePercentage ?? 0.0).toInt(),
                            Icons.trending_up_rounded,
                            AppColors.success,
                            suffix: '%',
                          ),
                          const Divider(),
                          _buildAnimatedStatRow(
                            context,
                            'Quizzes Taken',
                            quizzesTaken,
                            Icons.quiz_rounded,
                            AppColors.info,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Action Buttons with CustomButton
                  CustomButton.gradient(
                    text: 'View Quiz History',
                    icon: Icons.history_rounded,
                    onPressed: () => context.push(RouteConstants.quizHistory),
                  ),
                  const SizedBox(height: 12),

                  CustomButton(
                    text: 'Change Password',
                    icon: Icons.lock_rounded,
                    outlined: true,
                    onPressed: () => _showChangePasswordDialog(context, ref),
                  ),

                  const SizedBox(height: 32),

                  // Sign Out Button with error styling
                  CustomButton(
                    text: 'Sign Out',
                    icon: Icons.logout,
                    onPressed: () => _showSignOutDialog(context, ref),
                    gradient: const LinearGradient(colors: AppColors.errorGradient),
                  ),
                    // Extra padding for system navigation
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
        loading: () => const Center(child: ShimmerLoading.circular(width: 100)),
        error: (error) => ErrorStateWidget(
          message: error,
          errorType: ErrorType.network,
          onRetry: () => ref.read(profileProvider.notifier).loadProfile(),
        ),
      ),
    );
  }

  Widget _buildAnimatedStatRow(
    BuildContext context,
    String label,
    int value,
    IconData icon,
    Color color, {
    String? suffix,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
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
              Text(
                label,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          AnimatedCounter(
            value: value,
            duration: const Duration(milliseconds: 1200),
            textStyle: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
            suffix: suffix,
          ),
        ],
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                ref
                    .read(profileProvider.notifier)
                    .updateProfile(nameController.text);
                Navigator.of(context).pop();
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context, WidgetRef ref) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Current Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'New Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirm New Password',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (newPasswordController.text ==
                      confirmPasswordController.text &&
                  newPasswordController.text.isNotEmpty) {
                ref
                    .read(profileProvider.notifier)
                    .changePassword(
                      currentPasswordController.text,
                      newPasswordController.text,
                    );
                Navigator.of(context).pop();
              }
            },
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }

  void _showSignOutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(authProvider.notifier).signOut();
              Navigator.of(context).pop();
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}
