library;

/// CryptoComputeService 使用示例

import 'package:flutter/foundation.dart';
import 'package:shunle/services/crypto_compute_service.dart';
import 'package:shunle/utils/crypto/aes_encrypt_simple.dart';

class CryptoUsageExample {
  /// 获取加密服务实例
  final cryptoService = CryptoComputeService.instance;

  /// 示例：加密用户数据
  Future<String> encryptUserData(String userData) async {
    try {
      debugPrint('🔐 开始加密用户数据...');

      // 使用新的 cryptoComputeService（自动处理平台差异）
      final encrypted = await cryptoService.encrypt(userData);

      debugPrint('✅ 用户数据加密成功，长度: ${encrypted.length}');
      return encrypted;
    } catch (e) {
      debugPrint('❌ 加密失败: $e');
      rethrow;
    }
  }

  /// 示例：解密用户数据
  Future<String> decryptUserData(String encryptedData) async {
    try {
      debugPrint('🔓 开始解密用户数据...');

      // 使用新的 cryptoComputeService
      final decrypted = await cryptoService.decrypt(encryptedData);

      debugPrint('✅ 用户数据解密成功');
      return decrypted;
    } catch (e) {
      debugPrint('❌ 解密失败: $e');
      rethrow;
    }
  }

  /// 示例：生成视频 URL
  Future<String> generateVideoUrl(String videoPath) async {
    try {
      debugPrint('🎬 开始生成视频 URL...');

      // 使用新的 cryptoComputeService 生成 m3u8 URL
      final videoUrl = await cryptoService.getm3u8(
        '10.1.200.144:5555', // baseapi
        videoPath,           // path
      );

      debugPrint('✅ 视频 URL 生成成功: $videoUrl');
      return videoUrl;
    } catch (e) {
      debugPrint('❌ URL 生成失败: $e');
      rethrow;
    }
  }

  /// 示例：批量处理视频 URL
  Future<List<String>> generateMultipleVideoUrls(List<String> videoPaths) async {
    try {
      debugPrint('🎬 开始批量生成视频 URL...');

      // 使用 Future.wait 进行并发处理
      final futures = videoPaths.map((path) => generateVideoUrl(path)).toList();
      final urls = await Future.wait(futures);

      debugPrint('✅ 批量处理完成，共生成 ${urls.length} 个 URL');
      return urls;
    } catch (e) {
      debugPrint('❌ 批量处理失败: $e');
      rethrow;
    }
  }

  /// 示例：性能对比测试
  Future<void> performanceComparison() async {
    debugPrint('⚡ 开始性能对比测试...');

    const testData = '这是性能测试用的文本数据。';

    // 测试 cryptoComputeService
    final stopwatch = Stopwatch()..start();

    final encrypted = await cryptoService.encrypt(testData);
    stopwatch.stop();

    debugPrint('📊 性能对比结果:');
    debugPrint('   - cryptoComputeService 加密耗时: ${stopwatch.elapsedMilliseconds}ms');

    // 测试 AesEncryptSimple 直接调用
    stopwatch.reset();
    stopwatch.start();
    final directEncrypted = AesEncryptSimple.encrypt(testData);
    stopwatch.stop();

    debugPrint('   - AesEncryptSimple 直接调用耗时: ${stopwatch.elapsedMilliseconds}ms');
    debugPrint('   - 结果一致性: ${encrypted == directEncrypted}');
  }

  /// 示例：根据平台选择不同策略
  Future<String> smartEncrypt(String data) async {
    if (kIsWeb) {
      debugPrint('🌐 Web 平台：使用同步加密');
      return AesEncryptSimple.encrypt(data);
    } else {
      debugPrint('📱 原生平台：使用多线程加密');
      return await cryptoService.encrypt(data);
    }
  }
}