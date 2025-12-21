/// 封面缓存管理器
library;

import 'dart:collection';
import 'dart:typed_data';

import 'package:flutter/material.dart';

/// 封面缓存管理器
///
/// 负责管理视频封面图片的内存缓存，实现 LRU 缓存策略
class CoverCacheManager {
  static final CoverCacheManager _instance = CoverCacheManager._internal();
  factory CoverCacheManager() => _instance;

  CoverCacheManager._internal();

  /// 使用 LinkedHashMap 实现 LRU 缓存策略
  final LinkedHashMap<String, Uint8List> _memoryCache = LinkedHashMap();
  static const int _maxMemoryCacheSize = 20; // 增加缓存大小到20个

  /// 内存限制（10MB）
  static const int _maxCacheBytes = 10 * 1024 * 1024; // 10MB
  int _currentCacheBytes = 0;

  /// 添加到缓存（带大小检查）
  void addToCache(String url, Uint8List data) {
    // 如果已存在，先移除
    _memoryCache.remove(url);

    // 检查并清理超出内存限制的缓存
    _cleanupCacheIfNeeded(data.length);

    // 添加新缓存
    _memoryCache[url] = data;
    _currentCacheBytes += data.length;

    debugPrint(
      '缓存封面: ${_memoryCache.length}个, 总大小: ${(_currentCacheBytes / 1024 / 1024).toStringAsFixed(2)}MB',
    );
  }

  /// 清理缓存以容纳新数据
  void _cleanupCacheIfNeeded(int newSize) {
    while (_currentCacheBytes + newSize > _maxCacheBytes &&
        _memoryCache.isNotEmpty) {
      final oldestUrl = _memoryCache.keys.first;
      final oldestData = _memoryCache.remove(oldestUrl)!;
      _currentCacheBytes -= oldestData.length;
      debugPrint(
        '清理缓存: $oldestUrl, 释放: ${(oldestData.length / 1024).toStringAsFixed(2)}KB',
      );
    }
  }

  /// 从缓存获取（访问时更新LRU）
  Uint8List? getFromCache(String url) {
    if (!_memoryCache.containsKey(url)) {
      return null;
    }

    // 将访问的项移到最后（LRU）
    final data = _memoryCache.remove(url);
    _memoryCache[url] = data!;
    return data;
  }

  /// 检查是否已缓存
  bool isCached(String url) {
    return _memoryCache.containsKey(url);
  }

  /// 获取缓存大小
  int get cacheSize => _memoryCache.length;

  /// 获取当前缓存字节大小
  int get currentCacheBytes => _currentCacheBytes;

  /// 清理指定URL的缓存
  void clearCache(String url) {
    final data = _memoryCache.remove(url);
    if (data != null) {
      _currentCacheBytes -= data.length;
    }
  }

  /// 清理所有缓存
  void clearAllCache() {
    _memoryCache.clear();
    _currentCacheBytes = 0;
  }

  /// 获取所有缓存的URL
  List<String> get cachedUrls => _memoryCache.keys.toList();

  /// 检查内存使用情况
  String get memoryUsage {
    final mb = _currentCacheBytes / 1024 / 1024;
    return '${mb.toStringAsFixed(2)}MB / ${(_maxCacheBytes / 1024 / 1024).toStringAsFixed(2)}MB';
  }
}
