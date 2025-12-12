# CODEBUDDY.md 本文件为 CodeBuddy Code 在此仓库中工作提供指导。

一直使用中文。

## 项目概述

**shunle** 是一个 Flutter 3.38.3 应用程序，配置支持多平台部署（Android、iOS、Web、Windows、Linux、macOS）。目前处于脚手架/演示状态，依赖项较少。

## 常用开发命令

### 运行应用
```bash
# 在已连接的设备上运行（自动检测）
flutter run

# 在特定平台上运行
flutter run -d chrome      # Web 浏览器
flutter run -d windows     # Windows 桌面
flutter run -d android     # Android 设备/模拟器
flutter run -d ios         # iOS 模拟器/设备（仅 macOS）

# 发布模式
flutter run --release
```

### 构建
```bash
# Android 构建
flutter build apk              # 调试 APK
flutter build apk --release    # 发布 APK
flutter build appbundle        # Play 商店应用包

# iOS 构建（需要 macOS）
flutter build ios
flutter build ipa

# 桌面构建
flutter build windows
flutter build linux
flutter build macos

# Web 构建
flutter build web
```

### 测试
```bash
# 运行所有测试
flutter test

# 运行特定测试文件
flutter test test/widget_test.dart

# 运行并生成覆盖率报告
flutter test --coverage
```

### 代码质量
```bash
# 分析代码（提交前运行）
flutter analyze

# 格式化代码
flutter format .

# 清理构建产物
flutter clean

# 重新安装依赖
flutter pub get
```

### 依赖管理
```bash
# 检查过时的包
flutter pub outdated

# 升级依赖
flutter pub upgrade

# 清理并重新安装（故障排除）
flutter clean && flutter pub get
```

## 代码架构

### 当前结构
- **入口点：** `lib/main.dart` - 包含整个演示应用的单个文件
- **状态管理：** StatefulWidget 配合 setState()（无外部框架）
- **导航：** 默认 MaterialApp 路由（无路由包）
- **测试：** `test/widget_test.dart` 中的单个组件测试

### 平台配置

#### Android
- **包名：** com.example.shunle
- **构建系统：** Gradle 配合 Kotlin DSL
- **Java/Kotlin 目标：** JVM 17
- **原生代码：** `android/app/src/main/kotlin/com/example/shunle/MainActivity.kt`
- **最小功能：** 继承 FlutterActivity，无自定义平台通道

#### iOS
- **Bundle ID：** 在 Runner.xcodeproj 中配置
- **显示名称：** "Shunle"
- **原生代码：** `ios/Runner/AppDelegate.swift`
- **方向：** 竖屏 + 横屏（iPad 支持所有方向）

#### Web
- **入口：** `web/index.html`
- **PWA：** 使用 manifest.json 配置
- **主题色：** #0175C2

#### 桌面
- **Windows/Linux：** 基于 CMake 的构建系统
- **macOS：** Xcode 项目

### 依赖项
**生产环境：**
- `flutter` SDK
- `cupertino_icons: ^1.0.8`

**开发环境：**
- `flutter_test` SDK
- `flutter_lints: ^6.0.0`（强制执行 Flutter 推荐实践）

### 代码检查
- 配置文件：`analysis_options.yaml`
- 包含：`package:flutter_lints/flutter.yaml`
- 未定义自定义规则

## 重要说明

### 多平台支持
本项目配置支持 6 个平台。开发时注意：
- 在目标平台上测试平台特定代码
- 需要时使用平台检查：`Platform.isAndroid`、`Platform.isIOS` 等
- Web 需要不同的考虑（无 dart:io，使用条件导入）

### 架构建议
当前状态为演示脚手架。生产环境开发时建议：
- 实现适当的文件夹结构（features/core/shared 模式）
- 添加状态管理（Provider、Riverpod、Bloc 或 GetX）
- 添加导航解决方案（推荐 go_router）
- 分离关注点（数据层/领域层/表现层）
- 添加网络库（dio 或 http）
- 实现依赖注入（get_it）

### 开发工作流
1. `flutter clean` - 切换分支或依赖更改后执行
2. `flutter pub get` - 修改 pubspec.yaml 后执行
3. `flutter analyze` - 提交更改前执行
4. `flutter test` - 确保测试通过
5. `flutter run` - 在实际设备/模拟器上测试

### 热重载
在调试模式下（`flutter run`）：
- 按 `r` - 热重载（保留状态）
- 按 `R` - 热重启（重置状态）
- 按 `q` - 退出

### 平台特定说明
- **Android：** 需要 Android SDK 和模拟器/设备
- **iOS/macOS：** 需要安装 Xcode 的 macOS
- **Web：** 开发时使用 `flutter run -d chrome` 运行
- **Windows：** 需要安装 C++ 桌面开发的 Visual Studio
- **Linux：** 需要 GTK3 和其他 Linux 开发库
