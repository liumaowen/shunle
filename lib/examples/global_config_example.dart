import 'package:flutter/material.dart';
import 'package:shunle/providers/global_config.dart';

/// GlobalConfig 静态变量使用示例

class GlobalConfigExample extends StatelessWidget {
  const GlobalConfigExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('GlobalConfig 静态变量示例')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 示例 1: 读取配置
          Card(
            child: ListTile(
              title: const Text('示例 1: 读取配置'),
              subtitle: const Text('直接使用静态变量'),
              trailing: Text(
                '域名: ${GlobalConfig.playDomain}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 示例 2: 读取其他配置
          Card(
            child: ListTile(
              title: const Text('示例 2: 读取所有配置'),
              subtitle: const Text('使用便捷的静态 getter'),
              trailing: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('随机数范围: ${GlobalConfig.shortVideoRandomMin}-${GlobalConfig.shortVideoRandomMax}'),
                  Text('已初始化: ${GlobalConfig.initialized ? "是" : "否"}'),
                  Text('域名: ${GlobalConfig.playDomain}'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 示例 3: 初始化配置
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('示例 3: 初始化配置', style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      GlobalConfig.initialize(
                        Mgtvconfig(
                          shortVideoRandomMax: 500,
                          playDomain: 'https://updated.example.com',
                          initialized: true,
                        ),
                      );
                      // 显示提示
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('配置已更新！')),
                      );
                      debugPrint('配置已更新！: ${GlobalConfig.playDomain}');
                    },
                    child: const Text('初始化新配置'),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 示例 4: 在其他页面中使用
          Card(
            child: ListTile(
              title: const Text('示例 4: 在任何地方使用'),
              subtitle: const Text('静态变量可以在任何地方访问'),
              trailing: const Icon(Icons.share),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const _OtherPageExample(),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // 示例 5: 重置配置
          Card(
            child: ListTile(
              title: const Text('示例 5: 重置配置'),
              subtitle: const Text('重置为默认值'),
              trailing: const Icon(Icons.refresh),
              onTap: () {
                GlobalConfig.reset();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('配置已重置！')),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// 其他页面示例
class _OtherPageExample extends StatelessWidget {
  const _OtherPageExample();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('其他页面示例')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '这个页面也能访问相同配置:\n${GlobalConfig.playDomain}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('返回'),
            ),
          ],
        ),
      ),
    );
  }
}

/// 使用总结：

/// 1. 基本读取：
/// ```dart
/// final domain = GlobalConfig.playDomain;
/// final max = GlobalConfig.shortVideoRandomMax;
/// ```

/// 2. 获取完整配置：
/// ```dart
/// final config = GlobalConfig.instance;
/// ```

/// 3. 初始化配置：
/// ```dart
/// GlobalConfig.initialize(newConfig);
/// ```

/// 4. 重置配置：
/// ```dart
/// GlobalConfig.reset();
/// ```

/// 5. 在任何地方使用：
/// 静态变量可以在任何地方直接访问，不需要 Provider 上下文