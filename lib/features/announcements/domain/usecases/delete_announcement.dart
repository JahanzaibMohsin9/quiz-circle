import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/announcement_repository.dart';

/// Use case to delete announcement
class DeleteAnnouncement {
  final AnnouncementRepository repository;

  DeleteAnnouncement(this.repository);

  Future<Either<Failure, void>> call(String id) async {
    return await repository.deleteAnnouncement(id);
  }
}
