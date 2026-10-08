// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NotificationModel _$NotificationModelFromJson(Map<String, dynamic> json) =>
    NotificationModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      type: $enumDecode(_$NotificationTypeEnumMap, json['type']),
      title: json['title'] as String,
      message: json['message'] as String,
      data: json['data'] as Map<String, dynamic>? ?? const {},
      isRead: json['isRead'] as bool? ?? false,
      timestamp: DateTime.parse(json['timestamp'] as String),
      actionUrl: json['actionUrl'] as String?,
    );

Map<String, dynamic> _$NotificationModelToJson(NotificationModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'type': _$NotificationTypeEnumMap[instance.type],
      'title': instance.title,
      'message': instance.message,
      'data': instance.data,
      'isRead': instance.isRead,
      'timestamp': instance.timestamp.toIso8601String(),
      'actionUrl': instance.actionUrl,
    };

const _$NotificationTypeEnumMap = {
  NotificationType.quiz: 'quiz',
  NotificationType.announcement: 'announcement',
  NotificationType.system: 'system',
  NotificationType.submission: 'submission',
};
