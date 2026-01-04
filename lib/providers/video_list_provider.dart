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
  final int _pageSize = 5;

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
  ///
  /// 参数:
  /// - tab: tab单个分类
  ///
  Future<void> loadInitialVideos(TabsType tab, String? dramaId) async {
    // 防止重复加载
    if (_loadingState == LoadingState.loading) return;

    _loadingState = LoadingState.loading;
    _currentPage = 1;
    _videos = [];
    _errorMessage = null;
    notifyListeners();

    String page = _currentPage.toString();
    if (tab.id == '0') {
      // 只有推荐频道时，page为空，采用随机页码
      page = '';
    }

    try {
      List<VideoData> newVideos = [];
      // 判断是否为短剧类型
      if (tab.isDramaType) {
        // 短剧数据加载逻辑
        Map<String, String> dramaForm = {
          'PageIndex': page,
          'PageSize': _pageSize.toString(),
          'ChannelId': '',
          'GenderChannelType': '',
        };
        if (tab.videoType == 'dramadetail' &&
            dramaId != null &&
            dramaId != '') {
          newVideos = await VideoApiService.getDramaDetail(dramaId);
          _hasMore = false;
        } else {
          newVideos = await VideoApiService.fetchDrama(dramaForm);
          // 检查是否还有更多数据
          _hasMore = newVideos.length >= _pageSize;
        }
        _videos = newVideos;
      } else {
        // 普通视频数据加载逻辑
        newVideos = await VideoApiService.fetchFromAllProviders(
          page: page,
          pagesize: _pageSize.toString(),
          videoType: tab.videoType,
          sortType: tab.sortType,
          collectionId: tab.collectionId,
          isjm: true
        );
        if (newVideos.isEmpty) {
          _videos = LocalVideoResource.getLocalVideos();
        } else {
          _videos = newVideos;
        }
        // 检查是否还有更多数据
        _hasMore = newVideos.length >= _pageSize;
      }

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
  ///
  /// 参数:
  /// - tab: tab单个分类
  ///
  Future<void> loadNextPage(TabsType tab) async {
    // 防止重复加载
    if (_loadingState == LoadingState.loading) return;

    _loadingState = LoadingState.loading;
    notifyListeners();

    try {
      _currentPage++;
      String page = _currentPage.toString();
      if (tab.id == '0') {
        // 只有推荐频道时，page为空，采用随机页码
        page = '';
      }
      List<VideoData> newVideos = [];
      // 调用 API 获取下一页视频
      if (tab.isDramaType) {
        // 短剧数据加载逻辑
        Map<String, String> dramaForm = {
          'PageIndex': page,
          'PageSize': _pageSize.toString(),
          'ChannelId': '',
          'GenderChannelType': '',
        };
        newVideos = await VideoApiService.fetchDrama(dramaForm);
      } else {
        newVideos = await VideoApiService.fetchFromAllProviders(
          page: page,
          pagesize: _pageSize.toString(),
          videoType: tab.videoType,
          sortType: tab.sortType,
          collectionId: tab.collectionId,
          isjm: true
        );
      }

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

  /// 检查视频链接是否有效
  Future<bool> isVideoUrlValid(String videoUrl) async {
    try {
      return await VideoApiService.isVideoUrlValid(videoUrl);
    } catch (e) {
      return false;
    }
  }

  void removeVideo(String videoId) {
    _videos.removeWhere((video) => video.id == videoId);
    notifyListeners();
  }

  /// 设置视频列表（内部使用）
  void setVideos(List<VideoData> videos) {
    _videos = videos;
    notifyListeners();
  }

  /// 重试加载（在加载失败时调用）
  ///
  /// 参数:
  /// - tab: tab单个分类
  ///
  Future<void> retry(TabsType tab,String? dramaId) async {
    _loadingState = LoadingState.idle;
    _errorMessage = null;
    notifyListeners();
    await loadInitialVideos(tab,dramaId);
  }

  /// 获取短剧详情
  ///
  /// 注意：此方法已废弃，请使用 DramaProvider 来处理短剧相关状态
  /// 这里保持兼容性，但会清空当前视频列表
  ///
  /// 参数:
  /// - dramaId: 短剧ID
  ///
  /// 返回:
  /// - VideoData 包含完整的集数列表
  ///
  @Deprecated("请使用 DramaProvider 来处理短剧相关状态，这里保持兼容性但会清空当前视频列表")
  Future<void> getDramaDetail(String dramaId) async {
    final newVideos = await VideoApiService.getDramaDetail(dramaId);
    _videos = newVideos;
    notifyListeners();
  }

  /// 检查是否为短剧数据加载
  bool get isDramaMode => _videos.isNotEmpty && _videos.first.isDrama;
}
