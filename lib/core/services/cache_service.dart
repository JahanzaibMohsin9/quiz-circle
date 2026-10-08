import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';
import '../models/cache_models.dart';
import '../models/cache_metadata.dart';

/// Service for managing local cache using Hive
class CacheService {
  static const String _cacheBoxName = 'app_cache';
  static const String _metadataBoxName = 'cache_metadata';
  static const int _defaultCacheVersion = 1;
  static const int _maxCacheSizeBytes = 80 * 1024 * 1024; // 80 MB

  Box? _cacheBox;
  Box? _metadataBox;

  /// Initialize Hive and open cache box
  Future<void> init() async {
    try {
      await Hive.initFlutter();
      _cacheBox = await Hive.openBox(_cacheBoxName);
      _metadataBox = await Hive.openBox(_metadataBoxName);
      debugPrint('CacheService: Initialized successfully');

      // Clean up expired entries on startup
      await cleanExpired();

      // Check and enforce cache size limit
      await _enforceCacheSizeLimit();
    } catch (e) {
      debugPrint('CacheService: Failed to initialize - $e');
      rethrow;
    }
  }

  /// Get cached data by key
  /// Returns null if key doesn't exist or data has expired
  Future<T?> get<T>({
    required String key,
    required T Function(Map<String, dynamic>) fromJson,
  }) async {
    try {
      final box = _getBox();
      final cachedJson = box.get(key);

      if (cachedJson == null) {
        debugPrint('CacheService: Cache miss for key: $key');
        return null;
      }

      final cachedData = CachedData<T>.fromJson(
        cachedJson as Map<String, dynamic>,
        fromJson,
      );

      // Check if data has expired
      if (cachedData.isExpired) {
        debugPrint('CacheService: Cache expired for key: $key');
        await delete(key);
        return null;
      }

      debugPrint('CacheService: Cache hit for key: $key');
      return cachedData.data;
    } catch (e) {
      debugPrint('CacheService: Error getting cache for key $key - $e');
      return null;
    }
  }

  /// Set cached data with TTL (Time To Live)
  Future<void> set<T>({
    required String key,
    required T data,
    required Map<String, dynamic> Function(T) toJson,
    Duration ttl = const Duration(minutes: 5),
    int version = _defaultCacheVersion,
  }) async {
    try {
      final box = _getBox();
      final now = DateTime.now();

      final cachedData = CachedData<T>(
        data: data,
        timestamp: now,
        expiresAt: now.add(ttl),
        version: version,
      );

      await box.put(key, cachedData.toJson(toJson));
      debugPrint(
        'CacheService: Cached data for key: $key (TTL: ${ttl.inMinutes}m)',
      );
    } catch (e) {
      debugPrint('CacheService: Error setting cache for key $key - $e');
      rethrow;
    }
  }

  /// Delete cached data by key
  Future<void> delete(String key) async {
    try {
      final box = _getBox();
      await box.delete(key);
      debugPrint('CacheService: Deleted cache for key: $key');
    } catch (e) {
      debugPrint('CacheService: Error deleting cache for key $key - $e');
    }
  }

  /// Clear all cached data
  Future<void> clearAll() async {
    try {
      final box = _getBox();
      await box.clear();
      debugPrint('CacheService: Cleared all cache');
    } catch (e) {
      debugPrint('CacheService: Error clearing cache - $e');
    }
  }

  /// Check if a key exists in cache
  bool has(String key) {
    try {
      final box = _getBox();
      return box.containsKey(key);
    } catch (e) {
      debugPrint('CacheService: Error checking cache key $key - $e');
      return false;
    }
  }

  /// Get all cache keys
  List<String> getAllKeys() {
    try {
      final box = _getBox();
      return box.keys.cast<String>().toList();
    } catch (e) {
      debugPrint('CacheService: Error getting all keys - $e');
      return [];
    }
  }

  /// Clean up expired cache entries
  Future<void> cleanExpired() async {
    try {
      final box = _getBox();
      final keysToDelete = <String>[];

      for (final key in box.keys) {
        try {
          final cachedJson = box.get(key);
          if (cachedJson != null && cachedJson is Map) {
            final expiresAtStr = cachedJson['expiresAt'] as String?;
            if (expiresAtStr != null) {
              final expiresAt = DateTime.parse(expiresAtStr);
              if (DateTime.now().isAfter(expiresAt)) {
                keysToDelete.add(key as String);
              }
            }
          }
        } catch (e) {
          // If we can't parse the entry, mark it for deletion
          keysToDelete.add(key as String);
        }
      }

      for (final key in keysToDelete) {
        await box.delete(key);
      }

      debugPrint(
        'CacheService: Cleaned ${keysToDelete.length} expired entries',
      );
    } catch (e) {
      debugPrint('CacheService: Error cleaning expired cache - $e');
    }
  }

  /// Get cache box size in bytes (approximate)
  int getCacheSize() {
    try {
      final box = _getBox();
      return box.length;
    } catch (e) {
      debugPrint('CacheService: Error getting cache size - $e');
      return 0;
    }
  }

