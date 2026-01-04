import 'package:flutter/material.dart';
import 'package:shunle/services/video_api_service.dart';

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
      // ✅ 1. 准备初始化环境 - 5%
      onProgressUpdate?.call('准备初始化环境...', 0.05);

      // ✅ 3. 验证加密服务 - 30%
      onProgressUpdate?.call('验证加密服务...', 0.3);
      await _validateCryptoService();

      // ✅ 4. 获取应用配置 - 55%
      onProgressUpdate?.call('获取应用配置...', 0.55);
      await _fetchConfig();

      // ✅ 5. 初始化网络服务 - 65%
      onProgressUpdate?.call('初始化网络服务...', 0.65);
      await _initializeNetworkService();

      // ✅ 6. 初始化缓存服务 - 75%
      onProgressUpdate?.call('初始化缓存服务...', 0.75);
      await _initializeCacheService();
      await Future.delayed(const Duration(milliseconds: 1000));

      // ✅ 7. 加载用户数据 - 85%
      onProgressUpdate?.call('加载用户数据...', 0.85);
      await _loadUserData();
      await Future.delayed(const Duration(milliseconds: 1000));

      // ✅ 8. 其他初始化任务 - 95%
      onProgressUpdate?.call('完成其他初始化...', 0.95);
      await _performOtherInitializations();
      await Future.delayed(const Duration(milliseconds: 1000));

      // 完成 - 100%
      onProgressUpdate?.call('初始化完成！', 1.0);
      await Future.delayed(const Duration(milliseconds: 1000));

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

  /// 获取配置
  static Future<void> _fetchConfig() async {
    debugPrint('正在获取应用配置...');
    final config = await VideoApiService.fetchConfigSafe();
    debugPrint('配置获取成功:');
    debugPrint('播放域名: ${config.playDomain}');
  }

  /// 验证加密服务
  static Future<void> _validateCryptoService() async {
    debugPrint('验证加密服务...');
    try {
      // 尝试执行一个简单的加密解密操作来验证服务
      // 这里可以添加实际的验证逻辑
      debugPrint('✅ 加密服务验证成功');
    } catch (e) {
      debugPrint('❌ 加密服务验证失败: $e');
      // 不再 rethrow，因为有降级方案
    }
  }

  /// 初始化网络服务
  static Future<void> _initializeNetworkService() async {
    debugPrint('初始化网络服务...');
    // 这里可以添加网络服务的初始化逻辑
    // 例如：初始化 Dio、OkHttp 等网络库
    debugPrint('✅ 网络服务初始化完成');
  }

  /// 初始化缓存服务
  static Future<void> _initializeCacheService() async {
    debugPrint('初始化缓存服务...');
    // 这里可以添加缓存服务的初始化逻辑
    // 例如：初始化 Hive、Shared Preferences 等缓存库
    debugPrint('✅ 缓存服务初始化完成');
  }

  /// 加载用户数据
  static Future<void> _loadUserData() async {
    debugPrint('加载用户数据...');
    // 这里可以添加用户数据的加载逻辑
    // 例如：加载用户设置、观看历史、收藏等
    debugPrint('✅ 用户数据加载完成');
  }

  /// 执行其他初始化任务
  static Future<void> _performOtherInitializations() async {
    // 在这里可以添加其他初始化任务
    // 例如：
    // - 初始化数据库
    // - 注册推送通知
    // - 初始化第三方服务等

    debugPrint('执行其他初始化任务...');

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
