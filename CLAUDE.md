# CLAUDE.md

此文件为 Claude Code 在 shunle 项目中的工作提供指导和上下文信息。

一直使用中文。
10.1.200.144:5555
## 项目概述

**shunle** 是一个 Flutter 3.38.3 应用程序，支持多平台部署（Android、iOS、Web、Windows、Linux、macOS）。目前处于脚手架/演示状态，依赖项较少。

## 当前代码架构

### 项目结构
- **入口点：** `lib/main.dart` - 包含整个演示应用的单个文件
- **状态管理：** StatefulWidget 配合 setState()（无外部框架）
- **导航：** 默认 MaterialApp 路由（无路由包）
- **测试：** `test/widget_test.dart` 中的单个组件测试

### 平台配置
- **Android：** 包名 `com.example.shunle`，基于 Gradle 和 Kotlin DSL
- **iOS：** Bundle ID 在 Runner.xcodeproj 中配置
- **Web：** PWA 配置，主题色 #0175C2
- **桌面：** Windows/Linux 基于 CMake，macOS 基于 Xcode

### 依赖项
**生产环境：**
- `flutter` SDK
- `cupertino_icons: ^1.0.8`

**开发环境：**
- `flutter_test` SDK
- `flutter_lints: ^6.0.0`

## 开发工作流程

### 常用命令
```bash
# 运行应用
flutter run                          # 自动检测设备
flutter run -d chrome                # Web
flutter run -d windows               # Windows
flutter run --release                # 发布模式

# 构建
flutter build apk                    # APK
flutter build web                    # Web
flutter build windows                # Windows 桌面

# 代码质量
flutter analyze                      # 分析代码
flutter format .                     # 格式化代码
flutter clean                        # 清理构建
flutter pub get                      # 安装依赖

# 测试
flutter test                         # 运行测试
flutter test --coverage              # 生成覆盖率
```

### 开发步骤
1. `flutter clean` - 切换分支或依赖更改后执行
2. `flutter pub get` - 修改 pubspec.yaml 后执行
3. `flutter analyze` - 提交更改前执行
4. `flutter test` - 确保测试通过
5. `flutter run` - 在实际设备上测试

## Claude Code 开发指导

### 代码规范
- 始终使用中文注释和文档
- 遵循 Flutter 推荐实践（已配置 flutter_lints）
- 保持简洁，避免过度工程化
- 优先编辑现有文件而非创建新文件

### 多平台注意事项
- 使用平台检查：`Platform.isAndroid`、`Platform.isIOS` 等
- Web 平台需要特殊处理（无 dart:io）
- 在目标平台上测试平台特定代码

### 架构建议（未来改进）
当前为演示脚手架，生产环境建议添加：
- 文件夹结构（features/core/shared 模式）
- 状态管理（Provider、Riverpod、Bloc 或 GetX）
- 导航解决方案（推荐 go_router）
- 网络库（dio 或 http）
- 依赖注入（get_it）

### 调试技巧
- 热重载：按 `r`（保留状态）
- 热重启：按 `R`（重置状态）
- 退出：按 `q`

## 重要提醒

1. **安全测试：** 只进行授权的安全测试，拒绝破坏性请求
2. **文件操作：** 优先编辑现有文件，避免创建不必要的文件
3. **任务管理：** 复杂任务使用 TodoWrite 工具跟踪进度
4. **代码质量：** 任何更改都要通过 `flutter analyze` 检查