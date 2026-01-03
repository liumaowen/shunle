import 'package:flutter/material.dart';
import 'package:shunle/widgets/video_data.dart';
import 'package:shunle/widgets/category_video_item.dart';
import '../services/video_api_service.dart';

/// 分类列表页面
class CategoryListPage extends StatefulWidget {
  final TabsType category;

  const CategoryListPage({
    required this.category,
    Key? key,
  }) : super(key: key);

  @override
  State<CategoryListPage> createState() => _CategoryListPageState();
}

class _CategoryListPageState extends State<CategoryListPage> {
  late Future<List<VideoData>> _videosFuture;

  @override
  void initState() {
    super.initState();
    _videosFuture = _fetchVideos();
  }

  /// 获取分类视频数据
  Future<List<VideoData>> _fetchVideos() async {
    try {
      // 使用 VideoApiService 直接获取数据
      return await VideoApiService.fetchFromAllProviders(
        page: '',
        pagesize: '20',
        videoType: widget.category.videoType,
        sortType: widget.category.sortType,
        collectionId: widget.category.collectionId,
      );
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
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // 加载失败
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Colors.grey,
                  ),
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
          final videos = snapshot.data!;
          return ListView.builder(
            itemCount: videos.length,
            itemBuilder: (context, index) {
              final video = videos[index];
              return CategoryVideoItem(video: video);
            },
          );
        },
      ),
    );
  }
}