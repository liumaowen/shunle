/// 短剧详情页
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/drama_provider.dart';
import '../providers/video_list_provider.dart';
import '../widgets/short_video_list.dart';
import '../widgets/video_data.dart';
import '../widgets/episode_selector_dialog.dart';

/// 短剧详情页面
/// 显示短剧的所有集数，支持上下滑动播放
class DramaDetailPage extends StatefulWidget {
  /// 短剧ID
  final String dramaId;

  /// 初始播放集数
  final int initialEpisode;

  const DramaDetailPage({
    super.key,
    required this.dramaId,
    this.initialEpisode = 1,
  });

  @override
  State<DramaDetailPage> createState() => _DramaDetailPageState();
}

class _DramaDetailPageState extends State<DramaDetailPage> {
  late final DramaProvider _dramaProvider;
  late final VideoListProvider _videoListProvider;
  late int _currentEpisode;

  @override
  void initState() {
    super.initState();
    debugPrint('DramaDetailPage initState:${widget.dramaId}');
    _currentEpisode = widget.initialEpisode;
    _dramaProvider = DramaProvider();
    _videoListProvider = VideoListProvider();
    _loadDramaDetail();
  }

  /// 加载短剧详情
  Future<void> _loadDramaDetail() async {
    await _dramaProvider.loadDramaDetail(widget.dramaId);
    if (mounted) {
      setState(() {
        _currentEpisode = widget.initialEpisode;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('短剧详情'),),
      body: ChangeNotifierProvider.value(
        value: _dramaProvider,
        child: Consumer<DramaProvider>(
          builder: (context, dramaProvider, child) {
            // 创建短剧集数列表的 VideoListProvider
            return ChangeNotifierProvider.value(
              value: _videoListProvider,
              child: Consumer<VideoListProvider>(
                builder: (context, videoListProvider, child) {
                  // 当短剧数据加载完成后，设置集数列表到 VideoListProvider
                  if (dramaProvider.dramaEpisodes.isNotEmpty &&
                      videoListProvider.videos.isEmpty) {
                    // 使用公共方法设置视频列表
                    videoListProvider.setVideos(dramaProvider.dramaEpisodes);
                  }

                  return ShortVideoList(
                    tab: _buildDramaTab(),
                    showEpisodeControls: true,
                    onDramaTap: (drama) {
                      // 点击短剧时的处理，可以扩展为更多功能
                      debugPrint('Clicked on drama: ${drama.description}');
                    },
                    // 集数控制回调
                    onEpisodeChange: (episodeIndex) {
                      final episode = dramaProvider.playEpisode(episodeIndex);
                      // 更新 VideoListProvider 显示当前集数
                      // _videoListProvider._videos = [episode];
                      // _videoListProvider.notifyListeners();
                    },
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  /// 构建短剧 Tab
  TabsType _buildDramaTab() {
    return TabsType(
      title: '短剧详情',
      id: 'drama_${widget.dramaId}',
      videoType: 'drama',
      sortType: 'detail',
      isDramaType: true,
    );
  }
}

/// 短剧详情页面路由
class DramaDetailRoute {
  static const String routeName = '/drama/detail';

  /// 创建路由
  static Route createRoute({
    required String dramaId,
    int initialEpisode = 1,
  }) {
    return MaterialPageRoute(
      builder: (context) => DramaDetailPage(
        dramaId: dramaId,
        initialEpisode: initialEpisode,
      ),
    );
  }
}