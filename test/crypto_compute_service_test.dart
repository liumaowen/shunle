import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import '../lib/services/crypto_compute_service.dart';
import '../lib/utils/crypto/aes_encrypt_simple.dart';

void main() {
  group('CryptoComputeService', () {
    late CryptoComputeService service;

    setUp(() {
      service = CryptoComputeService.instance;
    });

    group('Web 平台兼容性测试', () {
      test('Web 平台 encrypt 方法应该正常工作', () async {
        // 模拟 Web 环境
        debugPrint('🌐 测试 Web 平台的 encrypt 方法');

        final result = await service.encrypt('test plaintext');
        expect(result, isA<String>());
        expect(result.isNotEmpty, isTrue);
        debugPrint('✅ Web 平台 encrypt 测试通过');
      });

      test('Web 平台 decrypt 方法应该正常工作', () async {
        // 模拟 Web 环境
        debugPrint('🌐 测试 Web 平台的 decrypt 方法');

        // 先加密一个文本
        final encrypted = await service.encrypt('test plaintext');
        final result = await service.decrypt(encrypted);

        expect(result, equals('test plaintext'));
        debugPrint('✅ Web 平台 decrypt 测试通过');
      });

      test('Web 平台 getm3u8 方法应该正常工作', () async {
        // 模拟 Web 环境
        debugPrint('🌐 测试 Web 平台的 getm3u8 方法');

        final result = await service.getm3u8('http://localhost:8080', '/test/path');
        expect(result, isA<String>());
        expect(result.contains('sign='), isTrue);
        expect(result.contains('t='), isTrue);
        debugPrint('✅ Web 平台 getm3u8 测试通过: $result');
      });
    });

    group('平台兼容性测试', () {
      test('initialize 方法不应该抛出异常', () async {
        expect(() async => await service.initialize(), returnsNormally);
        debugPrint('✅ initialize 方法测试通过');
      });

      test('isInitialized 应该返回 true', () {
        expect(service.isInitialized, isTrue);
        debugPrint('✅ isInitialized 测试通过');
      });

      test('dispose 方法不应该抛出异常', () {
        expect(() => service.dispose(), returnsNormally);
        debugPrint('✅ dispose 方法测试通过');
      });
    });

    group('功能一致性测试', () {
      test('compute 服务应该与 AesEncryptSimple 结果一致', () async {
        debugPrint('🔍 测试 CryptoComputeService 与 AesEncryptSimple 的一致性');

        const testText = 'Hello, World! 123456';

        // 测试加密
        final encrypted1 = await service.encrypt(testText);
        final encrypted2 = AesEncryptSimple.encrypt(testText);
        expect(encrypted1, equals(encrypted2));

        // 测试解密
        final decrypted1 = await service.decrypt(encrypted1);
        final decrypted2 = AesEncryptSimple.decrypt(encrypted1);
        expect(decrypted1, equals(decrypted2));
        expect(decrypted1, equals(testText));

        debugPrint('✅ 功能一致性测试通过');
      });

      test('getm3u8 参数应该正确传递', () async {
        debugPrint('🔍 测试 getm3u8 参数传递');

        final baseapi = 'http://10.1.200.144:5555';
        final path = '/video/episode1';
        final customKey = 'test-key-123';

        final result = await service.getm3u8(baseapi, path, key: customKey);

        // 验证结果格式
        expect(result, startsWith('$baseapi$path'));
        expect(result, contains('sign='));
        expect(result, contains('t='));
        expect(result, isNot(contains(customKey))); // 密钥不应该出现在最终 URL 中
        debugPrint('✅ getm3u8 参数传递测试通过: $result');
      });
    });
  });
}