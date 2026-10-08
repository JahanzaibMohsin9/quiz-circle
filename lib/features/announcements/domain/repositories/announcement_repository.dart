import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/announcement.dart';

/// Abstract repository for announcements
abstract class AnnouncementRepository {
  /// Get all announcements
  Future<Either<Failure, List<Announcement>>> getAnnouncements();

  /// Get announcement by ID
  Future<Either<Failure, Announcement>> getAnnouncementById(String id);

  /// Create new announcement (admin only)
  Future<Either<Failure, void>> createAnnouncement(Announcement announcement);

  /// Delete announcement (admin only)
  Future<Either<Failure, void>> deleteAnnouncement(String id);

  /// Stream of announcements for real-time updates
  Stream<Either<Failure, List<Announcement>>> watchAnnouncements();
}
