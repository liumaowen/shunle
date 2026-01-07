/// 视频详情页面
library;

import 'package:flutter/material.dart';
import 'package:shunle/services/video_api_service.dart';
import 'package:shunle/widgets/video_data.dart';
import 'package:shunle/widgets/chewie_video_player.dart';

/// 视频详情页面
/// 显示视频播放器、视频描述、观看次数、标签和点赞收藏功能
class VideoDetailPage extends StatefulWidget {
  /// 视频ID
  final String videoId;

  /// 从视频列表页跳转时传入视频ID
  const VideoDetailPage({
    super.key,
    required this.videoId,
  });

  @override
  State<VideoDetailPage> createState() => _VideoDetailPageState();
}

class _VideoDetailPageState extends State<VideoDetailPage>
    with SingleTickerProviderStateMixin {
  late Future<VideoDetailData> _futureVideoDetail;
  late TabController _tabController;

  // 交互状态
  bool _isLiked = false;
  bool _isCollected = false;
  int _likeCount = 0;
  int _collectionCount = 0;

  // 视频播放控制器引用（暂时未使用）

  @override
  void initState() {
    super.initState();
    _futureVideoDetail = _fetchVideoDetail();
    _tabController = TabController(length: 1, vsync: this);
  }

  /// 获取视频详情数据
  Future<VideoDetailData> _fetchVideoDetail() async {
    try {
      return await VideoApiService.videoDetail(widget.videoId);
    } catch (e) {
      debugPrint('获取视频详情失败: $e');
      rethrow;
    }
  }

  /// 点赞按钮点击事件
  void _onLikeTap() {
    setState(() {
      _isLiked = !_isLiked;
      _likeCount = _isLiked ? _likeCount + 1 : _likeCount - 1;
    });
  }

  /// 收藏按钮点击事件
  void _onCollectTap() {
    setState(() {
      _isCollected = !_isCollected;
      _collectionCount = _isCollected ? _collectionCount + 1 : _collectionCount - 1;
    });
  }

  /// 分享按钮点击事件
  void _onShareTap() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('分享功能开发中...'),
        backgroundColor: Colors.grey,
      ),
    );
  }

  /// 格式化数字显示
  String _formatNumber(String number) {
    int num = int.tryParse(number) ?? 1;
    if (num >= 10000) {
      num = num * 8;
      final wan = num / 10000;
      return '${wan.toStringAsFixed(1)}万';
    }
    return num.toString();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          '视频详情',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<VideoDetailData>(
        future: _futureVideoDetail,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.white));
          }

          if (snapshot.hasError) {
            return _buildErrorWidget(snapshot.error.toString());
          }

          if (!snapshot.hasData) {
            return const Center(
              child: Text('没有找到视频详情', style: TextStyle(color: Colors.white)),
            );
          }

          final videoDetail = snapshot.data!;
          return _buildVideoDetail(videoDetail);
        },
      ),
    );
  }

  /// 构建错误显示页面
  Widget _buildErrorWidget(String errorMessage) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: Colors.white, size: 64),
          const SizedBox(height: 16),
          Text(
            '加载失败',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            errorMessage,
            style: TextStyle(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _futureVideoDetail = _fetchVideoDetail();
              });
            },
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }

  /// 构建视频详情页面
  Widget _buildVideoDetail(VideoDetailData videoDetail) {
    // 初始化点赞收藏数量
    _likeCount = int.tryParse(videoDetail.likes ?? '0') ?? 0;
    _collectionCount = int.tryParse(videoDetail.collectionCount ?? '0') ?? 0;

    return Column(
      children: [
        // 视频播放器部分
        Expanded(
          flex: 1,
          child: Container(
            color: Colors.black,
            child: ChewieVideoPlayer(
              video: videoDetail,
              shouldPlay: true,
              onVideoLoadFailed: () {
                // 视频加载失败的处理
                debugPrint('视频加载失败');
              },
            ),
          ),
        ),

        // 视频详情信息部分
        Expanded(
          flex: 2,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 视频描述
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      videoDetail.description.isNotEmpty
                          ? videoDetail.description
                          : '暂无描述',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  // 查看次数
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      children: [
                        const Icon(Icons.visibility, color: Colors.white70, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          '${_formatNumber(videoDetail.viewCount ?? '0')} 次观看',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 标签（自动换行）
                  if (videoDetail.tags != null && videoDetail.tags!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '标签',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _buildTags(videoDetail.tags!),
                          ),
                        ],
                      ),
                    ),

                  // 点赞收藏行
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // 点赞
                      _buildActionButton(
                        icon: _isLiked ? Icons.favorite : Icons.favorite_border,
                        color: _isLiked ? Colors.red : Colors.white,
                        label: _formatNumber(_likeCount.toString()),
                        onTap: _onLikeTap,
                      ),

                      // 收藏
                      _buildActionButton(
                        icon: _isCollected ? Icons.bookmark : Icons.bookmark_border,
                        color: _isCollected ? Colors.amber : Colors.white,
                        label: _formatNumber(_collectionCount.toString()),
                        onTap: _onCollectTap,
                      ),

                      // 分享
                      _buildActionButton(
                        icon: Icons.share,
                        color: Colors.white,
                        label: '分享',
                        onTap: _onShareTap,
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 构建标签列表
  List<Widget> _buildTags(List<String> tags) {

    return tags.map((tag) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Colors.grey[700]!,
            width: 1,
          ),
        ),
        child: Text(
          '#$tag',
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
      );
    }).toList();
  }

  /// 构建操作按钮（点赞、收藏、分享）
  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: 28,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}