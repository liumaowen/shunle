/// 短剧预加载管理器
library;

import 'dart:math';
import '../widgets/video_data.dart';
import 'package:flutter/foundation.dart';

/// 短剧预加载管理器
/// 负责预加载短剧集数的封面和相关信息
class DramaPreloadManager {
  static final DramaPreloadManager _instance = DramaPreloadManager._internal();

  factory DramaPreloadManager() => _instance;

  DramaPreloadManager._internal();

  /// 预加载任务队列
  final List<_PreloadTask> _preloadQueue = [];

  /// 当前正在进行的预加载任务
  _PreloadTask? _currentTask;

  /// 是否启用预加载
  bool _enabled = true;

  /// 最大并发预加载数量
  static const int _maxConcurrentPreloads = 2;

  /// 预加载范围：前后各多少集
  static const int _preloadRange = 3;

  /// 启用或禁用预加载
  void setEnabled(bool enabled) {
    _enabled = enabled;
    if (!enabled) {
      clearQueue();
    }
  }

  /// 是否启用预加载
  bool get enabled => _enabled;

  /// 清空预加载队列
  void clearQueue() {
    _preloadQueue.clear();
    _currentTask = null;
  }

  /// 预加载短剧集数
  ///
  /// 参数:
  /// - dramaId: 短剧ID
  /// - totalEpisodes: 总集数
  /// - currentEpisode: 当前播放集数
  /// - episodeLoadFunction: 加载单集信息的函数
  ///
  void preloadDramaEpisodes({
    required String dramaId,
    required int totalEpisodes,
    required int currentEpisode,
    required Future<EpisodeInfo> Function(String) episodeLoadFunction,
  }) {
    if (!_enabled) return;

    // 清除之前的队列
    clearQueue();

    // 计算需要预加载的集数范围
    final start = max(1, currentEpisode - _preloadRange);
    final end = min(totalEpisodes, currentEpisode + _preloadRange);

    // 添加预加载任务
    for (int i = start; i <= end; i++) {
      // 跳过当前正在播放的集数
      if (i == currentEpisode) continue;

      final episodeId = '${dramaId}_episode_$i';
      _preloadQueue.add(_PreloadTask(
        episodeId: episodeId,
        priority: i == currentEpisode - 1 || i == currentEpisode + 1 ? 1 : 0,
        loadFunction: () => episodeLoadFunction(episodeId),
      ));
    }

    // 按优先级排序
    _preloadQueue.sort((a, b) => b.priority.compareTo(a.priority));

    // 开始预加载
    _startPreloading();
  }

  /// 开始执行预加载任务
  void _startPreloading() {
    if (!_enabled || _currentTask != null) return;

    // 检查并发限制
    final activePreloads = _preloadQueue.where((task) => task.isRunning).length;
    if (activePreloads >= _maxConcurrentPreloads) {
      return;
    }

    // 获取下一个任务
    final nextTaskIndex = _preloadQueue.indexWhere(
      (task) => !task.isRunning && !task.isCompleted,
    );

    if (nextTaskIndex != -1) {
      final nextTask = _preloadQueue[nextTaskIndex];
      _currentTask = nextTask;
      nextTask.run().then((_) {
        _currentTask = null;
        _startPreloading(); // 继续下一个任务
      }).catchError((error) {
        _currentTask = null;
        _startPreloading(); // 继续下一个任务，忽略错误
      });
    }
  }

  /// 预加载单个集数信息
  ///
  /// 参数:
  /// - episodeId: 集数ID
  /// - episodeLoadFunction: 加载函数
  ///
  Future<void> preloadEpisode({
    required String episodeId,
    required Future<EpisodeInfo> Function(String) episodeLoadFunction,
  }) async {
    if (!_enabled) return;

    try {
      await episodeLoadFunction(episodeId);
      // 这里可以缓存集数信息
      debugPrint('预加载完成: $episodeId');
    } catch (error) {
      debugPrint('预加载失败: $episodeId, $error');
    }
  }

  /// 取消所有预加载任务
  void cancelAll() {
    clearQueue();
  }
}

/// 预加载任务类
class _PreloadTask {
  final String episodeId;
  final int priority;
  final Future<EpisodeInfo> Function() loadFunction;

  bool _isRunning = false;
  bool _isCompleted = false;

  bool get isRunning => _isRunning;
  bool get isCompleted => _isCompleted;

  _PreloadTask({
    required this.episodeId,
    required this.priority,
    required this.loadFunction,
  });

  Future<void> run() async {
    _isRunning = true;
    try {
      await loadFunction();
      _isCompleted = true;
    } finally {
      _isRunning = false;
    }
  }
}