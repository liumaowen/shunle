import 'package:flutter/material.dart';
import "package:flutter/services.dart";
import "package:persistent_bottom_nav_bar_v2/persistent_bottom_nav_bar_v2.dart";
import 'package:shunle/interactive_example.dart';
import 'package:shunle/screens.dart';
import 'package:shunle/services/app_initializer.dart';
import 'package:shunle/tabs.dart';
import 'package:shunle/providers/global_config.dart';


void main() async {
  // runApp(MyApp());

  WidgetsFlutterBinding.ensureInitialized();
  // 初始化全局配置
  GlobalConfig.initialize(const Mgtvconfig());

  // make navigation bar transparent
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(systemNavigationBarColor: Colors.transparent),
  );
  // make flutter draw behind navigation bar
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  // 在应用启动时调用，例如 main.dart 中
  await AppInitializer.initialize(
    // context: context,    // 可选，用于显示加载指示器
    showLoading: true, // 是否显示加载指示器
  );
  runApp(Tabs());
}

class PersistenBottomNavBarDemo extends StatelessWidget {
  const PersistenBottomNavBarDemo({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: "Persistent Bottom Navigation Bar Demo",
    home: Builder(
      builder: (context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pushNamed("/minimal"),
              child: const Text("Show Minimal Example"),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pushNamed("/interactive"),
              child: const Text("Show Interactive Example"),
            ),
          ],
        ),
      ),
    ),
    routes: {
      "/minimal": (context) => const MinimalExample(),
      "/interactive": (context) => const InteractiveExample(),
    },
  );
}

class MinimalExample extends StatelessWidget {
  const MinimalExample({super.key});

  List<PersistentTabConfig> _tabs() => [
    PersistentTabConfig(
      screen: const MainScreen(),
      item: ItemConfig(icon: const Icon(Icons.home), title: "Home"),
    ),
    PersistentTabConfig(
      screen: const MainScreen(),
      item: ItemConfig(icon: const Icon(Icons.message), title: "Messages"),
    ),
    PersistentTabConfig(
      screen: const MainScreen(),
      item: ItemConfig(icon: const Icon(Icons.settings), title: "Settings"),
    ),
  ];

  @override
  Widget build(BuildContext context) => PersistentTabView(
    tabs: _tabs(),
    navBarBuilder: (navBarConfig) =>
        Style1BottomNavBar(navBarConfig: navBarConfig),
  );
}

