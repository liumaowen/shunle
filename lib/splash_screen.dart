library;

import 'package:flutter/material.dart';
import 'package:shunle/tabs.dart';
import 'package:shunle/widgets/splash_loading_with_progress.dart';
import 'package:shunle/services/app_initializer.dart';

/// 启动页面
/// 处理应用初始化和加载流程
class SplashScreen extends StatelessWidget {
  const SplashScreen({Key? key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '顺乐短剧',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const SplashContent(),
      debugShowCheckedModeBanner: false,
    );
  }
}

/// 启动内容组件
class SplashContent extends StatefulWidget {
  const SplashContent({Key? key});

  @override
  State<SplashContent> createState() => _SplashContentState();
}

class _SplashContentState extends State<SplashContent> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initializeApp(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
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
        return SplashLoadingWithProgress(
          onInitialized: _navigateToMain,
          onStepUpdate: _onStepUpdate,
        );
      },
    );
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
    debugPrint('初始化进度: ${(progress * 100).toStringAsFixed(0)}% - $step');
  }
}
