import 'dart:ui';

import 'package:flutter/material.dart';
import "package:flutter/services.dart";
import 'package:provider/provider.dart';
import 'package:shunle/providers/video_list_provider.dart';
import 'package:shunle/providers/video_manager.dart';
import 'package:shunle/splash_screen.dart';
import 'package:shunle/providers/global_config.dart';

void main() async {
  // WidgetsFlutterBinding 确保在 MyApp 的 build 方法之前初始化
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => VideoManager()),
        ChangeNotifierProvider(create: (context) => VideoListProvider()),
      ],
      child: const MyApp()
    )
  );

  // 初始化全局配置
  GlobalConfig.initialize(const Mgtvconfig());

  // 初始化应用（在启动页面中进行）
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '瞬乐',
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
      home: SplashScreen(),
      debugShowCheckedModeBanner: false,
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
