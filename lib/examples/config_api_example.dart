import 'package:flutter/material.dart';
import 'package:shunle/utils/api/config_api_service.dart';
import 'package:shunle/utils/api/arraybuffer_response_decoder.dart';
import 'package:shunle/providers/global_config.dart';

/// 配置 API 使用示例
class ConfigApiExample extends StatefulWidget {
  const ConfigApiExample({super.key});

  @override
  State<ConfigApiExample> createState() => _ConfigApiExampleState();
}

class _ConfigApiExampleState extends State<ConfigApiExample> {
  bool _isLoading = false;
  String _status = '';
  Map<String, dynamic>? _config;

  @override
  void initState() {
    super.initState();
    _fetchConfig();
  }

  /// 获取配置信息
  Future<void> _fetchConfig() async {
    setState(() {
      _isLoading = true;
      _status = '正在获取配置...';
    });

    try {
      // 方法1：使用 ConfigApiService
      final config = await ConfigApiService.fetchConfigSafe();

      setState(() {
        _config = config;
        _isLoading = false;
        _status = '获取配置成功！';
      });

      // 打印配置信息
      print('配置信息:');
      print('播放域名: ${config['playDomain']}');
      print('短视频随机最大值: ${config['shortVideoRandomMax']}');
      print('短视频随机最小值: ${config['shortVideoRandomMin']}');

      // 打印全局配置
      print('全局配置 - 播放域名: ${GlobalConfig.playDomain}');
      print('全局配置 - 短视频随机最大值: ${GlobalConfig.shortVideoRandomMax}');
      print('全局配置 - 短视频随机最小值: ${GlobalConfig.shortVideoRandomMin}');

    } catch (e) {
      setState(() {
        _isLoading = false;
        _status = '获取配置失败: $e';
      });
    }
  }

  /// 测试 ArrayBuffer 解码器
  Future<void> _testArrayBufferDecoder() async {
    setState(() {
      _status = '测试 ArrayBuffer 解码器...';
    });

    try {
      // 模拟响应体（这里应该是从 API 获取的实际数据）
      // 为了演示，我们可以创建一个模拟的加密字符串
      final mockResponse = '{"data": [{"pKey": "ShortVideoRandomPage", "value1": "5", "value2": "10"}, {"pKey": "PlayDomain", "value1": "https://example.com"}]}';

      // 加密这个字符串以便测试（在实际应用中，这个字符串应该是从 API 获取的加密数据）
      // 这里我们直接使用模拟数据测试解码
      final result = await ArrayBufferResponseDecoder.decodeAndExtractConfig(
        responseBody: mockResponse,
      );

      setState(() {
        _config = result;
        _status = 'ArrayBuffer 解码测试成功！';
      });

      print('解码结果:');
      print('shortVideoRandomMax: ${result['shortVideoRandomMax']}');
      print('shortVideoRandomMin: ${result['shortVideoRandomMin']}');
      print('playDomain: ${result['playDomain']}');

    } catch (e) {
      setState(() {
        _status = 'ArrayBuffer 解码测试失败: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('配置 API 示例'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _isLoading ? null : _fetchConfig,
                  child: const Text('获取配置'),
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _testArrayBufferDecoder,
                  child: const Text('测试解码'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              '状态: $_status',
              style: TextStyle(
                color: _status.contains('成功') ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(height: 20),
            _config != null
                ? _buildConfigCard(_config!)
                : const Text('暂无配置信息'),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigCard(Map<String, dynamic> config) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '配置信息',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _buildConfigItem('播放域名', config['playDomain']),
            _buildConfigItem('短视频随机最大值', config['shortVideoRandomMax']),
            _buildConfigItem('短视频随机最小值', config['shortVideoRandomMin']),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigItem(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value?.toString() ?? 'N/A'),
        ],
      ),
    );
  }
}