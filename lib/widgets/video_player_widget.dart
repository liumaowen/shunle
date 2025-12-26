/// 短视频播放器组件
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:persistent_bottom_nav_bar_v2/persistent_bottom_nav_bar_v2.dart';
import 'package:shunle/drama/drama_detail_page.dart';
import 'package:shunle/providers/global_config.dart';
import 'package:video_player/video_player.dart';
import 'video_data.dart';
import '../services/crypto_compute_service.dart';
import '../utils/cover_cache_manager.dart';

/// 视频播放器 Widget
/// 使用 VideoPlayer 实现视频播放，自定义 UI 控制
class VideoPlayerWidget extends StatefulWidget {
  /// 测试视频数据
  final int len;

  /// 视频数据
  final VideoData video;

  /// 是否应该播放（由父组件控制）
  final bool shouldPlay;

  /// 视频加载失败的回调
  final VoidCallback? onVideoLoadFailed;

  /// 视频播放完成前10秒回调
  final VoidCallback? onVideoPlayBefore10;

  /// 是否为短剧
  final bool isDrama;

  /// 总集数
  final int? totalEpisodes;

  /// 当前集数
  final int? currentEpisode;

  /// 集数切换回调
  final Function(int)? onEpisodeChange;

  const VideoPlayerWidget({
    super.key,
    required this.len,
    required this.video,
    required this.shouldPlay,
    this.onVideoLoadFailed,
    this.onVideoPlayBefore10,
    this.isDrama = false,
    this.totalEpisodes,
    this.currentEpisode,
    this.onEpisodeChange,
  });

  @override
  State<VideoPlayerWidget> createState() => VideoPlayerWidgetState();
}

