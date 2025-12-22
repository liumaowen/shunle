import 'package:flutter/material.dart';
import 'package:shunle/home/home_float_tabs.dart';
import 'package:shunle/widgets/video_data.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _currentTabIndex = 0;
  final List<TabsType> _tabs = [
    TabsType(title: '推荐', id: '0', videoType: '1', sortType: '7',collectionId: ''),
    TabsType(title: '绿帽', id: '2', videoType: '', sortType: '2',collectionId: '25'),
    TabsType(title: '萝莉', id: '3', videoType: '', sortType: '0',collectionId: '31'),
    TabsType(title: '深喉', id: '4', videoType: '', sortType: '2',collectionId: '11'),
    TabsType(title: '泄密', id: '5', videoType: '', sortType: '2',collectionId: '8'),
    TabsType(title: '麻豆', id: '1', videoType: '', sortType: '0',collectionId: '152'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: HomeFloatTabs(
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
