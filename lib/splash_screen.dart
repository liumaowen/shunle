library;

import 'package:flutter/material.dart';
import 'package:shunle/tabs.dart';
import 'package:shunle/widgets/splash_loading_widget.dart';
import 'package:shunle/services/app_initializer.dart';

/// 启动页面
/// 处理应用初始化和加载流程
class SplashScreen extends StatelessWidget {
  const SplashScreen({Key? key});

  @override
  Widget build(BuildContext context) {
    return const SplashContent();
  }
}

/// 启动内容组件
class SplashContent extends StatefulWidget {
  const SplashContent({Key? key});

  @override
  State<SplashContent> createState() => _SplashContentState();
}

class _SplashContentState extends State<SplashContent> {
  double _progress = 0.0;
  String _currentStep = '正在初始化...';
  bool _isInitialized = false;
  Future<void>? _initializationFuture;

  @override
  void initState() {
    super.initState();
    _startInitialization();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initializationFuture,
      builder: (context, snapshot) {
        // debugPrint('启动内容组件构建...${snapshot.connectionState}');
        if (snapshot.connectionState == ConnectionState.done) {
          debugPrint('启动内容组件完成,跳转到主应用');
          // 初始化完成后立即跳转
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _navigateToMain();
          });
          return Container(); // 返回空容器，因为会立即跳转
        } else if (snapshot.hasError) {
          // 发生错误，也跳转到主应用，让用户能够使用
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _navigateToMain();
          });
          return Container();
        }

        // 显示加载界面
        return SplashLoadingWidget(
          loadingText: _currentStep,
          showProgress: true,
          progress: _progress,
        );
      },
    );
  }

  /// 开始初始化
  void _startInitialization() {
    if (!_isInitialized) {
      _isInitialized = true;
      _initializationFuture = _initializeApp();
    }
  }

  /// 初始化应用
  Future<void> _initializeApp() async {
    try {
      // 调用 AppInitializer 进行初始化
      await AppInitializer.initialize(onProgressUpdate: _onStepUpdate);
    } catch (e) {
      debugPrint('应用初始化失败: $e');
      // 不抛出错误，让用户能够进入应用
      // 即使初始化失败，也应该正常跳转到主应用
    }
  }

  /// 导航到主应用
  void _navigateToMain() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => Tabs()),
    );
  }

  /// 处理步骤更新
  void _onStepUpdate(String step, double progress) {
    if (mounted) {
      setState(() {
        _currentStep = step;
        _progress = progress;
      });
      debugPrint('初始化进度: ${(progress * 100).toStringAsFixed(0)}% - $step');
    }
  }
}
