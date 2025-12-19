# Flutter 应用生命周期管理使用指南

## 概述

本指南介绍如何在 Flutter 应用中管理应用生命周期，特别是在应用启动时自动获取配置数据。

## 主要组件

### 1. AppInitializer - 应用初始化服务

```dart
import 'package:shunle/services/app_initializer.dart';

// 在应用启动时调用
AppInitializer.initialize(
  context: context,  // 可选
  showLoading: true, // 是否显示加载指示器
);
```

**特点：**
- 支持显示/隐藏加载指示器
- 统一的初始化入口
- 错误处理和重试机制

### 2. AppLifecycleManager - 生命周期管理器

```dart
import 'package:shunle/utils/app_lifecycle_manager.dart';

// 在 MaterialApp 中使用
App(
  home: AppLifecycleManager(
    child: MyApp(),
  ),
);
```

**特点：**
- 监听应用生命周期事件
- 应用启动时自动获取配置
- 提供状态回调和错误处理

### 3. AppStartupWidget - 启动组件

```dart
import 'package:shunle/widgets/app_startup_widget.dart';

// 包裹主应用
AppStartupWidget(
  home: MyApp(),
);
```

**特点：**
- 显示启动画面
- 处理初始化失败
- 提供重试功能

## 使用方式

### 方式一：直接使用 AppInitializer（推荐）

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 应用启动时初始化
  await AppInitializer.initialize(
    showLoading: true,
  );

  runApp(MyApp());
}
```

### 方式二：使用 AppStartupWidget（适用于需要启动画面的应用）

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    AppStartupWidget(
      home: MyApp(),
    ),
  );
}
```

### 方式三：使用 AppLifecycleManager（适用于需要生命周期监听的应用）

```dart
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: AppLifecycleManager(
        child: Tabs(),
      ),
    );
  }
}
```

## 生命周期事件

AppLifecycleManager 支持监听以下生命周期事件：

- `resumed` - 应用从后台回到前台
- `inactive` - 应用处于非活动状态
- `paused` - 应用进入后台
- `detached` - 应用被销毁
- `hidden` - 应用隐藏（Android 10+）

## 配置获取

### 自动获取配置

```dart
// 应用启动时自动获取
AppInitializer.initialize();

// 手动获取
final config = await ConfigApiService.fetchConfigSafe();
```

### 自定义配置获取

```dart
// 显示加载指示器
await AppInitializer.initialize(
  context: context,
  showLoading: true,
);

// 不显示加载指示器
await AppInitializer.initialize(
  showLoading: false,
);
```

## 错误处理

### 错误恢复机制

1. **初始化失败**：显示错误信息和重试按钮
2. **网络错误**：自动使用默认值继续运行
3. **配置解析错误**：记录错误并使用默认配置

```dart
// 重试初始化
await AppInitializer.initialize(
  showLoading: true,
);
```

## 最佳实践

1. **避免阻塞主线程**：初始化操作应在 `initState` 或单独的 `async` 函数中执行
2. **处理网络错误**：确保在网络不可用时应用仍能正常运行
3. **显示加载状态**：为长时间运行的初始化任务提供用户反馈
4. **使用 mounted 检查**：在异步操作中检查组件是否仍被挂载

## 示例代码

### 完整的启动流程

```dart
class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      await AppInitializer.initialize(
        showLoading: true,
      );
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      print('初始化失败: $e');
      // 处理错误或使用默认值
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    return Tabs();
  }
}
```

## 性能优化

1. **预加载**：在应用启动时预加载常用数据
2. **缓存配置**：将配置数据缓存到本地存储
3. **并行初始化**：使用 `Future.wait` 并行执行多个初始化任务

## 注意事项

1. 仅在必要时显示加载指示器
2. 初始化时间不应超过 3-5 秒
3. 确保初始化失败不会导致应用崩溃
4. 提供明确的错误信息和恢复机制