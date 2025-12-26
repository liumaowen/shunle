/// 加密隔离服务
/// 将 CPU 密集的加密/解密操作移到 Isolate，避免阻塞主线程
/// 在 Web 平台上降级为异步执行
library;

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' hide Key;
import 'package:encrypt/encrypt.dart';
import 'package:crypto/crypto.dart';

// 仅在原生平台导入 Isolate 相关
// ignore: uri_does_not_exist
import 'crypto_isolate_native.dart' if (dart.library.html) 'crypto_isolate_fallback.dart' as isolate_impl;
import 'isolate_helper.dart';

/// 密钥和 IV（与 AesEncryptSimple 保持一致）
const String _aesKey = 'gFzviOY0zOxVq1cu';
const String _aesIv = 'ZmA0Osl677UdSrl0';

/// ============================================================================
/// 加密操作实现（降级方案用）
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
/// 加密隔离服务类
/// ============================================================================

/// 加密隔离服务
/// 在原生平台上使用 Isolate，在 Web 平台上使用事件循环
class CryptoIsolateService {
  static CryptoIsolateService? _instance;
  dynamic _isolate; // Isolate 实例（仅在原生平台）
  dynamic _isolateSendPort; // 发送给 Isolate 的 SendPort
  bool _isWeb = kIsWeb;

  /// 获取单例实例
  static CryptoIsolateService get instance {
    _instance ??= CryptoIsolateService._();
    return _instance!;
  }

  CryptoIsolateService._();

  /// 初始化服务
  Future<void> initialize() async {
    // 已初始化
    if (_isolateSendPort != null) {
      return;
    }

    // Web 平台：直接返回，使用事件循环
    if (_isWeb) {
      debugPrint('⚠️ 检测到 Web 平台，使用事件循环异步方案');
      return;
    }

    // 原生平台：尝试启动 Isolate
    try {
      await _initializeIsolate();
      debugPrint('✅ 加密 Isolate 初始化成功');
    } catch (e) {
      debugPrint('⚠️ Isolate 初始化失败: $e，使用事件循环降级方案');
      _isolate = null;
      _isolateSendPort = null;
    }
  }

  /// 初始化 Isolate
  Future<void> _initializeIsolate() async {
    try {
      if (_isWeb) {
        throw Exception('Web 平台不支持 Isolate');
      }

      // 在原生平台，使用 crypto_isolate_native 中的入口点
      // 这里动态加载以避免 Web 编译错误
      debugPrint('正在启动加密 Isolate...');

      // 使用反射调用 Isolate.spawn
      final isolateSpawn = _getIsolateSpawn();
      if (isolateSpawn == null) {
        throw Exception('无法获取 Isolate.spawn');
      }

      final receivePort = _createReceivePort();
      if (receivePort == null) {
        throw Exception('无法创建 ReceivePort');
      }

      // 启动 Isolate
      _isolate = await isolateSpawn(
        isolate_impl.cryptoIsolateEntryPoint,
        (receivePort as dynamic).sendPort,
      );

      // 等待 Isolate 发送它的 SendPort
      final isolateReceivePort = await Future.any<dynamic>([
        (receivePort as dynamic).first as Future<dynamic>,
        Future<dynamic>.delayed(
          const Duration(seconds: 5),
          () => throw Exception('Isolate 响应超时'),
        ),
      ]);

      if (isolateReceivePort != null) {
        _isolateSendPort = isolateReceivePort;
        debugPrint('✅ 成功获取 Isolate SendPort');
      } else {
        throw Exception('无效的 Isolate SendPort');
      }
    } catch (e) {
      debugPrint('❌ Isolate 初始化失败: $e');
      rethrow;
    }
  }

  /// 创建 ReceivePort 实例
  /// 在原生平台创建真实的 ReceivePort，在 Web 平台返回 null
  dynamic _createReceivePort() {
    if (_isWeb) {
      return null;
    }
    return createReceivePort();
  }

