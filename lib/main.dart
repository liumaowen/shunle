import 'package:flutter/material.dart';
import "package:flutter/services.dart";
import 'package:shunle/splash_screen.dart';
import 'package:shunle/providers/global_config.dart';

void main() async {
  runApp(const MyApp());

  // WidgetsFlutterBinding 确保在 MyApp 的 build 方法之前初始化
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化全局配置
  GlobalConfig.initialize(const Mgtvconfig());

  // make navigation bar transparent
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(systemNavigationBarColor: Colors.transparent),
  );
  // make flutter draw behind navigation bar
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // 初始化应用（在启动页面中进行）
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: '顺乐短剧',
      home: SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
