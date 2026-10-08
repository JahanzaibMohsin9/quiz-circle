import 'package:json_annotation/json_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/announcement.dart';

part 'announcement_model.g.dart';

@JsonSerializable()
class AnnouncementModel {
  final String id;
  final String title;
  final String message;
  final String authorId;
  final String authorName;
  @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
  final DateTime timestamp;
  final bool isPinned;

  const AnnouncementModel({
    required this.id,
    required this.title,
    required this.message,
    required this.authorId,
    required this.authorName,
    required this.timestamp,
    this.isPinned = false,
  });

  factory AnnouncementModel.fromJson(Map<String, dynamic> json) =>
      _$AnnouncementModelFromJson(json);

  Map<String, dynamic> toJson() => _$AnnouncementModelToJson(this);

  /// Convert to domain entity
  Announcement toDomain() => Announcement(
    id: id,
    title: title,
    message: message,
    authorId: authorId,
    authorName: authorName,
    timestamp: timestamp,
    isPinned: isPinned,
  );

  /// Create from domain entity
  factory AnnouncementModel.fromDomain(Announcement announcement) =>
      AnnouncementModel(
        id: announcement.id,
        title: announcement.title,
        message: announcement.message,
        authorId: announcement.authorId,
        authorName: announcement.authorName,
        timestamp: announcement.timestamp,
        isPinned: announcement.isPinned,
      );

  /// Timestamp conversion helpers
  static DateTime _timestampFromJson(dynamic timestamp) {
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    } else if (timestamp is int) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    } else if (timestamp is String) {
      return DateTime.parse(timestamp);
    }
    return DateTime.now();
  }

  static dynamic _timestampToJson(DateTime timestamp) {
    return Timestamp.fromDate(timestamp);
  }
}
