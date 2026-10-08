import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/announcement.dart';
import '../repositories/announcement_repository.dart';

/// Use case to get all announcements
class GetAnnouncements {
  final AnnouncementRepository repository;

  GetAnnouncements(this.repository);

  Future<Either<Failure, List<Announcement>>> call() async {
    return await repository.getAnnouncements();
  }
}
