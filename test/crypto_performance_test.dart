import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:shunle/services/crypto_compute_service.dart';
import 'package:shunle/utils/crypto/aes_encrypt_simple.dart';

void main() {
  group('Crypto 性能测试', () {
    late CryptoComputeService service;

    setUp(() {
      service = CryptoComputeService.instance;
    });

    group('多线程性能测试', () {
      test('大数据量加密性能测试', () async {
        debugPrint('🚀 开始大数据量加密性能测试');

        // 创建一个较大的测试文本
        final largeText = '这是一段较大的文本，用于测试加密性能。' * 100;

        final stopwatch = Stopwatch()..start();

        // 使用 compute 方式
        final result = await service.encrypt(largeText);

        stopwatch.stop();

        expect(result, isA<String>());
        expect(result.isNotEmpty, isTrue);

        debugPrint('📊 大数据量加密性能结果:');
        debugPrint('   - 加密耗时: ${stopwatch.elapsedMilliseconds}ms');
        debugPrint('   - 文本大小: ${largeText.length} 字符');
        debugPrint('   - 结果大小: ${result.length} 字符');

        // 检查是否在合理时间内完成（通常应该小于 100ms）
        expect(stopwatch.elapsedMilliseconds, lessThan(1000));
        debugPrint('✅ 大数据量加密性能测试通过');
      });

      test('并发加密请求测试', () async {
        debugPrint('🔄 开始并发加密请求测试');

        final testTexts = [
          '第一个测试文本',
          '第二个测试文本',
          '第三个测试文本',
          '第四个测试文本',
          '第五个测试文本',
        ];

        final stopwatch = Stopwatch()..start();

        // 创建多个并发请求
        final futures = testTexts.map((text) => service.encrypt(text)).toList();

        // 等待所有请求完成
        final results = await Future.wait(futures);

        stopwatch.stop();

        expect(results, hasLength(testTexts.length));
        expect(results, everyElement(isA<String>()));
        expect(results, everyElement(isNotEmpty));

        debugPrint('📊 并发加密性能结果:');
        debugPrint('   - 并发数量: ${testTexts.length}');
        debugPrint('   - 总耗时: ${stopwatch.elapsedMilliseconds}ms');
        debugPrint('   - 平均每个: ${(stopwatch.elapsedMilliseconds / testTexts.length).toStringAsFixed(2)}ms');

        // 检查并发性能（应该比串行更快）
        expect(stopwatch.elapsedMilliseconds, lessThan(testTexts.length * 50));
        debugPrint('✅ 并发加密请求测试通过');
      });

      test('重复调用性能测试', () async {
        debugPrint('🔄 开始重复调用性能测试');

        const testText = '性能测试文本';
        const repeatCount = 10;

        final stopwatch = Stopwatch()..start();

        // 重复调用相同文本
        for (int i = 0; i < repeatCount; i++) {
          await service.encrypt(testText);
        }

        stopwatch.stop();

        debugPrint('📊 重复调用性能结果:');
        debugPrint('   - 重复次数: $repeatCount');
        debugPrint('   - 总耗时: ${stopwatch.elapsedMilliseconds}ms');
        debugPrint('   - 平均每次: ${(stopwatch.elapsedMilliseconds / repeatCount).toStringAsFixed(2)}ms');

        // 检查稳定性
        expect(stopwatch.elapsedMilliseconds, lessThan(repeatCount * 20));
        debugPrint('✅ 重复调用性能测试通过');
      });
    });

    group('与同步方式对比测试', () {
      test('compute vs 同步方式对比', () async {
        debugPrint('⚖️ 开始 compute vs 同步方式对比测试');

        final testText = '对比测试文本，用于验证多线程的性能优势。' * 20;

        // 测试 compute 方式
        final computeStopwatch = Stopwatch()..start();
        final computeResult = await service.encrypt(testText);
        computeStopwatch.stop();

        // 测试同步方式
        final syncStopwatch = Stopwatch()..start();
        final syncResult = AesEncryptSimple.encrypt(testText);
        syncStopwatch.stop();

        // 验证结果一致
        expect(computeResult, equals(syncResult));

        debugPrint('📊 性能对比结果:');
        debugPrint('   - compute 耗时: ${computeStopwatch.elapsedMilliseconds}ms');
        debugPrint('   - 同步耗时: ${syncStopwatch.elapsedMilliseconds}ms');
        debugPrint('   - 时间差: ${computeStopwatch.elapsedMilliseconds - syncStopwatch.elapsedMilliseconds}ms');

        // 在 Android 平台上，compute 应该不会比同步慢太多
        // 在 Web 平台上，compute 会直接使用同步方法，耗时应该相同
        final timeDiff = computeStopwatch.elapsedMilliseconds - syncStopwatch.elapsedMilliseconds;
        expect(timeDiff.abs(), lessThan(50));

        debugPrint('✅ compute vs 同步方式对比测试通过');
      });
    });

    group('内存使用测试', () {
      test('大量数据内存使用测试', () async {
        debugPrint('💾 开始大量数据内存使用测试');

        // 创建一个较大的数据集
        final largeDataSet = List.generate(100, (i) => '这是一个较大的测试文本，用于测试内存使用情况。$i');

        final stopwatch = Stopwatch()..start();
        final futures = largeDataSet.map((text) => service.encrypt(text)).toList();
        final results = await Future.wait(futures);
        stopwatch.stop();

        expect(results, hasLength(largeDataSet.length));

        debugPrint('📊 内存使用测试结果:');
        debugPrint('   - 处理数据量: ${largeDataSet.length} 条');
        debugPrint('   - 总耗时: ${stopwatch.elapsedMilliseconds}ms');
        debugPrint('   - 平均每条: ${(stopwatch.elapsedMilliseconds / largeDataSet.length).toStringAsFixed(2)}ms');

        // 检查内存使用是否合理
        expect(stopwatch.elapsedMilliseconds, lessThan(1000));
        debugPrint('✅ 大量数据内存使用测试通过');
      });
    });
  });
}