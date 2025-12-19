import 'package:flutter/material.dart';
import 'package:shunle/utils/api/config_api_service.dart';

/// 应用生命周期管理器
/// 在应用启动时自动获取配置数据
class AppLifecycleManager extends StatefulWidget {
  final Widget child;

  const AppLifecycleManager({
    super.key,
    required this.child,
  });

  @override
  State<AppLifecycleManager> createState() => _AppLifecycleManagerState();
}

class _AppLifecycleManagerState extends State<AppLifecycleManager>
    with WidgetsBindingObserver {
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // 注册为 WidgetsBindingObserver
    WidgetsBinding.instance.addObserver(this);

    // 应用启动时获取配置
    _fetchConfigOnStartup();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// 应用启动时获取配置
  Future<void> _fetchConfigOnStartup() async {
    // 避免重复加载
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      print('应用启动，正在获取配置...');

      // 获取配置
      final config = await ConfigApiService.fetchConfigSafe();

      // 更新全局配置
      // GlobalConfig 已经在 ConfigApiService 中自动更新

      print('配置获取成功:');
      print('播放域名: ${config['playDomain']}');
      print('短视频随机最大值: ${config['shortVideoRandomMax']}');
      print('短视频随机最小值: ${config['shortVideoRandomMin']}');

      // 可以在这里根据配置进行其他初始化操作
      _postConfigInitialization(config);

    } catch (e) {
      print('应用启动时配置获取失败: $e');
      setState(() {
        _error = '配置获取失败: $e';
      });

      // 使用默认值继续运行
      _useDefaultConfig();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// 配置获取后的初始化操作
  void _postConfigInitialization(Map<String, dynamic> config) {
    // 在这里可以添加配置获取后的其他初始化逻辑
    // 例如：
    // - 初始化网络客户端
    // - 设置默认值
    // - 预加载数据等
  }

  /// 使用默认配置
  void _useDefaultConfig() {
    // 当配置获取失败时，使用默认值继续运行
    print('使用默认配置继续运行');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        // 应用从后台回到前台
        print('应用状态: resumed (前台)');
        break;
      case AppLifecycleState.inactive:
        // 应用处于非活动状态（如接听电话）
        print('应用状态: inactive (非活动)');
        break;
      case AppLifecycleState.paused:
        // 应用进入后台
        print('应用状态: paused (后台)');
        break;
      case AppLifecycleState.detached:
        // 应用被销毁
        print('应用状态: detached (销毁)');
        break;
      case AppLifecycleState.hidden:
        // 应用隐藏（Android 10+）
        print('应用状态: hidden (隐藏)');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    // 在应用启动时显示加载指示器（可选）
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              const Text('正在初始化应用...'),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(
                  '错误: $_error',
                  style: const TextStyle(color: Colors.red),
                ),
              ],
            ],
          ),
        ),
      );
    }

    // 如果有错误但不是加载状态，可以显示错误提示
    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                '配置加载失败',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                '$_error',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _fetchConfigOnStartup,
                child: const Text('重试'),
              ),
            ],
          ),
        ),
      );
    }

    // 正常返回子组件
    return widget.child;
  }
}