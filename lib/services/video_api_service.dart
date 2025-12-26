/// 视频 API 服务层
library;

import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shunle/providers/global_config.dart';
import 'package:shunle/widgets/video_data.dart';
import 'package:shunle/utils/crypto/uuid_utils.dart';
import 'package:shunle/services/crypto_compute_service.dart';

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
  static Future<List<VideoData>> fetchVideos({
    required String page,
    String size = '10,',
  }) async {
    try {
      // 构建 URL
      final uri = Uri.parse(
        baseUrl,
      ).replace(queryParameters: {'page': page, 'size': size});

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

  /// 获取配置信息
  static Future<Mgtvconfig> fetchConfigSafe() async {
    try {
      return await getConfig();
    } catch (error) {
      print('获取配置失败: $error');
      return Mgtvconfig();
    }
  }

  static Future<List<VideoData>> fetchMgtvList(
    Map<String, String> mgtvForm,
  ) async {
    try {
      // 获取配置信息
      final config = GlobalConfig.instance;
      // 构建 URL
      final uri = Uri.parse('${GlobalConfig.apiBase}/Web/VideoList');
      // 构建请求头
      final headers = {
        "authorization": "Bearer null",
        "priority": "u=1, i",
        "x-auth-uuid": UUIDUtils.generateV4(),
        "content-type": "application/x-www-form-urlencoded; charset=UTF-8",
      };
      // 发送 POST 请求
      final response = await http
          .post(
            uri,
            headers: headers,
            body: Uri(queryParameters: mgtvForm).query,
          )
          .timeout(timeout);
      if (response.statusCode == 200) {
        final text = response.body;
        // ✅ 使用 Isolate 解密数据（不阻塞主线程）
        final decryptedPassword = await CryptoComputeService.instance.decrypt(
          text,
        );
        // 解析 JSON
        final list99 = json.decode(decryptedPassword);
        // 提取数据
        final list100 = list99?['data']['items'] ?? [];
        final List<dynamic> dataList = list100 as List<dynamic>;

        // ✅ 使用 Isolate 生成所有 m3u8 URL
        for (final element in dataList) {
          element['link'] = await CryptoComputeService.instance.getm3u8(
            config.playDomain,
            element['playUrl'],
          );
          element['playUrl'] = element['playUrl'];
          element['needJiemi'] = true;

          // 设置封面 URL
          // element['coverUrl'] = '${config.playDomain}${element['imgUrl']}';
        }
        if (dataList.isEmpty) {
          return [];
        } else {
          // 将 JSON 转换为 VideoData 对象列表
          return dataList.indexed
              .map(
                (item) => VideoData.fromJson(
                  item.$2 as Map<String, dynamic>,
                  item.$1,
                ),
              )
              .toList();
        }
      } else {
        throw Exception('HTTP 错误: ${response.statusCode}');
      }
    } catch (error) {
      throw Exception('获取Mgtv失败: $error');
    }
  }

  /// 获取短剧
  static Future<List<VideoData>> fetchDrama(
    Map<String, String> dramaForm,
  ) async {
    try {
      // 获取配置信息
      final config = GlobalConfig.instance;
      // 构建 URL
      final uri = Uri.parse(
        '${GlobalConfig.apiBase}/ShortMovie/ShortMovieList',
      );
      // 构建请求头
      final headers = {
        "authorization": "Bearer null",
        "Accept": "application/json, text/plain, */*",
        "x-auth-uuid": UUIDUtils.generateV4(),
        "content-type": "application/x-www-form-urlencoded; charset=UTF-8",
      };
      // ✅ 使用 Isolate 加密（不阻塞主线程）
      final String aesform = await CryptoComputeService.instance.encrypt(
        json.encode(dramaForm),
      );
      // 发送 POST 请求
      final response = await http
          .post(uri, headers: headers, body: aesform)
          .timeout(timeout);
      if (response.statusCode == 200) {
        final text = response.body;
        // ✅ 使用 Isolate 解密数据（不阻塞主线程）
        final decryptedPassword = await CryptoComputeService.instance.decrypt(
          text,
        );
        // 解析 JSON
        final list99 = json.decode(decryptedPassword);
        // 提取数据
        final list100 = list99?['data']['items'] ?? [];
        final List<dynamic> dataList = list100 as List<dynamic>;

        // ✅ 使用 Isolate 生成所有 m3u8 URL
        for (final element in dataList) {
          element['link'] = await CryptoComputeService.instance.getm3u8(
            config.playDomain,
            element['first']['playUrl'],
          );
          element['contentType'] = ContentType.drama;
          element['needJiemi'] = true;
          element['playUrl'] = element['first']['playUrl'];
          // 设置封面 URL
          // element['coverUrl'] = '${config.playDomain}${element['imgUrl']}';
        }

        if (dataList.isEmpty) {
          return [];
        } else {
          // 将 JSON 转换为 VideoData 对象列表
          return dataList.indexed
              .map(
                (item) => VideoData.fromJson(
                  item.$2 as Map<String, dynamic>,
                  item.$1,
                ),
              )
              .toList();
        }
      } else {
        throw Exception('HTTP 错误: ${response.statusCode}');
      }
    } catch (error) {
      throw Exception('获取drama失败: $error');
    }
  }

  /// 获取短剧详情
  /// 参数:
  /// - dramaId: 短剧ID
  ///
  /// 返回:
  /// - VideoData 列表，包含完整的集数列表
  ///
  static Future<List<VideoData>> getDramaDetail(String dramaId) async {
    try {
      // 获取配置信息
      final config = GlobalConfig.instance;
      // 构建 URL
      final uri = Uri.parse(
        '${GlobalConfig.apiBase}/ShortMovie/ShortMovieDetail',
      );
      // 构建请求头
      final headers = {
        "authorization": "Bearer null",
        "Accept": "application/json, text/plain, */*",
        "x-auth-uuid": UUIDUtils.generateV4(),
        "content-type": "application/x-www-form-urlencoded; charset=UTF-8",
      };
      // ✅ 使用 Isolate 加密（不阻塞主线程）
      final String aesform = await CryptoComputeService.instance.encrypt(
        json.encode({"Id": dramaId}),
      );
      // 发送 POST 请求
      final response = await http
          .post(uri, headers: headers, body: aesform)
          .timeout(timeout);
      if (response.statusCode == 200) {
        final text = response.body;
        // ✅ 使用 Isolate 解密数据（不阻塞主线程）
        final decryptedPassword = await CryptoComputeService.instance.decrypt(
          text,
        );
        // 解析 JSON
        final list99 = json.decode(decryptedPassword);
        // 提取数据
        final list100 = list99?['data']['items'] ?? [];
        final List<dynamic> dataList = list100 as List<dynamic>;

        // ✅ 使用 Isolate 生成前 5 个视频的 m3u8 URL
        for (var i = 0; i < dataList.length; i++) {
          final element = dataList[i];
          if (i < 5) {
            element['link'] = await CryptoComputeService.instance.getm3u8(
              config.playDomain,
              element['playUrl'],
            );
          }
          element['playUrl'] = element['playUrl'];
          element['contentType'] = ContentType.episode;
          element['needJiemi'] = true;
          // 设置封面 URL
          // element['coverUrl'] = '${config.playDomain}${element['imgUrl']}';
        }
        if (dataList.isEmpty) {
          return [];
        } else {
          // 将 JSON 转换为 VideoData 对象列表
          return dataList.indexed
              .map(
                (item) => VideoData.fromJson(
                  item.$2 as Map<String, dynamic>,
                  item.$1,
                ),
              )
              .toList();
        }
      } else {
        throw Exception('获取drama详情HTTP 错误: ${response.statusCode}');
      }
    } catch (error) {
      throw Exception('获取drama详情失败: $error');
    }
  }

  static Future<bool> isVideoUrlValid(String videoUrl) async {
    try {
      final response = await http
          .head(Uri.parse(videoUrl))
          .timeout(const Duration(seconds: 5));
      // 返回状态码200表示有效
      return response.statusCode == 200;
    } catch (e) {
      // 请求异常，视为无效
      return false;
    }
  }

  /// 获取短剧详情（新方法，返回完整的短剧信息）
  ///
  /// 参数:
  /// - dramaId: 短剧ID
  ///
  /// 返回:
  /// - VideoData 包含完整的集数列表信息
  ///
  static Future<VideoData?> getDramaDetailWithEpisodes(String dramaId) async {
    try {
      // 首先获取短剧基本信息
      final uri = Uri.parse(
        '${GlobalConfig.apiBase}/ShortMovie/ShortMovieDetail',
      );
      final headers = {
        "authorization": "Bearer null",
        "Accept": "application/json, text/plain, */*",
        "x-auth-uuid": UUIDUtils.generateV4(),
        "content-type": "application/x-www-form-urlencoded; charset=UTF-8",
      };

      // ✅ 使用 Isolate 加密（不阻塞主线程）
      final response = await http
          .post(
            uri,
            headers: headers,
            body: await CryptoComputeService.instance.encrypt(
              json.encode({"Id": dramaId}),
            ),
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final text = response.body;
        // ✅ 使用 Isolate 解密数据（不阻塞主线程）
        final decryptedPassword = await CryptoComputeService.instance.decrypt(
          text,
        );
        final jsonData = json.decode(decryptedPassword);
        final dramaData = jsonData?['data'];

        if (dramaData == null) {
          return null;
        }

        // 解析短剧基本信息
        final drama = VideoData(
          id: dramaId,
          description: dramaData['name'] ?? '',
          duration: const Duration(seconds: 0),
          coverUrl: dramaData['imgUrl'] ?? '',
          videoUrl: '',
          category: 'drama',
          contentType: ContentType.drama,
          totalEpisodes: dramaData['totalEpisodes']?.toInt() ?? 0,
          episodes: [],
        );

        // 解析集数列表
        final episodesList = dramaData['items'] as List?;
        if (episodesList != null) {
          drama.episodes = episodesList.map((episodeJson) {
            return EpisodeInfo.fromJson(episodeJson);
          }).toList();
        }

        return drama;
      } else {
        throw Exception('获取短剧详情HTTP 错误: ${response.statusCode}');
      }
    } catch (error) {
      throw Exception('获取短剧详情失败: $error');
    }
  }

  static Future<Mgtvconfig> getConfig() async {
    try {
      Mgtvconfig mgtvconfig = Mgtvconfig();
      int shortVideoRandomMax = mgtvconfig.shortVideoRandomMax; // 默认值
      int shortVideoRandomMin = mgtvconfig.shortVideoRandomMin; // 默认值
      String playDomain = mgtvconfig.playDomain;
      // 构建 URL
      final uri = Uri.parse('${GlobalConfig.apiBase}/Web/Config');
      // 请求头
      final headers = {
        'authorization': 'Bearer null',
        'priority': 'u=1, i',
        'x-auth-uuid': UUIDUtils.generateV4(),
        'content-type': 'application/x-www-form-urlencoded; charset=UTF-8',
      };
      // 发送 POST 请求
      final response = await http.post(uri, headers: headers).timeout(timeout);
      if (response.statusCode == 200) {
        final text = response.body;
        // ✅ 使用 Isolate 解密数据（不阻塞主线程）
        final decryptedPassword = await CryptoComputeService.instance.decrypt(
          text,
        );
        // 解析 JSON
        final list99 = json.decode(decryptedPassword);
        // 提取数据
        final list100 = list99?['data'] ?? [];
        for (final element in list100) {
          if (element is Map<String, dynamic>) {
            if (element['pKey'] == 'ShortVideoRandomPage') {
              shortVideoRandomMax =
                  num.tryParse(
                    element['value2']?.toString() ?? '200',
                  )?.toInt() ??
                  200;
              shortVideoRandomMin =
                  num.tryParse(element['value1']?.toString() ?? '1')?.toInt() ??
                  1;
            }
            if (element['pKey'] == 'PlayDomain') {
              playDomain = element['value1'];
            }
          }
        }
        mgtvconfig = Mgtvconfig(
          shortVideoRandomMax: shortVideoRandomMax,
          shortVideoRandomMin: shortVideoRandomMin,
          playDomain: playDomain,
          initialized: true,
        );
        GlobalConfig.initialize(mgtvconfig);
        return mgtvconfig;
      } else {
        throw Exception('HTTP 获取配置错误: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('配置获取失败: $e');
    }
  }

  // ignore: non_constant_identifier_names
  static List<VideoApiProvider> API_PROVIDERS = [
    VideoApiProviderImpl(
      name: 'Kuaishou',
      enabled: false,
      fetchFunction: ({page, pagesize, videoType, sortType, collectionId}) {
        return VideoApiService.fetchVideos(
          page: page ?? '1',
          size: pagesize ?? '10',
        );
      },
    ),
    VideoApiProviderImpl(
      name: 'Mgtv',
      enabled: true,
      fetchFunction: ({page, pagesize, videoType, sortType, collectionId}) {
        int pageindex =
            (Random().nextDouble() *
                    (GlobalConfig.shortVideoRandomMax -
                        GlobalConfig.shortVideoRandomMin +
                        1))
                .floor() +
            GlobalConfig.shortVideoRandomMin;
        Map<String, String> mgtvForm = {
          'PageIndex': page!.isNotEmpty ? page : pageindex.toString(),
          'PageSize': pagesize!.isNotEmpty ? pagesize : '5',
          'VideoType': videoType ?? '',
          'SortType': sortType ?? '0',
          'CollectionId': collectionId ?? '',
        };
        return VideoApiService.fetchMgtvList(mgtvForm);
      },
    ),
  ];

  /// 从所有启用的 API 提供商获取视频并合并
  /// @param collectionId 收藏ID，用于不同分类的视频获取
  static Future<List<VideoData>> fetchFromAllProviders({
    String? page,
    String? pagesize,
    String? videoType,
    String? sortType,
    String? collectionId,
  }) async {
    final enabledProviders = API_PROVIDERS.where((p) => p.enabled).toList();
    final futures = enabledProviders.map((provider) async {
      try {
        final videos = await provider.fetch(
          page: page,
          pagesize: pagesize,
          collectionId: collectionId,
          videoType: videoType,
          sortType: sortType,
        );
        return {'success': true, 'data': videos, 'provider': provider.name};
      } catch (e) {
        return {'success': false, 'error': e, 'provider': provider.name};
      }
    }).toList();

    final results = await Future.wait(futures);

    final allVideos = <VideoData>[];
    for (final result in results) {
      if (result.containsKey('success') && result['success'] == true) {
        print(
          '${result['provider']}: 获取 ${(result['data'] as List).length} 个视频',
        );
        allVideos.addAll(result['data'] as List<VideoData>);
      } else {
        debugPrint('${result['provider']}: 请求失败 - ${result['error']}');
      }
    }

    return allVideos;
  }
}

/// 获取 短剧 视频
Future<List<VideoData>> getDrama({
  String? page,
  String? pagesize,
  String? videoType,
  String? sortType,
  String? collectionId,
}) async {
  Map<String, String> dramaForm = {
    'PageIndex': page!.isNotEmpty ? page : '1',
    'PageSize': pagesize!.isNotEmpty ? pagesize : '5',
    'ChannelId': '',
    'GenderChannelType': '',
  };
  return VideoApiService.fetchDrama(dramaForm);
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
