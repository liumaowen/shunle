/// 视频 API 服务层
library;

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../widgets/video_data.dart';

/// 视频 API 服务，封装所有视频数据的网络请求
class VideoApiService {
  /// API 基础 URL
  static const String baseUrl = 'https://www.qylapi.top/api/ksvideo';

  /// 请求超时时间（秒）
  static const Duration timeout = Duration(seconds: 10);

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
      final uri = Uri.parse(baseUrl).replace(queryParameters: {
        'page': page.toString(),
        'size': size.toString(),
      });

      // 发送 GET 请求
      final response = await http.get(uri).timeout(timeout);

      // 检查响应状态码
      if (response.statusCode == 200) {
        // 解析 JSON
        final jsonData = json.decode(response.body);

        // 检查 API 返回状态
        if (jsonData['code'] == 200 && jsonData['data'] != null) {
          final List<dynamic> dataList = jsonData['data'] as List<dynamic>;

          // 将 JSON 转换为 VideoData 对象列表
          return dataList
              .map((item) => VideoData.fromJson(item as Map<String, dynamic>))
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
