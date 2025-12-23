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
  late final PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 短剧分类
    final dramaTabs = [
      TabsType(
        title: '热门短剧',
        id: 'drama_hot',
        videoType: 'drama',
        sortType: '',
        isDramaType: true,
      ),
    ];

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              itemCount: dramaTabs.length,
              itemBuilder: (context, index) {
                final tab = dramaTabs[index];
                return ChangeNotifierProvider(
                  create: (_) => VideoListProvider(),
                  child: ShortVideoList(tab: tab, showEpisodeControls: true),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
