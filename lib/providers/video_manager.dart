// lib/providers/video_manager.dart
import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/video_data.dart';

/// 视频控制器状态
class VideoControllerState {
  final VideoData video;
  final String tabId;
  int listIndex;
  VideoPlayerController? controller;
  bool isVisible = false;
  bool isPlaying = false;
  Duration? lastPosition;
  DateTime lastVisibleTime = DateTime.now();
  DateTime lastAccessTime = DateTime.now();
  double visibility = 0.0;
  String? error;

  // 🚨 新增：标记控制器是否正在初始化中（防止时序问题）
  bool isInitializing = false;

  VideoControllerState({
    required this.video,
    required this.tabId,
    required this.listIndex,
  });
}

/// 全局视频管理器（与你的 VideoListProvider 并存）
class VideoManager extends ChangeNotifier {
  // 使用 LinkedHashMap 保持插入顺序，方便LRU
  final LinkedHashMap<String, VideoControllerState> _videoStates =
      LinkedHashMap();

  String? _currentPlayingId;
  String? _currentTabId;

  // 配置：最多同时存在3个视频控制器
  // ignore: constant_identifier_names
  static const int MAX_CONCURRENT_CONTROLLERS = 3;

  // 获取视频控制器
  Future<VideoPlayerController?> getController({
    required VideoData video,
    required String tabId,
    required int listIndex,
  }) async {
    final String stateId = '${tabId}_${video.id}';
    debugPrint('获取控制器: ${video.description} (Tab: $tabId)(videoId: ${video.id})');

    VideoControllerState? state;

    if (_videoStates.containsKey(stateId)) {
      state = _videoStates[stateId]!;
      state.listIndex = listIndex;

      // 🚨 关键：检查控制器是否仍然有效
      if (state.controller != null) {
        try {
          // 尝试访问一个属性来检查是否已被释放
          final _ = state.controller!.value.isInitialized;
          debugPrint('✅ 复用现有控制器: $stateId');
          state.lastAccessTime = DateTime.now();

          // 更新访问顺序（用于LRU）
          _videoStates.remove(stateId);
          _videoStates[stateId] = state;

          return state.controller;
        } catch (e) {
          debugPrint('⚠️ 控制器无效（可能已被释放），重新创建: $stateId');
          state.controller = null; // 标记为null，触发重新创建
        }
      }
    } else {
      // 创建新的状态
      state = VideoControllerState(
        video: video,
        tabId: tabId,
        listIndex: listIndex,
      );
      _videoStates[stateId] = state;
    }

    // 如果控制器不存在或无效，创建新的
    if (state.controller == null) {
      await _createController(state);
    }

    state.lastAccessTime = DateTime.now();

    // 更新访问顺序
    _videoStates.remove(stateId);
    _videoStates[stateId] = state;
    debugPrint('getController: ${_videoStates.length} 个控制器存在');
    return state.controller;
  }

  Future<void> _createController(VideoControllerState state) async {
    // 🚨 新增：标记正在初始化
    state.isInitializing = true;

    // 如果达到限制，释放最不重要的视频
    if (_getActiveControllerCount() >= MAX_CONCURRENT_CONTROLLERS) {
      await _releaseLeastImportantController();
    }
    if (_getActiveControllerCount() >= MAX_CONCURRENT_CONTROLLERS) {
      await _releaseLeastImportantController();
    }

    try {
      // 🚨 关键修改点：这里使用你的视频URL逻辑
      var videoUrl = state.video.videoUrl;

      // 创建控制器（保持你的现有逻辑）
      VideoPlayerController controller;
      if (videoUrl.startsWith('assets/')) {
        var assetPath = videoUrl.replaceFirst('assets/', '');
        controller = VideoPlayerController.asset(assetPath);
      } else {
        controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
      }

      controller.setLooping(true);

      // 🚨 关键：如果是短剧，需要特殊处理
      if (state.video.isDrama) {
        // 你可以在这里添加短剧特有的初始化逻辑
      }
      controller.addListener(() {
        if (controller.value.hasError) {
          debugPrint('❌ 控制器出现错误: ${state.video.id}');
          state.error = controller.value.errorDescription;
        }
      });
      state.controller = controller;
      final initFuture = controller.initialize();
      final timeoutFuture = Future.delayed(Duration(seconds: 10), () {
        throw TimeoutException('控制器初始化超时');
      });

      await Future.any([initFuture, timeoutFuture]);

      // 初始化后静音
      await controller.setVolume(0.0);

      debugPrint('✅ 创建控制器: ${state.video.id} (Tab: ${state.tabId})');
    } catch (e) {
      debugPrint('❌ 创建控制器失败: ${state.video.id}, error: $e');
      state.error = e.toString();
      state.controller = null;
    } finally {
      // 🚨 新增：清除初始化标记
      state.isInitializing = false;
    }
  }

