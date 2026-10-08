import 'package:equatable/equatable.dart';

/// Metadata for cached entries
class CacheMetadata extends Equatable {
  final DateTime lastUpdated;
  final DateTime? expiresAt;
  final String source; // 'network', 'cache', 'persistent'
  final int version;
  final bool isPersistent;
  final int? sizeBytes;

  const CacheMetadata({
    required this.lastUpdated,
    this.expiresAt,
    required this.source,
    this.version = 1,
    this.isPersistent = false,
    this.sizeBytes,
  });

  /// Check if the cached data is still valid
  bool get isValid =>
      isPersistent ||
      (expiresAt != null && DateTime.now().isBefore(expiresAt!));

  /// Check if the cached data has expired
  bool get isExpired => !isValid;

  /// Get age of cached data
  Duration get age => DateTime.now().difference(lastUpdated);

  /// Format age as human-readable string
  String get ageFormatted {
    final age = this.age;
    if (age.inMinutes < 1) return 'Just now';
    if (age.inHours < 1) return '${age.inMinutes}m ago';
    if (age.inDays < 1) return '${age.inHours}h ago';
    if (age.inDays < 7) return '${age.inDays}d ago';
    return '${(age.inDays / 7).floor()}w ago';
  }

  CacheMetadata copyWith({
    DateTime? lastUpdated,
    DateTime? expiresAt,
    String? source,
    int? version,
    bool? isPersistent,
    int? sizeBytes,
  }) {
    return CacheMetadata(
      lastUpdated: lastUpdated ?? this.lastUpdated,
      expiresAt: expiresAt ?? this.expiresAt,
      source: source ?? this.source,
      version: version ?? this.version,
      isPersistent: isPersistent ?? this.isPersistent,
      sizeBytes: sizeBytes ?? this.sizeBytes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lastUpdated': lastUpdated.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
      'source': source,
      'version': version,
      'isPersistent': isPersistent,
      'sizeBytes': sizeBytes,
    };
  }

  factory CacheMetadata.fromJson(Map<String, dynamic> json) {
    return CacheMetadata(
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'] as String)
          : null,
      source: json['source'] as String? ?? 'cache',
      version: json['version'] as int? ?? 1,
      isPersistent: json['isPersistent'] as bool? ?? false,
      sizeBytes: json['sizeBytes'] as int?,
    );
  }

  @override
  List<Object?> get props => [
    lastUpdated,
    expiresAt,
    source,
    version,
    isPersistent,
    sizeBytes,
  ];
}
