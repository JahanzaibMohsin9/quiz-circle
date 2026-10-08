import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import '../../data/datasources/notification_remote_datasource.dart';
import '../../data/repositories/notification_repository_impl.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notification_repository.dart';

/// Provider for notification repository
final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepositoryImpl(
    remoteDataSource: NotificationRemoteDataSource(),
  );
});

/// State class for notifications
class NotificationState {
  final List<AppNotification> notifications;
  final int unreadCount;
  final bool isLoading;
  final String? error;

  const NotificationState({
    this.notifications = const [],
    this.unreadCount = 0,
    this.isLoading = false,
    this.error,
  });

  NotificationState copyWith({
    List<AppNotification>? notifications,
    int? unreadCount,
    bool? isLoading,
    String? error,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notification notifier
class NotificationNotifier extends Notifier<NotificationState> {
  NotificationRepository? _repository;
  String? _userId;
  StreamSubscription<List<AppNotification>>? _notificationSubscription;

  @override
  NotificationState build() {
    _repository = ref.read(notificationRepositoryProvider);
    final userAsync = ref.watch(currentUserProvider);

    _userId = userAsync.when(
      data: (user) => user?.id,
      loading: () => null,
      error: (_, _) => null,
    );

    // Cancel existing subscription if any (to handle re-builds correctly)
    _notificationSubscription?.cancel();

    // Clean up subscription when provider is disposed
    ref.onDispose(() {
      _notificationSubscription?.cancel();
    });

    if (_userId != null) {
      _setupListener();
      return const NotificationState(isLoading: true);
    }

    return const NotificationState();
  }

  /// Set up the notification listener
  void _setupListener() {
    if (_userId == null || _repository == null) return;

    _notificationSubscription = _repository!
        .watchUserNotifications(_userId!)
        .listen(
          (notifications) {
            final unreadCount = notifications.where((n) => !n.isRead).length;
            state = state.copyWith(
              notifications: notifications,
              unreadCount: unreadCount,
              isLoading: false,
            );
          },
          onError: (error) {
            debugPrint('Error listening to notifications: $error');
            state = state.copyWith(isLoading: false, error: error.toString());
          },
        );
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    if (_userId == null || _repository == null) return;

    final result = await _repository!.markAsRead(notificationId, _userId!);
    result.fold(
      (failure) {
        debugPrint('Failed to mark notification as read: ${failure.message}');
        state = state.copyWith(error: failure.message);
      },
      (_) {
        // Update handled by stream
      },
    );
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    if (_userId == null || _repository == null) return;

    final result = await _repository!.markAllAsRead(_userId!);
    result.fold(
      (failure) {
        debugPrint('Failed to mark all as read: ${failure.message}');
        state = state.copyWith(error: failure.message);
      },
      (_) {
        // Update handled by stream
      },
    );
  }

  /// Delete notification
  Future<void> deleteNotification(String notificationId) async {
    if (_userId == null || _repository == null) return;

    final result = await _repository!.deleteNotification(
      notificationId,
      _userId!,
    );
    result.fold(
      (failure) {
        debugPrint('Failed to delete notification: ${failure.message}');
        state = state.copyWith(error: failure.message);
      },
      (_) {
        // Update handled by stream
      },
    );
  }

  /// Refresh notifications
  Future<void> refresh() async {
    if (_userId == null || _repository == null) return;

    state = state.copyWith(isLoading: true);

    final result = await _repository!.getUserNotifications(_userId!);
    result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, error: failure.message);
      },
      (notifications) {
        final unreadCount = notifications.where((n) => !n.isRead).length;
        state = state.copyWith(
          notifications: notifications,
          unreadCount: unreadCount,
          isLoading: false,
        );
      },
    );
  }
}

/// Provider for notification state
final notificationProvider =
    NotifierProvider<NotificationNotifier, NotificationState>(
      NotificationNotifier.new,
    );

/// Provider for unread count only (optimized for performance)
final unreadCountProvider = Provider<int>((ref) {
  final notificationState = ref.watch(notificationProvider);
  return notificationState.unreadCount;
});
