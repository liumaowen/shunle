/// 使用 compute() 函数的加密服务
/// 在 Android 平台上使用多线程避免阻塞主线程
/// Web 平台使用同步方式直接调用 AesEncryptSimple
library;

import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../utils/crypto/aes_encrypt_simple.dart';
import 'package:path/path.dart' as path;

/// 使用 compute() 函数的加密服务
/// Android 平台使用多线程，Web 平台使用同步方式
class CryptoComputeService {
  static CryptoComputeService? _instance;

  static CryptoComputeService get instance {
    _instance ??= CryptoComputeService._();
    return _instance!;
  }

  CryptoComputeService._();

  /// 初始化服务（为了保持接口一致性）
  Future<void> initialize() async {
    // Web 平台：直接返回，使用同步方式
    if (kIsWeb) {
      debugPrint('⚠️ 检测到 Web 平台，使用同步加密方案');
      return;
    }

    // Android 平台：compute() 不需要初始化
    debugPrint('📱 Android 平台，使用 compute() 多线程方案');
  }

  /// 异步加密
  Future<String> encrypt(String plaintext) async {
    await initialize();

    // if (kIsWeb) {
    // Web 端直接使用 AesEncryptSimple
    return AesEncryptSimple.encrypt(plaintext);
    // }

    // Android 端使用 compute
    // return await compute(_encryptInWorker, plaintext);
  }

  /// 异步解密
  Future<String> decrypt(String ciphertext) async {
    await initialize();

    // if (kIsWeb) {
    // Web 端直接使用 AesEncryptSimple
    return AesEncryptSimple.decrypt(ciphertext);
    // }

    // Android 端使用 compute
    // return await compute(_decryptInWorker, ciphertext);
  }

  /// 异步生成 m3u8 URL
  Future<String> getm3u8(
    String baseapi,
    String path, {
    String key = 'wB760Vqpk76oRSVA1TNz',
  }) async {
    await initialize();

    // if (kIsWeb) {
    // Web 端直接使用 AesEncryptSimple
    return AesEncryptSimple.getm3u8(baseapi, path, key: key);
    // }

    // Android 端使用 compute
    // return await compute(_getm3u8InWorker, {
    //   'baseapi': baseapi,
    //   'path': path,
    //   'key': key,
    // });
  }

  /// 在 Isolate 中运行的加密函数
  static String _encryptInWorker(String plaintext) {
    return AesEncryptSimple.encrypt(plaintext);
  }

  /// 在 Isolate 中运行的解密函数
  static String _decryptInWorker(String ciphertext) {
    return AesEncryptSimple.decrypt(ciphertext);
  }

  /// 在 Isolate 中运行的 m3u8 函数
  static String _getm3u8InWorker(Map<String, String> params) {
    return AesEncryptSimple.getm3u8(
      params['baseapi']!,
      params['path']!,
      key: params['key']!,
    );
  }

  /// 异步解密图片
  Future<Uint8List> fetchAndDecrypt(String url) async {
    if (kIsWeb) {
      // Web 端直接使用 AesEncryptSimple
      return AesEncryptSimple.fetchAndDecrypt(url);
    }

    // Android 端使用 compute
    return await compute(_fetchAndDecryptInWorker, url);
  }

  /// 在 Isolate 中运行的 fetchAndDecrypt 函数
  static Future<Uint8List> _fetchAndDecryptInWorker(String url) async {
    return await AesEncryptSimple.fetchAndDecrypt(url);
  }

  /// 检查是否已初始化
  bool get isInitialized => true; // compute() 不需要初始化，总是返回 true

  /// 清理资源
  void dispose() {
    // compute() 不需要清理资源
    debugPrint('🧹 CryptoComputeService 已清理');
  }
}
