library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 启动加载动画组件
/// 显示应用的启动加载状态，包括加载动画和进度提示
class SplashLoadingWidget extends StatefulWidget {
  /// 加载提示文本
  final String? loadingText;

  /// 是否显示进度条
  final bool showProgress;

  /// 背景颜色
  final Color? backgroundColor;

  /// 文本颜色
  final Color? textColor;

  /// Logo 图片（如果有）
  final String? logoAsset;

  /// 加载进度（0.0 - 1.0）
  final double? progress;

  const SplashLoadingWidget({
    Key? key,
    this.loadingText,
    this.showProgress = true,
    this.backgroundColor,
    this.textColor,
    this.logoAsset,
    this.progress,
  });

  @override
  State<SplashLoadingWidget> createState() => _SplashLoadingWidgetState();
}

class _SplashLoadingWidgetState extends State<SplashLoadingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    // 创建旋转动画
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 设置沉浸式状态栏
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: widget.backgroundColor ?? Colors.blue,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );

    return Scaffold(
      backgroundColor: widget.backgroundColor ?? Colors.blue,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Logo 或加载动画
            _buildLogoOrAnimation(),

            const SizedBox(height: 40),

            // 应用名称
            _buildAppName(),

            const SizedBox(height: 20),

            // 加载文本
            _buildLoadingText(),

            const SizedBox(height: 30),

            // 进度条
            if (widget.showProgress) _buildProgress(),

            // 版本信息
            _buildVersionInfo(),
          ],
        ),
      ),
    );
  }

  /// 构建 Logo 或加载动画
  Widget _buildLogoOrAnimation() {
    if (widget.logoAsset != null) {
      // 如果有 Logo，显示 Logo
      return Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.asset(
            widget.logoAsset!,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildAnimationIcon();
            },
          ),
        ),
      );
    } else {
      // 否则显示动画图标
      return _buildAnimationIcon();
    }
  }

  /// 构建动画图标
  Widget _buildAnimationIcon() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.rotate(
          angle: _controller.value * 2 * 3.14159,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(50),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: const Icon(
              Icons.play_circle_filled,
              size: 50,
              color: Colors.blue,
            ),
          ),
        );
      },
    );
  }

  /// 构建应用名称
  Widget _buildAppName() {
    return Text(
      '顺乐短剧',
      style: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: widget.textColor ?? Colors.white,
        shadows: [
          Shadow(
            color: Colors.black.withValues(alpha: 0.3),
            offset: const Offset(2, 2),
            blurRadius: 4,
          ),
        ],
      ),
    );
  }

  /// 构建加载文本
  Widget _buildLoadingText() {
    final text = widget.loadingText ?? '正在加载中...';

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Text(
        text,
        key: ValueKey(text),
        style: TextStyle(
          fontSize: 16,
          color: widget.textColor ?? Colors.white.withValues(alpha: 0.9),
        ),
      ),
    );
  }

  /// 构建进度条
  Widget _buildProgress() {
    if (widget.progress != null) {
      // 显示具体进度的进度条
      return Column(
        children: [
          SizedBox(
            width: 200,
            child: LinearProgressIndicator(
              value: widget.progress,
              backgroundColor: Colors.white.withValues(alpha: 0.3),
              valueColor: AlwaysStoppedAnimation<Color>(
                widget.textColor ?? Colors.white,
              ),
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${(widget.progress! * 100).toStringAsFixed(0)}%',
            style: TextStyle(
              fontSize: 12,
              color: widget.textColor ?? Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      );
    } else {
      // 显示无限循环的进度条
      return SizedBox(
        width: 200,
        child: LinearProgressIndicator(
          backgroundColor: Colors.white.withValues(alpha: 0.3),
          valueColor: AlwaysStoppedAnimation<Color>(
            widget.textColor ?? Colors.white,
          ),
          minHeight: 6,
          borderRadius: BorderRadius.circular(3),
        ),
      );
    }
  }

  /// 构建版本信息
  Widget _buildVersionInfo() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Text(
        'v1.0.0',
        style: TextStyle(
          fontSize: 12,
          color: widget.textColor ?? Colors.white.withValues(alpha: 0.6),
        ),
      ),
    );
  }
}
