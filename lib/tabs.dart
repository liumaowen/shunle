import "dart:ui";

import "package:flutter/material.dart";
import "package:shunle/drama/drama.dart";
import "package:shunle/home/home.dart";
import 'package:persistent_bottom_nav_bar_v2/persistent_bottom_nav_bar_v2.dart';

class Tabs extends StatelessWidget {
  Tabs({super.key});

  final List<PersistentTabConfig> _tabs = [
    PersistentTabConfig(
      screen: Home(),
      item: ItemConfig(
        icon: SizedBox.shrink(),
        title: "推荐",
        activeForegroundColor: Colors.white, // 选中时的颜色
        inactiveForegroundColor: Colors.grey, // 未选中时的颜色
        textStyle: TextStyle(height: 2),
      ),
    ),
    PersistentTabConfig(
      screen: Drams(),
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
