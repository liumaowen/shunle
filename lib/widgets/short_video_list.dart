/// 短视频列表组件
library;

import 'package:flutter/material.dart';
import 'video_data.dart';
import 'video_placeholder.dart';

/// 短视频列表容器
/// 使用纵向 PageView 实现上下滑动切换视频
class ShortVideoList extends StatelessWidget {
  final List<VideoData> videos;

  const ShortVideoList({
    super.key,
    required this.videos,
  });

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      scrollDirection: Axis.vertical,
      itemCount: videos.length,
      itemBuilder: (context, index) {
        return VideoPlaceholder(video: videos[index]);
      },
    );
  }
}
