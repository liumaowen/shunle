import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

/// M3U8 签名 URL 工具类
/// 用于生成和验证 M3U8 视频流签名的 URL
class M3U8Utils {
  /// 默认盐值
  static const String _defaultSalt = 'wB760Vqpk76oRSVA1TNz';

  /// 生成 M3U8 签名 URL
  ///
  /// [baseUrl] 基础 URL
  /// [path] 路径
  /// [salt] 盐值（可选）
  /// [expireSeconds] 过期时间（秒，可选）
  /// [key] 自定义密钥（可选）
  /// 返回签名的 URL
  static String generateSignedUrl({
    required String baseUrl,
    required String path,
    String salt = _defaultSalt,
    int? expireSeconds,
    String? key,
  }) {
    // 构建完整 URL
    final url = _joinUrl(baseUrl, path);

    // 生成时间戳
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final expireTime = expireSeconds != null ? timestamp + (expireSeconds * 1000) : null;

    // 生成签名
    final signature = _generateSignature(
      url: url,
      timestamp: timestamp,
      salt: salt,
      expireTime: expireTime,
      key: key,
    );

    // 构建查询参数
    final params = <String, String>{};
    params['t'] = timestamp.toString();
    params['sign'] = signature;

    if (expireTime != null) {
      params['e'] = expireTime.toString();
    }

    // 添加 URL 查询参数
    return _addQueryParams(url, params);
  }

  /// 生成 M3U8 Master 签名 URL
  ///
  /// [baseUrl] 基础 URL
  /// [salt] 盐值（可选）
  /// [expireSeconds] 过期时间（秒，可选）
  /// [key] 自定义密钥（可选）
  /// 返回 Master 签名 URL
  static String generateMasterUrl({
    required String baseUrl,
    String salt = _defaultSalt,
    int? expireSeconds,
    String? key,
  }) {
    final url = baseUrl.endsWith('/') ? baseUrl : '$baseUrl/';
    return generateSignedUrl(
      baseUrl: url,
      path: 'master.m3u8',
      salt: salt,
      expireSeconds: expireSeconds,
      key: key,
    );
  }

  /// 生成 M3U8 TS 签名 URL
  ///
  /// [baseUrl] 基础 URL
  /// [tsName] TS 文件名
  /// [salt] 盐值（可选）
  /// [expireSeconds] 过期时间（秒，可选）
  /// [key] 自定义密钥（可选）
  /// 返回 TS 签名 URL
  static String generateTsUrl({
    required String baseUrl,
    required String tsName,
    String salt = _defaultSalt,
    int? expireSeconds,
    String? key,
  }) {
    return generateSignedUrl(
      baseUrl: baseUrl,
      path: tsName,
      salt: salt,
      expireSeconds: expireSeconds,
      key: key,
    );
  }

  /// 验证 M3U8 URL 签名
  ///
  /// [url] 要验证的 URL
  /// [salt] 盐值（可选）
  /// [key] 自定义密钥（可选）
  /// 返回是否有效
  static bool validateSignature(String url, {String salt = _defaultSalt, String? key}) {
    try {
      // 解析 URL
      final uri = Uri.parse(url);

      // 获取查询参数
      final params = uri.queryParameters;

      // 检查必要参数
      if (!params.containsKey('t') || !params.containsKey('sign')) {
        return false;
      }

      // 获取时间戳和签名
      final timestamp = int.tryParse(params['t']!);
      final providedSignature = params['sign']!;

      if (timestamp == null) {
        return false;
      }

      // 检查过期时间
      if (params.containsKey('e')) {
        final expireTime = int.tryParse(params['e']!);
        if (expireTime != null && DateTime.now().millisecondsSinceEpoch > expireTime) {
          return false;
        }
      }

      // 移除签名参数，重新生成签名
      final cleanUrl = url.replaceAll(RegExp(r'[?&]sign=[^&]*'), '')
                          .replaceAll(RegExp(r'&sign=[^&]*'), '');

      if (cleanUrl.endsWith('?')) {
        cleanUrl.substring(0, cleanUrl.length - 1);
      }

      // 重新计算签名
      final expireTime = params.containsKey('e') ? int.tryParse(params['e']!) : null;
      final calculatedSignature = _generateSignature(
        url: cleanUrl,
        timestamp: timestamp,
        salt: salt,
        expireTime: expireTime,
        key: key,
      );

      // 比较签名
      return calculatedSignature == providedSignature;
    } catch (e) {
      return false;
    }
  }

