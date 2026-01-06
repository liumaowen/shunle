import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:shunle/providers/global_config.dart';
import 'dart:convert';
import 'dart:math';
import 'package:shunle/utils/crypto/aes_encrypt_simple.dart';

/// 自定义超时异常类
class TimeoutException implements Exception {
  final String message;
  final Duration duration;

  const TimeoutException(this.message, this.duration);

  @override
  String toString() => message;
}

class ApiBase {
  /// 最大重试次数
  static const int _maxRetries = 3;

  /// 请求延迟（毫秒）
  static const int _retryDelay = 1000;

  /// 带重试机制的HTTP GET请求
  static Future<http.Response> _getWithRetry(Uri url) async {
    Exception? lastError;

    for (int i = 0; i < _maxRetries; i++) {
      try {
        final response = await http.get(
          url,
          headers: {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36 Edg/143.0.0.0',
            'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7',
          },
        ).timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            throw TimeoutException('请求超时，请检查网络连接', const Duration(seconds: 30));
          },
        );

        if (response.statusCode == 200) {
          return response;
        } else {
          throw Exception('HTTP ${response.statusCode}: ${response.body}');
        }
      } catch (e) {
        lastError = e is Exception ? e : Exception(e.toString());
        debugPrint('请求失败 (${i + 1}/$_maxRetries): $e');

        if (i < _maxRetries - 1) {
          await Future.delayed(Duration(milliseconds: _retryDelay));
        }
      }
    }

    throw lastError ?? Exception('未知错误');
  }

  /// 获取基础URL并更新全局配置
  static Future<void> getBaseUrl() async {
    final url = GlobalConfig.yongjiuapiBase;
    final firsturl = await _getFirstUrl(url);
    if (firsturl.startsWith('http')) {
      final secondurl = await getSecondUrl(firsturl);
      if (secondurl.startsWith('http')) {
        final finalurl = await getFinalUrlFromApi(secondurl);
        if (finalurl.startsWith('http')) {
          GlobalConfig.apiBase = finalurl;
        }
      }
    }
  }

  /// 从API获取最终地址
  static Future<String> getFinalUrlFromApi(String url) async {
    try {
      final domain = Uri.parse(url).host.split('.').sublist(1).join('.');
      final params = {"Domain": domain};
      final encryptedDomain = AesEncryptSimple.encrypt(json.encode(params));

      final apiUrl =
          '${Uri.parse(url).scheme}://${Uri.parse(url).host}/Web/GetJumpURL2';

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "text/plain"},
        body: encryptedDomain,
      );

      if (response.statusCode == 200) {
        final decryptedResponse = AesEncryptSimple.decrypt(response.body);
        final data = json.decode(decryptedResponse);
        final List<String> domains = data['data']['jumpDomains']?.split(',');
        if (domains.isEmpty) {
          return '无法从API获取最终地址';
        }
        return domains[0];
      } else {
        return 'API请求失败';
      }
    } catch (e) {
      return '从API获取最终地址时出错: $e';
    }
  }

  /// 获取第二页的 URL
  static Future<String> getSecondUrl(String url) async {
    try {
      final response = await _getWithRetry(Uri.parse(url));
      if (response.statusCode == 200) {
        final document = parser.parse(response.body);
        final scripts = document.querySelectorAll('script');

        String? scriptContentWithDomains;
        for (var script in scripts) {
          if (script.text.contains('mainDomains')) {
            scriptContentWithDomains = script.text;
            break;
          }
        }

        if (scriptContentWithDomains != null) {
          // Extract the list of mainDomains using a regular expression
          final regex = RegExp(r'const mainDomains = (\[[^\]]+\]);');
          final match = regex.firstMatch(scriptContentWithDomains);

          if (match != null) {
            final domainsJson = match.group(1)!.replaceAll("'", '"');
            final List<dynamic> mainDomains = json.decode(domainsJson);

            // Simulate the JavaScript logic in Dart
            final random = Random();

            //- `randomSubdomain()` logic
            const chars = "abcdefghijklmnopqrstuvwxyz0123456789";
            final sub = String.fromCharCodes(
              Iterable.generate(
                15,
                (_) => chars.codeUnitAt(random.nextInt(chars.length)),
              ),
            );

            // - `getRandomMainDomain()` logic
            final mainDomain = mainDomains[random.nextInt(mainDomains.length)];

            // a.href = `https://${sub}.${mainDomain}/`;
            return 'https://$sub.$mainDomain/';
          }
        }
      }
      return '无法从第一页面解析第二地址';
    } catch (e) {
      debugPrint('解析第二地址时出错: $e');
      return '解析第二地址时出错';
    }
  }

  /// 获取第一页的 URL
  static Future<String> _getFirstUrl(String url) async {
    try {
      // 获取原始 HTML
      final response = await _getWithRetry(Uri.parse(url));
      if (response.statusCode == 200) {
        final document = parser.parse(response.body);

        // 查找包含重定向逻辑的 script 标签
        final scripts = document.querySelectorAll('script');
        for (var script in scripts) {
          final scriptContent = script.text;

          // Case 1: Simple window.location.href redirect
          if (scriptContent.contains('window.location.href')) {
            final regex = RegExp(r"window\.location\.href = '([^']+)';");
            final match = regex.firstMatch(scriptContent);
            if (match != null) {
              final redirectedUrl = match.group(1);
              if (redirectedUrl != null) {
                return redirectedUrl;
              }
            }
          }

          // 查找目标服务器地址
          if (scriptContent.contains('strU = "http://')) {
            // 提取目标服务器
            final regex = RegExp(r'strU = "http://([^"]+)"');
            final match = regex.firstMatch(scriptContent);
            if (match != null) {
              final baseUrl = 'http://${match.group(1)}';

              // 提取参数解析逻辑
              final dRegex = RegExp(r'btoa\(([^)]+)\)');
              final dMatch = dRegex.firstMatch(scriptContent);
              final pMatch = dRegex.allMatches(scriptContent).length > 1
                  ? dRegex.allMatches(scriptContent).elementAt(1)
                  : null;

              if (dMatch != null && pMatch != null) {
                // 构建重定向 URL
                final hostname = Uri.parse(url).host;
                final path =
                    Uri.parse(url).path +
                    (Uri.parse(url).query.isNotEmpty
                        ? '?${Uri.parse(url).query}'
                        : '');

                final encodedHostname = base64.encode(utf8.encode(hostname));
                final encodedPath = base64.encode(utf8.encode(path));

                return '$baseUrl?d=$encodedHostname&p=$encodedPath';
              }
            }
          }
        }
      }
      return url;
    } catch (e) {
      print('Error: $e');
      return url;
    }
  }
}