  /// 🚨 重要：切换到指定视频（供 PageView 调用）
  Future<void> switchToVideo({
    required VideoData video,
    required String tabId,
    required int listIndex,
  }) async {
    // 先验证所有控制器
    validateControllers();

    final stateId = '${tabId}_${video.id}';

    // 更新当前Tab
    _currentTabId = tabId;

    // 暂停当前视频
    if (_currentPlayingId != null &&
        _videoStates.containsKey(_currentPlayingId!)) {
      final currentState = _videoStates[_currentPlayingId!]!;
      if (currentState.controller != null &&
          currentState.controller!.value.isInitialized &&
          currentState.controller!.value.isPlaying) {
        try {
          currentState.controller!.pause();
          currentState.isPlaying = false;
        } catch (e) {
          debugPrint('⚠️ 暂停当前视频失败: $e');
        }
      }
    }

    // 播放新视频
    if (_videoStates.containsKey(stateId)) {
      final newState = _videoStates[stateId]!;
      if (newState.controller != null &&
          newState.controller!.value.isInitialized) {
        try {
          await newState.controller!.setVolume(1.0);
          await newState.controller!.play();
          newState.isPlaying = true;
          _currentPlayingId = stateId;

          // 预加载相邻视频
          _preloadAdjacentVideos(tabId, listIndex);
        } catch (e) {
          debugPrint('❌ 播放新视频失败: $e');
          newState.controller = null;
        }
      }
    }
    debugPrint('switchToVideo: ${_videoStates.length} 个控制器存在');
    notifyListeners();
  }

  /// 预加载相邻视频
  void _preloadAdjacentVideos(String tabId, int centerIndex) {
    final videosInTab = _getVideosInTab(tabId);
    if (videosInTab.isEmpty) return;

    // 按列表位置排序
    videosInTab.sort((a, b) => a.listIndex.compareTo(b.listIndex));

    int? centerIndexInList;
    for (int i = 0; i < videosInTab.length; i++) {
      if (videosInTab[i].listIndex == centerIndex) {
        centerIndexInList = i;
        break;
      }
    }

    if (centerIndexInList == null) return;

    // 预加载前后各1个
    final preloadRange = 1;
    for (int i = 1; i <= preloadRange; i++) {
      final prevIndex = centerIndexInList - i;
      if (prevIndex >= 0) {
        _ensureControllerLoaded(videosInTab[prevIndex]);
      }

      final nextIndex = centerIndexInList + i;
      if (nextIndex < videosInTab.length) {
        _ensureControllerLoaded(videosInTab[nextIndex]);
      }
    }
  }

  Future<void> _ensureControllerLoaded(VideoControllerState state) async {
    if (state.controller == null || !state.controller!.value.isInitialized) {
      await _createController(state);
    }
  }

