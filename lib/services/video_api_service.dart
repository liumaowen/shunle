/// 视频 API 服务层
library;

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shunle/providers/global_config.dart';
import 'package:shunle/widgets/video_data.dart';
import 'package:shunle/utils/crypto/uuid_utils.dart';
import 'package:shunle/utils/api/config_api_service.dart';

/// 视频 API 服务，封装所有视频数据的网络请求
class VideoApiService {
  /// API 基础 URL
  static const String baseUrl = 'https://www.qylapi.top/api/ksvideo';

  /// 请求超时时间（秒）
  static const Duration timeout = Duration(seconds: 60);

  /// 获取视频列表
  ///
  /// 参数:
  /// - [page]: 页码，从 1 开始
  /// - [size]: 每页数量，默认 10
  ///
  /// 返回: 视频数据列表
  ///
  /// 异常:
  /// - 网络错误
  /// - API 返回错误
  /// - JSON 解析失败
  Future<List<VideoData>> fetchVideos({
    required int page,
    int size = 10,
  }) async {
    try {
      // 构建 URL
      final uri = Uri.parse(baseUrl).replace(
        queryParameters: {'page': page.toString(), 'size': size.toString()},
      );

      // 发送 GET 请求
      final response = await http.get(uri).timeout(timeout);

      // 检查响应状态码
      if (response.statusCode == 200) {
        // 解析 JSON
        final jsonData = json.decode(response.body);
        // 检查 API 返回状态
        if (jsonData != null) {
          final List<dynamic> dataList = jsonData as List<dynamic>;

          // 将 JSON 转换为 VideoData 对象列表
          return dataList.indexed
              .map(
                (item) => VideoData.fromJson(
                  item.$2 as Map<String, dynamic>,
                  item.$1,
                ),
              )
              .toList();
        } else {
          throw Exception('API 返回错误: code=${jsonData['code']}');
        }
      } else {
        throw Exception('HTTP 错误: ${response.statusCode}');
      }
    } on http.ClientException catch (e) {
      throw Exception('网络连接失败: $e');
    } catch (e) {
      throw Exception('请求失败: $e');
    }
  }
}

/// 获取配置信息（已弃用，使用 ConfigApiService.fetchConfig）
@Deprecated('使用 ConfigApiService.fetchConfig 替代')
void getconfig() async {
  try {
    // 使用新的配置 API 服务
    final config = await ConfigApiService.fetchConfigSafe();

    // 打印配置信息
    print('配置获取成功:');
    print('播放域名: ${config['playDomain']}');
    print('短视频随机最大值: ${config['shortVideoRandomMax']}');
    print('短视频随机最小值: ${config['shortVideoRandomMin']}');

  } catch (e) {
    print('配置获取失败: $e');
  }
}

// ignore: non_constant_identifier_names
List<VideoApiProvider> API_PROVIDERS = [
  VideoApiProviderImpl(
    name: 'Kuaishou',
    enabled: true,
    fetchFunction: ({collectionId, videoType, sortType}) {
      return VideoApiService().fetchVideos(page: 1, size: 10);
    },
  ),
];

/// 从所有启用的 API 提供商获取视频并合并
/// @param collectionId 收藏ID，用于不同分类的视频获取
Future<List<VideoData>> fetchFromAllProviders({
  String? collectionId,
  String? videoType,
  String? sortType,
}) async {
  final enabledProviders = API_PROVIDERS.where((p) => p.enabled).toList();

  final futures = enabledProviders.map((provider) async {
    try {
      final videos = await provider.fetch();
      return {'success': true, 'data': videos, 'provider': provider.name};
    } catch (e) {
      return {'success': false, 'error': e, 'provider': provider.name};
    }
  }).toList();

  final results = await Future.wait(futures);

  final allVideos = <VideoData>[];
  for (final result in results) {
    if (result.containsKey('success') && result['success'] == true) {
      print('${result['provider']}: 获取 ${(result['data'] as List).length} 个视频');
      allVideos.addAll(result['data'] as List<VideoData>);
    } else {
      debugPrint('${result['provider']}: 请求失败 - ${result['error']}');
    }
  }

  return allVideos;
}

/// 本地视频资源（示例数据）
class LocalVideoResource {
  static const List<Map<String, dynamic>> mockVideos = [
    {
      'id': 'local_1',
      'title': '本地视频 1',
      'link': 'assets/videos/1.mp4',
      'coverUrl': '',
      'type': '本地',
    },
    {
      'id': 'local_2',
      'title': '本地视频 2',
      'link': 'assets/videos/2.mp4',
      'coverUrl': '',
      'type': '本地',
    },
    {
      'id': 'local_3',
      'title': '本地视频 3',
      'link': 'assets/videos/3.mp4',
      'coverUrl': '',
      'type': '本地',
    },
  ];

  /// 获取本地视频列表
  static List<VideoData> getLocalVideos() {
    return mockVideos
        .asMap()
        .entries
        .map((entry) => VideoData.fromJson(entry.value, entry.key))
        .toList();
  }
}
