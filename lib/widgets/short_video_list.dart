import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:shunle/providers/global_config.dart';
import 'package:shunle/widgets/video_data.dart';
import 'dart:async';

import '../providers/video_list_provider.dart';
import '../utils/cover_cache_manager.dart';
import '../services/crypto_compute_service.dart';
import 'video_player_widget.dart';
import 'episode_selector_dialog.dart';

/// 短视频列表组件
class ShortVideoList extends StatefulWidget {
  /// tab索引
  final TabsType tab;

  /// 短剧id
  final String? dramaId;

  /// 是否显示集数控制按钮
  final bool showEpisodeControls;

  /// 短剧点击回调
  final Function(VideoData)? onDramaTap;

  /// 集数切换回调
  final Function(int)? onEpisodeChange;

  const ShortVideoList({
    super.key,
    required this.tab,
    this.dramaId,
    this.showEpisodeControls = false,
    this.onDramaTap,
    this.onEpisodeChange,
  });

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
    debugPrint('⏸️ ShortVideoList.pauseCurrentVideo() 当前索引: $_currentIndex');
    final playerState = _playerKeys[_currentIndex]?.currentState;
    if (playerState != null) {
      debugPrint('✅ 找到视频播放器状态，执行暂停：${playerState.widget.video.description}');
      playerState.pause();
    } else {
      debugPrint('❌ 未找到视频播放器状态，当前缓存数量: ${_playerKeys.length}');
    }
  }

  /// 播放当前视频
  void playCurrentVideo() {
    debugPrint('▶️ ShortVideoList.playCurrentVideo() 当前索引: $_currentIndex');
    final playerState = _playerKeys[_currentIndex]?.currentState;
    if (playerState != null) {
      debugPrint('✅ 找到视频播放器状态，执行播放：${playerState.widget.video.description}');
      playerState.play();
    } else {
      debugPrint('❌ 未找到视频播放器状态，当前缓存数量: ${_playerKeys.length}');
    }
  }

  /// 根据视频类型构建不同的视频项目
  Widget _buildVideoItem(VideoData video, int index, int len) {
    if (video.isDrama) {
      return _buildDramaItem(video, index, len);
    } else {
      return _buildNormalVideoItem(video, index, len);
    }
  }

  /// 构建普通视频项目
  Widget _buildNormalVideoItem(VideoData video, int index, int len) {
    return Center(
      child: VideoPlayerWidget(
        key: _playerKeys[index],
        len: len,
        video: video,
        // 只有当前可见的视频才播放
        shouldPlay: index == _currentIndex,
        // 视频加载失败的回调
        onVideoLoadFailed: () => _handleVideoLoadFailed(index),
        // 播放完成前10秒的回调
        onVideoPlayBefore10: () => _handleVideoPlayBefore10(index),
      ),
    );
  }

  /// 构建短剧项目
  Widget _buildDramaItem(VideoData drama, int index, len) {
    return Stack(
      children: [
        Center(
          child: VideoPlayerWidget(
            key: _playerKeys[index],
            len: len,
            video: drama,
            // 只有当前可见的视频才播放
            shouldPlay: index == _currentIndex,
            // 视频加载失败的回调
            onVideoLoadFailed: () => _handleVideoLoadFailed(index),
            // 短剧相关参数
            isDrama: true,
            totalEpisodes: drama.totalEpisodes,
            currentEpisode: drama.currentEpisode,
            onEpisodeChange: (episodeNumber) {
              _handleEpisodeChange(drama, episodeNumber);
            },
          ),
        ),
        // 短剧信息覆盖层
        if (widget.showEpisodeControls) _buildDramaOverlay(drama, index),
      ],
    );
  }

  /// 构建短剧信息覆盖层
  Widget _buildDramaOverlay(VideoData drama, int index) {
    return Positioned(
      bottom: 60,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(8),
        color: Colors.black54,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              drama.description,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '第${drama.currentEpisode}/${drama.totalEpisodes}集',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                // 集数选择按钮
                ElevatedButton(
                  onPressed: () => _showEpisodeSelector(drama),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('选集'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 显示集数选择器
  void _showEpisodeSelector(VideoData drama) {
    showDialog(
      context: context,
      builder: (context) => EpisodeSelectorDialog(
        episodes: drama.episodes ?? [],
        currentEpisode: drama.currentEpisode ?? 1,
        onEpisodeSelected: (episode) {
          Navigator.of(context).pop();
          _handleEpisodeChange(drama, episode.episodeNumber);
        },
      ),
    );
  }

  /// 处理集数切换
  void _handleEpisodeChange(VideoData drama, int episodeNumber) {
    // 更新短剧的当前集数
    setState(() {
      drama.currentEpisode = episodeNumber;
    });

    // 通知外部集数已切换
    widget.onEpisodeChange?.call(episodeNumber); // 直接传递实际的集数

    // 重新加载当前视频
    _playerKeys[_currentIndex]?.currentState?.loadVideo(drama);
  }

  /// 缓存范围：保活当前视频和前后各 N 个视频
  /// 例如：_cacheRange = 1 时，同时保活 3 个视频（当前 + 前1 + 后1）
  /// 降低缓存以减少内存占用和解码器压力
  /// 根据 tab 类型动态设置
  final int _cacheRange = 1;

  /// 每个视频播放器的全局键，用于控制播放/暂停
  final Map<int, GlobalKey<VideoPlayerWidgetState>> _playerKeys = {};

  /// 缓存访问记录（用于 LRU 清理）
  final List<int> _cacheAccessOrder = [];

  /// 预加载定时器
  Timer? _preloadTimer;

  /// 预加载范围：接下来预加载的视频数量
  /// 减少预加载以节省内存
  static const int _preloadRange = 1;

  @override
  void initState() {
    super.initState();

    // 监听页面滚动，实现无限加载
    _pageController.addListener(_onPageScroll);

    // 初始化加载视频
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<VideoListProvider>().loadInitialVideos(
          widget.tab,
          widget.dramaId,
        );
      }
    });
  }

  /// 内存清理计时器
  Timer? _cleanupTimer;

  /// 标记组件是否正在销毁
  bool _isDisposing = false;

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
        debugPrint('🧹 清理超出范围的视频索引: $index (当前总数: ${_playerKeys.length})');

        // 先暂停并释放视频播放器资源
        try {
          final state = key.currentState;
          if (state != null) {
            // 调用视频播放器的清理方法
            if (state.mounted) {
              debugPrint('⏸️ 暂停超出范围的视频: $index');
              key.currentState?.pause();
            } else {
              debugPrint('⚠️ 视频组件已 unmounted，无法暂停: $index');
            }
          }
        } catch (e) {
          debugPrint('❌ 清理视频播放器时出错: $e');
        }

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
    if (_currentIndex >= videos.length - 2 && provider.hasMore) {
      provider.loadNextPage(widget.tab);
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
    _preloadTimer = Timer(const Duration(milliseconds: 500), () {
      final provider = context.read<VideoListProvider>();
      final videos = provider.videos;
      // 通知外部集数已切换
      widget.onEpisodeChange?.call(
        videos[_currentIndex].currentEpisode ?? 1,
      ); // 直接传递实际的集数
      // 获取配置信息
      final config = GlobalConfig.instance;
      // 预加载当前索引之后 _preloadRange 个视频的封面
      final startIndex = _currentIndex + 1;
      final endIndex = (startIndex + _preloadRange).clamp(0, videos.length - 1);

      for (int i = startIndex; i <= endIndex; i++) {
        final video = videos[i];
        // if (video.coverUrl.isNotEmpty &&
        //     !CoverCacheManager().isCached(video.coverUrl)) {
        //   // 使用 Future 在后台线程执行解密和缓存
        //   Future.microtask(() async {
        //     try {
        //       final coverData = await AesEncryptSimple.fetchAndDecrypt(
        //         video.coverUrl,
        //       );
        //       CoverCacheManager().addToCache(video.coverUrl, coverData);
        //       // 将数据存储到 VideoData 中
        //       video.cachedCover = coverData;
        //     } catch (e) {
        //       debugPrint('预加载封面失败: ${video.coverUrl}, 错误: $e');
        //     }
        //   });
        // }
        if (video.playUrl != null &&
            video.playUrl!.isNotEmpty &&
            !CoverCacheManager().isPlayCached(video.playUrl!)) {
          // ✅ 使用 compute() 在后台线程执行 getm3u8（不阻塞主线程）
          Future.microtask(() async {
            try {
              final palyData = await CryptoComputeService.instance.getm3u8(
                config.playDomain,
                video.playUrl!,
              );
              CoverCacheManager().addToPlayCache(video.playUrl!, palyData);
              // 将数据存储到 VideoData 中
              video.setvideourl = palyData;
            } catch (e) {
              debugPrint('预加载视频失败: ${video.coverUrl}, 错误: $e');
            }
          });
        }
      }
    });
  }

  @override
  void dispose() {
    debugPrint('🔄 ShortVideoList 开始资源释放');

    // 标记组件即将销毁
    _isDisposing = true;

    // 停止所有预加载和清理定时器
    if (_preloadTimer != null) {
      debugPrint('⏰ 取消预加载定时器');
      _preloadTimer?.cancel();
    }

    if (_cleanupTimer != null) {
      debugPrint('🧹 取消清理定时器');
      _cleanupTimer?.cancel();
    }

    // 暂停所有视频播放器
    debugPrint('⏸️ 暂停所有视频播放器 (总数: ${_playerKeys.length})');
    _playerKeys.forEach((index, key) {
      try {
        if (key.currentState?.mounted == true) {
          key.currentState?.pause();
          debugPrint('⏸️ 已暂停视频: $index');
        } else {
          debugPrint('⚠️ 视频组件已 unmounted: $index');
        }
      } catch (e) {
        debugPrint('❌ 暂停视频播放器 $index 时出错: $e');
      }
    });

    // 清理所有引用
    debugPrint('🗑️ 清理所有引用 (缓存记录: ${_playerKeys.length})');
    _playerKeys.clear();
    _cacheAccessOrder.clear();

    // 释放页面控制器
    debugPrint('📄 释放页面控制器');
    _pageController.dispose();

    debugPrint('✅ ShortVideoList 资源释放完成');
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
            () => provider.retry(widget.tab, widget.dramaId),
          );
        }

        // 列表为空（无视频）
        if (provider.videos.isEmpty) {
          return _buildEmptyWidget();
        }
        debugPrint('当前索引：$_currentIndex 总数：${provider.videos.length} ');
        return Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              physics: const PageScrollPhysics(), // web 滑动
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
                final isInCacheRange =
                    (index - _currentIndex).abs() <= _cacheRange;

                // 只为缓存范围内的视频创建播放器
                if (isInCacheRange) {
                  // 为每个视频创建全局键
                  if (!_playerKeys.containsKey(index)) {
                    _playerKeys[index] = GlobalKey<VideoPlayerWidgetState>();
                  }

                  return _buildVideoItem(video, index, provider.videos.length);
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

  /// 播放完成前10秒处理下一个视频是否有效
  void _handleVideoPlayBefore10(int currenVideoIndex) async {
    final provider = context.read<VideoListProvider>();
    if (provider.videos.length > currenVideoIndex + 1) {
      // 获取配置信息
      final config = GlobalConfig.instance;
      final nextVideo = provider.videos[currenVideoIndex + 1];
      bool isVideoUrlValid = await provider.isVideoUrlValid(nextVideo.videoUrl);
      debugPrint("isVideoUrlValid: $isVideoUrlValid");
      debugPrint("nextVideoUrl旧: ${nextVideo.videoUrl}");
      if (!isVideoUrlValid) {
        // ✅ 使用 compute() 在后台线程执行 getm3u8（不阻塞主线程）
        Future.microtask(() async {
          try {
            final palyData = await CryptoComputeService.instance.getm3u8(
              config.playDomain,
              nextVideo.playUrl!,
            );
            CoverCacheManager().addToPlayCache(nextVideo.playUrl!, palyData);
            // 将数据存储到 VideoData 中
            nextVideo.setvideourl = palyData;
            debugPrint("nextVideoUrl新: $palyData");

            // 步骤2：强制重新加载下一个视频播放器
            debugPrint('强制重新加载下一个视频播放器，索引: ${currenVideoIndex + 1}');
            final nextPlayerKey = _playerKeys[currenVideoIndex + 1];
            if (nextPlayerKey?.currentState != null) {
              nextPlayerKey!.currentState!.loadVideo(nextVideo);
            }
          } catch (e) {
            debugPrint('预加载视频失败: ${nextVideo.playUrl}, 错误: $e');
          }
        });
      }
    }
  }

  /// 处理视频加载失败
  void _handleVideoLoadFailed(int failedVideoIndex) {
    final provider = context.read<VideoListProvider>();

    // 检查索引是否有效
    if (failedVideoIndex < 0 || failedVideoIndex >= provider.videos.length) {
      debugPrint(
        '❌ 无效的视频索引: $failedVideoIndex，当前列表长度: ${provider.videos.length}',
      );
      return;
    }

    final failedVideo = provider.videos[failedVideoIndex];

    // 标记视频为加载失败
    failedVideo.markAsFailed();

    // 从当前列表中移除失败的视频
    provider.removeVideo(failedVideo.id);

    debugPrint('failedVideoIndex: $failedVideoIndex');
    debugPrint('_currentIndex: $_currentIndex');

    // 如果失败的视频是当前正在播放的视频，跳转到下一个视频
    if (failedVideoIndex == _currentIndex) {
      // 如果当前索引超出范围，设置为最后一个
      if (_currentIndex >= provider.videos.length) {
        if (provider.videos.isNotEmpty) {
          setState(() {
            _currentIndex = provider.videos.length - 1;
          });

          // 跳转到新的当前视频
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_currentIndex >= 0 && _currentIndex < provider.videos.length) {
              _pageController.animateToPage(
                _currentIndex,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            }
          });
        } else {
          // 如果没有视频了，显示空状态
          debugPrint('所有视频都已加载失败或被删除');
        }
      } else if (_currentIndex < provider.videos.length) {
        // 如果有下一个视频，跳转到下一个
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _pageController.animateToPage(
            _currentIndex,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        });
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
