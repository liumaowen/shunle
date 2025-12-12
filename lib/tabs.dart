import "package:flutter/material.dart";
import "package:shunle/home.dart";
import 'package:persistent_bottom_nav_bar_v2/persistent_bottom_nav_bar_v2.dart';

class Tabs extends StatelessWidget {
  Tabs({super.key});

  final List<PersistentTabConfig> _tabs = [
    PersistentTabConfig(
      screen: Home(),
      item: ItemConfig(
        icon: SizedBox.shrink(),
        title: "tuijian",
        activeForegroundColor: Colors.white, // 选中时的颜色
        inactiveForegroundColor: Colors.grey, // 未选中时的颜色
      ),
    ),
    PersistentTabConfig(
      screen: Scaffold(body: Center(child: Text("Messages"))),
      item: ItemConfig(
        icon: SizedBox.shrink(),
        title: "messages",
        activeForegroundColor: Colors.white, // 选中时的颜色
        inactiveForegroundColor: Colors.grey, // 未选中时的颜色
      ),
    ),
    PersistentTabConfig(
      screen: Scaffold(body: Center(child: Text("Settings"))),
      item: ItemConfig(
        icon: SizedBox.shrink(),
        title: "my",
        activeForegroundColor: Colors.white, // 选中时的颜色
        inactiveForegroundColor: Colors.grey, // 未选中时的颜色
      ),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // 设置浅色主题
      theme: ThemeData.light().copyWith(
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
      home: PersistentTabView(
        tabs: _tabs,
        navBarBuilder: (navBarConfig) => Style1BottomNavBar(
          navBarConfig: navBarConfig,
          navBarDecoration: NavBarDecoration(
            color: Colors.black,
            padding: EdgeInsets.only(top: 8, bottom: 12),
          ),
        ),
        navBarOverlap: NavBarOverlap.full(),
      ),
    );
  }
}