  /// Close the cache box
  Future<void> close() async {
    try {
      await _cacheBox?.close();
      await _metadataBox?.close();
      debugPrint('CacheService: Closed cache boxes');
    } catch (e) {
      debugPrint('CacheService: Error closing cache boxes - $e');
    }
  }

  /// Get the cache box, throw if not initialized
  Box _getBox() {
    if (_cacheBox == null || !_cacheBox!.isOpen) {
      throw Exception('CacheService not initialized. Call init() first.');
    }
    return _cacheBox!;
  }

  /// Get the metadata box, throw if not initialized
  Box _getMetadataBox() {
    if (_metadataBox == null || !_metadataBox!.isOpen) {
      throw Exception('CacheService not initialized. Call init() first.');
    }
    return _metadataBox!;
  }

  /// Set persistent cache data (never expires)
  Future<void> setPersistent<T>({
    required String key,
    required T data,
    required Map<String, dynamic> Function(T) toJson,
    int version = _defaultCacheVersion,
  }) async {
    try {
      final box = _getBox();
      final metadataBox = _getMetadataBox();
      final now = DateTime.now();

      final cachedData = CachedData<T>(
        data: data,
        timestamp: now,
        expiresAt: now.add(
          const Duration(days: 365 * 10),
        ), // Effectively never expires
        version: version,
      );

      final jsonData = cachedData.toJson(toJson);
      await box.put(key, jsonData);

      // Store metadata
      final metadata = CacheMetadata(
        lastUpdated: now,
        source: 'persistent',
        version: version,
        isPersistent: true,
        sizeBytes: _estimateSize(jsonData),
      );
      await metadataBox.put(key, metadata.toJson());

      debugPrint('CacheService: Cached persistent data for key: $key');

      // Check cache size after adding
      await _enforceCacheSizeLimit();
    } catch (e) {
      debugPrint(
        'CacheService: Error setting persistent cache for key $key - $e',
      );
      rethrow;
    }
  }

  /// Set cache data with extended TTL
  Future<void> setWithExtendedTTL<T>({
    required String key,
    required T data,
    required Map<String, dynamic> Function(T) toJson,
    required Duration ttl,
    int version = _defaultCacheVersion,
  }) async {
    try {
      final box = _getBox();
      final metadataBox = _getMetadataBox();
      final now = DateTime.now();
      final expiresAt = now.add(ttl);

      final cachedData = CachedData<T>(
        data: data,
        timestamp: now,
        expiresAt: expiresAt,
        version: version,
      );

      final jsonData = cachedData.toJson(toJson);
      await box.put(key, jsonData);

      // Store metadata
      final metadata = CacheMetadata(
        lastUpdated: now,
        expiresAt: expiresAt,
        source: 'network',
        version: version,
        sizeBytes: _estimateSize(jsonData),
      );
      await metadataBox.put(key, metadata.toJson());

      debugPrint(
        'CacheService: Cached data for key: $key (TTL: ${ttl.inHours}h)',
      );

      // Check cache size after adding
      await _enforceCacheSizeLimit();
    } catch (e) {
      debugPrint('CacheService: Error setting cache for key $key - $e');
      rethrow;
    }
  }

  /// Get cache metadata for a key
  Future<CacheMetadata?> getMetadata(String key) async {
    try {
      final metadataBox = _getMetadataBox();
      final metadataJson = metadataBox.get(key);

      if (metadataJson == null) {
        return null;
      }

      return CacheMetadata.fromJson(metadataJson as Map<String, dynamic>);
    } catch (e) {
      debugPrint('CacheService: Error getting metadata for key $key - $e');
      return null;
    }
  }

  /// Get cached data with metadata (even if expired)
  Future<CachedDataWithMetadata<T>?> getWithMetadata<T>({
    required String key,
    required T Function(Map<String, dynamic>) fromJson,
  }) async {
    try {
      final box = _getBox();
      final cachedJson = box.get(key);

      if (cachedJson == null) {
        return null;
      }

      final cachedData = CachedData<T>.fromJson(
        cachedJson as Map<String, dynamic>,
        fromJson,
      );

      final metadata = await getMetadata(key);

      return CachedDataWithMetadata<T>(data: cachedData, metadata: metadata);
    } catch (e) {
      debugPrint(
        'CacheService: Error getting cache with metadata for key $key - $e',
      );
      return null;
    }
  }

  /// Batch set multiple cache entries
  /// Uses parallel execution for better performance
  Future<void> setMultiple<T>({
    required Map<String, T> items,
    required Map<String, dynamic> Function(T) toJson,
    Duration ttl = const Duration(minutes: 5),
    int version = _defaultCacheVersion,
  }) async {
    await Future.wait(
      items.entries.map(
        (entry) => set<T>(
          key: entry.key,
          data: entry.value,
          toJson: toJson,
          ttl: ttl,
          version: version,
        ),
      ),
    );
  }

  /// Batch get multiple cache entries
  /// Uses parallel execution for better performance
  Future<Map<String, T?>> getMultiple<T>({
    required List<String> keys,
    required T Function(Map<String, dynamic>) fromJson,
  }) async {
    final futures = keys.map(
      (key) => get<T>(
        key: key,
        fromJson: fromJson,
      ).then((value) => MapEntry(key, value)),
    );

    final entries = await Future.wait(futures);
    return Map.fromEntries(entries);
  }

