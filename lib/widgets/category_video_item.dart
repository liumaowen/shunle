import 'package:flutter/material.dart';
import 'video_data.dart';

/// 分类视频列表项组件
class CategoryVideoItem extends StatelessWidget {
  final VideoData video;

  const CategoryVideoItem({
    required this.video,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 图片部分
          _buildImage(),
          // 标题部分
          _buildTitle(),
          // 点赞数部分
          _buildLikes(),
        ],
      ),
    );
  }

  /// 构建图片
  Widget _buildImage() {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
      child: AspectRatio(
        aspectRatio: 16 / 9, // 16:9 比例
        child: _buildImageContent(),
      ),
    );
  }

  /// 构建图片内容
  Widget _buildImageContent() {
    // 如果有缓存的封面图片
    if (video.isCoverCached) {
      return Image.memory(
        video.cachedCover!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholder();
        },
      );
    }

    // 显示占位图
    return _buildPlaceholder();
  }

  /// 构建占位图
  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey.shade800,
      child: const Icon(
        Icons.image_not_supported,
        size: 48,
        color: Colors.grey,
      ),
    );
  }

  /// 构建标题
  Widget _buildTitle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Text(
        video.description.isNotEmpty ? video.description : '无标题',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  /// 构建点赞数
  Widget _buildLikes() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const Icon(
            Icons.thumb_up,
            color: Colors.grey,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            _generateRandomLikes(),
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  /// 生成随机点赞数（占位用）
  String _generateRandomLikes() {
    // 生成 100-9999 之间的随机数
    return (100 + (DateTime.now().millisecondsSinceEpoch % 9900)).toString();
  }
}