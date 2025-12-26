/// 原生平台加密 Isolate 实现
/// 仅在 Android/iOS/Windows/Linux/macOS 平台使用
/// Web 平台不会加载此文件
library;

import 'dart:convert';
import 'dart:isolate';
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
/// Isolate 消息定义
/// ============================================================================

/// 发送给 Isolate 的请求
class IsolateRequest {
  final String operation; // 'encrypt', 'decrypt', 'getm3u8'
  final String plaintext; // 用于加密/解密
  final String baseapi; // 用于 getm3u8
  final String path; // 用于 getm3u8
  final String key; // 用于 getm3u8
  final SendPort replyTo;

  IsolateRequest({
    required this.operation,
    this.plaintext = '',
    this.baseapi = '',
    this.path = '',
    this.key = 'wB760Vqpk76oRSVA1TNz',
    required this.replyTo,
  });
}

/// Isolate 返回的响应
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
/// Isolate 入口点
/// ============================================================================

/// 在 Isolate 中运行的入口点函数
/// 这是一个顶级函数，会在独立的线程中执行
void cryptoIsolateEntryPoint(SendPort mainSendPort) {
  // 创建 Isolate 的接收端口
  final isolateReceivePort = ReceivePort();

  // 向主线程发送 Isolate 的 SendPort
  mainSendPort.send(isolateReceivePort.sendPort);

  // 监听来自主线程的消息
  isolateReceivePort.listen((dynamic message) {
    if (message is IsolateRequest) {
      try {
        String result;

        switch (message.operation) {
          case 'encrypt':
            result = _encryptInIsolate(message.plaintext);
          case 'decrypt':
            result = _decryptInIsolate(message.plaintext);
          case 'getm3u8':
            result = _getm3u8InIsolate(
              message.baseapi,
              message.path,
              message.key,
            );
          default:
            throw Exception('未知的加密操作: ${message.operation}');
        }

        // 发送成功结果给主线程
        message.replyTo.send(
          IsolateResponse(success: true, result: result),
        );
      } catch (e) {
        // 发送错误给主线程
        message.replyTo.send(
          IsolateResponse(
            success: false,
            error: '${message.operation} 失败: $e',
          ),
        );
      }
    }
  });
}