  /// 释放最不重要的控制器（LRU算法）
  Future<void> _releaseLeastImportantController() async {
    if (_videoStates.isEmpty) return;

    // 找到最久未访问的视频
    String? lruId;
    DateTime? oldestTime;

    for (final entry in _videoStates.entries) {
      // 跳过当前正在播放的视频
      if (entry.key == _currentPlayingId) continue;

      if (oldestTime == null ||
          entry.value.lastAccessTime.isBefore(oldestTime)) {
        oldestTime = entry.value.lastAccessTime;
        lruId = entry.key;
      }
    }

    if (lruId != null && _videoStates.containsKey(lruId)) {
      await _releaseController(_videoStates[lruId]!);
      _videoStates.remove(lruId);
      debugPrint('🗑️ 释放视频资源 (LRU): $lruId');
    }
        debugPrint('releaseLeastImportant: ${_videoStates.length} 个控制器存在');
  }

  Future<void> _releaseController(VideoControllerState state) async {
    if (state.controller != null) {
      try {
        // 保存播放位置
        if (state.controller!.value.isInitialized) {
          state.lastPosition = state.controller!.value.position;
          await _savePlaybackPosition(state.video.id, state.lastPosition!);
        }
        // 先标记为null，再释放
        final controller = state.controller!;
        state.controller = null; // 先标记为null，防止其他代码访问
        state.isPlaying = false;
        // 延迟释放，确保其他操作已完成
        Future.delayed(Duration.zero, () {
          try {
            controller.dispose();
            debugPrint('✅ 成功释放控制器: ${state.video.id}');
          } catch (e) {
            debugPrint('⚠️ 释放控制器时出错（可能已释放）: $e');
          }
        });
      } catch (e) {
        debugPrint('⚠️ 释放控制器时出错: $e');
      } finally {
        state.controller = null;
        state.isPlaying = false;
      }
    }
  }

  List<VideoControllerState> _getVideosInTab(String tabId) {
    return _videoStates.values.where((state) => state.tabId == tabId).toList();
  }

  int _getActiveControllerCount() {
    int count = 0;
    for (final state in _videoStates.values) {
      if (state.controller != null && state.controller!.value.isInitialized) {
        count++;
      }
    }
    return count;
  }

