import 'package:equatable/equatable.dart';
import 'cache_metadata.dart';

/// Wrapper class for cached data with metadata
class CachedData<T> extends Equatable {
  final T data;
  final DateTime timestamp;
  final DateTime expiresAt;
  final int version;

  const CachedData({
    required this.data,
    required this.timestamp,
    required this.expiresAt,
    this.version = 1,
  });

  /// Check if the cached data is still valid
  bool get isValid => DateTime.now().isBefore(expiresAt);

  /// Check if the cached data has expired
  bool get isExpired => !isValid;

  /// Create a new CachedData with updated data
  CachedData<T> copyWith({
    T? data,
    DateTime? timestamp,
    DateTime? expiresAt,
    int? version,
  }) {
    return CachedData<T>(
      data: data ?? this.data,
      timestamp: timestamp ?? this.timestamp,
      expiresAt: expiresAt ?? this.expiresAt,
      version: version ?? this.version,
    );
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson(Map<String, dynamic> Function(T) toJsonT) {
    return {
      'data': toJsonT(data),
      'timestamp': timestamp.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
      'version': version,
    };
  }

  /// Create from JSON
  factory CachedData.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    return CachedData<T>(
      data: fromJsonT(json['data'] as Map<String, dynamic>),
      timestamp: DateTime.parse(json['timestamp'] as String),
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      version: json['version'] as int? ?? 1,
    );
  }

  @override
  List<Object?> get props => [data, timestamp, expiresAt, version];
}

/// Wrapper for cached data with metadata
class CachedDataWithMetadata<T> extends Equatable {
  final CachedData<T> data;
  final CacheMetadata? metadata;

  const CachedDataWithMetadata({required this.data, this.metadata});

  @override
  List<Object?> get props => [data, metadata];
}

/// Cache statistics
class CacheStatistics extends Equatable {
  final int totalEntries;
  final int expiredEntries;
  final int persistentEntries;
  final int totalSizeBytes;
  final DateTime? oldestEntry;
  final DateTime? newestEntry;

  const CacheStatistics({
    required this.totalEntries,
    required this.expiredEntries,
    required this.persistentEntries,
    required this.totalSizeBytes,
    this.oldestEntry,
    this.newestEntry,
  });

  /// Get human-readable size
  String get sizeFormatted {
    if (totalSizeBytes < 1024) return '$totalSizeBytes B';
    if (totalSizeBytes < 1024 * 1024) {
      return '${(totalSizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(totalSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  List<Object?> get props => [
    totalEntries,
    expiredEntries,
    persistentEntries,
    totalSizeBytes,
    oldestEntry,
    newestEntry,
  ];
}
