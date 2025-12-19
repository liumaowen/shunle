import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:shunle/utils/crypto/crypto_utils.dart';
import 'package:shunle/utils/crypto/uuid_utils.dart';
import 'package:shunle/providers/global_config.dart';

/// 配置 API 服务 - 获取系统配置信息
class ConfigApiService {
  /// 配置 API 基础 URL
  static const String baseUrl = 'https://api.mgtv109.cc';

  /// 请求超时时间（毫秒）
  static const Duration timeout = Duration(seconds: 60);

  /// 获取配置信息
  ///
  /// 对应 JavaScript 代码：fetchConfig
  ///
  /// 返回配置数据，包含：
  /// - shortVideoRandomMax: 短视频随机最大值
  /// - shortVideoRandomMin: 短视频随机最小值
  /// - playDomain: 播放域名
  static Future<Map<String, dynamic>> fetchConfig() async {
    try {
      // 构建 URL
      final uri = Uri.parse('$baseUrl/Web/Config');

      // 请求头
      final headers = {
        'authorization': 'Bearer null',
        'priority': 'u=1, i',
        'x-auth-uuid': UUIDUtils.generateV4(),
        'content-type': 'application/x-www-form-urlencoded; charset=UTF-8'
      };

      // 发送 POST 请求
      final response = await http.post(
        uri,
        headers: headers,
        body: {}, // JavaScript 中传入的空对象 {}
      ).timeout(timeout);

      if (response.statusCode == 200) {
        // JavaScript 中使用 TextDecoder 解码 ArrayBuffer
        // 在 Dart 中，http.Response.body 已经是 String 类型
        final text = response.body;
        // 解密数据
        final decryptedPassword = await CryptoUtils.aesDecrypt(text);

        // 解析 JSON
        final list99 = json.decode(decryptedPassword);

        // 提取数据
        final list100 = list99?['data'] ?? [];

        // 解析配置
        int shortVideoRandomMax = 200; // 默认值
        int shortVideoRandomMin = 1;  // 默认值
        String? playDomain;

        for (final element in list100) {
          if (element is Map<String, dynamic>) {
            if (element['pKey'] == 'ShortVideoRandomPage') {
              shortVideoRandomMax = num.tryParse(element['value2']?.toString() ?? '200')?.toInt() ?? 200;
              shortVideoRandomMin = num.tryParse(element['value1']?.toString() ?? '1')?.toInt() ?? 1;
            }
            if (element['pKey'] == 'PlayDomain') {
              playDomain = element['value1'];
            }
          }
        }

        // 更新全局配置
        if (playDomain != null) {
          GlobalConfig.updatePlayDomain(playDomain);
        }

        // 返回配置
        return {
          'shortVideoRandomMax': shortVideoRandomMax,
          'shortVideoRandomMin': shortVideoRandomMin,
          'playDomain': playDomain ?? GlobalConfig.playDomain,
        };
      } else {
        throw Exception('HTTP 错误: ${response.statusCode}');
      }
    } on http.ClientException catch (e) {
      throw Exception('网络连接失败: $e');
    } catch (e) {
      throw Exception('获取配置失败: $e');
    }
  }

  /// 获取配置并返回默认值（失败时使用）
  ///
  /// 对应 JavaScript 代码中的 catch 返回值
  static Map<String, dynamic> getDefaultConfig() {
    return {
      'shortVideoRandomMax': 200,
      'shortVideoRandomMin': 1,
      'playDomain': GlobalConfig.playDomain,
    };
  }

  /// 带错误处理的获取配置方法
  ///
  /// 类似 JavaScript 中的 try-catch 模式
  static Future<Map<String, dynamic>> fetchConfigSafe() async {
    try {
      return await fetchConfig();
    } catch (error) {
      print('获取配置失败: $error');
      return getDefaultConfig();
    }
  }
}