/// 短视频数据模型
library;

/// 单个视频的数据结构
class VideoData {
  final String id;
  final String description;      // 视频描述
  final Duration duration;        // 视频时长
  final String coverUrl;          // 封面图 URL（预留，未来实现）
  final String? videoUrl;         // 视频 URL（预留，未来实现）

  // 预留字段（未来扩展）
  final String authorName;        // 作者名称
  final String authorAvatar;      // 作者头像 URL
  final int likeCount;            // 点赞数
  final int commentCount;         // 评论数
  final String category;          // 分类（推荐、关注等）

  const VideoData({
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
  factory VideoData.fromJson(Map<String, dynamic> json) {
    return VideoData(
      id: json['id'] as String? ?? '',
      videoUrl: json['videoUrl'] as String? ?? '',
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
