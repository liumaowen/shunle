/// 视频列表状态管理（Provider）
library;

import 'package:flutter/foundation.dart';
import '../services/video_api_service.dart';
import '../widgets/video_data.dart';

/// 加载状态枚举
enum LoadingState { idle, loading, error }

/// 视频列表状态管理类
/// 使用 Provider 管理视频列表数据、分页逻辑和加载状态
class VideoListProvider extends ChangeNotifier {
  /// API 服务实例
  final VideoApiService _apiService = VideoApiService();

  /// 视频列表
  List<VideoData> _videos = [];
  List<VideoData> get videos => List.unmodifiable(_videos);
  set videos(List<VideoData> value) {
    _videos = value;
    notifyListeners();
  }

  /// 当前页码
  int _currentPage = 1;

  /// 每页数量
  final int _pageSize = 10;

  /// 加载状态
  LoadingState _loadingState = LoadingState.idle;
  LoadingState get loadingState => _loadingState;

  /// 错误信息
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// 是否还有更多数据
  bool _hasMore = true;
  bool get hasMore => _hasMore;

  /// 初始化加载视频
  /// 从第一页开始加载
  Future<void> loadInitialVideos() async {
    // 防止重复加载
    if (_loadingState == LoadingState.loading) return;

    _loadingState = LoadingState.loading;
    _currentPage = 1;
    _videos = [];
    _errorMessage = null;
    notifyListeners();

    try {
      // 调用 API 获取视频
      final newVideos = await fetchFromAllProviders();
      if (newVideos.isEmpty) {
        _videos = LocalVideoResource.getLocalVideos();
      } else {
        _videos = newVideos;
      }

      // 检查是否还有更多数据
      _hasMore = newVideos.length >= _pageSize;
      _loadingState = LoadingState.idle;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _loadingState = LoadingState.error;
      notifyListeners();
    }
  }

  /// 加载下一页
  /// 当滚动到倒数第 2 个视频时触发
  Future<void> loadNextPage() async {
    // 防止重复加载
    if (_loadingState == LoadingState.loading) return;

    // 如果没有更多数据，不继续加载
    if (!_hasMore) return;

    _loadingState = LoadingState.loading;
    notifyListeners();

    try {
      _currentPage++;

      // 调用 API 获取下一页视频
      final newVideos = await fetchFromAllProviders();

      // 将新视频追加到列表
      _videos.addAll(newVideos);

      // 检查是否还有更多数据
      _hasMore = newVideos.length >= _pageSize;
      _loadingState = LoadingState.idle;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _loadingState = LoadingState.error;
      // 回滚页码（加载失败时）
      _currentPage--;
      notifyListeners();
    }
  }

  void removeVideo(String videoId) {
    _videos.removeWhere((video) => video.id == videoId);
    notifyListeners();
  }

  /// 重试加载（在加载失败时调用）
  Future<void> retry() async {
    _loadingState = LoadingState.idle;
    _errorMessage = null;
    notifyListeners();
    await loadInitialVideos();
  }
}
