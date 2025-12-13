/// 短视频占位组件
library;

import 'package:flutter/material.dart';
import 'video_data.dart';

/// 单个短视频的占位符组件
/// 显示黑色背景、播放图标、描述信息和进度条占位
class VideoPlaceholder extends StatefulWidget {
  final VideoData video;
  final VoidCallback? onTap;

  const VideoPlaceholder({super.key, required this.video, this.onTap});

  @override
  State<VideoPlaceholder> createState() => _VideoPlaceholderState();
}

class _VideoPlaceholderState extends State<VideoPlaceholder> {
  // 预留播放状态（未来实现视频播放功能）
  bool _isPlaying = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // 黑色背景
        Container(color: Colors.black),

        // 居中的播放图标
        GestureDetector(
          onTap: widget.onTap ?? _togglePlayPause,
          child: Center(
            child: Icon(
              Icons.play_arrow_rounded,
              size: 80,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ),

        // 底部信息叠加层
        _buildVideoInfo(),

        // 底部进度条占位
        _buildProgressBar(),
      ],
    );
  }

  /// 构建视频信息叠加层（描述、时长等）
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
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
              shadows: [Shadow(color: Colors.black87, blurRadius: 4)],
            ),
          ),
          const SizedBox(height: 8),
          // 视频时长
          Text(
            '时长: ${_formatDuration(widget.video.duration)}',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12,
              shadows: const [Shadow(color: Colors.black87, blurRadius: 2)],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建进度条占位
  Widget _buildProgressBar() {
    return Positioned(
      bottom: 0,
      left: 16,
      right: 16,
      child: GestureDetector(
        onHorizontalDragUpdate: (details) {
          // 预留拖动处理（未来实现进度条拖动功能）
          setState(() {
            _isPlaying = true;
          });
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 时间显示
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '00:00 / ${_formatDuration(widget.video.duration)}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 10,
                  shadows: const [Shadow(color: Colors.black87, blurRadius: 2)],
                ),
              ),
            ),
            const SizedBox(height: 4),
            // 进度条
            Container(
              height: 1,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(1),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // 已播放部分
                  FractionallySizedBox(
                    widthFactor: 0.3, // 占位：30% 进度
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
          ],
        ),
      ),
    );
  }

  /// 切换播放/暂停状态
  void _togglePlayPause() {
    setState(() {
      _isPlaying = !_isPlaying;
    });
    // TODO: 连接真实视频播放器
  }

  /// 格式化时长（mm:ss）
  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
