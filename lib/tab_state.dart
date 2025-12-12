import 'package:flutter/material.dart';

/// Tab状态管理类
/// 管理当前选中的tab索引，使用Provider进行状态共享
class TabState extends ChangeNotifier {
  int _currentIndex = 0;

  /// 获取当前选中的tab索引
  int get currentIndex => _currentIndex;

  /// 设置当前选中的tab索引
  void setCurrentIndex(int index) {
    _currentIndex = index;
    notifyListeners();
  }

  /// 切换到下一个tab
  void nextTab() {
    _currentIndex++;
    notifyListeners();
  }

  /// 切换到上一个tab
  void previousTab() {
    _currentIndex--;
    notifyListeners();
  }

  /// 重置到第一个tab
  void reset() {
    _currentIndex = 0;
    notifyListeners();
  }
}