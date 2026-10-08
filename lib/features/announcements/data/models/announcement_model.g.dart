// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'announcement_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AnnouncementModel _$AnnouncementModelFromJson(Map<String, dynamic> json) =>
    AnnouncementModel(
      id: json['id'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      authorId: json['authorId'] as String,
      authorName: json['authorName'] as String,
      timestamp: AnnouncementModel._timestampFromJson(json['timestamp']),
      isPinned: json['isPinned'] as bool? ?? false,
    );

Map<String, dynamic> _$AnnouncementModelToJson(AnnouncementModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'message': instance.message,
      'authorId': instance.authorId,
      'authorName': instance.authorName,
      'timestamp': AnnouncementModel._timestampToJson(instance.timestamp),
      'isPinned': instance.isPinned,
    };
