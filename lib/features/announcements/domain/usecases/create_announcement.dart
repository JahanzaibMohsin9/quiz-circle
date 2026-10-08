import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/announcement.dart';
import '../repositories/announcement_repository.dart';

/// Use case to create announcement
class CreateAnnouncement {
  final AnnouncementRepository repository;

  CreateAnnouncement(this.repository);

  Future<Either<Failure, void>> call(Announcement announcement) async {
    return await repository.createAnnouncement(announcement);
  }
}
