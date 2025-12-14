import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/video_list_provider.dart';
import 'widgets/short_video_list.dart';

/// 首页使用的悬浮Tabs组件
/// 实现透明背景、不占用空间、横向滚动的分类导航
class HomeFloatTabs extends StatefulWidget {
  final int initialIndex;
  final List<String> tabs;
  final ValueChanged<int>? onTabChanged;

  const HomeFloatTabs({
    super.key,
    this.initialIndex = 0,
    required this.tabs,
    this.onTabChanged,
  }) : assert(initialIndex >= 0 && initialIndex < tabs.length);

  @override
  State<HomeFloatTabs> createState() => _HomeFloatTabsState();
}

class _HomeFloatTabsState extends State<HomeFloatTabs> {
  late int _currentIndex;
  late PageController _pageController;

  /// 为每个 Tab 保持独立的 VideoListProvider 实例，防止切换时被销毁
  late final Map<int, VideoListProvider> _providers;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
    // 为每个 Tab 创建对应的 Provider 实例
    _providers = {
      for (int i = 0; i < widget.tabs.length; i++) i: VideoListProvider(),
    };
  }

  @override
  void dispose() {
    _pageController.dispose();
    debugPrint('dispose');
    debugPrint('dispose${_providers.values.toString()}');
    // 释放所有 Provider 实例
    for (final provider in _providers.values) {
      provider.dispose();
    }
    super.dispose();
  }

  void _onTabChanged(int index) {
    setState(() {
      _currentIndex = index;
    });

    // 平滑切换页面
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
    );

    // 通知回调
    widget.onTabChanged?.call(index);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 底层：全屏视频列表 PageView
        Positioned.fill(
          child: PageView.builder(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(), // 禁止 PageView 手动滑动
            itemCount: widget.tabs.length,
            itemBuilder: (context, index) {
              return _buildTabContent(widget.tabs[index], index);
            },
          ),
        ),

        // 上层：悬浮透明 Tab 条
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(child: _buildFloatTabBar()),
        ),
      ],
    );
  }

  /// 构建悬浮透明 Tab 条
  Widget _buildFloatTabBar() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.6), // 顶部半透明
            Colors.transparent, // 底部完全透明
          ],
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const ClampingScrollPhysics(),
        child: Row(
          children: widget.tabs.asMap().entries.map((entry) {
            final index = entry.key;
            final title = entry.value;
            final isSelected = index == _currentIndex;

            return InkWell(
              // 使用 InkWell 提供更好的点击区域和点击反馈
              onTap: () => _onTabChanged(index),
              child: Padding(
                // 用 Padding 扩大可点击区域
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Tab 文字
                    Text(
                      title,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey,
                        fontSize: 16,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                      ),
                    ),
                    const SizedBox(height: 2),
                    // 选中指示器
                    Container(
                      height: 3,
                      width: 30,
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(1.5),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  /// 构建tab内容（短视频列表）
  Widget _buildTabContent(String tabTitle, int index) {
    // 使用 ChangeNotifierProvider.value 传入预创建的 Provider 实例
    // 这样切换 Tab 时不会销毁旧 Provider，避免 "already disposed" 错误
    return ChangeNotifierProvider<VideoListProvider>.value(
      value: _providers[index]!,
      child: const ShortVideoList(),
    );
  }
}
