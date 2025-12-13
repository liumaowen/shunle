/// 短视频播放器组件
library;

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'video_data.dart';

/// 视频播放器 Widget
/// 使用 Chewie 实现视频播放、控制和 UI
class VideoPlayerWidget extends StatefulWidget {
  /// 视频数据
  final VideoData video;

  /// 是否应该播放（由父组件控制）
  final bool shouldPlay;

  const VideoPlayerWidget({
    super.key,
    required this.video,
    required this.shouldPlay,
  });

  @override
  State<VideoPlayerWidget> createState() => VideoPlayerWidgetState();
}

/// 视频播放器状态类
class VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
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
      // 创建视频播放器控制器
      _videoController = VideoPlayerController.networkUrl(
        Uri.parse(widget.video.videoUrl ?? ''),
      );

      // 初始化播放器
      await _videoController!.initialize();

      // 创建 Chewie 控制器
      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: widget.shouldPlay,
        looping: true,
        aspectRatio: 9 / 16, // 竖屏视频比例
        showControls: true,
        allowFullScreen: false, // 禁用全屏（保持应用内播放）
        allowMuting: true,
        // 封面图
        placeholder: _buildPlaceholder(),
      );

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
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

  /// 构建封面图占位符
  Widget _buildPlaceholder() {
    return Container(
      color: Colors.black,
      child: CachedNetworkImage(
        imageUrl: widget.video.coverUrl,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: Colors.black87,
          child: const Center(
            child: Icon(Icons.image, color: Colors.white30, size: 48),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          color: Colors.black87,
          child: const Center(
            child: Icon(Icons.broken_image, color: Colors.white30, size: 48),
          ),
        ),
      ),
    );
  }

  /// 构建加载状态 UI
  Widget _buildLoadingWidget() {
    return Container(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 封面图
          _buildPlaceholder(),
          // 加载指示器
          const Center(
            child: CircularProgressIndicator(
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建错误状态 UI
  Widget _buildErrorWidget() {
    return Container(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 封面图
          _buildPlaceholder(),
          // 错误提示
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.white,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  '视频加载失败',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建视频信息叠加层
  Widget _buildVideoInfo() {
    return Positioned(
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
                  fontSize: 12,
                  shadows: [
                    Shadow(color: Colors.black87, blurRadius: 2),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // 释放播放器资源
    _videoController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 加载失败
    if (_hasError) {
      return _buildErrorWidget();
    }

    // 加载中
    if (!_isInitialized) {
      return _buildLoadingWidget();
    }

    // 播放器就绪
    return Stack(
      fit: StackFit.expand,
      children: [
        // Chewie 播放器
        Chewie(controller: _chewieController!),
        // 视频信息叠加层
        _buildVideoInfo(),
      ],
    );
  }
}
