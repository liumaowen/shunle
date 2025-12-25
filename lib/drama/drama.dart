import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/video_list_provider.dart';
import '../widgets/short_video_list.dart';
import '../widgets/video_data.dart';

class Drams extends StatefulWidget {
  const Drams({super.key});

  @override
  State<Drams> createState() => _DramsState();

  /// 暂停当前正在播放的视频
  static void pauseAllVideos(BuildContext context) {
    context.findAncestorStateOfType<_DramsState>()?._pauseAllVideos();
  }

  /// 恢复当前视频的播放
  static void playCurrentVideo(BuildContext context) {
    context.findAncestorStateOfType<_DramsState>()?._playCurrentVideo();
  }
}

class _DramsState extends State<Drams> {

  /// 为每个 Tab 保持独立的 VideoListProvider 实例，防止切换时被销毁
  late final VideoListProvider _providers;
  late final GlobalKey _videoListKey;

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
    _videoListKey = GlobalKey();
  }

  /// 暂停当前正在播放的视频（公开方法供 Tabs 调用）
  void pauseAllVideos() {
    final state = _videoListKey.currentState;
    if (state != null) {
      (state as dynamic).pauseCurrentVideo();
    }
  }

  /// 恢复当前视频的播放（公开方法供 Tabs 调用）
  void playCurrentVideo() {
    final state = _videoListKey.currentState;
    if (state != null) {
      (state as dynamic).playCurrentVideo();
    }
  }

  /// 私有方法供 Drams 类的静态方法调用
  void _pauseAllVideos() {
    pauseAllVideos();
  }

  /// 私有方法供 Drams 类的静态方法调用
  void _playCurrentVideo() {
    playCurrentVideo();
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
      child: ShortVideoList(key: _videoListKey, tab: dramaTabs),
    );
  }
}
