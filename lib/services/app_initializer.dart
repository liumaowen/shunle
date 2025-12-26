
import 'package:flutter/material.dart';
import 'package:shunle/services/video_api_service.dart';
import 'package:shunle/services/crypto_compute_service.dart';

/// 应用初始化服务
/// 提供应用启动时的各种初始化功能
class AppInitializer {
  /// 应用启动时初始化
  ///
  /// [context] 可选的 BuildContext，用于显示加载提示
  /// [showLoading] 是否显示加载指示器
  /// [onProgressUpdate] 进度更新回调
  static Future<void> initialize({
    BuildContext? context,
    bool showLoading = true,
    Function(String step, double progress)? onProgressUpdate,
  }) async {
    debugPrint('开始应用初始化...');

    if (showLoading && context != null) {
      _showLoadingIndicator(context);
    }

    try {
      // ✅ 1. 初始化加密服务（必须首先初始化）- 20%
      onProgressUpdate?.call('初始化加密服务...', 0.2);
      await _initializeCryptoIsolate();

      // 2. 获取配置 - 50%
      onProgressUpdate?.call('获取应用配置...', 0.5);
      await _fetchConfig();

      // 3. 其他初始化任务 - 90%
      onProgressUpdate?.call('完成其他初始化...', 0.9);
      await _performOtherInitializations();

      // 完成 - 100%
      onProgressUpdate?.call('初始化完成！', 1.0);

      debugPrint('应用初始化完成');
    } catch (e) {
      debugPrint('应用初始化失败: $e');
      // 不再 rethrow，让应用能够正常启动
      // 即使初始化失败，用户也应该能够使用应用
    } finally {
      if (showLoading && context != null) {
        _hideLoadingIndicator(context);
      }
    }
  }

  /// ✅ 初始化加密 Isolate
  static Future<void> _initializeCryptoIsolate() async {
    debugPrint('正在初始化加密 Isolate...');
    try {
      await CryptoComputeService.instance.initialize();
      debugPrint('✅ 加密 Isolate 初始化成功');
    } catch (e) {
      debugPrint('❌ 加密 Isolate 初始化失败: $e');
      // 不再 rethrow，因为有降级方案
      // Web 平台会自动使用降级实现
    }
  }

  /// 获取配置
  static Future<void> _fetchConfig() async {
    debugPrint('正在获取应用配置...');
    final config = await VideoApiService.fetchConfigSafe();
    debugPrint('配置获取成功:');
    debugPrint('播放域名: ${config.playDomain}');
  }

  /// 执行其他初始化任务
  static Future<void> _performOtherInitializations() async {
    // 在这里可以添加其他初始化任务
    // 例如：
    // - 初始化数据库
    // - 加载缓存数据
    // - 注册推送通知
    // - 初始化第三方服务等

    debugPrint('执行其他初始化任务...');

    // 模拟其他初始化任务
    // await Future.delayed(const Duration(milliseconds: 100));

    debugPrint('其他初始化任务完成');
  }

  /// 显示加载指示器
  static void _showLoadingIndicator(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
  }

  /// 隐藏加载指示器
  static void _hideLoadingIndicator(BuildContext context) {
    Navigator.of(context).pop();
  }
}

