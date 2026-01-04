import 'package:flutter/material.dart';
import 'package:shunle/utils/cover_cache_manager.dart';
import 'package:shunle/utils/crypto/aes_encrypt_simple.dart';
import 'video_data.dart';
import 'visibility_detector.dart';

/// 分类视频列表项组件
class CategoryVideoItem extends StatefulWidget {
  final VideoData video;
  final VoidCallback? onImageLoaded;

  const CategoryVideoItem({
    required this.video,
    this.onImageLoaded,
    Key? key,
  });

  @override
  State<CategoryVideoItem> createState() => _CategoryVideoItemState();
}

class _CategoryVideoItemState extends State<CategoryVideoItem> {
  late final VideoData _video;

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
    try {
      // 检查全局缓存
      final cacheManager = CoverCacheManager();
      if (cacheManager.isCached(_video.coverUrl)) {
        final cachedData = cacheManager.getFromCache(_video.coverUrl);
        if (cachedData != null && _video.cachedCover != cachedData) {
          _video.cachedCover = cachedData;
        }
        _updateImageState();
        return;
      }

      // 如果没有缓存，立即开始解密加载
      _updateImageState();

      // 使用类似VideoApiService中的解密逻辑
      final coverData = await AesEncryptSimple.fetchAndDecrypt(
        _video.coverUrl,
      );

      // 添加到全局缓存
      cacheManager.addToCache(_video.coverUrl, coverData);
      // 设置到当前视频
      _video.cachedCover = coverData;

      // 更新UI
      if (mounted) {
        setState(() {
          // 图片已缓存，会自动更新UI
        });
      }

      // 通知监听器
      widget.onImageLoaded?.call();
    } catch (e) {
      debugPrint('加载图片失败: ${_video.coverUrl}, 错误: $e');
    }
  }

  /// 更新图片状态
  void _updateImageState() {
    setState(() {
      // 图片状态更新
    });
  }

  /// 图片变为可见时的回调
  void _onImageVisible() {
    // 如果图片已经缓存，不需要加载
    if (_video.isCoverCached) {
      return;
    }

    // 开始加载图片
    _loadImage();
  }

  /// 图片变为不可见时的回调
  void _onImageInvisible() {
    // 图片不可见时，可以取消加载
    // 这里简单处理，不清除已缓存的数据
  }

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
          // 图片部分 - 使用可见性检测
          VisibilityDetector(
            onVisible: _onImageVisible,
            onInvisible: _onImageInvisible,
            child: _buildImage(),
          ),
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
        _video.description.isNotEmpty ? _video.description : '无标题',
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