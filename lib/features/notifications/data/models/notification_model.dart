import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/entities/notification_type.dart';

part 'notification_model.g.dart';

@JsonSerializable()
class NotificationModel extends AppNotification {
  const NotificationModel({
    required super.id,
    required super.userId,
    required super.type,
    required super.title,
    required super.message,
    super.data,
    super.isRead,
    required super.timestamp,
    super.actionUrl,
  });

  /// Create from JSON
  factory NotificationModel.fromJson(Map<String, dynamic> json) =>
      _$NotificationModelFromJson(json);

  /// Convert to JSON
  Map<String, dynamic> toJson() => _$NotificationModelToJson(this);

  /// Create from Firestore document
  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      userId: data['userId'] as String,
      type: NotificationType.fromString(data['type'] as String),
      title: data['title'] as String,
      message: data['message'] as String,
      data: Map<String, dynamic>.from(data['data'] as Map? ?? {}),
      isRead: data['isRead'] as bool? ?? false,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      actionUrl: data['actionUrl'] as String?,
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'type': type.name,
      'title': title,
      'message': message,
      'data': data,
      'isRead': isRead,
      'timestamp': Timestamp.fromDate(timestamp),
      if (actionUrl != null) 'actionUrl': actionUrl,
    };
  }

  /// Create from entity
  factory NotificationModel.fromEntity(AppNotification notification) {
    return NotificationModel(
      id: notification.id,
      userId: notification.userId,
      type: notification.type,
      title: notification.title,
      message: notification.message,
      data: notification.data,
      isRead: notification.isRead,
      timestamp: notification.timestamp,
      actionUrl: notification.actionUrl,
    );
  }
}
