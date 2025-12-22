/// 短视频播放器组件
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'video_data.dart';
import '../utils/crypto/aes_encrypt_simple.dart';
import '../utils/cover_cache_manager.dart';

/// 视频播放器 Widget
/// 使用 VideoPlayer 实现视频播放，自定义 UI 控制
class VideoPlayerWidget extends StatefulWidget {
  /// 视频数据
  final VideoData video;

  /// 是否应该播放（由父组件控制）
  final bool shouldPlay;

  /// 视频加载失败的回调
  final VoidCallback? onVideoLoadFailed;

  const VideoPlayerWidget({
    super.key,
    required this.video,
    required this.shouldPlay,
    this.onVideoLoadFailed,
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
  }

  /// 初始化视频播放器
  Future<void> _initializePlayer() async {
    try {
      // 异步加载封面数据，避免阻塞主线程
      if (widget.video.coverUrl.isNotEmpty) {
        _loadCoverAsync();
      }

      // 创建视频播放器控制器
      // 支持本地视频（assets/ 前缀）和网络视频（http/https）
      var videoUrl = widget.video.videoUrl ?? '';
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
      final coverData = await AesEncryptSimple.fetchAndDecrypt(
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

  /// 播放视频
  void play() {
    _videoController?.play();
  }

  /// 暂停视频
  void pause() {
    _videoController?.pause();
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
              '视频加载失败${widget.video.id}',
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
          child: GestureDetector(
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 时间显示
                _buildTimeDisplay(position, duration),
                const SizedBox(height: 8),
                // 进度条容器 - 增加触摸区域
                SizedBox(
                  // 触摸区域高度（比显示高度大）
                  height: 20, // 触摸区域高度
                  // 实际显示的进度条高度
                  child: _buildProgressBarStack(progress, screenWidth),
                ),
              ],
            ),
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

  @override
  void dispose() {
    // 释放播放器资源
    debugPrint('🔴 dispose 被调用: ${widget.video.id}');
    _videoController?.removeListener(_updatePosition);
    _videoController?.dispose();
    // 释放ValueNotifier资源
    _positionNotifier.dispose();
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

    // 使用 Stack 布局，根据状态显示不同内容
    return Stack(
      fit: StackFit.expand,
      children: [
        // 基础背景
        if (_isInitialized)
          AspectRatio(
            aspectRatio: _videoController!.value.aspectRatio,
            child: VideoPlayer(_videoController!),
          )
        else if (widget.video.cachedCover != null)
          _buildCoverImage()
        else
          Container(color: Colors.black),

        // 视频封面层（仅在初始化前显示）
        if (!_isInitialized && widget.video.cachedCover != null)
          _buildCoverImage(),

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
                height: MediaQuery.of(context).size.height * 0.6,
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

        // 视频信息叠加层（仅在初始化后显示）
        if (_isInitialized)
          Positioned(
            bottom: 80,
            left: 16,
            right: 80,
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
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),

        // 进度条（仅在初始化后显示）
        if (_isInitialized) _buildProgressBar(),
      ],
    );
  }

  /// AutomaticKeepAliveClientMixin 必需实现
  /// 返回 true 表示需要保持组件状态，实现视频缓存
  @override
  bool get wantKeepAlive => true;
}
