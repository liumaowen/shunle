/// 短剧缓存管理器
library;

import '../widgets/video_data.dart';

/// 短剧缓存管理器
/// 用于缓存短剧详情和集数数据，避免重复请求
class DramaCacheManager {
  static final DramaCacheManager _instance = DramaCacheManager._internal();

  factory DramaCacheManager() => _instance;

  DramaCacheManager._internal();

  /// 缓存存储
  final Map<String, VideoData> _dramaCache = {};

  /// 缓存过期时间（毫秒）
  static const Duration _cacheExpiry = Duration(hours: 1);

  /// 缓存时间记录
  final Map<String, DateTime> _cacheTimestamps = {};

  /// 是否启用缓存
  bool _enabled = true;

  /// 启用或禁用缓存
  void setEnabled(bool enabled) {
    _enabled = enabled;
    if (!enabled) {
      clearCache();
    }
  }

  /// 是否启用缓存
  bool get enabled => _enabled;

  /// 缓存单个短剧
  ///
  /// 参数:
  /// - dramaId: 短剧ID
  /// - drama: 短剧数据
  ///
  void cacheDrama(String dramaId, VideoData drama) {
    if (!_enabled) return;

    _dramaCache[dramaId] = drama;
    _cacheTimestamps[dramaId] = DateTime.now();
  }

  /// 获取缓存的短剧
  ///
  /// 参数:
  /// - dramaId: 短剧ID
  ///
  /// 返回:
  /// - VideoData 缓存的短剧数据，如果不存在或已过期则返回 null
  ///
  VideoData? getCachedDrama(String dramaId) {
    if (!_enabled || !_dramaCache.containsKey(dramaId)) {
      return null;
    }

    // 检查是否过期
    final timestamp = _cacheTimestamps[dramaId];
    if (timestamp == null) {
      return null;
    }

    if (DateTime.now().difference(timestamp) > _cacheExpiry) {
      // 缓存已过期，移除
      removeDrama(dramaId);
      return null;
    }

    return _dramaCache[dramaId];
  }

  /// 检查是否存在有效的缓存
  ///
  /// 参数:
  /// - dramaId: 短剧ID
  ///
  /// 返回:
  /// - bool 是否存在有效缓存
  ///
  bool hasValidCache(String dramaId) {
    return getCachedDrama(dramaId) != null;
  }

  /// 获取缓存的集数列表
  ///
  /// 参数:
  /// - dramaId: 短剧ID
  ///
  /// 返回:
  /// - List<EpisodeInfo> 缓存的集数列表，如果没有缓存则返回空列表
  ///
  List<EpisodeInfo>? getCachedEpisodes(String dramaId) {
    final drama = getCachedDrama(dramaId);
    return drama?.episodes;
  }

  /// 预缓存短剧集数
  ///
  /// 参数:
  /// - dramaId: 短剧ID
  /// - episodes: 集数列表
  ///
  void preCacheEpisodes(String dramaId, List<EpisodeInfo> episodes) {
    if (!_enabled) return;

    final drama = getCachedDrama(dramaId);
    if (drama != null) {
      // 创建新的短剧数据，更新集数列表
      final updatedDrama = VideoData(
        id: drama.id,
        description: drama.description,
        duration: drama.duration,
        coverUrl: drama.coverUrl,
        videoUrl: drama.videoUrl,
        category: drama.category,
        contentType: drama.contentType,
        totalEpisodes: drama.totalEpisodes,
        currentEpisode: drama.currentEpisode,
        episodes: episodes,
      );

      cacheDrama(dramaId, updatedDrama);
    }
  }

  /// 移除单个短剧缓存
  ///
  /// 参数:
  /// - dramaId: 短剧ID
  ///
  void removeDrama(String dramaId) {
    _dramaCache.remove(dramaId);
    _cacheTimestamps.remove(dramaId);
  }

  /// 清除所有缓存
  void clearCache() {
    _dramaCache.clear();
    _cacheTimestamps.clear();
  }

  /// 获取缓存统计信息
  Map<String, dynamic> getCacheStats() {
    final now = DateTime.now();
    final expiredCount = _cacheTimestamps.values.where((timestamp) {
      return now.difference(timestamp) > _cacheExpiry;
    }).length;

    return {
      'enabled': _enabled,
      'totalCached': _dramaCache.length,
      'expiredCount': expiredCount,
      'sizeInMB': (_dramaCache.length * 1024 * 0.5).toStringAsFixed(2), // 估算每个短剧约0.5MB
    };
  }

  /// 清理过期缓存
  void cleanupExpiredCache() {
    if (!_enabled) return;

    final now = DateTime.now();
    final expiredKeys = <String>[];

    for (final entry in _cacheTimestamps.entries) {
      if (now.difference(entry.value) > _cacheExpiry) {
        expiredKeys.add(entry.key);
      }
    }

    for (final key in expiredKeys) {
      removeDrama(key);
    }
  }

  /// 批量预加载短剧信息
  ///
  /// 参数:
  /// - dramaIds: 需要预加载的短剧ID列表
  /// - loadFunction: 加载函数，用于获取短剧数据
  ///
  Future<void> preLoadDramas(
    List<String> dramaIds,
    Future<VideoData> Function(String) loadFunction,
  ) async {
    if (!_enabled) return;

    for (final dramaId in dramaIds) {
      // 如果没有缓存或已过期，则预加载
      if (!hasValidCache(dramaId)) {
        try {
          final drama = await loadFunction(dramaId);
          cacheDrama(dramaId, drama);
        } catch (e) {
          // 预加载失败，跳过
          continue;
        }
      }
    }
  }
}