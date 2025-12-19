import 'package:flutter/material.dart';
import 'package:shunle/utils/api/config_api_service.dart';

/// 应用初始化服务
/// 提供应用启动时的各种初始化功能
class AppInitializer {
  /// 应用启动时初始化
  ///
  /// [context] 可选的 BuildContext，用于显示加载提示
  /// [showLoading] 是否显示加载指示器
  static Future<void> initialize({
    BuildContext? context,
    bool showLoading = true,
  }) async {
    print('开始应用初始化...');

    if (showLoading && context != null) {
      _showLoadingIndicator(context);
    }

    try {
      // 1. 获取配置
      await _fetchConfig();

      // 2. 其他初始化任务
      await _performOtherInitializations();

      print('应用初始化完成');

    } catch (e) {
      print('应用初始化失败: $e');
      rethrow;
    } finally {
      if (showLoading && context != null) {
        _hideLoadingIndicator(context);
      }
    }
  }

  /// 获取配置
  static Future<void> _fetchConfig() async {
    print('正在获取应用配置...');

    final config = await ConfigApiService.fetchConfigSafe();

    print('配置获取成功:');
    print('播放域名: ${config['playDomain']}');
    print('短视频随机最大值: ${config['shortVideoRandomMax']}');
    print('短视频随机最小值: ${config['shortVideoRandomMin']}');
  }

  /// 执行其他初始化任务
  static Future<void> _performOtherInitializations() async {
    // 在这里可以添加其他初始化任务
    // 例如：
    // - 初始化数据库
    // - 加载缓存数据
    // - 注册推送通知
    // - 初始化第三方服务等

    print('执行其他初始化任务...');

    // 模拟其他初始化任务
    await Future.delayed(const Duration(milliseconds: 100));

    print('其他初始化任务完成');
  }

  /// 显示加载指示器
  static void _showLoadingIndicator(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  /// 隐藏加载指示器
  static void _hideLoadingIndicator(BuildContext context) {
    Navigator.of(context).pop();
  }

  /// 仅获取配置（不显示加载指示器）
  static Future<Map<String, dynamic>> fetchConfigOnly() async {
    return await ConfigApiService.fetchConfigSafe();
  }
}