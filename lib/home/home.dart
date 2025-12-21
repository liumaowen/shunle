import 'package:flutter/material.dart';
import 'package:shunle/home/home_float_tabs.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _currentTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: HomeFloatTabs(
        initialIndex: _currentTabIndex,
        tabs: const ['推荐', '关注', '热榜', '视频'],
        onTabChanged: (index) {
          setState(() {
            _currentTabIndex = index;
          });
        },
      ),
    );
  }
}
