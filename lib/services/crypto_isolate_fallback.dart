/// Web 平台 Isolate 降级方案（虚拟文件）
/// 在 Web 平台上用来替代 crypto_isolate_native.dart
/// 提供相同的接口但不实际使用 Isolate
library;

import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart';
import 'package:crypto/crypto.dart';

/// 密钥和 IV
const String _aesKey = 'gFzviOY0zOxVq1cu';
const String _aesIv = 'ZmA0Osl677UdSrl0';

/// ============================================================================
/// 加密操作实现
/// ============================================================================

/// AES 加密
String _encryptInIsolate(String plaintext) {
  try {
    final keyBytes = Uint8List.fromList(utf8.encode(_aesKey));
    final ivBytes = Uint8List.fromList(utf8.encode(_aesIv));
    final plaintextBytes = Uint8List.fromList(utf8.encode(plaintext));

    final keyParameter = Key(keyBytes);
    final ivParameter = IV(ivBytes);

    final encrypter = Encrypter(AES(keyParameter, mode: AESMode.cbc));
    final encrypted = encrypter.encryptBytes(plaintextBytes, iv: ivParameter);

    return base64.encode(encrypted.bytes);
  } catch (e) {
    throw Exception('加密失败: $e');
  }
}

/// AES 解密
String _decryptInIsolate(String ciphertext) {
  try {
    final cipherBytes = base64.decode(ciphertext);

    final keyBytes = Uint8List.fromList(utf8.encode(_aesKey));
    final ivBytes = Uint8List.fromList(utf8.encode(_aesIv));

    final keyParameter = Key(keyBytes);
    final ivParameter = IV(ivBytes);

    final encrypter = Encrypter(AES(keyParameter, mode: AESMode.cbc));
    final decryptedBytes = encrypter.decryptBytes(
      Encrypted(cipherBytes),
      iv: ivParameter,
    );

    return utf8.decode(decryptedBytes);
  } catch (e) {
    throw Exception('解密失败: $e');
  }
}

/// 生成 m3u8 URL
String _getm3u8InIsolate(String baseapi, String path, String key) {
  final timestamp = DateTime.now().millisecondsSinceEpoch;
  final r = (timestamp / 1000).floor().toString();
  final sign = _createMD5('$key/$path$r').toLowerCase();
  final hp = path.contains('http') ? path : '$baseapi$path';
  return '$hp?sign=$sign&t=$r';
}

/// MD5 哈希
String _createMD5(String input) {
  final bytes = utf8.encode(input);
  final digest = md5.convert(bytes);
  return digest.toString();
}

/// ============================================================================
/// Isolate 消息定义（兼容接口）
/// ============================================================================

/// 发送给 Isolate 的请求（虚拟，在 Web 上不使用）
class IsolateRequest {
  final String operation;
  final String plaintext;
  final String baseapi;
  final String path;
  final String key;
  final dynamic replyTo; // 在 Web 上不需要，但为了兼容性支持

  IsolateRequest({
    required this.operation,
    this.plaintext = '',
    this.baseapi = '',
    this.path = '',
    this.key = 'wB760Vqpk76oRSVA1TNz',
    this.replyTo, // Web 上不需要，可选参数
  });
}

/// Isolate 返回的响应（虚拟）
class IsolateResponse {
  final bool success;
  final String result;
  final String? error;

  IsolateResponse({
    required this.success,
    this.result = '',
    this.error,
  });
}

/// ============================================================================
/// Isolate 入口点（虚拟，在 Web 上不使用）
/// ============================================================================

/// 虚拟的 Isolate 入口点（Web 平台不会调用此函数）
void cryptoIsolateEntryPoint(dynamic mainSendPort) {
  // 这个函数在 Web 上不会被调用
  // 仅在此处定义以保持接口一致性
}