  Future<void> _savePlaybackPosition(String videoId, Duration position) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('playback_$videoId', position.inMilliseconds);
    } catch (e) {
      debugPrint('保存播放位置失败: $e');
    }
  }

  /// 🚨 重要：从管理器获取视频控制器
  VideoPlayerController? getExistingController(String tabId, String videoId) {
    final stateId = '${tabId}_$videoId';
    return _videoStates[stateId]?.controller;
  }

  /// 清理所有资源
  Future<void> disposeAll() async {
    for (final state in _videoStates.values) {
      try {
        state.controller?.dispose();
      } catch (e) {
        debugPrint('⚠️ 释放控制器时出错: $e');
      }
    }
    _videoStates.clear();
    _currentPlayingId = null;
    _currentTabId = null;
  }

  /// 处理视频可见性变化
  void handleVideoVisibility({
    required VideoData video,
    required String tabId,
    required double visibleFraction,
    required int listIndex,
  }) {
    final stateId = '${tabId}_${video.id}';
    final state = _videoStates[stateId];

    if (state == null) {
      debugPrint('⚠️ 视频状态不存在: $stateId，可能已被释放');
      return;
    }

    // 🚨 新增：如果还在初始化中，不处理可见性变化
    if (state.isInitializing) {
      debugPrint('⏳ 控制器正在初始化中，暂不处理可见性变化: $stateId');
      return;
    }

    // 🚨 关键：检查控制器是否仍然有效
    if (state.controller == null) {
      debugPrint('⚠️ 控制器已被释放，忽略可见性变化: $stateId');
      return;
    }

    state.lastVisibleTime = DateTime.now();
    state.visibility = visibleFraction;
    state.listIndex = listIndex;

    final bool isVisible = visibleFraction > 0.5;

    if (isVisible && !state.isVisible) {
      _onVideoBecomeVisible(state);
    } else if (!isVisible && state.isVisible) {
      _onVideoBecomeInvisible(state);
    }

    state.isVisible = isVisible;
  }

  void _onVideoBecomeVisible(VideoControllerState state) {
    debugPrint('🎬 视频变为可见: ${state.video.id}');

    // 🚨 新增：如果还在初始化中，等待初始化完成后再处理
    if (state.isInitializing) {
      debugPrint('⏳ 控制器正在初始化，延迟播放: ${state.video.id}');
      return;
    }

    // 🚨 关键：检查控制器是否仍然有效（未被dispose）
    if (state.controller == null || !state.controller!.value.isInitialized) {
      debugPrint('⚠️ 控制器无效或未初始化，跳过播放: ${state.video.id}');
      return;
    }

    // 暂停当前播放的视频
    if (_currentPlayingId != null &&
        _videoStates.containsKey(_currentPlayingId!)) {
      final currentState = _videoStates[_currentPlayingId!]!;
      // 🚨 关键：检查当前控制器是否仍然有效
      if (currentState.controller != null &&
          currentState.controller!.value.isInitialized &&
          currentState.controller!.value.isPlaying) {
        try {
          currentState.controller!.pause();
          currentState.isPlaying = false;
        } catch (e) {
          debugPrint('⚠️ 暂停视频失败（可能已disposed）: $e');
        }
      }
    }

    // 设置当前播放的视频
    _currentPlayingId = '${state.tabId}_${state.video.id}';

    // 播放视频
    if (state.controller != null && state.controller!.value.isInitialized) {
      try {
        state.controller!.setVolume(1.0);
        state.controller!.play();
        state.isPlaying = true;
        debugPrint('▶️ 开始播放: ${state.video.id}');
      } catch (e) {
        debugPrint('❌ 播放视频失败（可能已disposed）: $e');
        state.controller = null;
      }
    }

    // 预加载相邻视频
    _preloadAdjacentVideos(state.tabId, state.listIndex);

    notifyListeners();
  }

  void _onVideoBecomeInvisible(VideoControllerState state) {
    debugPrint('⏸️ 视频变为不可见: ${state.video.id}');

    if (state.controller != null && state.controller!.value.isInitialized) {
      try {
        // 保存播放位置
        state.lastPosition = state.controller!.value.position;

        // 暂停播放
        state.controller!.pause();
        state.isPlaying = false;

        // 静音
        state.controller!.setVolume(0.0);

        // 如果不是当前播放的视频，考虑释放
        if (_currentPlayingId != '${state.tabId}_${state.video.id}') {
          final timeSinceVisible = DateTime.now().difference(
            state.lastVisibleTime,
          );
          if (timeSinceVisible > Duration(seconds: 30)) {
            // 30秒没看这个视频了，释放资源
            _releaseControllerIfNeeded(state);
          }
        }
      } catch (e) {
        debugPrint('⚠️ 处理视频不可见时出错（可能已disposed）: $e');
      }
    }

    notifyListeners();
  }

  void _releaseControllerIfNeeded(VideoControllerState state) {
    // 如果已经有很多控制器了，释放这个
    if (_getActiveControllerCount() > MAX_CONCURRENT_CONTROLLERS) {
      _releaseController(state);
    }
  }

  /// 验证所有控制器的有效性，清理无效的控制器
  void validateControllers() {
    final invalidKeys = <String>[];

    for (final entry in _videoStates.entries) {
      final state = entry.value;
      if (state.controller != null) {
        try {
          // 尝试访问控制器属性
          final _ = state.controller!.value.isInitialized;
        } catch (e) {
          debugPrint('⚠️ 发现无效控制器: ${entry.key}');
          invalidKeys.add(entry.key);
        }
      }
    }

    // 清理无效的控制器
    for (final key in invalidKeys) {
      final state = _videoStates[key];
      if (state != null) {
        debugPrint('🧹 清理无效控制器: $key');
        try {
          state.controller?.dispose();
        } catch (e) {
          debugPrint('⚠️ 清理无效控制器时出错: $e');
        }
        state.controller = null;
        state.isPlaying = false;
      }
    }
  }

  // 🚨 新增：在 notifyListeners 前验证所有控制器
  @override
  void notifyListeners() {
    validateControllers();
    super.notifyListeners();
  }
}
