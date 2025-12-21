/// 短视频列表容器
/// 使用纵向 PageView 实现上下滑动切换视频，支持无限滚动加载
library;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'dart:async';

import '../providers/video_list_provider.dart';
import '../utils/cover_cache_manager.dart';
import '../utils/crypto/aes_encrypt_simple.dart';
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

  /// 预加载定时器
  Timer? _preloadTimer;

  /// 预加载范围：接下来预加载的视频数量
  static const int _preloadRange = 3;

  @override
  void initState() {
    super.initState();

    // 监听页面滚动，实现无限加载
    _pageController.addListener(_onPageScroll);

    // 启动内存清理
    _startMemoryCleanup();

    // 初始化加载视频
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<VideoListProvider>().loadInitialVideos();
      }
    });
  }

  /// 内存清理计时器
  Timer? _cleanupTimer;

  /// 启动内存清理
  void _startMemoryCleanup() {
    _cleanupTimer?.cancel();
    // 每30秒清理一次超出范围的缓存
    _cleanupTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _cleanupOutOfRangeVideos();
    });
  }

  /// 清理超出缓存范围的视频
  void _cleanupOutOfRangeVideos() {
    // 查找需要清理的索引
    final keysToRemove = <int>[];
    _playerKeys.forEach((index, key) {
      // 只保留当前页面前后 _cacheRange 个视频
      if ((index - _currentIndex).abs() > _cacheRange) {
        keysToRemove.add(index);
      }
    });

    // 清理超出范围的键
    for (final index in keysToRemove) {
      final key = _playerKeys[index];
      if (key != null) {
        debugPrint('清理超出范围的视频索引: $index');
        _playerKeys.remove(index);
      }
    }

    debugPrint('当前缓存视频数量: ${_playerKeys.length}');
  }

  /// 页面滚动监听回调
  /// 当滚动到倒数第 2 个视频时，触发加载下一页
  void _onPageScroll() {
    final provider = context.read<VideoListProvider>();
    final videos = provider.videos;
    // 触发条件：滚动到倒数第 2 个视频且还有更多数据
    debugPrint('当前索引：$_currentIndex 总数：${videos.length} ');
    if (_currentIndex >= videos.length - 2) {
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

    // 预加载封面
    _preloadCovers();
  }

  /// 预加载接下来几个视频的封面
  void _preloadCovers() {
    // 取消之前的预加载任务
    _preloadTimer?.cancel();

    // 延迟预加载，避免阻塞主线程
    _preloadTimer = Timer(const Duration(milliseconds: 200), () {
      final provider = context.read<VideoListProvider>();
      final videos = provider.videos;

      // 预加载当前索引之后 _preloadRange 个视频的封面
      final startIndex = _currentIndex + 1;
      final endIndex = (startIndex + _preloadRange).clamp(0, videos.length - 1);

      for (int i = startIndex; i <= endIndex; i++) {
        final video = videos[i];
        if (video.coverUrl.isNotEmpty &&
            !CoverCacheManager().isCached(video.coverUrl)) {
          // 使用 Future 在后台线程执行解密和缓存
          Future.microtask(() async {
            try {
              final coverData = await AesEncryptSimple.fetchAndDecrypt(
                video.coverUrl,
              );
              CoverCacheManager().addToCache(video.coverUrl, coverData);
              // 将数据存储到 VideoData 中
              video.cachedCover = coverData;
            } catch (e) {
              debugPrint('预加载封面失败: ${video.coverUrl}, 错误: $e');
            }
          });
        }
      }
    });
  }


  @override
  void dispose() {
    _pageController.dispose();
    _playerKeys.clear();
    _cacheAccessOrder.clear();
    _preloadTimer?.cancel();
    _cleanupTimer?.cancel();
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

        return Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              physics: const PageScrollPhysics(), // web 滑动
              onPageChanged: _onPageChanged,
              // 如果还有更多数据，itemCount 加 1 用于显示加载指示器
              itemCount: provider.videos.length + 1,
              allowImplicitScrolling: true,
              itemBuilder: (context, index) {
                // 最后一项显示加载指示器（当还有更多数据时）
                if (index >= provider.videos.length) {
                  return _buildLoadingIndicator();
                }

                final video = provider.videos[index];

                // 检查是否在缓存范围内
                final isInCacheRange =
                    (index - _currentIndex).abs() <= _cacheRange;

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
                    // 视频加载失败的回调
                    onVideoLoadFailed: () => _handleVideoLoadFailed(index),
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
            ),
            _buildNavigationButtons(),
          ],
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

  /// 构建导航按钮组件
  /// 只在 Web 平台显示
  Widget _buildNavigationButtons() {
    return Stack(
      children: [
        // 向上翻页按钮
        Positioned(
          left: 16,
          top: 0,
          bottom: 0,
          child: Center(
            child: kIsWeb
                ? _buildNavigationButton(
                    icon: Icons.keyboard_arrow_up,
                    onPressed: _goToPrevious,
                    tooltip: '上一页',
                  )
                : const SizedBox.shrink(),
          ),
        ),
        // 向下翻页按钮
        Positioned(
          right: 16,
          top: 0,
          bottom: 0,
          child: Center(
            child: kIsWeb
                ? _buildNavigationButton(
                    icon: Icons.keyboard_arrow_down,
                    onPressed: _goToNext,
                    tooltip: '下一页',
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }

  /// 构建单个导航按钮
  Widget _buildNavigationButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTapDown: (_) => onPressed(),
        onTapCancel: () => {},
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
      ),
    );
  }

  /// 跳转到上一页
  void _goToPrevious() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  /// 跳转到下一页
  void _goToNext() {
    final provider = context.read<VideoListProvider>();
    if (_currentIndex < provider.videos.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  /// 处理视频加载失败
  void _handleVideoLoadFailed(int failedVideoIndex) {
    final provider = context.read<VideoListProvider>();
    final failedVideo = provider.videos[failedVideoIndex];

    // 标记视频为加载失败
    failedVideo.markAsFailed();

    // 从当前列表中移除失败的视频
    provider.removeVideo(failedVideo.id);

    // 如果失败的视频是当前正在播放的视频，跳转到下一个视频
    if (failedVideoIndex == _currentIndex) {
      // 如果有下一个视频，跳转到下一个
      if (_currentIndex < provider.videos.length) {
        // 如果当前索引超出范围，设置为最后一个
        if (_currentIndex >= provider.videos.length) {
          setState(() {
            _currentIndex = provider.videos.length - 1;
          });
        }

        // 跳转到下一个视频
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _pageController.animateToPage(
            _currentIndex,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        });
      } else if (provider.videos.isEmpty) {
        // 如果没有视频了，显示空状态
        debugPrint('所有视频都已加载失败或被删除');
      }
    } else if (failedVideoIndex < _currentIndex) {
      // 如果失败的视频在当前视频之前，调整当前索引
      setState(() {
        _currentIndex--;
      });
    }

    debugPrint('视频加载失败并已移除: ${failedVideo.id}');
  }
}
