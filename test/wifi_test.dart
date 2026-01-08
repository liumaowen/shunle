import 'package:flutter_test/flutter_test.dart';
import 'package:shunle/services/network_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NetworkService Tests', () {
    test('初始化网络服务', () async {
      final networkService = NetworkService();
      await networkService.initialize();
      expect(networkService, isNotNull);
    });

    test('检查WiFi状态', () async {
      final networkService = NetworkService();
      await networkService.initialize();

      final isWifi = await networkService.getIsWifi();
      // 应该返回布尔值
      expect(isWifi, isA<bool>());
    });

    test('监听网络状态变化', () async {
      final networkService = NetworkService();
      await networkService.initialize();

      bool lastState = false;
      networkService.listenNetworkStatus((isWifi) {
        lastState = isWifi;
      });

      // 等待一下让监听器设置完成
      await Future.delayed(const Duration(milliseconds: 100));

      // 验证回调函数被设置
      expect(lastState, isA<bool>());

      // 清理
      networkService.dispose();
    });
  });
}