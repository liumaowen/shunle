/// 短剧状态管理（Provider）
library;

import 'package:flutter/foundation.dart';
import '../services/video_api_service.dart';
import '../widgets/video_data.dart';
import 'drama_cache_manager.dart';

/// 短剧加载状态枚举
enum DramaLoadingState { idle, loading, error }

/// 短剧状态管理类
/// 专门处理短剧相关的数据加载和状态管理
class DramaProvider extends ChangeNotifier {
  /// 当前短剧详情
  VideoData? _currentDrama;
  VideoData? get currentDrama => _currentDrama;

  /// 短剧集数列表
  List<VideoData> _dramaEpisodes = [];
  List<VideoData> get dramaEpisodes => List.unmodifiable(_dramaEpisodes);

  /// 加载状态
  DramaLoadingState _loadingState = DramaLoadingState.idle;
  DramaLoadingState get loadingState => _loadingState;

  /// 错误信息
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// 是否正在加载
  bool get isLoading => _loadingState == DramaLoadingState.loading;

  /// 是否有错误
  bool get hasError => _loadingState == DramaLoadingState.error;

  /// 初始化短剧详情加载
  /// 获取短剧的详细信息，包括所有集数
  ///
  /// 参数:
  /// - dramaId: 短剧ID
  ///
  Future<void> loadDramaDetail(String dramaId) async {
    // 防止重复加载
    if (_loadingState == DramaLoadingState.loading) return;

    // 检查缓存
    final cacheManager = DramaCacheManager();
    final cachedDrama = cacheManager.getCachedDrama(dramaId);

    if (cachedDrama != null) {
      // 使用缓存数据
      _currentDrama = cachedDrama;
      _dramaEpisodes = _buildDramaEpisodesList(_currentDrama!);
      _loadingState = DramaLoadingState.idle;
      notifyListeners();
      return;
    }

    _loadingState = DramaLoadingState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      // 获取短剧详情
      final dramaDetail = await VideoApiService.getDramaDetailWithEpisodes(dramaId);

      if (dramaDetail != null) {
        _currentDrama = dramaDetail;

        // 缓存数据
        cacheManager.cacheDrama(dramaId, dramaDetail);

        // 设置集数列表
        _dramaEpisodes = _buildDramaEpisodesList(dramaDetail);
      } else {
        _dramaEpisodes = [];
      }

      _loadingState = DramaLoadingState.idle;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _loadingState = DramaLoadingState.error;
      notifyListeners();
    }
  }

  /// 构建短剧集数列表
  List<VideoData> _buildDramaEpisodesList(VideoData drama) {
    if (drama.episodes != null) {
      // 将 EpisodeInfo 转换为 VideoData
      return drama.episodes!.map((episode) {
        return VideoData(
          id: episode.episodeId,
          description: episode.title,
          duration: const Duration(seconds: 0), // EpisodeInfo 暂无时长字段
          coverUrl: '', // EpisodeInfo 暂无封面字段
          videoUrl: episode.videoUrl,
          category: 'drama',
          contentType: ContentType.episode,
          totalEpisodes: drama.totalEpisodes,
          currentEpisode: episode.episodeNumber,
        );
      }).toList();
    } else {
      // 如果没有集数列表，使用当前视频作为唯一集数
      return [drama];
    }
  }

  /// 播放指定集数
  ///
  /// 参数:
  /// - episodeIndex: 集数索引
  ///
  /// 返回:
  /// - VideoData 对应的集数
  VideoData playEpisode(int episodeIndex) {
    if (episodeIndex < 0 || episodeIndex >= _dramaEpisodes.length) {
      throw ArgumentError('Invalid episode index: $episodeIndex');
    }

    // 更新当前短剧的当前集数
    if (_currentDrama != null) {
      // 创建新的 VideoData 实例更新当前集数
      _currentDrama = VideoData(
        id: _currentDrama!.id,
        description: _currentDrama!.description,
        duration: _currentDrama!.duration,
        coverUrl: _currentDrama!.coverUrl,
        videoUrl: _currentDrama!.videoUrl,
        category: _currentDrama!.category,
        contentType: _currentDrama!.contentType,
        totalEpisodes: _currentDrama!.totalEpisodes,
        currentEpisode: _dramaEpisodes[episodeIndex].currentEpisode,
        episodes: _currentDrama!.episodes,
      );
      notifyListeners();
    }

    return _dramaEpisodes[episodeIndex];
  }

  /// 获取当前集数
  VideoData? getCurrentEpisode() {
    if (_currentDrama == null || _dramaEpisodes.isEmpty) {
      return null;
    }

    final currentIndex = (_currentDrama!.currentEpisode ?? 1) - 1;
    if (currentIndex >= 0 && currentIndex < _dramaEpisodes.length) {
      return _dramaEpisodes[currentIndex];
    }

    return null;
  }

  /// 播放上一集
  VideoData? playPreviousEpisode() {
    if (_currentDrama == null) return null;

    final currentIndex = (_currentDrama!.currentEpisode ?? 1) - 1;
    if (currentIndex > 0) {
      return playEpisode(currentIndex - 1);
    }

    return null;
  }

  /// 播放下一集
  VideoData? playNextEpisode() {
    if (_currentDrama == null) return null;

    final currentIndex = (_currentDrama!.currentEpisode ?? 1) - 1;
    if (currentIndex < _dramaEpisodes.length - 1) {
      return playEpisode(currentIndex + 1);
    }

    return null;
  }

  /// 重试加载
  Future<void> retry(String dramaId) async {
    _loadingState = DramaLoadingState.idle;
    _errorMessage = null;
    notifyListeners();
    await loadDramaDetail(dramaId);
  }

  /// 清除数据
  void clear() {
    _currentDrama = null;
    _dramaEpisodes = [];
    _loadingState = DramaLoadingState.idle;
    _errorMessage = null;
    notifyListeners();
  }
}