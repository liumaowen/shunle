import "dart:ui";

import "package:flutter/material.dart";
import "package:shunle/drama/drama.dart";
import "package:shunle/home/home.dart";
import 'package:persistent_bottom_nav_bar_v2/persistent_bottom_nav_bar_v2.dart';

class Tabs extends StatefulWidget {
  Tabs({super.key});

  @override
  State<Tabs> createState() => _TabsState();
}

class _TabsState extends State<Tabs> {
  late PersistentTabController _tabController;
  int _currentTabIndex = 0;
  late final GlobalKey _homeKey;
  late final GlobalKey _dramsKey;

  @override
  void initState() {
    super.initState();
    _tabController = PersistentTabController(initialIndex: 0);
    _homeKey = GlobalKey();
    _dramsKey = GlobalKey();
  }

  late final List<PersistentTabConfig> _tabs = [
    PersistentTabConfig(
      screen: Home(key: _homeKey),
      item: ItemConfig(
        icon: SizedBox.shrink(),
        title: "推荐",
        activeForegroundColor: Colors.white, // 选中时的颜色
        inactiveForegroundColor: Colors.grey, // 未选中时的颜色
        textStyle: TextStyle(height: 2),
      ),
    ),
    PersistentTabConfig(
      // screen: Scaffold(body: Center(child: Text("短剧"))),
      screen: Drams(key: _dramsKey),
      item: ItemConfig(
        icon: SizedBox.shrink(),
        title: "短剧",
        activeForegroundColor: Colors.white, // 选中时的颜色
        inactiveForegroundColor: Colors.grey, // 未选中时的颜色
        textStyle: TextStyle(height: 2),
      ),
    ),
    PersistentTabConfig(
      screen: Scaffold(body: Center(child: Text("Settings"))),
      item: ItemConfig(
        icon: SizedBox.shrink(),
        title: "my",
        activeForegroundColor: Colors.white, // 选中时的颜色
        inactiveForegroundColor: Colors.grey, // 未选中时的颜色
        textStyle: TextStyle(height: 2),
      ),
    ),
  ];

  void _onItemTapped(int index) {
    debugPrint('点击了第 $index 个选项卡');

    // 暂停上一个 Tab 的视频
    if (_currentTabIndex == 0) {
      // 暂停推荐 Tab 的视频
      final homeState = _homeKey.currentState;
      if (homeState != null) {
        (homeState as dynamic).pauseAllVideos();
      }
    } else if (_currentTabIndex == 1) {
      // 暂停短剧 Tab 的视频
      final dramsState = _dramsKey.currentState;
      if (dramsState != null) {
        (dramsState as dynamic).pauseAllVideos();
      }
    }

    // 更新当前索引
    _currentTabIndex = index;

    // 播放新 Tab 的视频
    if (index == 0) {
      // 播放推荐 Tab 的视频
      final homeState = _homeKey.currentState;
      if (homeState != null) {
        (homeState as dynamic).playCurrentVideo();
      }
    } else if (index == 1) {
      // 播放短剧 Tab 的视频
      final dramsState = _dramsKey.currentState;
      if (dramsState != null) {
        (dramsState as dynamic).playCurrentVideo();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // 设置浅色主题
      theme: ThemeData(
        fontFamily: 'Roboto',
        primaryColor: Colors.white, // 改成你想要的颜色
      ),
      // 设置深色主题
      darkTheme: ThemeData.dark().copyWith(
        // 你可以在这里自定义深色主题样式
        primaryColor: Colors.white,
        scaffoldBackgroundColor: Colors.black,
        colorScheme: ColorScheme.dark(),
      ),
      // 使用深色主题
      themeMode: ThemeMode.dark,
      scrollBehavior: MyScrollBehavior(),
      // home: VerticalPageDemo(),
      home: PersistentTabView(
        tabs: _tabs,
        controller: _tabController,
        onTabChanged:(value) => _onItemTapped(value),
        navBarBuilder: (navBarConfig) => Style1BottomNavBar(
          navBarConfig: navBarConfig,
          navBarDecoration: NavBarDecoration(
            color: Colors.black,
            // padding: EdgeInsets.only(top: 8, bottom: 12),
          ),
        ),
        navBarOverlap: NavBarOverlap.none(),
      ),
    );
  }
}

class MyScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
  };
}
