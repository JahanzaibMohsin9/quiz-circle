import 'package:equatable/equatable.dart';

/// Announcement entity
class Announcement extends Equatable {
  final String id;
  final String title;
  final String message;
  final String authorId;
  final String authorName;
  final DateTime timestamp;
  final bool isPinned;

  const Announcement({
    required this.id,
    required this.title,
    required this.message,
    required this.authorId,
    required this.authorName,
    required this.timestamp,
    this.isPinned = false,
  });

  @override
  List<Object?> get props => [
    id,
    title,
    message,
    authorId,
    authorName,
    timestamp,
    isPinned,
  ];
}