  /// 检查 URL 是否过期
  ///
  /// [url] 要检查的 URL
  /// 返回是否过期
  static bool isExpired(String url) {
    try {
      final uri = Uri.parse(url);
      final params = uri.queryParameters;

      if (!params.containsKey('e')) {
        return false; // 没有过期时间，永不过期
      }

      final expireTime = int.tryParse(params['e']!);
      if (expireTime == null) {
        return false;
      }

      return DateTime.now().millisecondsSinceEpoch > expireTime;
    } catch (e) {
      return true; // 解析失败，视为过期
    }
  }

  /// 获取 URL 过期时间
  ///
  /// [url] URL 字符串
  /// 返回过期时间 DateTime，如果不存在或已过期返回 null
  static DateTime? getExpireTime(String url) {
    try {
      final uri = Uri.parse(url);
      final params = uri.queryParameters;

      if (!params.containsKey('e')) {
        return null; // 没有过期时间
      }

      final expireTime = int.tryParse(params['e']!);
      if (expireTime == null) {
        return null;
      }

      return DateTime.fromMillisecondsSinceEpoch(expireTime);
    } catch (e) {
      return null;
    }
  }

  /// 获取 URL 时间戳
  ///
  /// [url] URL 字符串
  /// 返回时间戳（毫秒），如果不存在返回 null
  static int? getTimestamp(String url) {
    try {
      final uri = Uri.parse(url);
      final params = uri.queryParameters;

      if (!params.containsKey('t')) {
        return null;
      }

      return int.tryParse(params['t']!);
    } catch (e) {
      return null;
    }
  }

  /// 生成签名
  static String _generateSignature({
    required String url,
    required int timestamp,
    required String salt,
    int? expireTime,
    String? key,
  }) {
    // 构建签名字符串
    final signString = _buildSignString(url, timestamp, salt, expireTime, key);

    // 使用 MD5 哈希
    final bytes = utf8.encode(signString);
    final digest = md5.convert(bytes);

    return digest.toString();
  }

  /// 构建签名字符串
  static String _buildSignString(
    String url,
    int timestamp,
    String salt,
    int? expireTime,
    String? key,
  ) {
    final keyString = key ?? '';
    final expireString = expireTime?.toString() ?? '';

    return '$url$timestamp$salt$expireString$keyString';
  }

  /// 合并 URL
  static String _joinUrl(String baseUrl, String path) {
    // 移除路径末尾的斜杠
    final cleanBaseUrl = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;

    // 确保路径以斜杠开头
    final cleanPath = path.startsWith('/') ? path : '/$path';

    return '$cleanBaseUrl$cleanPath';
  }

  /// 添加查询参数
  static String _addQueryParams(String url, Map<String, String> params) {
    final uri = Uri.parse(url);
    final existingParams = Map<String, String>.from(uri.queryParameters);

    // 添加新参数
    existingParams.addAll(params);

    // 重新构建 URL
    final newUri = uri.replace(queryParameters: existingParams);
    return newUri.toString();
  }

  /// 从 URL 提取路径
  static String extractPath(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.path;
    } catch (e) {
      return '';
    }
  }

  /// 生成随机盐值
  static String generateSalt({int length = 16}) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random.secure();

    return List.generate(length, (index) {
      return chars[random.nextInt(chars.length)];
    }).join();
  }

  /// 验证 URL 格式
  static bool isValidUrl(String url) {
    try {
      Uri.parse(url);
      return true;
    } catch (e) {
      return false;
    }
  }
}