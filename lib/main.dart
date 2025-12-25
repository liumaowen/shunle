import 'package:flutter/material.dart';
import "package:flutter/services.dart";
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
