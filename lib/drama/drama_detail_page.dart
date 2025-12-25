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
  late int _jishu;

  @override
  void initState() {
    super.initState();
    _currentEpisode = widget.initialEpisode;
    _dramaProvider = VideoListProvider();
    _jishu = _currentEpisode;
  }

  /// 处理集数变化
  void _handleEpisodeChange(int episodeNumber) {
    setState(() {
      _jishu = episodeNumber;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: SafeArea(
              bottom: false, // 只在顶部预留空间给状态栏
              child: _buildTabContent(),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(child: _buildTabBar()),
          ),
        ],
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
      child: ShortVideoList(
        tab: _buildDramaTab(),
        dramaId: widget.dramaId,
        onEpisodeChange: _handleEpisodeChange,
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      height: 50,
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.0), // 顶部半透明
            Colors.transparent, // 底部完全透明
          ],
        ),
      ),
      child: Row(
        children: [
          // 返回按钮 + 文字组合
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
            },
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  // 返回图标
                  SizedBox(
                    width: 36,
                    height: 36,
                    child: Center(
                      child: Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  // 返回文字
                  Text(
                    '第 $_jishu 集',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 2,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
