import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';
import 'package:flutter/material.dart';

/// 网络检测服务类
class NetworkService {
  static final NetworkService _instance = NetworkService._internal();
  factory NetworkService() => _instance;
  NetworkService._internal();

  final Connectivity _connectivity = Connectivity();

  // 是否是WiFi网络
  bool _isWifi = false;

  // 网络状态监听器
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  /// 初始化网络检测
  Future<void> initialize() async {
    try {
      // 获取当前网络状态
      final connectivityResult = await _connectivity.checkConnectivity();
      _isWifi = _checkIsWifi(connectivityResult);

      debugPrint('网络检测已初始化，当前WiFi状态: $_isWifi');
    } catch (e) {
      debugPrint('初始化网络检测失败: $e');
    }
  }

  /// 检查是否是WiFi网络
  bool _checkIsWifi(List<ConnectivityResult> results) {
    return results.contains(ConnectivityResult.wifi);
  }

  /// 获取当前网络状态
  Future<bool> getIsWifi() async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      _isWifi = _checkIsWifi(connectivityResult);
      return _isWifi;
    } catch (e) {
      debugPrint('获取网络状态失败: $e');
      return false;
    }
  }

  /// 监听网络状态变化
  void listenNetworkStatus(Function(bool isWifi) onWifiChanged) {
    _connectivitySubscription?.cancel();

    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((results) {
      _isWifi = _checkIsWifi(results);
      debugPrint('网络状态变化: $results, WiFi: $_isWifi');
      onWifiChanged(_isWifi);
    });
  }

  /// 取消网络监听
  void dispose() {
    _connectivitySubscription?.cancel();
  }
}