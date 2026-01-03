library;

import 'package:flutter/material.dart';
import 'package:shunle/widgets/splash_loading_widget.dart';

/// 带进度显示的启动加载组件
/// 可以实时显示加载进度，提供更好的用户体验
class SplashLoadingWithProgress extends StatefulWidget {
  /// 初始化完成后的回调
  final VoidCallback onInitialized;

  /// 初始化步骤的回调，用于更新进度
  final Function(String step, double progress)? onStepUpdate;

  const SplashLoadingWithProgress({
    Key? key,
    required this.onInitialized,
    this.onStepUpdate,
  });

  @override
  State<SplashLoadingWithProgress> createState() =>
      _SplashLoadingWithProgressState();
}

class _SplashLoadingWithProgressState extends State<SplashLoadingWithProgress> {
  double _progress = 0.0;
  String _currentStep = '正在初始化...';

  @override
  void initState() {
    super.initState();
    _startInitialization();
  }

  @override
  Widget build(BuildContext context) {
    return SplashLoadingWidget(
      loadingText: _currentStep,
      showProgress: true,
      progress: _progress,
    );
  }

  /// 开始初始化流程
  Future<void> _startInitialization() async {
    try {
      // 步骤 1: 初始化全局配置 (10%)
      await _updateProgress('初始化全局配置...', 0.1);
      await Future.delayed(const Duration(milliseconds: 10));

      // 步骤 2: 初始化加密服务 (20%)
      await _updateProgress('初始化加密服务...', 0.2);
      await Future.delayed(const Duration(milliseconds: 0));

      // 步骤 3: 初始化网络服务 (30%)
      await _updateProgress('初始化网络服务...', 0.3);
      await Future.delayed(const Duration(milliseconds: 0));

      // 步骤 4: 初始化缓存服务 (50%)
      await _updateProgress('初始化缓存服务...', 0.5);
      await Future.delayed(const Duration(milliseconds: 0));

      // 步骤 5: 加载用户数据 (70%)
      await _updateProgress('加载用户数据...', 0.7);
      await Future.delayed(const Duration(milliseconds: 0));

      // 步骤 6: 预加载热门内容 (90%)
      await _updateProgress('预加载热门内容...', 0.9);
      await Future.delayed(const Duration(milliseconds: 0));

      // 步骤 7: 初始化完成 (100%)
      await _updateProgress('初始化完成，即将进入应用...', 1.0);
      await Future.delayed(const Duration(milliseconds: 0));

      // 初始化完成，跳转到主应用
      if (mounted) {
        widget.onInitialized();
      }
    } catch (e) {
      debugPrint('初始化失败: $e');
      // 发生错误时，仍然跳转，但记录错误
      if (mounted) {
        widget.onInitialized();
      }
    }
  }

  /// 更新进度
  Future<void> _updateProgress(String step, double progress) async {
    if (mounted) {
      setState(() {
        _currentStep = step;
        _progress = progress;
      });

      // 通知监听者
      widget.onStepUpdate?.call(step, progress);
    }
  }
}
