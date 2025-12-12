import 'package:flutter/material.dart';
import 'widgets/video_data.dart';
import 'widgets/short_video_list.dart'; // 使用 ShortVideoList 和 generateMockVideos

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

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabChanged(int index) {
    setState(() {
      _currentIndex = index;
    });

    // 平滑切换页面
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 100),
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
          child: SafeArea(
            child: _buildFloatTabBar(),
          ),
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

            return GestureDetector(
              onTap: () => _onTabChanged(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Tab 文字
                    Text(
                      title,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey,
                        fontSize: 16,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        shadows: [
                          Shadow(
                            color: Colors.black,
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
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
    // 为每个 Tab 生成对应的视频列表
    final videos = generateMockVideos(tabTitle, count: 20);
    return ShortVideoList(videos: videos);
  }
}