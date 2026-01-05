import 'package:flutter/material.dart';
import 'package:shunle/widgets/video_data.dart';
import 'package:shunle/widgets/category_video_item.dart';
import '../services/video_api_service.dart';

/// 分类列表页面
class CategoryListPage extends StatefulWidget {
  final TabsType category;

  const CategoryListPage({required this.category, Key? key});

  @override
  State<CategoryListPage> createState() => _CategoryListPageState();
}

class _CategoryListPageState extends State<CategoryListPage> {
  late Future<List<VideoData>> _videosFuture;
  List<VideoData> _allVideos = [];
  final ScrollController _scrollController = ScrollController();
  int _currentPage = 1;
  final int _pageSize = 10;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _videosFuture = _fetchVideos();
    // 添加滚动监听
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// 滚动监听回调
  void _onScroll() {
    if (!_hasMore || _isLoadingMore) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;

    // 当滚动到倒数第二个项目时加载下一页
    // 提前一些距离加载，提升用户体验
    if (currentScroll >= maxScroll - 200) {
      _loadMore();
    }
  }

  /// 加载更多数据
  void _loadMore() async {
    if (!_hasMore || _isLoadingMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      await _fetchVideos(page: _currentPage + 1);
    } catch (e) {
      debugPrint('加载更多数据失败: $e');
    } finally {
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  /// 获取分类视频数据
  Future<List<VideoData>> _fetchVideos({int page = 1}) async {
    try {
      // 使用 VideoApiService 直接获取数据
      final videos = await VideoApiService.fetchFromAllProviders(
        page: page.toString(),
        pagesize: _pageSize.toString(),
        videoType: widget.category.videoType,
        sortType: widget.category.sortType,
        collectionId: widget.category.collectionId,
        isjm: false,
      );

      // 检查是否还有更多数据
      setState(() {
        if (page == 1) {
          _allVideos = videos;
        } else {
          _allVideos.addAll(videos);
        }
        _hasMore = videos.length == _pageSize;
        _currentPage = page;
      });

      return videos;
    } catch (e) {
      debugPrint('获取分类视频失败: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category.title),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<VideoData>>(
        future: _videosFuture,
        builder: (context, snapshot) {
          // 加载中
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 加载失败
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    '加载失败: ${snapshot.error}',
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _videosFuture = _fetchVideos();
                      });
                    },
                    child: const Text('重试'),
                  ),
                ],
              ),
            );
          }

          // 数据为空
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.video_library_outlined,
                    size: 48,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '暂无${widget.category.title}相关视频',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          // 显示列表
          return ListView.builder(
            controller: _scrollController,
            itemCount: _allVideos.length + (_hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              // 如果是最后一个 item 并且还有更多数据，显示加载指示器
              if (index == _allVideos.length && _hasMore) {
                return _buildLoadingIndicator();
              }

              // 正常的视频项
              final video = _allVideos[index];
              return CategoryVideoItem(
                video: video,
                onImageLoaded: () {
                  // 图片加载完成后的回调
                  // debugPrint('图片加载完成: ${video.description}');
                },
              );
            },
          );
        },
      ),
    );
  }

  /// 构建加载更多指示器
  Widget _buildLoadingIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: _isLoadingMore
            ? const CircularProgressIndicator()
            : const Text(
                '没有更多了',
                style: TextStyle(color: Colors.grey),
              ),
      ),
    );
  }
}
