import 'package:flutter/material.dart';
import 'package:shunle/home/home_float_tabs.dart';
import 'package:shunle/widgets/video_data.dart';
import 'package:provider/provider.dart';
import '../providers/video_list_provider.dart';
import '../widgets/short_video_list.dart';
import '../widgets/video_data.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _currentTabIndex = 0;

  /// 为每个 Tab 保持独立的 VideoListProvider 实例，防止切换时被销毁
  late final VideoListProvider _providers;
  late final GlobalKey _videoListKey;

  @override
  void initState() {
    super.initState();
    _providers = VideoListProvider();
    _videoListKey = GlobalKey();
  }

  /// 暂停当前正在播放的视频（公开方法供 Tabs 调用）
  void pauseAllVideos() {
    debugPrint('🔥 Home.pauseAllVideos() 实例方法被调用');
    final state = _videoListKey.currentState;
    if (state != null) {
      debugPrint('✅ 找到 ShortVideoList 状态，调用 pauseCurrentVideo()');
      (state as dynamic).pauseCurrentVideo();
    } else {
      debugPrint('❌ 未找到 ShortVideoList 状态，key: $_videoListKey');
    }
  }

  /// 恢复当前视频的播放（公开方法供 Tabs 调用）
  void playCurrentVideo() {
    debugPrint('🔥 Home.playCurrentVideo() 实例方法被调用');
    final state = _videoListKey.currentState;
    if (state != null) {
      debugPrint('✅ 找到 ShortVideoList 状态，调用 playCurrentVideo()');
      (state as dynamic).playCurrentVideo();
    } else {
      debugPrint('❌ 未找到 ShortVideoList 状态，key: $_videoListKey');
    }
  }


  final TabsType tuijianTab = TabsType(
    title: '推荐',
    id: '0',
    videoType: '1',
    sortType: '7',
    collectionId: '',
  );
  final List<TabsType> _tabs = [
    TabsType(
      title: '推荐',
      id: '0',
      videoType: '1',
      sortType: '7',
      collectionId: '',
    ),
    // TabsType(
    //   title: '绿帽',
    //   id: '2',
    //   videoType: '',
    //   sortType: '2',
    //   collectionId: '25',
    // ),
    // TabsType(
    //   title: '萝莉',
    //   id: '3',
    //   videoType: '',
    //   sortType: '0',
    //   collectionId: '31',
    // ),
    // TabsType(
    //   title: '深喉',
    //   id: '4',
    //   videoType: '',
    //   sortType: '2',
    //   collectionId: '11',
    // ),
    // TabsType(
    //   title: '泄密',
    //   id: '5',
    //   videoType: '',
    //   sortType: '2',
    //   collectionId: '8',
    // ),
    // TabsType(
    //   title: '麻豆',
    //   id: '1',
    //   videoType: '',
    //   sortType: '0',
    //   collectionId: '152',
    // ),
  ];

  @override
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     body: HomeFloatTabs(
  //     key: _floatTabsKey,
  //     initialIndex: _currentTabIndex,
  //     tabs: _tabs,
  //     onTabChanged: (index) {
  //       setState(() {
  //         _currentTabIndex = index;
  //       });
  //     },
  //     ),
  //   );
  // }
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
      child: ShortVideoList(key: _videoListKey, tab: tuijianTab),
    );
  }
}