  /// 获取 Isolate.spawn 方法引用
  /// 在原生平台返回可调用的 spawn 方法，在 Web 平台返回 null
  dynamic _getIsolateSpawn() {
    if (_isWeb) {
      return null;
    }
    return getIsolateSpawn();
  }

  /// 异步加密
  Future<String> encrypt(String plaintext) async {
    await initialize();
    return _executeOperation('encrypt', plaintext: plaintext);
  }

  /// 异步解密
  Future<String> decrypt(String ciphertext) async {
    await initialize();
    return _executeOperation('decrypt', plaintext: ciphertext);
  }

  /// 异步生成 m3u8 URL
  Future<String> getm3u8(
    String baseapi,
    String path, {
    String key = 'wB760Vqpk76oRSVA1TNz',
  }) async {
    await initialize();
    return _executeOperation(
      'getm3u8',
      baseapi: baseapi,
      path: path,
      key: key,
    );
  }

  /// 执行加密操作
  Future<String> _executeOperation(
    String operation, {
    String plaintext = '',
    String baseapi = '',
    String path = '',
    String key = 'wB760Vqpk76oRSVA1TNz',
  }) async {
    // 如果 Isolate 可用，使用 Isolate；否则使用事件循环
    if (_isolateSendPort != null && !_isWeb) {
      return _executeInIsolate(operation, plaintext, baseapi, path, key);
    }

    // 回退到事件循环
    return _executeInEventLoop(operation, plaintext, baseapi, path, key);
  }

  /// 在 Isolate 中执行（原生平台）
  Future<String> _executeInIsolate(
    String operation,
    String plaintext,
    String baseapi,
    String path,
    String key,
  ) async {
    try {
      // 创建回复端口
      final replyPort = _createReceivePort();
      if (replyPort == null) {
        throw Exception('无法创建回复端口');
      }

      // 创建请求消息
      final request = isolate_impl.IsolateRequest(
        operation: operation,
        plaintext: plaintext,
        baseapi: baseapi,
        path: path,
        key: key,
        replyTo: (replyPort as dynamic).sendPort,
      );

      // 发送请求给 Isolate
      (_isolateSendPort as dynamic).send(request);

      // 等待响应（超时 30 秒）
      final response = await Future.any<dynamic>([
        (replyPort as dynamic).first as Future<dynamic>,
        Future<dynamic>.delayed(
          const Duration(seconds: 30),
          () => throw Exception('Isolate 操作超时'),
        ),
      ]) as isolate_impl.IsolateResponse?;

      if (response == null) {
        throw Exception('无效的响应');
      }

      if (response.success) {
        return response.result;
      } else {
        throw Exception(response.error ?? '未知错误');
      }
    } catch (e) {
      debugPrint('Isolate 操作失败: $e，回退到事件循环');
      // 回退到事件循环
      return _executeInEventLoop(operation, plaintext, baseapi, path, key);
    }
  }

  /// 在事件循环中执行（Web 平台和降级方案）
  Future<String> _executeInEventLoop(
    String operation,
    String plaintext,
    String baseapi,
    String path,
    String key,
  ) async {
    return Future.microtask(() {
      try {
        String result;

        switch (operation) {
          case 'encrypt':
            result = _encryptInIsolate(plaintext);
          case 'decrypt':
            result = _decryptInIsolate(plaintext);
          case 'getm3u8':
            result = _getm3u8InIsolate(baseapi, path, key);
          default:
            throw Exception('未知的加密操作: $operation');
        }

        return result;
      } catch (e) {
        throw Exception('$operation 失败: $e');
      }
    });
  }

  /// 检查是否已初始化
  bool get isInitialized => _isolateSendPort != null;

  /// 清理资源
  void dispose() {
    try {
      if (_isolate != null && !_isWeb) {
        (_isolate as dynamic).kill();
        debugPrint('✅ Isolate 已清理');
      }
    } catch (e) {
      debugPrint('清理 Isolate 失败: $e');
    }
    _isolate = null;
    _isolateSendPort = null;
  }
}
