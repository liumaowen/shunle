/// 短视频数据模型
library;

import 'dart:typed_data';

/// 单个视频的数据结构
class VideoData {
  final String id;
  final String description;      // 视频描述
  final Duration duration;        // 视频时长
  final String coverUrl;          // 封面图 URL
  final String? videoUrl;         // 视频 URL

  // 预留字段（未来扩展）
  final String authorName;        // 作者名称
  final String authorAvatar;      // 作者头像 URL
  final int likeCount;            // 点赞数
  final int commentCount;         // 评论数
  final String category;          // 分类（推荐、关注等）

  /// 封面图片缓存
  Uint8List? _cachedCover;

  /// 是否加载失败
  bool _loadFailed = false;

  /// 获取缓存的封面图片
  Uint8List? get cachedCover => _cachedCover;

  /// 设置缓存的封面图片
  set cachedCover(Uint8List? value) {
    _cachedCover = value;
  }

  /// 是否已缓存封面
  bool get isCoverCached => _cachedCover != null;

  /// 是否加载失败
  bool get isLoadFailed => _loadFailed;

  /// 标记为加载失败
  void markAsFailed() {
    _loadFailed = true;
  }

  VideoData({
    required this.id,
    required this.description,
    required this.duration,
    required this.category,
    this.coverUrl = '',
    this.videoUrl,
    this.authorName = '未知用户',
    this.authorAvatar = '',
    this.likeCount = 0,
    this.commentCount = 0,
  });

  /// 从 JSON 对象创建 VideoData 实例
  /// 用于将 API 返回的数据转换为本地数据模型
  factory VideoData.fromJson(Map<String, dynamic> json, int index) {
    return VideoData(
      id: json['id'] as String? ?? 'ks_${DateTime.now().millisecondsSinceEpoch}_$index',
      videoUrl: json['link'] as String? ?? '',
      coverUrl: json['coverUrl'] as String? ?? '',
      description: json['title'] as String? ?? '',  // API 的 title 映射到 description
      category: json['type'] as String? ?? '',      // API 的 type 映射到 category
      duration: const Duration(seconds: 0), // API 无此字段，使用默认值
      authorName: '未知用户',                        // API 无此字段，使用默认值
      authorAvatar: '',                             // API 无此字段，使用默认值
      likeCount: 0,                                 // API 无此字段，使用默认值
      commentCount: 0,                              // API 无此字段，使用默认值
    );
  }
}

/// 生成模拟视频数据
List<VideoData> generateMockVideos(String category, {int count = 20}) {
  return List.generate(count, (index) {
    return VideoData(
      id: '$category-$index',
      description: '这是$category视频 #${index + 1}',
      duration: Duration(seconds: 30 + (index % 5) * 10),
      category: category,
      authorName: '用户${index + 1}',
      likeCount: 100 + index * 10,
      commentCount: 20 + index * 5,
    );
  });
}

/// 视频 API 提供者接口
abstract class VideoApiProvider {
  String get name;
  bool get enabled;

  /// 获取视频列表
  ///
  /// [collectionId] - 集合 ID（可选）
  /// [videoType] - 视频类型（可选）
  /// [sortType] - 排序类型（可选）
  ///
  /// 返回视频数据列表
  Future<List<VideoData>> fetch({
    String? page,
    String? collectionId,
    String? videoType,
    String? sortType,
  });
}

/// VideoApiProvider 的具体实现类
class VideoApiProviderImpl implements VideoApiProvider {
  @override
  final String name;

  @override
  final bool enabled;

  final Future<List<VideoData>> Function({
    String? page,
    String? collectionId,
    String? videoType,
    String? sortType,
  }) _fetchFunction;

  const VideoApiProviderImpl({
    required this.name,
    required this.enabled,
    required Future<List<VideoData>> Function({
      String? page,
      String? collectionId,
      String? videoType,
      String? sortType,
    }) fetchFunction,
  }) : _fetchFunction = fetchFunction;

  @override
  Future<List<VideoData>> fetch({
    String? page,
    String? collectionId,
    String? videoType,
    String? sortType,
  }) {
    return _fetchFunction(
      page: page,
      collectionId: collectionId,
      videoType: videoType,
      sortType: sortType,
    );
  }
}

class TabsType {
  final String title;
  final String id;
  final String? videoType;
  final String? sortType;
  final String? collectionId;

  const TabsType({
    required this.title,
    required this.id,
    this.videoType,
    this.sortType,
    this.collectionId,
  });
}

