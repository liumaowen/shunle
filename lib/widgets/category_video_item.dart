import 'package:flutter/material.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:shunle/utils/cover_cache_manager.dart';
import 'package:shunle/utils/crypto/aes_encrypt_simple.dart';
import 'video_data.dart';

/// 分类视频列表项组件
class CategoryVideoItem extends StatefulWidget {
  final VideoData video;
  final VoidCallback? onImageLoaded;
  final VoidCallback? onToDetail;

  const CategoryVideoItem({
    required this.video,
    this.onImageLoaded,
    Key? key,
    this.onToDetail,
  });

  @override
  State<CategoryVideoItem> createState() => _CategoryVideoItemState();
}

class _CategoryVideoItemState extends State<CategoryVideoItem> {
  late final VideoData _video;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _video = widget.video;
    // 不再立即加载，等待可见性检测
  }

  @override
  void dispose() {
    // Timer 已移除，不需要清理
    super.dispose();
  }

  /// 异步加载图片
  void _loadImage() async {
    if (_isLoading) return; // 防止重复加载

    setState(() {
      _isLoading = true;
    });

    try {
      // 检查全局缓存
      final cacheManager = CoverCacheManager();
      if (cacheManager.isCached(_video.coverUrl)) {
        final cachedData = cacheManager.getFromCache(_video.coverUrl);
        if (cachedData != null && _video.cachedCover != cachedData) {
          _video.cachedCover = cachedData;
        }
      } else {
        // 没有缓存，开始解密
        final coverData = await AesEncryptSimple.fetchAndDecrypt(
          _video.coverUrl,
        );

        // 添加到全局缓存
        cacheManager.addToCache(_video.coverUrl, coverData);
        _video.cachedCover = coverData;
      }

      // 解密完成或已有缓存，更新UI显示图片
      if (mounted) {
        setState(() {
          _isLoading = false;
          // 图片已缓存，_buildImageContent 会自动显示图片
        });
      }

      // 通知监听器
      widget.onImageLoaded?.call();
    } catch (e) {
      debugPrint('加载图片失败: ${_video.coverUrl}, 错误: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// 构建图片内容

  /// 图片变为可见时的回调
  void _onImageVisible(VisibilityInfo info) {
    // 如果图片已经缓存，不需要加载
    if (_video.isCoverCached) {
      return;
    }
    debugPrint('图片变为可见: ${info.visibleFraction}');
    // 当组件超过50%可见时加载
    if (info.visibleFraction > 0.1) {
      // 开始加载图片
      _loadImage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key('video-item-${_video.id}'),
      onVisibilityChanged: _onImageVisible,
      child: GestureDetector(
        onTap: () {
          widget.onToDetail?.call();
        },
        child: Container(
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
        ),
      ),
    );
  }

  /// 构建图片
  Widget _buildImage() {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
      child: _buildImageContent(),
    );
  }

  /// 构建图片内容
  Widget _buildImageContent() {
    // 如果有缓存的封面图片
    if (_video.isCoverCached) {
      return Image.memory(
        _video.cachedCover!,
        fit: BoxFit.contain,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          return child;
        },
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholder();
        },
      );
    }

    // 如果正在加载，显示加载指示器
    if (_isLoading) {
      return Container(
        height: 280,
        color: Colors.grey.shade800,
        child: const Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
          ),
        ),
      );
    }

    // 显示占位图
    return _buildPlaceholder();
  }

  /// 构建占位图
  Widget _buildPlaceholder() {
    return Container(
      height: 280,
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
        _video.description.isNotEmpty ? _video.description : '无标题',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  /// 构建点赞数
  Widget _buildLikes() {
    return Padding(
      padding: const EdgeInsets.only(top: 0, left: 12, right: 12, bottom: 12),
      child: Row(
        children: [
          const Icon(Icons.visibility, color: Colors.grey, size: 14),
          const SizedBox(width: 4),
          Text(
            formatNumberSimple(_video.viewCount ?? '1'),
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.thumb_up, color: Colors.grey, size: 14),
          const SizedBox(width: 4),
          Text(
            formatNumberSimple(_video.likes ?? '1'),
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.favorite, color: Colors.grey, size: 14),
          const SizedBox(width: 4),
          Text(
            formatNumberSimple(_video.collectionCount ?? '1'),
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  String formatNumberSimple(String p) {
    int s = int.parse(p);
    if (s >= 10000) {
      s = s * 8;
      double wan = s / 10000;
      return '${(wan % 1 == 0) ? wan.toInt() : wan.toStringAsFixed(1)}万';
    }
    return s.toString();
  }
}
