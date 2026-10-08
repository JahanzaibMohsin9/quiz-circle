import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../data/datasources/announcement_remote_datasource.dart';
import '../../data/repositories/announcement_repository_impl.dart';
import '../../domain/entities/announcement.dart';
import '../../domain/repositories/announcement_repository.dart';
import '../../domain/usecases/create_announcement.dart';
import '../../domain/usecases/delete_announcement.dart';
import '../../domain/usecases/get_announcements.dart';
import '../../../../core/services/notification_helper.dart';

// Data Source Provider
final announcementRemoteDataSourceProvider =
    Provider<AnnouncementRemoteDataSource>((ref) {
      return AnnouncementRemoteDataSourceImpl();
    });

// Repository Provider
final announcementRepositoryProvider = Provider<AnnouncementRepository>((ref) {
  final remoteDataSource = ref.watch(announcementRemoteDataSourceProvider);
  return AnnouncementRepositoryImpl(remoteDataSource: remoteDataSource);
});

// Use Case Providers
final getAnnouncementsUseCaseProvider = Provider<GetAnnouncements>((ref) {
  final repository = ref.watch(announcementRepositoryProvider);
  return GetAnnouncements(repository);
});

final createAnnouncementUseCaseProvider = Provider<CreateAnnouncement>((ref) {
  final repository = ref.watch(announcementRepositoryProvider);
  return CreateAnnouncement(repository);
});

final deleteAnnouncementUseCaseProvider = Provider<DeleteAnnouncement>((ref) {
  final repository = ref.watch(announcementRepositoryProvider);
  return DeleteAnnouncement(repository);
});

// Announcement State
class AnnouncementState {
  final List<Announcement> announcements;
  final bool isLoading;
  final String? error;

  AnnouncementState({
    required this.announcements,
    required this.isLoading,
    this.error,
  });

  AnnouncementState copyWith({
    List<Announcement>? announcements,
    bool? isLoading,
    String? error,
  }) {
    return AnnouncementState(
      announcements: announcements ?? this.announcements,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

// Announcement Notifier
class AnnouncementNotifier extends Notifier<AnnouncementState> {
  @override
  AnnouncementState build() {
    return AnnouncementState(announcements: [], isLoading: false);
  }

  Future<void> loadAnnouncements() async {
    state = state.copyWith(isLoading: true);

    final getAnnouncements = ref.read(getAnnouncementsUseCaseProvider);
    final result = await getAnnouncements();

    result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, error: failure.message);
      },
      (announcements) {
        state = state.copyWith(
          announcements: announcements,
          isLoading: false,
        );
      },
    );
  }

  Future<bool> createNewAnnouncement({
    required String title,
    required String message,
    required String authorId,
    required String authorName,
  }) async {
    final announcement = Announcement(
      id: const Uuid().v4(),
      title: title,
      message: message,
      authorId: authorId,
      authorName: authorName,
      timestamp: DateTime.now(),
    );

    final createAnnouncement = ref.read(createAnnouncementUseCaseProvider);
    final result = await createAnnouncement(announcement);

    return result.fold(
      (failure) {
        state = state.copyWith(error: failure.message);
        return false;
      },
      (_) async {
        // Create notifications for all users
        try {
          await NotificationHelper.instance.createAnnouncementNotifications(
            announcementId: announcement.id,
            title: title,
            message: message.length > 100
                ? '${message.substring(0, 100)}...'
                : message,
          );
        } catch (e) {
          // Log error but don't fail the announcement creation
          debugPrint('Failed to create notifications: $e');
        }

        // Reload announcements after creation
        loadAnnouncements();
        return true;
      },
    );
  }

  Future<bool> removeAnnouncement(String id) async {
    final deleteAnnouncement = ref.read(deleteAnnouncementUseCaseProvider);
    final result = await deleteAnnouncement(id);

    return result.fold(
      (failure) {
        state = state.copyWith(error: failure.message);
        return false;
      },
      (_) {
        // Remove from local state
        final updatedAnnouncements = state.announcements
            .where((a) => a.id != id)
            .toList();
        state = state.copyWith(announcements: updatedAnnouncements);
        return true;
      },
    );
  }
}

// Announcement Provider
final announcementProvider =
    NotifierProvider<AnnouncementNotifier, AnnouncementState>(() {
      return AnnouncementNotifier();
    });

// Stream Provider for real-time announcements
final announcementsStreamProvider = StreamProvider<List<Announcement>>((ref) {
  final repository = ref.watch(announcementRepositoryProvider);

  return repository.watchAnnouncements().map(
    (either) => either.fold(
      (failure) => <Announcement>[],
      (announcements) => announcements,
    ),
  );
});
