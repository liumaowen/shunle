/// 短视频播放器组件
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:persistent_bottom_nav_bar_v2/persistent_bottom_nav_bar_v2.dart';
import 'package:provider/provider.dart';
import 'package:shunle/drama/drama_detail_page.dart';
import 'package:shunle/providers/video_manager.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'video_data.dart';

/// 视频播放器 Widget
/// 使用 VideoPlayer 实现视频播放，自定义 UI 控制
class OptimizedVideoPlayerWidget extends StatefulWidget {
  /// 视频数据
  final VideoData video;

  final String tabId;

  final int listIndex;

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

  /// 是否使用软件解码器
  final bool useSoftwareDecoder;

  const OptimizedVideoPlayerWidget({
    super.key,
    required this.video,
    required this.tabId,
    required this.listIndex,
    required this.shouldPlay,
    this.onVideoLoadFailed,
    this.onVideoPlayBefore10,
    this.isDrama = false,
    this.totalEpisodes,
    this.currentEpisode,
    this.onEpisodeChange,
    this.useSoftwareDecoder = false,
  });

  @override
  State<OptimizedVideoPlayerWidget> createState() =>
      OptimizedVideoPlayerWidgetState();
}

/// 视频播放器状态类
/// 使用 AutomaticKeepAliveClientMixin 保持组件状态，实现视频缓存
class OptimizedVideoPlayerWidgetState extends State<OptimizedVideoPlayerWidget>
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

  // 标记组件是否正在销毁，防止回调在销毁后执行
  bool _isDisposing = false;

  // 追踪监听器是否已添加
  bool _hasPositionListener = false;
  bool _hasControllerUpdateListener = false;

  // 🚨 缓存视频宽高比，避免每次都访问控制器
  double _cachedVideoRatio = 1.0;

  // 🚨 新增：缓存最近的可见度，用于初始化完成后重新处理
  double _lastVisibleFraction = 0.0;

  @override
  void initState() {
    super.initState();
    if (mounted) {
      debugPrint('initstate:${widget.video.id}');
      initializeVideo();
    }
  }

  @override
  void didUpdateWidget(OptimizedVideoPlayerWidget oldWidget) {
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
      initializeVideo();
    }
  }

  Future<void> initializeVideo() async {
    // 🚨 关键：防止重复初始化
    if (_isInitialized && _videoController != null) {
      try {
        // 检查控制器是否仍然有效
        final _ = _videoController!.value.isInitialized;
        debugPrint('✅ 控制器已初始化，跳过重新初始化');
        return;
      } catch (e) {
        debugPrint('⚠️ 控制器无效，需要重新初始化: $e');
        // 控制器无效，重置状态
        setState(() {
          _videoController = null;
          _isInitialized = false;
          _hasError = false;
        });
      }
    }

    if (!mounted) {
      debugPrint('⚠️ Widget 已卸载，跳过初始化');
      return;
    }

    final manager = Provider.of<VideoManager>(context, listen: false);
    try {
      _videoController = await manager.getController(
        video: widget.video,
        tabId: widget.tabId,
        listIndex: widget.listIndex,
      );

      if (!mounted) return;

      if (_videoController != null) {
        try {
          // 🚨 关键：检查控制器是否有效
          if (!_videoController!.value.isInitialized) {
            debugPrint('⚠️ 控制器未初始化，等待初始化完成');
            return;
          }

          // 监听位置变化
          if (!_hasPositionListener) {
            _videoController!.addListener(_updatePosition);
            _hasPositionListener = true;
          }

          if (mounted) {
            setState(() {
              _isInitialized = true;
            });
          }

          // 🚨 新增：初始化完成后，重新检查可见性并触发播放
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && !_isDisposing) {
              debugPrint('✅ 控制器初始化完成，重新处理可见性 (可见度: $_lastVisibleFraction)');
              // 使用缓存的可见度值重新处理可见性变化
              // 如果视频仍然可见，将自动播放；如果不可见，将停止播放
              final manager = Provider.of<VideoManager>(context, listen: false);
              manager.handleVideoVisibility(
                video: widget.video,
                tabId: widget.tabId,
                visibleFraction: _lastVisibleFraction,
                listIndex: widget.listIndex,
              );
            }
          });
        } catch (e) {
          debugPrint('❌ 控制器访问失败（可能已释放）: $e');
          if (mounted) {
            _setError();
          }
        }
      } else {
        debugPrint('❌ 获取控制器失败，返回null');
        if (mounted) {
          _setError();
        }
      }
    } catch (e) {
      debugPrint('❌ 视频初始化错误: $e');
      if (mounted) {
        _setError();
      }
    }
  }

  void _onControllerUpdate() {
    if (_videoController != null &&
        _videoController!.value.isInitialized &&
        mounted) {
      _videoController!.removeListener(_onControllerUpdate);
      _hasControllerUpdateListener = false;
      _videoController!.addListener(_updatePosition);
      _hasPositionListener = true;
      setState(() {
        _isInitialized = true;
      });
    }
  }

  void _setError() {
    setState(() {
      _hasError = true;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isDisposing && mounted) {
        widget.onVideoLoadFailed?.call();
      }
    });
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

      // 检查是否为解码器错误
      if (e.toString().contains('MediaCodec') ||
          e.toString().contains('decoder')) {
        debugPrint('🔄 检测到解码器错误...');

        // 如果当前没有使用软件解码器，记录错误但不立即重试
        if (!widget.useSoftwareDecoder) {
          debugPrint('💡 提示: 可以尝试设置 useSoftwareDecoder=true 来使用软件解码器');
        }
      }

      if (mounted) {
        setState(() {
          _hasError = true;
          debugPrint('1111播放器初始化失败:${widget.video.videoUrl}');
        });
        // 通知父组件视频加载失败
        WidgetsBinding.instance.addPostFrameCallback((_) {
          // 检查组件是否正在销毁，防止回调在销毁后执行
          if (!_isDisposing && mounted) {
            widget.onVideoLoadFailed?.call();
          }
        });
      }
    }
  }

  /// 更新视频位置
  void _updatePosition() {
    if (_videoController != null && !_isSeeking) {
      try {
        final newPosition = _videoController!.value.position;
        if (newPosition != _currentPosition) {
          _currentPosition = newPosition;
          _positionNotifier.value = newPosition;

          // 缓存视频宽高比
          if (_videoController!.value.isInitialized) {
            _cachedVideoRatio = _videoController!.value.aspectRatio;
          }

          // 检查是否需要触发前10秒回调
          final duration = _videoController!.value.duration;
          if (duration.inSeconds > 10) {
            final befor10 = duration.inSeconds - 10;
            final currseconds = _currentPosition.inSeconds;
            bool needjiemi = widget.video.needJiemi ?? false;

            if (needjiemi && (currseconds == befor10)) {
              _before10Timer?.cancel();
              _before10Timer = Timer(const Duration(milliseconds: 500), () {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!_isDisposing && mounted) {
                    widget.onVideoPlayBefore10?.call();
                  }
                });
              });
            }
          }
        }
      } catch (e) {
        debugPrint('⚠️ 更新位置时出错（控制器可能已释放）: $e');
      }
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
            const SizedBox(height: 16),
            // 重试按钮
            ElevatedButton(
              onPressed: () {
                _initializePlayer();
              },
              child: const Text('重试'),
            ),
            const SizedBox(height: 16),
            // 如果是解码器错误，显示使用软件解码器的选项
            ElevatedButton(onPressed: initializeVideo, child: const Text('重试')),
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
    debugPrint('🔄 开始重新加载视频: ${newVideo.id}');

    try {
      // 先暂停当前视频
      _videoController?.pause();

      // 清理之前的资源
      _before10Timer?.cancel();
      if (_hasPositionListener) {
        _videoController?.removeListener(_updatePosition);
        _hasPositionListener = false;
      }
      if (_hasControllerUpdateListener) {
        _videoController?.removeListener(_onControllerUpdate);
        _hasControllerUpdateListener = false;
      }
    } catch (e) {
      debugPrint('⚠️ 清理监听器时出错: $e');
    }

    // 重置状态（不释放控制器，由 VideoManager 管理）
    setState(() {
      _videoController = null;
      _isInitialized = false;
      _hasError = false;
      _currentPosition = Duration.zero;
      _isDisposing = false; // 重置销毁标记
    });

    // 重新初始化（使用 VideoManager 系统）
    initializeVideo();
  }

  void _onVisibilityChanged(VisibilityInfo info) {
    debugPrint('👀 视频可见性变化: ${widget.video.id}');
    debugPrint ('👀 视频可见度: ${info.visibleFraction}');

    // 🚨 新增：缓存可见度，用于初始化完成后重新处理
    _lastVisibleFraction = info.visibleFraction;

    // 检查组件是否已卸载或正在销毁，防止在销毁后访问 context
    if (!mounted || _isDisposing) {
      return;
    }

    final manager = Provider.of<VideoManager>(context, listen: false);

    // 通知管理器可见性变化
    manager.handleVideoVisibility(
      video: widget.video,
      tabId: widget.tabId,
      visibleFraction: info.visibleFraction,
      listIndex: widget.listIndex,
    );
  }

  @override
  void dispose() {
    // 标记组件即将销毁，防止后续回调执行
    _isDisposing = true;
    debugPrint('🔴 开始释放 VideoPlayerWidget 资源: ${widget.video.id}');

    try {
      // 清理监听器（但不释放控制器本身，由 VideoManager 管理）
      if (_hasPositionListener && _videoController != null) {
        debugPrint('📹 移除位置监听器');
        _videoController?.removeListener(_updatePosition);
        _hasPositionListener = false;
      }
      if (_hasControllerUpdateListener && _videoController != null) {
        debugPrint('📹 移除控制器更新监听器');
        _videoController?.removeListener(_onControllerUpdate);
        _hasControllerUpdateListener = false;
      }
    } catch (e) {
      debugPrint('⚠️ 清理监听器时出错: $e');
    }

    // 释放ValueNotifier资源
    debugPrint('🔔 释放 ValueNotifier 监听器');
    _positionNotifier.dispose();

    // 取消防抖 Timer
    if (_before10Timer != null) {
      debugPrint('⏰ 取消防抖 Timer');
      _before10Timer?.cancel();
    }

    // 清理所有 WidgetsBinding 回调
    // 注意：addPostFrameCallback 是一次性回调，会自动清理
    // 但为了确保清理，我们添加一个标记来防止组件销毁后仍然执行回调

    debugPrint('✅ VideoPlayerWidget 资源释放完成: ${widget.video.id}');
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

    // 🚨 关键：检查控制器是否仍然有效
    if (_isInitialized && _videoController != null) {
      try {
        // 尝试访问控制器属性，检查是否已被释放
        final _ = _videoController!.value.isInitialized;
      } catch (e) {
        debugPrint('⚠️ 控制器已被释放，重置状态: $e');
        // 控制器无效，重置状态
        setState(() {
          _videoController = null;
          _isInitialized = false;
          _hasError = false;
        });

        // 尝试重新初始化
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !_isDisposing) {
            initializeVideo();
          }
        });

        return _buildLoadingPlaceholder();
      }
    }

    // 使用 LayoutBuilder 获取父容器约束
    return LayoutBuilder(
      builder: (context, constraints) {
        // 基础视频显示组件
        Widget videoWidget;

        // 🚨 关键：在 build 时再次检查控制器是否有效（可能被 LRU 释放）
        if (_isInitialized && _videoController != null) {
          try {
            // 尝试访问控制器属性，检查是否已被释放
            final _ = _videoController!.value.isInitialized;

            // 🚨 使用缓存的宽高比，避免访问已释放的控制器
            double videoRatio = _cachedVideoRatio;

            // 如果缓存为默认值，尝试从控制器获取
            if (_cachedVideoRatio == 1.0) {
              try {
                videoRatio = _videoController!.value.aspectRatio;
                _cachedVideoRatio = videoRatio;
              } catch (e) {
                debugPrint('⚠️ 无法获取视频宽高比: $e');
              }
            }

            // 使用 FittedBox 来强制视频按原始比例显示，防止拉伸
            videoWidget = FittedBox(
              fit: BoxFit.contain,
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
          } catch (e) {
            debugPrint('⚠️ 构建视频播放器失败（控制器可能被释放）: $e');
            // 控制器已被释放，重置状态
            setState(() {
              _videoController = null;
              _isInitialized = false;
              _hasError = false;
            });
            // 尝试重新初始化
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && !_isDisposing) {
                initializeVideo();
              }
            });
            videoWidget = _buildLoadingPlaceholder();
          }
        } else if (widget.video.cachedCover != null) {
          // 未初始化但有封面
          videoWidget = _buildCoverImage();
        } else {
          // 未初始化且无封面
          videoWidget = Container(color: Colors.black);
        }

        // 使用 Stack 布局，叠加其他UI元素
        return VisibilityDetector(
          key: Key('${widget.tabId}_${widget.video.id}'),
          onVisibilityChanged: _onVisibilityChanged,
          child: Stack(
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
                    if (_videoController != null) {
                      try {
                        setState(() {
                          if (_videoController!.value.isPlaying) {
                            _videoController!.pause();
                          } else {
                            _videoController!.play();
                          }
                        });
                      } catch (e) {
                        debugPrint('⚠️ 播放/暂停失败: $e');
                      }
                    }
                  },
                  child: Center(
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.9,
                      height: MediaQuery.of(context).size.height * 0.7,
                      decoration: BoxDecoration(color: Colors.transparent),
                      child: _videoController != null
                          ? AnimatedOpacity(
                              opacity: _videoController!.value.isPlaying
                                  ? 0.0
                                  : 1.0,
                              duration: const Duration(milliseconds: 80),
                              child: Icon(
                                Icons.play_arrow_rounded,
                                size: 120,
                                color: Colors.white.withValues(alpha: 0.5),
                              ),
                            )
                          : SizedBox.shrink(),
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
                          shadows: [
                            Shadow(color: Colors.black87, blurRadius: 4),
                          ],
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
          ),
        );
      },
    );
  }

  /// 构建加载占位符
  Widget _buildLoadingPlaceholder() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text('重新加载视频...', style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
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
