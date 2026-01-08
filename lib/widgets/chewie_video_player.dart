/// 基于 chewie 的视频播放器组件
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';
import 'video_data.dart';

/// 基于 chewie 的视频播放器 Widget
/// 提供完善的视频播放控制界面
class ChewieVideoPlayer extends StatefulWidget {
  /// 视频数据
  final VideoDetailData video;

  /// 是否应该播放（由父组件控制）
  final bool shouldPlay;

  /// 视频加载失败的回调
  final VoidCallback? onVideoLoadFailed;

  const ChewieVideoPlayer({
    super.key,
    required this.video,
    required this.shouldPlay,
    this.onVideoLoadFailed,
  });

  @override
  State<ChewieVideoPlayer> createState() => _ChewieVideoPlayerState();
}

class _ChewieVideoPlayerState extends State<ChewieVideoPlayer> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }



  Future<void> _initializePlayer() async {
    try {
      _isInitialized = false;

      // 如果视频 URL 为空，使用占位符
      final videoUrl = widget.video.videoUrl;

      _videoPlayerController = VideoPlayerController.networkUrl(
        Uri.parse(videoUrl),
      );

      // 等待控制器初始化
      await _videoPlayerController.initialize();

      // 设置 chewie 控制器
      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController,
        autoPlay: widget.shouldPlay,
        looping: false,
        aspectRatio: _videoPlayerController.value.aspectRatio,
        allowFullScreen: true,
        allowMuting: false, // 禁用静音按钮以节省空间
        showControls: true,
        showOptions: false,
        allowPlaybackSpeedChanging: false, // 禁用播放速度调整
        playbackSpeeds: [],
        hideControlsTimer: const Duration(seconds: 3), // 3秒后自动隐藏控制面板
        materialProgressColors: ChewieProgressColors(
          playedColor: Colors.white,
          handleColor: Colors.white,
          backgroundColor: Colors.white30,
          bufferedColor: Colors.white54,
        ),
        placeholder: Container(
          color: Colors.black,
          child: const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        ),
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, color: Colors.white, size: 48),
                const SizedBox(height: 16),
                Text('视频加载失败', style: TextStyle(color: Colors.white)),
                const SizedBox(height: 16),
                Text(
                  errorMessage,
                  style: TextStyle(color: Colors.white70),
                  maxLines: 2,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      );
      // 监听视频播放状态
      _videoPlayerController.addListener(_onVideoStateChange);
      if (mounted) {
        setState(() {
          _isInitialized = true;
          // 视频初始化完成后自动播放
          if (widget.shouldPlay && !kIsWeb) {
            _videoPlayerController.play();
          }
        });
      }
    } catch (e) {
      debugPrint('视频播放器初始化失败: $e');
      widget.onVideoLoadFailed?.call();
    }
  }

  void _onVideoStateChange() {
    final state = _videoPlayerController.value;

    if (state.isInitialized && !_isInitialized) {
      setState(() {
        _isInitialized = true;
      });
      // 可以在这里添加初始化完成后的回调
    }

    if (state.hasError) {
      debugPrint('视频播放器错误: ${state.errorDescription}');
      widget.onVideoLoadFailed?.call();
    }
  }

  void pause() {
    _videoPlayerController.pause();
  }

  void play() {
    _videoPlayerController.play();
  }

  @override
  void didUpdateWidget(ChewieVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 如果视频 URL 变化，需要重新初始化播放器
    if (widget.video.videoUrl != oldWidget.video.videoUrl) {
      _chewieController?.dispose();
      _videoPlayerController.dispose();
      _initializePlayer();
    }
    // 如果 shouldPlay 变化，控制播放
    else if (widget.shouldPlay != oldWidget.shouldPlay) {
      if (widget.shouldPlay) {
        _videoPlayerController.play();
      } else {
        _videoPlayerController.pause();
      }
    }
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoPlayerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Container(
        color: Colors.black,
        height: 300,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return FittedBox(
      fit: BoxFit.contain,
      child: Container(
        constraints: const BoxConstraints(
          minHeight: 200,
          maxHeight: 400,
        ),
        child: AspectRatio(
          aspectRatio: _videoPlayerController.value.aspectRatio,
          child: Chewie(controller: _chewieController!),
        ),
      ),
    );
  }
}

/// 扩展 VideoData 类，提供从 VideoDetailData 创建的方法
extension VideoDataExtension on VideoData {
  /// 从 VideoDetailData 创建 VideoData
  static VideoData fromDetail(VideoDetailData detail) {
    return VideoData(
      id: detail.id,
      description: detail.description,
      duration: detail.duration,
      videoUrl: detail.videoUrl,
      coverUrl: detail.coverUrl,
      playUrl: detail.playUrl,
      category: detail.contentType.toString(),
      needJiemi: detail.needJiemi,
      likes: detail.likes,
      viewCount: detail.viewCount,
      collectionCount: detail.collectionCount,
      contentType: detail.contentType,
    );
  }
}

