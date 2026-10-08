import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/announcement.dart';
import '../../domain/repositories/announcement_repository.dart';
import '../datasources/announcement_remote_datasource.dart';
import '../models/announcement_model.dart';

/// Implementation of announcement repository
class AnnouncementRepositoryImpl implements AnnouncementRepository {
  final AnnouncementRemoteDataSource remoteDataSource;

  AnnouncementRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<Announcement>>> getAnnouncements() async {
    try {
      final announcements = await remoteDataSource.getAnnouncements();
      return Right(announcements.map((model) => model.toDomain()).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      debugPrint('Unexpected error in getAnnouncements: $e');
      return const Left(ServerFailure('Failed to fetch announcements'));
    }
  }

  @override
  Future<Either<Failure, Announcement>> getAnnouncementById(String id) async {
    try {
      final announcement = await remoteDataSource.getAnnouncementById(id);
      return Right(announcement.toDomain());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      debugPrint('Unexpected error in getAnnouncementById: $e');
      return const Left(ServerFailure('Failed to fetch announcement'));
    }
  }

  @override
  Future<Either<Failure, void>> createAnnouncement(
    Announcement announcement,
  ) async {
    try {
      final model = AnnouncementModel.fromDomain(announcement);
      await remoteDataSource.createAnnouncement(model);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      debugPrint('Unexpected error in createAnnouncement: $e');
      return const Left(ServerFailure('Failed to create announcement'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteAnnouncement(String id) async {
    try {
      await remoteDataSource.deleteAnnouncement(id);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      debugPrint('Unexpected error in deleteAnnouncement: $e');
      return const Left(ServerFailure('Failed to delete announcement'));
    }
  }

  @override
  Stream<Either<Failure, List<Announcement>>> watchAnnouncements() {
    try {
      return remoteDataSource
          .watchAnnouncements()
          .map(
            (announcements) => Right<Failure, List<Announcement>>(
              announcements.map((model) => model.toDomain()).toList(),
            ),
          )
          .handleError((error) {
            debugPrint('Error in watchAnnouncements stream: $error');
            return const Left<Failure, List<Announcement>>(
              ServerFailure('Failed to watch announcements'),
            );
          });
    } catch (e) {
      debugPrint('Unexpected error in watchAnnouncements: $e');
      return Stream.value(
        const Left(ServerFailure('Failed to watch announcements')),
      );
    }
  }
}
