import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';
import 'package:flutter/material.dart';

/// 网络检测服务类
class NetworkService {
  static final NetworkService _instance = NetworkService._internal();
  factory NetworkService() => _instance;
  NetworkService._internal();

  final Connectivity _connectivity = Connectivity();

  // 是否是有线网络（包括WiFi和以太网）
  bool _isWiredNetwork = false;

  // 网络状态监听器
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  /// 初始化网络检测
  Future<void> initialize() async {
    try {
      // 获取当前网络状态
      final connectivityResult = await _connectivity.checkConnectivity();
      _isWiredNetwork = _checkIsWiredNetwork(connectivityResult);

      debugPrint('网络检测已初始化，当前有线网络状态: $_isWiredNetwork');
    } catch (e) {
      debugPrint('初始化网络检测失败: $e');
    }
  }

  /// 检查是否是有线网络（包括WiFi和以太网）
  bool _checkIsWiredNetwork(List<ConnectivityResult> results) {
    return results.contains(ConnectivityResult.wifi) ||
           results.contains(ConnectivityResult.ethernet);
  }

  /// 获取当前网络状态
  Future<bool> getIsWiredNetwork() async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      _isWiredNetwork = _checkIsWiredNetwork(connectivityResult);
      return _isWiredNetwork;
    } catch (e) {
      debugPrint('获取网络状态失败: $e');
      return false;
    }
  }

  /// 监听网络状态变化
  void listenNetworkStatus(Function(bool isWiredNetwork) onWiredNetworkChanged) {
    _connectivitySubscription?.cancel();

    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((results) {
      _isWiredNetwork = _checkIsWiredNetwork(results);
      debugPrint('网络状态变化: $results, 有线网络: $_isWiredNetwork');
      onWiredNetworkChanged(_isWiredNetwork);
    });
  }

  /// 取消网络监听
  void dispose() {
    _connectivitySubscription?.cancel();
  }
}