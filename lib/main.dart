import 'dart:ui';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shunle/splash_screen.dart';
import 'package:shunle/providers/global_config.dart';

void main() async {
  // WidgetsFlutterBinding 确保在 MyApp 的 build 方法之前初始化
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化网络监听
  final connectivityResult = await Connectivity().checkConnectivity();
  debugPrint('初始网络状态: $connectivityResult');
  SnackBar(
    content: Text('初始网络状态: $connectivityResult'),
    backgroundColor: Colors.grey,
  );

  // 监听网络变化
  Connectivity().onConnectivityChanged.listen((result) {
    debugPrint('网络状态变化: $result');
    SnackBar(content: Text('网络状态变化: $result'), backgroundColor: Colors.grey);
    // 可以在这里添加网络状态变化的处理逻辑
  });

  runApp(
    // MultiProvider(
    //   providers: [
    //     ChangeNotifierProvider(create: (context) => VideoListProvider()),
    //   ],
    //   child: const MyApp()
    // )
    const MyApp(),
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