/// 视频播放器状态类
/// 使用 AutomaticKeepAliveClientMixin 保持组件状态，实现视频缓存
class VideoPlayerWidgetState extends State<VideoPlayerWidget>
    with AutomaticKeepAliveClientMixin {
  VideoPlayerController? _videoController;
  bool _isInitialized = false;
  bool _hasError = false;
  Duration _currentPosition = Duration.zero;
  final ValueNotifier<Duration> _positionNotifier = ValueNotifier(
    Duration.zero,
  );
  bool _isSeeking = false;
  double _progressHeight = 1.0;
  double _borderRadius = 1.0;

  // 防抖 Timer
  Timer? _before10Timer;
  bool _hasTriggeredBefore10Callback = false;

  @override
  void initState() {
    super.initState();
    if (mounted) {
      debugPrint('initstate:${widget.video.id}');
      _initializePlayer();
    }
  }

  @override
  void didUpdateWidget(VideoPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 当 shouldPlay 状态改变时，控制播放/暂停
    if (widget.shouldPlay != oldWidget.shouldPlay) {
      if (widget.shouldPlay && _isInitialized) {
        play();
      } else if (!widget.shouldPlay && _isInitialized) {
        pause();
      }
    }

    // 步骤1：检测视频 URL 是否变化，如果变化则重新加载
    if (widget.video.videoUrl != oldWidget.video.videoUrl) {
      debugPrint('视频 URL 已变化，重新加载: ${widget.video.videoUrl}');
      loadVideo(widget.video);
    }
  }

  /// 初始化视频播放器
  Future<void> _initializePlayer() async {
    try {
      if (widget.video.needJiemi!) {
        // 异步加载封面数据，避免阻塞主线程
        if (widget.video.coverUrl.isNotEmpty) {
          // _loadCoverAsync();
        }
        // 异步加载封面数据，避免阻塞主线程
        if (widget.video.playUrl != null && widget.video.playUrl!.isNotEmpty) {
          // _loadPlayAsync();
        }
      }

      // 创建视频播放器控制器
      // 支持本地视频（assets/ 前缀）和网络视频（http/https）
      var videoUrl = widget.video.videoUrl;
      if (videoUrl.startsWith('assets/')) {
        // 本地视频：使用 asset 路径
        // 移除 'assets/' 前缀，因为 asset() 会自动处理
        var assetPath = videoUrl.replaceFirst('assets/', '');
        _videoController = VideoPlayerController.asset(assetPath);
      } else {
        // 网络视频：使用 URL
        _videoController = VideoPlayerController.networkUrl(
          Uri.parse(videoUrl),
        );
      }
      _videoController!.setLooping(true);

      // 监听视频位置变化
      _videoController!.addListener(_updatePosition);

      // 初始化播放器
      await _videoController!.initialize();

      if (mounted) {
        setState(() {
          _isInitialized = true;
          // 视频初始化完成后自动播放
          if (widget.shouldPlay && !kIsWeb) {
            _videoController!.play();
          }
        });
      }
    } catch (e) {
      debugPrint('❌ 视频加载错误: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          debugPrint('1111播放器初始化失败:${widget.video.videoUrl}');
        });
        // 通知父组件视频加载失败
        WidgetsBinding.instance.addPostFrameCallback((_) {
          widget.onVideoLoadFailed?.call();
        });
      }
    }
  }

  /// 更新视频位置
  void _updatePosition() {
    if (_videoController != null && !_isSeeking) {
      final newPosition = _videoController!.value.position;
      if (newPosition != _currentPosition) {
        _currentPosition = newPosition;
        _positionNotifier.value = newPosition; // 通知监听器，不触发重建

        // 检查是否需要触发前10秒回调
        final duration = _videoController!.value.duration;
        if (duration.inSeconds > 10) {
          // 确保视频时长超过10秒
          final befor10 = duration.inSeconds - 10;
          final currseconds = _currentPosition.inSeconds;
          bool needjiemi = widget.video.needJiemi ?? false;

          // debugPrint("当前位置：${currseconds}");
          // debugPrint("总时长：${duration.inSeconds}");
          // debugPrint("是否需要解密：$needjiemi");
          // debugPrint("befor10：$befor10");

          /// 在播放完毕前10秒时，判断下一个视频是否有效
          if (needjiemi && (currseconds == befor10)) {
            // debugPrint("触发前10秒回调");

            // 防抖：如果500ms内多次触发，只执行最后一次
            _before10Timer?.cancel();
            _before10Timer = Timer(const Duration(milliseconds: 500), () {
              // debugPrint("播放完毕前10秒 - 执行回调");
              WidgetsBinding.instance.addPostFrameCallback((_) {
                widget.onVideoPlayBefore10?.call();
              });
            });
          }
        }
      }
    }
  }

  /// 异步加载封面数据
  Future<void> _loadCoverAsync() async {
    try {
      // 使用缓存检查
      final cacheManager = CoverCacheManager();
      if (cacheManager.isCached(widget.video.coverUrl)) {
        final cachedData = cacheManager.getFromCache(widget.video.coverUrl);
        if (cachedData != null) {
          if (mounted) {
            setState(() {
              widget.video.cachedCover = cachedData;
            });
          }
          return;
        }
      }

      // 异步加载封面
      final cryptoService = CryptoComputeService.instance;
      final coverData = await cryptoService.fetchAndDecrypt(
        widget.video.coverUrl,
      );

      // 缓存数据
      cacheManager.addToCache(widget.video.coverUrl, coverData);

      // 更新状态
      if (mounted) {
        setState(() {
          widget.video.cachedCover = coverData;
        });
      }
    } catch (e) {
      debugPrint('封面加载失败: ${widget.video.coverUrl}, 错误: $e');
      // 封面加载失败不影响视频播放
    }
  }

  /// 异步加载封面数据
  Future<void> _loadPlayAsync() async {
    try {
      // 使用缓存检查
      final cacheManager = CoverCacheManager();
      final config = GlobalConfig.instance;
      if (cacheManager.isPlayCached(widget.video.playUrl!)) {
        final cachedData = cacheManager.getFromCachePlay(widget.video.playUrl!);
        if (cachedData != null) {
          if (mounted) {
            setState(() {
              widget.video.setvideourl = cachedData;
            });
          }
          return;
        }
      }

      final cryptoService = CryptoComputeService.instance;
      final playData = await cryptoService.getm3u8(
        config.playDomain,
        widget.video.coverUrl,
      );

      // 缓存数据
      cacheManager.addToPlayCache(widget.video.playUrl!, playData);

      // 更新状态
      if (mounted) {
        setState(() {
          widget.video.setvideourl = playData;
        });
      }
    } catch (e) {
      debugPrint('视频预解密失败: ${widget.video.playUrl}, 错误: $e');
    }
  }

  /// 播放视频
  void play() {
    _videoController?.play();
    if (mounted) {
      setState(() {});
    }
  }

  /// 暂停视频
  void pause() {
    _videoController?.pause();
    if (mounted) {
      setState(() {});
    }
  }

  /// 构建错误状态 UI
  Widget _buildErrorWidget() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 48),
            const SizedBox(height: 16),
            Text(
              '视频加载失败',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  /// 视频封面
  Widget _buildCoverImage() {
    if (widget.video.cachedCover != null) {
      // 使用缓存的封面数据
      return Image.memory(
        widget.video.cachedCover!,
        fit: BoxFit.cover,
        gaplessPlayback: true, // 避免加载时出现闪烁
      );
    }

    // 显示加载指示器
    return Container(
      color: Colors.black,
      child: const Center(
        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
      ),
    );
  }

  // 缓存 MediaQuery 结果，避免重复计算
  Size? _cachedMediaQuerySize;

  /// 构建进度条占位
  Widget _buildProgressBar() {
    return ValueListenableBuilder<Duration>(
      valueListenable: _positionNotifier,
      builder: (context, position, child) {
        final duration = _videoController?.value.duration ?? Duration.zero;
        final progress = duration.inMilliseconds > 0
            ? (position.inMilliseconds / duration.inMilliseconds).clamp(
                0.0,
                1.0,
              )
            : 0.0;

        // 缓存 MediaQuery 结果，避免重复计算
        _cachedMediaQuerySize ??= MediaQuery.sizeOf(context);
        final screenWidth = _cachedMediaQuerySize!.width;

        return Positioned(
          bottom: 2,
          left: 16,
          right: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 时间显示
              _buildTimeDisplay(position, duration),
              const SizedBox(height: 8),
              // 进度条容器 - 增加触摸区域
              GestureDetector(
                onTapDown: (details) {
                  // 点击进度条跳转到对应位置
                  if (_videoController != null &&
                      _videoController!.value.isInitialized) {
                    _handleSeek(details, position, duration);
                  }
                },
                onHorizontalDragStart: (details) {
                  _isSeeking = true;
                  _progressHeight = 8.0;
                  _borderRadius = 8;
                  _updateSeekingUI();
                },
                onHorizontalDragUpdate: (details) {
                  // 拖动进度条
                  if (_videoController != null &&
                      _videoController!.value.isInitialized) {
                    _handleDragUpdate(details, duration);
                  }
                },
                onHorizontalDragEnd: (details) {
                  _isSeeking = false;
                  _progressHeight = 1.0;
                  _borderRadius = 1;
                  _updateSeekingUI();
                },
                child: SizedBox(
                  // 触摸区域高度（比显示高度大）
                  height: 20, // 触摸区域高度
                  // 实际显示的进度条高度
                  child: _buildProgressBarStack(progress, screenWidth),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 处理进度条点击
  void _handleSeek(
    TapDownDetails details,
    Duration position,
    Duration duration,
  ) {
    final tapPosition = details.localPosition.dx;
    final progress =
        tapPosition / (_cachedMediaQuerySize!.width - 32); // 减去左右padding
    final newPosition = Duration(
      milliseconds: (progress * duration.inMilliseconds)
          .clamp(0, duration.inMilliseconds)
          .toInt(),
    );
    _currentPosition = newPosition;
    _positionNotifier.value = newPosition;
    _videoController!.seekTo(newPosition);
  }

  /// 处理拖动更新
  void _handleDragUpdate(DragUpdateDetails details, Duration duration) {
    final newPosition = Duration(
      milliseconds:
          (details.globalPosition.dx /
                  _cachedMediaQuerySize!.width *
                  duration.inMilliseconds)
              .toInt(),
    );
    _currentPosition = newPosition;
    _positionNotifier.value = newPosition;
    _videoController!.seekTo(newPosition);
  }

  /// 更新 seeking 状态的UI
  void _updateSeekingUI() {
    if (mounted) {
      setState(() {});
    }
  }

  /// 构建时间显示
  Widget _buildTimeDisplay(Duration position, Duration duration) {
    return SizedBox(
      width: _cachedMediaQuerySize!.width,
      child: Align(
        alignment: Alignment.center,
        child: AnimatedOpacity(
          // opacity: _isSeeking ? 1.0 : 0.0,
          opacity: _isSeeking ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 80),
          child: Text(
            '${_formatDuration(position)} / ${_formatDuration(duration)}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      ),
    );
  }

  /// 构建进度条堆栈
  Widget _buildProgressBarStack(double progress, double screenWidth) {
    return Stack(
      alignment: Alignment.centerLeft,
      children: [
        // 背景轨道（触摸区域）
        Container(
          height: 20, // 完整触摸区域
          color: Colors.transparent,
        ),
        // 进度条
        Positioned(
          top: (20 - _progressHeight) / 2, // 垂直居中
          left: 0,
          right: 0,
          child: Container(
            height: _progressHeight,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(_borderRadius),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // 已播放部分
                FractionallySizedBox(
                  widthFactor: progress,
                  alignment: Alignment.centerLeft,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 格式化时长（mm:ss）
  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// 重新加载视频
  void loadVideo(VideoData newVideo) {
    if (_videoController != null && _videoController!.value.isInitialized) {
      _videoController!.pause();
      _videoController!.dispose();
    }

    setState(() {
      _videoController = null;
      _isInitialized = false;
      _hasError = false;
      _currentPosition = Duration.zero;
    });

    _initializePlayer();
  }

  @override
  void dispose() {
    // 释放播放器资源
    debugPrint('🔴 dispose 被调用: ${widget.video.id}');
    _videoController?.removeListener(_updatePosition);
    _videoController?.dispose();
    // 释放ValueNotifier资源
    _positionNotifier.dispose();
    // 取消防抖 Timer
    _before10Timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 必须调用 super.build 以支持 AutomaticKeepAliveClientMixin
    super.build(context);

    // 加载失败
    if (_hasError) {
      return _buildErrorWidget();
    }

    // 使用 LayoutBuilder 获取父容器约束
    return LayoutBuilder(
      builder: (context, constraints) {
        // 基础视频显示组件
        Widget videoWidget;

        if (_isInitialized) {
          // 获取视频宽高比
          double videoRatio = _videoController!.value.aspectRatio;

          // 使用 FittedBox 来强制视频按原始比例显示，防止拉伸
          videoWidget = FittedBox(
            fit: BoxFit.contain, // 保持比例，完整显示视频
            alignment: Alignment.center,
            child: SizedBox(
              width: videoRatio > 1.0 ? constraints.maxWidth : null,
              height: videoRatio <= 1.0 ? constraints.maxHeight : null,
              child: AspectRatio(
                aspectRatio: videoRatio,
                child: VideoPlayer(_videoController!),
              ),
            ),
          );
        } else if (widget.video.cachedCover != null) {
          // 未初始化但有封面
          videoWidget = _buildCoverImage();
        } else {
          // 未初始化且无封面
          videoWidget = Container(color: Colors.black);
        }

        // 使用 Stack 布局，叠加其他UI元素
        return Stack(
          fit: StackFit.expand,
          children: [
            // 基础视频组件
            videoWidget,

            // 视频封面层（仅在初始化前显示）
            if (!_isInitialized && widget.video.cachedCover != null)
              Positioned.fill(child: _buildCoverImage()),

            // 播放/暂停按钮（仅在初始化后显示）
            if (_isInitialized)
              GestureDetector(
                onTap: () {
                  setState(() {
                    if (_videoController!.value.isPlaying) {
                      _videoController!.pause();
                    } else {
                      _videoController!.play();
                    }
                  });
                },
                child: Center(
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.9,
                    height: MediaQuery.of(context).size.height * 0.7,
                    decoration: BoxDecoration(color: Colors.transparent),
                    child: AnimatedOpacity(
                      opacity: _videoController!.value.isPlaying ? 0.0 : 1.0,
                      duration: const Duration(milliseconds: 80),
                      child: Icon(
                        Icons.play_arrow_rounded,
                        size: 120,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ),
              ),
            // 进度条（仅在初始化后显示）
            if (_isInitialized) _buildProgressBar(),
            // 短剧集数控制（仅在初始化后且为短剧时显示）
            // if (_isInitialized && widget.isDrama) _buildEpisodeControls(),
            // 视频信息叠加层（仅在初始化后显示）
            if (_isInitialized && !_isSeeking)
              Positioned(
                bottom: 26,
                left: 16,
                right: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 视频描述
                    Text(
                      widget.video.description,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        shadows: [Shadow(color: Colors.black87, blurRadius: 4)],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    // 分类标签（如果有）
                    if (widget.video.category.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          '#${widget.video.category}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    if (_isInitialized &&
                        widget.video.totalEpisodes != null &&
                        widget.video.totalEpisodes! > 1)
                      _episodeCountBar(),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  /// 构建短剧集数控制器
  Widget _buildEpisodeControls() {
    return Positioned(
      top: 50,
      right: 10,
      child: Column(
        children: [
          // 上一集按钮
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(20),
            ),
            child: IconButton(
              icon: const Icon(Icons.skip_previous, color: Colors.white),
              onPressed: widget.currentEpisode! > 1
                  ? _playPreviousEpisode
                  : null,
            ),
          ),
          const SizedBox(height: 8),
          // 集数显示
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '第${widget.currentEpisode}/${widget.totalEpisodes}集',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          // 下一集按钮
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(20),
            ),
            child: IconButton(
              icon: const Icon(Icons.skip_next, color: Colors.white),
              onPressed: widget.currentEpisode! < widget.totalEpisodes!
                  ? _playNextEpisode
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  /// 播放上一集
  void _playPreviousEpisode() {
    if (widget.currentEpisode! > 1) {
      widget.onEpisodeChange?.call(widget.currentEpisode! - 1);
    }
  }

  /// 播放下一集
  void _playNextEpisode() {
    if (widget.currentEpisode! < widget.totalEpisodes!) {
      widget.onEpisodeChange?.call(widget.currentEpisode! + 1);
    }
  }

  /// 构建集数行
  Widget _episodeCountBar() {
    return Column(
      children: [
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () {
            debugPrint('跳转到集数列表页面');
            pushScreen(
              context,
              screen: DramaDetailPage(dramaId: widget.video.id),
              pageTransitionAnimation: PageTransitionAnimation.platform,
            );
            if (_videoController!.value.isPlaying) {
              _videoController!.pause();
            }
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Center(
              child: Text(
                '观看完整短剧·全${widget.video.totalEpisodes}集',
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// AutomaticKeepAliveClientMixin 必需实现
  /// 返回 true 表示需要保持组件状态，实现视频缓存
  @override
  bool get wantKeepAlive => true;
}
