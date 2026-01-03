import 'package:flutter/material.dart';
import 'package:persistent_bottom_nav_bar_v2/persistent_bottom_nav_bar_v2.dart';
import 'package:shunle/collection/collect_tabs.dart';
import 'package:shunle/widgets/video_data.dart';
import 'category_list_page.dart';

class Collection extends StatefulWidget {
  const Collection({Key? key});

  @override
  State<Collection> createState() => _CollectionState();
}

class _CollectionState extends State<Collection> {
  late final List<TabsType> _tabs;
  late final List<TabsType> _cates;

  @override
  void initState() {
    super.initState();

    _tabs = tabsData
        .map(
          (data) => TabsType(
            title: data['title'],
            id: data['id'],
            videoType: data['videoType'],
            sortType: data['sortType'],
            collectionId: data['collectionId'],
          ),
        )
        .toList();
    _cates = collectionCategories
        .map(
          (data) => TabsType(
            title: data['title'],
            id: data['id'],
            videoType: data['videoType'],
            sortType: data['sortType'],
            collectionId: data['collectionId'],
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0),
          child: CollectTabs(tabs: _tabs),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 2),
      child: Align(
        alignment: Alignment.topCenter,
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _cates.map((tab) {
            return ElevatedButton(
              onPressed: () {
                // 导航到分类列表页面
                pushScreen(
                  context,
                  screen: CategoryListPage(category: tab),
                  pageTransitionAnimation: PageTransitionAnimation.platform,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade800,
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                tab.title,
                style: const TextStyle(fontSize: 12, color: Colors.white),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
