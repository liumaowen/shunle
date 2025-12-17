/// 短视频列表容器
/// 使用纵向 PageView 实现上下滑动切换视频，支持无限滚动加载
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/video_list_provider.dart';
import 'video_player_widget.dart';

/// 短视频列表组件
class ShortVideoList extends StatefulWidget {
  const ShortVideoList({super.key});

  @override
  State<ShortVideoList> createState() => ShortVideoListState();
}

class ShortVideoListState extends State<ShortVideoList> {
  /// 页面控制器，管理页面位置
  final PageController _pageController = PageController();

  /// 当前页面索引
  int _currentIndex = 0;

  /// 暂停当前播放的视频
  void pauseCurrentVideo() {
    _playerKeys[_currentIndex]?.currentState?.pause();
  }

  /// 播放当前视频
  void playCurrentVideo() {
    _playerKeys[_currentIndex]?.currentState?.play();
  }

  /// 缓存范围：保活当前视频和前后各 N 个视频
  /// 例如：_cacheRange = 2 时，同时保活 5 个视频（当前 + 前2 + 后2）
  /// 可根据设备性能和内存情况调整：1-3 推荐
  static const int _cacheRange = 2;

  /// 每个视频播放器的全局键，用于控制播放/暂停
  final Map<int, GlobalKey<VideoPlayerWidgetState>> _playerKeys = {};

  /// 缓存访问记录（用于 LRU 清理）
  final List<int> _cacheAccessOrder = [];

  @override
  void initState() {
    super.initState();

    // 监听页面滚动，实现无限加载
    _pageController.addListener(_onPageScroll);

    // 初始化加载视频
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<VideoListProvider>().loadInitialVideos();
      }
    });
  }

  /// 页面滚动监听回调
  /// 当滚动到倒数第 2 个视频时，触发加载下一页
  void _onPageScroll() {
    final provider = context.read<VideoListProvider>();
    final videos = provider.videos;

    // 触发条件：滚动到倒数第 2 个视频且还有更多数据
    if (_currentIndex >= videos.length - 2 && provider.hasMore) {
      provider.loadNextPage();
    }
  }

  /// 页面改变回调
  /// 更新当前页面索引，控制视频的播放/暂停
  void _onPageChanged(int index) {
    // 暂停之前的视频
    _playerKeys[_currentIndex]?.currentState?.pause();

    // 更新当前索引
    setState(() {
      _currentIndex = index;
    });

    // 播放当前视频
    _playerKeys[_currentIndex]?.currentState?.play();

    // 记录访问顺序（LRU）
    _cacheAccessOrder.remove(index);
    _cacheAccessOrder.add(index);

    // 清理超出缓存范围的视频播放器
    _cleanupOutOfRangeVideos();
  }

  /// 清理超出缓存范围的视频播放器
  /// 只保活当前视频和前后各 _cacheRange 个视频
  void _cleanupOutOfRangeVideos() {
    final keysToRemove = <int>[];
    _playerKeys.forEach((index, key) {
      final distance = (index - _currentIndex).abs();
      final shouldRemove = distance > _cacheRange;
      // 如果视频超出缓存范围，标记为需要删除
      if (shouldRemove) {
        keysToRemove.add(index);
      }
    });
    // 删除超出范围的键并主动释放播放器资源
    for (final index in keysToRemove) {
      // 尝试获取 State 并调用 dispose（如果 Widget 还在树中）
      final state = _playerKeys[index]?.currentState;
      if (state != null) {
        // State 存在，说明 Widget 还在树中，标记为不再保活
        // AutomaticKeepAliveClientMixin 会在下次重建时自动清理
      }

      _playerKeys.remove(index);
      _cacheAccessOrder.remove(index);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _playerKeys.clear();
    _cacheAccessOrder.clear();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VideoListProvider>(
      builder: (context, provider, child) {
        // 初始化加载中
        if (provider.videos.isEmpty &&
            provider.loadingState == LoadingState.loading) {
          return _buildLoadingWidget();
        }

        // 初始化加载失败
        if (provider.videos.isEmpty &&
            provider.loadingState == LoadingState.error) {
          return _buildErrorWidget(
            provider.errorMessage ?? '加载失败',
            () => provider.retry(),
          );
        }

        // 列表为空（无视频）
        if (provider.videos.isEmpty) {
          return _buildEmptyWidget();
        }

        return PageView.builder(
          controller: _pageController,
          scrollDirection: Axis.vertical,
          onPageChanged: _onPageChanged,
          // 如果还有更多数据，itemCount 加 1 用于显示加载指示器
          itemCount: provider.videos.length + (provider.hasMore ? 1 : 0),
          allowImplicitScrolling: true,
          itemBuilder: (context, index) {
            // 最后一项显示加载指示器（当还有更多数据时）
            if (index >= provider.videos.length) {
              return _buildLoadingIndicator();
            }

            final video = provider.videos[index];

            // 检查是否在缓存范围内
            final isInCacheRange = (index - _currentIndex).abs() <= _cacheRange;

            // 只为缓存范围内的视频创建播放器
            if (isInCacheRange) {
              // 为每个视频创建全局键
              if (!_playerKeys.containsKey(index)) {
                _playerKeys[index] = GlobalKey<VideoPlayerWidgetState>();
              }
              return VideoPlayerWidget(
                key: _playerKeys[index],
                video: video,
                // 只有当前可见的视频才播放
                shouldPlay: index == _currentIndex,
              );
            } else {
              // 超出缓存范围的视频显示占位符
              return Container(
                color: Colors.black,
                child: Center(
                  child: CircularProgressIndicator(color: Colors.white70),
                ),
              );
            }
          },
        );
      },
    );
  }

  /// 构建加载指示器
  Widget _buildLoadingIndicator() {
    return Container(
      color: Colors.black,
      child: const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );
  }

  /// 构建初始化加载中的 UI
  Widget _buildLoadingWidget() {
    return Container(
      color: Colors.black,
      child: const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );
  }

  /// 构建错误提示 UI
  Widget _buildErrorWidget(String errorMessage, VoidCallback onRetry) {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 48),
            const SizedBox(height: 16),
            Text(
              errorMessage,
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('重试'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建空列表提示
  Widget _buildEmptyWidget() {
    return Container(
      color: Colors.black,
      child: const Center(
        child: Text(
          '暂无视频',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
    );
  }
}
