/// 短视频数据模型
library;

import 'dart:typed_data';

/// 内容类型枚举
enum ContentType {
  normal,    // 普通短视频
  drama,     // 短剧
  episode,   // 短剧单集
}

/// 单个视频的数据结构
class VideoData {
  final String id;
  final String description; // 视频描述
  final Duration duration; // 视频时长
  final String coverUrl; // 封面图 URL
  String videoUrl; // 视频 URL
  final String? playUrl; // 视频 URL(带域名)

  // 预留字段（未来扩展）
  final String category; // 分类（推荐、关注等）
  final String? likes; // 喜欢
  final String? viewCount; // 查看次数

  // 短剧相关字段
  ContentType contentType; // 内容类型
  int? totalEpisodes;           // 总集数
  int? currentEpisode;          // 当前集数
  List<EpisodeInfo>? episodes;  // 集数列表（短剧详情页用）

  /// 封面图片缓存
  Uint8List? _cachedCover;

  /// 缓存解密后视频
  String? _decryptedVideo;

  /// 是否加载失败
  bool _loadFailed = false;
  /// 是否需要解密
  bool? needJiemi = false;

  /// 获取缓存的封面图片
  Uint8List? get cachedCover => _cachedCover;

  /// 设置缓存的封面图片
  set cachedCover(Uint8List? value) {
    _cachedCover = value;
  }

  /// 设置缓存的视频
  set decryptedVideo(String? value) {
    _decryptedVideo = value;
  }

  set setvideourl(String value) {
    videoUrl = value;
  }

  /// 是否已缓存封面
  bool get isCoverCached => _cachedCover != null;

  /// 是否加载失败
  bool get isLoadFailed => _loadFailed;

  /// 判断是否为短剧
  bool get isDrama => contentType == ContentType.drama;

  /// 判断是否为短剧单集
  bool get isEpisode => contentType == ContentType.episode;

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
    required this.videoUrl,
    this.needJiemi,
    this.playUrl,
    this.contentType = ContentType.normal,
    this.totalEpisodes,
    this.currentEpisode = 1,
    this.episodes,
    this.likes,
    this.viewCount,
  });

  /// 从 JSON 对象创建 VideoData 实例
  /// 用于将 API 返回的数据转换为本地数据模型
  factory VideoData.fromJson(Map<String, dynamic> json, int index) {
    return VideoData(
      id:
          json['id'] as String? ??
          'ks_${DateTime.now().millisecondsSinceEpoch}_$index',
      videoUrl: json['link'] as String? ?? '',
      playUrl: json['playUrl'] as String? ?? '',
      coverUrl: json['coverUrl'] as String? ?? '',
      description:
          json['title'] as String? ?? '', // API 的 title 映射到 description
      category:
          json['channelName'] as String? ??
          '', // API 的 channelName 映射到 category
      duration: const Duration(seconds: 0), // API 无此字段，使用默认值
      contentType: json['contentType'] as ContentType? ?? ContentType.normal, // 默认为普通视频
      needJiemi: json['needJiemi'] as bool? ?? false,
      currentEpisode: int.tryParse(json['collectionIndex']?.toString() ?? '1') ?? 1,
      totalEpisodes: int.tryParse(json['episodeCount']?.toString() ?? '0') ?? 0, // 集数
      likes: json['likeCount'] as String? ?? '',
      viewCount: json['viewCount'] as String? ?? '',
    );
  }
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
  /// [isjm] - 是否视频解密
  ///
  /// 返回视频数据列表
  Future<List<VideoData>> fetch({
    String? page,
    String? pagesize,
    String? collectionId,
    String? videoType,
    String? sortType,
    bool isjm = false
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
    String? pagesize,
    String? collectionId,
    String? videoType,
    String? sortType,
    required bool isjm
  })
  _fetchFunction;

  const VideoApiProviderImpl({
    required this.name,
    required this.enabled,
    required Future<List<VideoData>> Function({
      String? page,
      String? pagesize,
      String? collectionId,
      String? videoType,
      String? sortType,
      required bool isjm
    })
    fetchFunction,
  }) : _fetchFunction = fetchFunction;

  @override
  Future<List<VideoData>> fetch({
    String? page,
    String? pagesize,
    String? collectionId,
    String? videoType,
    String? sortType,
    bool isjm = false,
  }) {
    return _fetchFunction(
      page: page,
      pagesize: pagesize,
      collectionId: collectionId,
      videoType: videoType,
      sortType: sortType,
      isjm: isjm
    );
  }
}

/// 集数信息模型
class EpisodeInfo {
  final String episodeId;        // 集数ID
  final int episodeNumber;      // 集数编号
  final String title;           // 集数标题
  final String? description;     // 集数简介
  final String videoUrl;         // 视频URL

  const EpisodeInfo({
    required this.episodeId,
    required this.episodeNumber,
    required this.title,
    this.description,
    required this.videoUrl,
  });

  /// 从 JSON 创建 EpisodeInfo
  factory EpisodeInfo.fromJson(Map<String, dynamic> json) {
    return EpisodeInfo(
      episodeId: json['id'] as String? ?? '',
      episodeNumber: int.tryParse(json['episodeNumber']?.toString() ?? '1') ?? 1,
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      videoUrl: json['videoUrl'] as String? ?? '',
    );
  }
}

class TabsType {
  final String title;
  final String id;
  final String? videoType;
  final String? sortType;
  final String? collectionId;
  final bool isDramaType; // 是否为短剧类型

  const TabsType({
    required this.title,
    required this.id,
    this.videoType,
    this.sortType,
    this.collectionId,
    this.isDramaType = false,
  });
}
/// 合集页面顶部tabs数据
const List<Map<String, dynamic>> tabsData = [
      {
        'title': '推荐',
        'id': '0',
        'videoType': '1',
        'sortType': '7',
        'collectionId': '',
      },
      {
        'title': '绿帽',
        'id': '2',
        'videoType': '',
        'sortType': '2',
        'collectionId': '25',
      },
      {
        'title': '萝莉',
        'id': '3',
        'videoType': '',
        'sortType': '0',
        'collectionId': '31',
      },
      {
        'title': '深喉',
        'id': '4',
        'videoType': '',
        'sortType': '2',
        'collectionId': '11',
      },
      {
        'title': '泄密',
        'id': '5',
        'videoType': '',
        'sortType': '2',
        'collectionId': '8',
      },
      {
        'title': '麻豆',
        'id': '1',
        'videoType': '',
        'sortType': '0',
        'collectionId': '152',
      },
    ];

/// 合集页面分类数据
const List<Map<String, dynamic>> collectionCategories = [
      {
        'title': '绿帽淫妻',
        'id': '2',
        'videoType': '',
        'sortType': '2',
        'collectionId': '25',
      },
      {
        'title': '萝莉少女',
        'id': '3',
        'videoType': '',
        'sortType': '0',
        'collectionId': '31',
      },
      {
        'title': '暴力深喉',
        'id': '4',
        'videoType': '',
        'sortType': '2',
        'collectionId': '11',
      },
      {
        'title': '泄密流出',
        'id': '5',
        'videoType': '',
        'sortType': '2',
        'collectionId': '8',
      },
      {
        'title': '麻豆女神',
        'id': '1',
        'videoType': '',
        'sortType': '0',
        'collectionId': '152',
      },
];
