import 'package:flutter/material.dart';
import 'package:shunle/home/home_float_tabs.dart';
import 'package:shunle/widgets/video_data.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();

  /// 暂停当前正在播放的视频
  static void pauseAllVideos(BuildContext context) {
    context.findAncestorStateOfType<_HomeState>()?._pauseAllVideos();
  }

  /// 恢复当前视频的播放
  static void playCurrentVideo(BuildContext context) {
    context.findAncestorStateOfType<_HomeState>()?._playCurrentVideo();
  }
}

class _HomeState extends State<Home> {
  int _currentTabIndex = 0;
  late final GlobalKey _floatTabsKey;

  @override
  void initState() {
    super.initState();
    _floatTabsKey = GlobalKey();
  }

  /// 暂停当前正在播放的视频（公开方法供 Tabs 调用）
  void pauseAllVideos() {
    final state = _floatTabsKey.currentState;
    if (state != null) {
      (state as dynamic).pauseAllVideos();
    }
  }

  /// 恢复当前视频的播放（公开方法供 Tabs 调用）
  void playCurrentVideo() {
    final state = _floatTabsKey.currentState;
    if (state != null) {
      (state as dynamic).resumeCurrentVideo();
    }
  }

  /// 私有方法供 Home 类的静态方法调用
  void _pauseAllVideos() {
    pauseAllVideos();
  }

  /// 私有方法供 Home 类的静态方法调用
  void _playCurrentVideo() {
    playCurrentVideo();
  }

  final List<TabsType> _tabs = [
    TabsType(
      title: '推荐',
      id: '0',
      videoType: '1',
      sortType: '7',
      collectionId: '',
    ),
    TabsType(
      title: '绿帽',
      id: '2',
      videoType: '',
      sortType: '2',
      collectionId: '25',
    ),
    TabsType(
      title: '萝莉',
      id: '3',
      videoType: '',
      sortType: '0',
      collectionId: '31',
    ),
    TabsType(
      title: '深喉',
      id: '4',
      videoType: '',
      sortType: '2',
      collectionId: '11',
    ),
    TabsType(
      title: '泄密',
      id: '5',
      videoType: '',
      sortType: '2',
      collectionId: '8',
    ),
    TabsType(
      title: '麻豆',
      id: '1',
      videoType: '',
      sortType: '0',
      collectionId: '152',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: HomeFloatTabs(
      key: _floatTabsKey,
      initialIndex: _currentTabIndex,
      tabs: _tabs,
      onTabChanged: (index) {
        setState(() {
          _currentTabIndex = index;
        });
      },
      ),
    );
  }
}
