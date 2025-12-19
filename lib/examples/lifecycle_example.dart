import 'package:flutter/material.dart';
import 'package:shunle/utils/api/config_api_service.dart';

/// 应用生命周期管理示例
class LifecycleExample extends StatefulWidget {
  const LifecycleExample({super.key});

  @override
  State<LifecycleExample> createState() => _LifecycleExampleState();
}

class _LifecycleExampleState extends State<LifecycleExample> {
  AppLifecycleState? _currentLifecycleState;
  bool _isInitialized = true;
  Map<String, dynamic>? _configData;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('应用生命周期管理示例'),
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (!_isInitialized) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('正在初始化应用...'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshConfig,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '应用生命周期状态',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '当前状态: ${_currentLifecycleState?.toString() ?? '未知'}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '配置信息',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (_configData != null) ...[
                    _buildConfigItem('播放域名', _configData!['playDomain']),
                    _buildConfigItem('短视频随机最大值', _configData!['shortVideoRandomMax']),
                    _buildConfigItem('短视频随机最小值', _configData!['shortVideoRandomMin']),
                  ] else
                    const Text('暂无配置数据'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '操作按钮',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _fetchConfigManual,
                    child: const Text('手动获取配置'),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _showConfigDialog,
                    child: const Text('查看完整配置'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigItem(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value?.toString() ?? 'N/A'),
        ],
      ),
    );
  }

  /// 手动获取配置
  Future<void> _fetchConfigManual() async {
    try {
      if (!mounted) return;

      setState(() {
        _isInitialized = false;
      });

      final config = await ConfigApiService.fetchConfigSafe();

      if (mounted) {
        setState(() {
          _configData = config;
          _isInitialized = true;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('配置获取成功')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('获取配置失败: $e')),
        );
      }
    }
  }

  /// 刷新配置
  Future<void> _refreshConfig() async {
    await _fetchConfigManual();
  }

  /// 显示配置对话框
  Future<void> _showConfigDialog() async {
    if (_configData == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('完整配置信息'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildConfigItem('播放域名', _configData!['playDomain']),
              _buildConfigItem('短视频随机最大值', _configData!['shortVideoRandomMax']),
              _buildConfigItem('短视频随机最小值', _configData!['shortVideoRandomMin']),
              const SizedBox(height: 16),
              const Text(
                '全局配置:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              _buildConfigItem('API 基础域名', 'https://api.mgtv109.cc'),
              _buildConfigItem('播放域名基础', 'https://api.mgtv109.cc'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  /// 设置生命周期状态（由 AppLifecycleManager 调用）
  void setLifecycleState(AppLifecycleState state) {
    setState(() {
      _currentLifecycleState = state;
    });
  }
}