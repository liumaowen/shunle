import 'package:flutter/material.dart';
import 'package:shunle/services/network_service.dart';

/// WiFi提醒组件
class WifiReminder extends StatefulWidget {
  final Widget child;
  final Widget? offlineWidget;

  const WifiReminder({
    Key? key,
    required this.child,
    this.offlineWidget,
  });

  @override
  State<WifiReminder> createState() => _WifiReminderState();
}

class _WifiReminderState extends State<WifiReminder> {
  final NetworkService _networkService = NetworkService();
  bool _isWiredNetworkConnected = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkNetworkStatus();
  }

  @override
  void dispose() {
    _networkService.dispose();
    super.dispose();
  }

  /// 检查网络状态
  Future<void> _checkNetworkStatus() async {
    try {
      final isConnected = await _networkService.getIsWiredNetwork();
      setState(() {
        _isWiredNetworkConnected = isConnected;
        _isLoading = false;
      });

      // 监听网络状态变化
      _networkService.listenNetworkStatus((isWiredNetwork) {
        setState(() {
          _isWiredNetworkConnected = isWiredNetwork;
        });
      });
    } catch (e) {
      debugPrint('检查网络状态失败: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 显示WiFi设置引导对话框
  Future<void> _showWifiSettingsDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.wifi_off, color: Colors.red),
              SizedBox(width: 8),
              Text('请连接WiFi'),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('本应用只能在WiFi环境下使用'),
              SizedBox(height: 16),
              Text('请按照以下步骤连接WiFi：'),
              SizedBox(height: 8),
              Text('1. 点击"打开WiFi设置"'),
              Text('2. 选择可用的WiFi网络'),
              Text('3. 输入密码并连接'),
              Text('4. 返回应用即可正常使用'),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('取消'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.settings),
              label: const Text('打开WiFi设置'),
              onPressed: () {
                Navigator.of(context).pop();
                _openWifiSettings();
              },
            ),
          ],
        );
      },
    );
  }

  /// 打开WiFi设置（平台特定）
  void _openWifiSettings() {
    // 在实际应用中，这里可以打开系统WiFi设置页面
    // 由于Flutter限制，需要使用平台通道
    debugPrint('打开WiFi设置');

    // 显示提示
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('请手动在系统设置中连接WiFi'),
        duration: Duration(seconds: 3),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // 如果不是有线网络（包括WiFi和以太网），显示离线组件或提醒
    if (!_isWiredNetworkConnected) {
      if (widget.offlineWidget != null) {
        return widget.offlineWidget!;
      }

      // 显示默认的离线页面
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.wifi_off,
                size: 100,
                color: Colors.grey,
              ),
              const SizedBox(height: 24),
              const Text(
                '请连接WiFi',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '本应用只能在WiFi环境下使用',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                icon: const Icon(Icons.settings),
                label: const Text('连接WiFi'),
                onPressed: _showWifiSettingsDialog,
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => _showWifiSettingsDialog(),
                child: const Text('查看设置指南'),
              ),
            ],
          ),
        ),
      );
    }

    // 如果是WiFi网络，显示正常内容
    return widget.child;
  }
}