  /// Get total cache size in bytes
  Future<int> getTotalCacheSize() async {
    try {
      final metadataBox = _getMetadataBox();
      int totalSize = 0;

      for (final key in metadataBox.keys) {
        final metadataJson = metadataBox.get(key);
        if (metadataJson != null && metadataJson is Map) {
          final metadata = CacheMetadata.fromJson(
            metadataJson.cast<String, dynamic>(),
          );
          totalSize += metadata.sizeBytes ?? 0;
        }
      }

      return totalSize;
    } catch (e) {
      debugPrint('CacheService: Error getting total cache size - $e');
      return 0;
    }
  }

  /// Get cache statistics
  Future<CacheStatistics> getStatistics() async {
    try {
      final box = _getBox();
      final metadataBox = _getMetadataBox();

      final int totalEntries = box.length;
      int expiredEntries = 0;
      int persistentEntries = 0;
      int totalSize = 0;
      DateTime? oldestEntry;
      DateTime? newestEntry;

      for (final key in metadataBox.keys) {
        final metadataJson = metadataBox.get(key);
        if (metadataJson != null && metadataJson is Map) {
          final metadata = CacheMetadata.fromJson(
            metadataJson.cast<String, dynamic>(),
          );

          if (metadata.isPersistent) {
            persistentEntries++;
          }

          if (metadata.isExpired) {
            expiredEntries++;
          }

          totalSize += metadata.sizeBytes ?? 0;

          if (oldestEntry == null ||
              metadata.lastUpdated.isBefore(oldestEntry)) {
            oldestEntry = metadata.lastUpdated;
          }

          if (newestEntry == null ||
              metadata.lastUpdated.isAfter(newestEntry)) {
            newestEntry = metadata.lastUpdated;
          }
        }
      }

      return CacheStatistics(
        totalEntries: totalEntries,
        expiredEntries: expiredEntries,
        persistentEntries: persistentEntries,
        totalSizeBytes: totalSize,
        oldestEntry: oldestEntry,
        newestEntry: newestEntry,
      );
    } catch (e) {
      debugPrint('CacheService: Error getting cache statistics - $e');
      return const CacheStatistics(
        totalEntries: 0,
        expiredEntries: 0,
        persistentEntries: 0,
        totalSizeBytes: 0,
      );
    }
  }

  /// Enforce cache size limit by removing oldest non-persistent entries
  Future<void> _enforceCacheSizeLimit() async {
    try {
      final totalSize = await getTotalCacheSize();

      if (totalSize <= _maxCacheSizeBytes) {
        return;
      }

      debugPrint(
        'CacheService: Cache size ($totalSize bytes) exceeds limit ($_maxCacheSizeBytes bytes). Cleaning up...',
      );

      final box = _getBox();
      final metadataBox = _getMetadataBox();

      // Get all entries with metadata, sorted by last updated (oldest first)
      final entries = <MapEntry<String, CacheMetadata>>[];

      for (final key in metadataBox.keys) {
        final metadataJson = metadataBox.get(key);
        if (metadataJson != null && metadataJson is Map) {
          final metadata = CacheMetadata.fromJson(
            metadataJson.cast<String, dynamic>(),
          );

          // Don't delete persistent entries
          if (!metadata.isPersistent) {
            entries.add(MapEntry(key as String, metadata));
          }
        }
      }

      // Sort by last updated (oldest first)
      entries.sort(
        (a, b) => a.value.lastUpdated.compareTo(b.value.lastUpdated),
      );

      // Delete oldest entries until we're under the limit
      int currentSize = totalSize;
      for (final entry in entries) {
        if (currentSize <= _maxCacheSizeBytes) {
          break;
        }

        await box.delete(entry.key);
        await metadataBox.delete(entry.key);

        currentSize -= entry.value.sizeBytes ?? 0;
        debugPrint('CacheService: Evicted cache entry: ${entry.key}');
      }

      final newSize = await getTotalCacheSize();
      debugPrint(
        'CacheService: Cache cleanup complete. New size: $newSize bytes',
      );
    } catch (e) {
      debugPrint('CacheService: Error enforcing cache size limit - $e');
    }
  }

  /// Estimate size of JSON data in bytes
  int _estimateSize(Map<String, dynamic> json) {
    try {
      // Simple estimation based on JSON string length
      final jsonString = json.toString();
      return jsonString.length * 2; // Approximate UTF-16 encoding
    } catch (e) {
      return 0;
    }
  }
}

/// Cache key constants
class CacheKeys {
  static const String systemAnalytics = 'system_analytics';
  static String quizAnalytics(String quizId) => 'quiz_analytics_$quizId';
  static String userAnalytics(String userId) => 'user_analytics_$userId';
  static String globalLeaderboard = 'global_leaderboard';
  static String quizLeaderboard(String quizId) => 'quiz_leaderboard_$quizId';
  static const String recentActivity = 'recent_activity';
}
