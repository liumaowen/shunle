import 'package:flutter/material.dart';
import 'package:shunle/services/app_initializer.dart';

/// 应用启动组件
/// 包含应用启动时的加载逻辑
class AppStartupWidget extends StatefulWidget {
  final Widget home;

  const AppStartupWidget({
    super.key,
    required this.home,
  });

  @override
  State<AppStartupWidget> createState() => _AppStartupWidgetState();
}

class _AppStartupWidgetState extends State<AppStartupWidget> {
  bool _isInitialized = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  /// 初始化应用
  Future<void> _initializeApp() async {
    try {
      // 使用 AppInitializer 进行初始化
      await AppInitializer.initialize(
        showLoading: true,
      );

      setState(() {
        _isInitialized = true;
      });

    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    }
  }

  /// 重试初始化
  Future<void> _retryInitialization() async {
    setState(() {
      _isInitialized = false;
      _error = null;
    });
    await _initializeApp();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      if (_error != null) {
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  '初始化失败',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    _error!,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _retryInitialization,
                  child: const Text('重试'),
                ),
              ],
            ),
          ),
        );
      }

      // 显示加载界面
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 80,
                height: 80,
                child: CircularProgressIndicator(
                  strokeWidth: 4,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                '正在启动应用...',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              const Text(
                '请稍候...',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    // 初始化完成，返回主界面
    return widget.home;
  }
}