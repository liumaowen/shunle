import 'package:flutter/material.dart';

/// 可见性检测组件
///
/// 检测子组件是否在可视区域内，并通知父组件
class VisibilityDetector extends StatefulWidget {
  final Widget child;
  final VoidCallback onVisible;
  final VoidCallback? onInvisible;

  const VisibilityDetector({
    required this.child,
    required this.onVisible,
    this.onInvisible,
    super.key,
  });

  @override
  State<VisibilityDetector> createState() => _VisibilityDetectorState();
}

class _VisibilityDetectorState extends State<VisibilityDetector> {
  final GlobalKey _key = GlobalKey();
  bool _isVisible = false;

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        // 只在滚动结束时检查可见性
        if (notification is ScrollEndNotification) {
          _checkVisibility();
        }
        return false;
      },
      child: VisibilityDetectorWidget(
        key: _key,
        child: widget.child,
        onVisible: () {
          if (!_isVisible) {
            setState(() {
              _isVisible = true;
            });
            widget.onVisible();
          }
        },
        onInvisible: () {
          if (_isVisible) {
            setState(() {
              _isVisible = false;
            });
            widget.onInvisible?.call();
          }
        },
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    // 延迟检查可见性，确保布局完成
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkVisibility();
    });
  }

  @override
  void didUpdateWidget(VisibilityDetector oldWidget) {
    super.didUpdateWidget(oldWidget);
    _checkVisibility();
  }

  void _checkVisibility() {
    final renderBox = _key.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;
    final screenHeight = MediaQuery.of(context).size.height;

    // 简化的可见性检查 - 只检查是否在屏幕范围内
    final bool isVisible = position.dy + size.height > 0 && position.dy < screenHeight;

    if (isVisible && !_isVisible) {
      // 只在首次可见时触发回调
      setState(() {
        _isVisible = true;
      });
      widget.onVisible();
    } else if (!isVisible && _isVisible) {
      // 只在离开屏幕时触发回调
      setState(() {
        _isVisible = false;
      });
      widget.onInvisible?.call();
    }
  }
}

/// 内部可见性检测组件
class VisibilityDetectorWidget extends StatefulWidget {
  final Widget child;
  final VoidCallback onVisible;
  final VoidCallback onInvisible;

  const VisibilityDetectorWidget({
    required this.child,
    required this.onVisible,
    required this.onInvisible,
    super.key,
  });

  @override
  State<VisibilityDetectorWidget> createState() => _VisibilityDetectorWidgetState();
}

class _VisibilityDetectorWidgetState extends State<VisibilityDetectorWidget> {
  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  @override
  void initState() {
    super.initState();
    // 延迟检查可见性
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkVisibility();
    });
  }

  void _checkVisibility() {
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;
    final screenHeight = MediaQuery.of(context).size.height;

    // 简化的可见性检查
    final bool isVisible = position.dy < screenHeight &&
                          position.dy + size.height > 0;

    if (isVisible) {
      widget.onVisible();
    } else {
      widget.onInvisible();
    }
  }
}