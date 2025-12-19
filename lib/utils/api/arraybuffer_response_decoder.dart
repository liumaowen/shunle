import 'dart:convert';
import 'package:shunle/utils/crypto/crypto_utils.dart';

/// ArrayBuffer 响应解码器
///
/// 用于处理 JavaScript 中使用 Arraybuffer 响应的场景
/// 在 Flutter 中，http.Response.body 已经是字符串，因此需要特殊处理
class ArrayBufferResponseDecoder {
  /// 解码 ArrayBuffer 响应
  ///
  /// 对应 JavaScript 代码：
  /// - `new TextDecoder().decode(response.data)`
  /// - `AES_Decrypt(text)`
  ///
  /// 在 Flutter 中，http.Response.body 直接返回字符串
  /// 因此此方法主要用于处理需要模拟 ArrayBuffer 解码的场景
  static Future<String> decodeAndDecrypt({
    required String responseBody,
    String? key,
    String? iv,
  }) async {
    try {
      // 如果传入了自定义的 key 和 iv，使用它们
      // 否则使用 CryptoUtils 默认的密钥
      final decryptKey = key ?? 'gFzviOY0zOxVq1cu';
      final decryptIv = iv ?? 'ZmA0Osl677UdSrl0';

      // 解密数据
      return await CryptoUtils.aesDecryptKey(
        responseBody,
        decryptKey,
        decryptIv,
      );
    } catch (e) {
      throw Exception('ArrayBuffer 解码失败: $e');
    }
  }

  /// 解码并解析 JSON
  static Future<Map<String, dynamic>> decodeAndParseJson({
    required String responseBody,
    String? key,
    String? iv,
  }) async {
    final decryptedText = await decodeAndDecrypt(
      responseBody: responseBody,
      key: key,
      iv: iv,
    );
    return json.decode(decryptedText);
  }

  /// 解码并提取配置项（类似于 JavaScript 中的逻辑）
  static Future<Map<String, dynamic>> decodeAndExtractConfig({
    required String responseBody,
    String? key,
    String? iv,
  }) async {
    final jsonData = await decodeAndParseJson(
      responseBody: responseBody,
      key: key,
      iv: iv,
    );

    // 提取数据
    final list100 = jsonData['data'] ?? [];

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

    return {
      'shortVideoRandomMax': shortVideoRandomMax,
      'shortVideoRandomMin': shortVideoRandomMin,
      'playDomain': playDomain,
      'rawData': jsonData,
    };
  }
}

/// CryptoUtils 的扩展方法，支持自定义密钥
extension CryptoUtilsExtension on CryptoUtils {
  /// 使用自定义密钥和 IV 解密
  static Future<String> aesDecryptKey(String ciphertext, String key, String iv) async {
    return await CryptoUtils.aesDecryptKey(ciphertext, key, iv);
  }
}