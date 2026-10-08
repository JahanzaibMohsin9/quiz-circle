import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../../../core/constants/firebase_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/announcement_model.dart';

/// Remote data source for announcements
abstract class AnnouncementRemoteDataSource {
  /// Get all announcements
  Future<List<AnnouncementModel>> getAnnouncements();

  /// Get announcement by ID
  Future<AnnouncementModel> getAnnouncementById(String id);

  /// Create new announcement
  Future<void> createAnnouncement(AnnouncementModel announcement);

  /// Delete announcement
  Future<void> deleteAnnouncement(String id);

  /// Watch announcements stream
  Stream<List<AnnouncementModel>> watchAnnouncements();
}

/// Implementation of announcement remote data source
class AnnouncementRemoteDataSourceImpl implements AnnouncementRemoteDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  AnnouncementRemoteDataSourceImpl({FirebaseFirestore? firestore, FirebaseFunctions? functions})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _functions = functions ?? FirebaseFunctions.instance;

  @override
  Future<List<AnnouncementModel>> getAnnouncements() async {
    try {
      final snapshot = await _firestore
          .collection(FirebaseConstants.announcementsCollection)
          .orderBy(FirebaseConstants.timestampField, descending: true)
          .get();

      return snapshot.docs
          .map((doc) => AnnouncementModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Error getting announcements: $e');
      throw const ServerException('Failed to fetch announcements');
    }
  }

  @override
  Future<AnnouncementModel> getAnnouncementById(String id) async {
    try {
      final doc = await _firestore
          .collection(FirebaseConstants.announcementsCollection)
          .doc(id)
          .get();

      if (!doc.exists) {
        throw const ServerException('Announcement not found');
      }

      return AnnouncementModel.fromJson(doc.data()!);
    } catch (e) {
      debugPrint('Error getting announcement by ID: $e');
      if (e is ServerException) rethrow;
      throw const ServerException('Failed to fetch announcement');
    }
  }

  @override
  Future<void> createAnnouncement(AnnouncementModel announcement) async {
    try {
      await _firestore
          .collection(FirebaseConstants.announcementsCollection)
          .doc(announcement.id)
          .set(announcement.toJson());

      debugPrint('Announcement created: ${announcement.id}');

      try {
        final callable = _functions.httpsCallable('sendAnnouncementNotification');
        await callable.call({
          'announcementId': announcement.id,
          'title': announcement.title,
          'body': announcement.message,
          'authorName': announcement.authorName,
        });
        debugPrint('Push notification trigger called for announcement: ${announcement.id}');
      } catch (e) {
        debugPrint('Optional push trigger failed (function may be missing): $e');
      }
    } catch (e) {
      debugPrint('Error creating announcement: $e');
      throw const ServerException('Failed to create announcement');
    }
  }

  @override
  Future<void> deleteAnnouncement(String id) async {
    try {
      await _firestore
          .collection(FirebaseConstants.announcementsCollection)
          .doc(id)
          .delete();

      debugPrint('Announcement deleted: $id');
    } catch (e) {
      debugPrint('Error deleting announcement: $e');
      throw const ServerException('Failed to delete announcement');
    }
  }

  @override
  Stream<List<AnnouncementModel>> watchAnnouncements() {
    try {
      return _firestore
          .collection(FirebaseConstants.announcementsCollection)
          .orderBy(FirebaseConstants.timestampField, descending: true)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs
                .map((doc) => AnnouncementModel.fromJson(doc.data()))
                .toList();
          });
    } catch (e) {
      debugPrint('Error watching announcements: $e');
      throw const ServerException('Failed to watch announcements');
    }
  }
}
