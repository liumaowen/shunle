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
  State<ShortVideoList> createState() => _ShortVideoListState();
}

class _ShortVideoListState extends State<ShortVideoList> {
  /// 页面控制器，管理页面位置
  final PageController _pageController = PageController();

  /// 当前页面索引
  int _currentIndex = 0;

  /// 每个视频播放器的全局键，用于控制播放/暂停
  final Map<int, GlobalKey<VideoPlayerWidgetState>> _playerKeys = {};

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
    // setState(() {
    // 暂停之前的视频
    _playerKeys[_currentIndex]?.currentState?.pause();

    // 更新当前索引
    _currentIndex = index;

    // 播放当前视频
    _playerKeys[_currentIndex]?.currentState?.play();
    // });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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
          itemBuilder: (context, index) {
            // 最后一项显示加载指示器（当还有更多数据时）
            if (index >= provider.videos.length) {
              return _buildLoadingIndicator();
            }

            final video = provider.videos[index];

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
