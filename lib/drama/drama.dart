import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/video_list_provider.dart';
import '../widgets/short_video_list.dart';
import '../widgets/video_data.dart';

class Drams extends StatefulWidget {
  const Drams({super.key});

  @override
  State<Drams> createState() => _DramsState();
}

class _DramsState extends State<Drams> {

  /// 为每个 Tab 保持独立的 VideoListProvider 实例，防止切换时被销毁
  late final VideoListProvider _providers;
  // 短剧分类
  final dramaTabs = TabsType(
    title: '热门短剧',
    id: 'drama_hot',
    videoType: 'drama',
    sortType: '',
    isDramaType: true,
  );

  @override
  void initState() {
    super.initState();
    _providers = VideoListProvider();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false, // 只在顶部预留空间给状态栏
        child: _buildTabContent(),
      ),
    );
  }

  /// 短剧列表
  Widget _buildTabContent() {
    // 使用 ChangeNotifierProvider.value 传入预创建的 Provider 实例
    // 这样切换 Tab 时不会销毁旧 Provider，避免 "already disposed" 错误
    return ChangeNotifierProvider<VideoListProvider>.value(
      value: _providers,
      child: ShortVideoList(tab: dramaTabs),
    );
  }
}
