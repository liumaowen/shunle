import 'package:flutter/material.dart';
import 'package:shunle/widgets/video_data.dart';

/// 首页使用的Tabs组件
/// 横向滚动的分类导航
class CollectTabs extends StatefulWidget {
  final int initialIndex;
  final List<TabsType> tabs;
  final ValueChanged<int>? onTabChanged;

  const CollectTabs({
    super.key,
    this.initialIndex = 0,
    required this.tabs,
    this.onTabChanged,
  }) : assert(initialIndex >= 0 && initialIndex < tabs.length);

  @override
  State<CollectTabs> createState() => _CollectTabsState();
}

class _CollectTabsState extends State<CollectTabs> {
  late int _currentIndex;

  @override
  void initState() {
    _currentIndex = widget.initialIndex;
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _onTabChanged(int index) {
    if (index != _currentIndex) {
      setState(() {
        _currentIndex = index;
      });
      widget.onTabChanged?.call(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false, // 只在顶部预留空间给状态栏
      child: Container(
        height: 50,
        decoration: BoxDecoration(color: Colors.black),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const ClampingScrollPhysics(),
          child: Row(
            children: widget.tabs.asMap().entries.map((entry) {
              final index = entry.key;
              final title = entry.value.title;
              final isSelected = index == _currentIndex;

              return InkWell(
                // 使用 GestureDetector 替代 InkWell 避免涟漪效果
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
      ),
    );
  }
}
