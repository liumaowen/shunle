import "package:flutter/material.dart";

class Test extends StatelessWidget {
  const Test({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: null,
          icon: Icon(Icons.menu),
          tooltip: 'nimeide',
        ),
        title: Text('Example title'),
        actions: [
          IconButton(onPressed: null, icon: Icon(Icons.search), tooltip: '搜索'),
          IconButton(
            onPressed: null,
            icon: Icon(Icons.sd_storage),
            tooltip: '存储',
          ),
        ],
      ),
      body: Container(
        margin: EdgeInsets.all(20.0),
        width:200,
        height:200,
        decoration: BoxDecoration(
          color:Colors.blue,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color:Colors.green,
              blurRadius: 5,
              offset: Offset(5,5)
            )
          ]
        ),
        padding: EdgeInsets.all(30.0),
        child: Center(
          child: Text('你好吗'),
        ),

      ),
      floatingActionButton: FloatingActionButton(
        onPressed: null,
        tooltip: '添加',
        child: Icon(Icons.add),
      ),
    );
  }
}

class Test2 extends StatefulWidget {
  @override
  State<Test2> createState() {
    return _Test2State();
  }
}

class _Test2State extends State<Test2> {
  int count = 0;

  @override
  void initState() {
    super.initState();
    debugPrint('initState阶段');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    debugPrint('didChangeDependencies阶段');
  }

  @override
  void didUpdateWidget(Test2 oldWidget) {
    super.didUpdateWidget(oldWidget);
    debugPrint('didUpdateWidget阶段');
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('build阶段');
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: null,
          icon: Icon(Icons.menu),
          tooltip: '菜单',
        ),
        title: Align(child: Text('我的测试')),
        // backgroundColor: Theme.of(context).colorScheme.primary,
        actions: [
          IconButton(onPressed: null, icon: Icon(Icons.search), tooltip: '搜索'),
        ],
      ),
      body: Container(
        margin: EdgeInsets.all(20.0),
        width:200,
        height:200,
        decoration: BoxDecoration(
          color:Colors.blue,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color:Colors.green,
              blurRadius: 5,
              offset: Offset(5,5)
            )
          ]
        ),
        padding: EdgeInsets.all(30.0),
        transform: Matrix4.rotationZ(0.05),
        child: Align(
          alignment: Alignment.center,
          child: Icon(
            Icons.star,
            size: 50.0,
            color: Colors.yellow,
           )
          ),

      ),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '首页'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: '设置'),
        ],
      ),
    );
  }
}
