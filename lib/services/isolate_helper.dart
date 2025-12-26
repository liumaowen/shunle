/// Isolate 辅助函数 - 在原生平台提供 Isolate 访问
/// 在 Web 平台降级为 null
library;

import 'package:flutter/foundation.dart';

// ignore: uri_does_not_exist
import 'dart:isolate' if (dart.library.html) 'dart:async';

/// 创建 ReceivePort 实例
/// 在原生平台创建真实的 ReceivePort，在 Web 平台返回 null
dynamic createReceivePort() {
  if (kIsWeb) {
    // Web 平台：不支持 Isolate，返回 null
    return null;
  }

  try {
    // 在原生平台：使用 ReceivePort
    // 这个调用只在原生平台编译时有效
    // 因为 dart:isolate 在原生平台被导入
    // ignore: undefined_method
    return ReceivePort() as dynamic;
  } catch (e) {
    return null;
  }
}

/// 获取 Isolate.spawn 方法
/// 在原生平台返回 Isolate.spawn，在 Web 平台返回 null
dynamic getIsolateSpawn() {
  if (kIsWeb) {
    // Web 平台：不支持 Isolate，返回 null
    return null;
  }

  try {
    // 在原生平台：验证 ReceivePort 可用来推断 Isolate 可用
    // 实际的 Isolate.spawn 调用会在 crypto_isolate_service.dart 中处理
    // ignore: undefined_method
    final receivePort = ReceivePort() as dynamic;
    if (receivePort != null) {
      // 返回标记表示 Isolate 可用
      return isolateSpawnMarker;
    }
  } catch (e) {
    return null;
  }
  return null;
}

/// 标记对象，表示 Isolate.spawn 可用
const dynamic isolateSpawnMarker = 'isolate_spawn_available';
