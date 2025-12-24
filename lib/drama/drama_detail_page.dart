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
  late final VideoListProvider _dramaProvider;
  late int _currentEpisode;

  @override
  void initState() {
    super.initState();
    _currentEpisode = widget.initialEpisode;
    _dramaProvider = VideoListProvider();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('短剧详情'),),
      body: SafeArea(
        bottom: false, // 只在顶部预留空间给状态栏
        child: _buildTabContent(),
      ),
    );
  }

  /// 构建短剧 Tab
  TabsType _buildDramaTab() {
    return TabsType(
      title: '短剧详情',
      id: 'drama_${widget.dramaId}',
      videoType: 'dramadetail',
      sortType: 'detail',
      isDramaType: true,
    );
  }

    /// 短剧详情列表
  Widget _buildTabContent() {
    // 使用 ChangeNotifierProvider.value 传入预创建的 Provider 实例
    // 这样切换 Tab 时不会销毁旧 Provider，避免 "already disposed" 错误
    return ChangeNotifierProvider<VideoListProvider>.value(
      value: _dramaProvider,
      child: ShortVideoList(tab: _buildDramaTab(),dramaId: widget.dramaId,),
    );
  }
}
