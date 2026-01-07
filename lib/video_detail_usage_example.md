# 视频详情页使用示例

## 从视频列表跳转到详情页

在视频列表页面中，可以通过以下方式跳转到视频详情页：

### 1. 在 CategoryVideoItem 中

```dart
CategoryVideoItem(
  video: videoData,
  onToDetail: () {
    // 跳转到视频详情页
    Navigator.pushNamed(
      context,
      '/video_detail',
      arguments: videoData.id,
    ).then((_) {
      // 可以在这里添加返回后的逻辑，如刷新数据
    });
  },
)
```

### 2. 在 ShortVideoList 中

```dart
// 在 _buildNormalVideoItem 或 _buildDramaItem 方法中添加点击事件
GestureDetector(
  onTap: () {
    Navigator.pushNamed(
      context,
      '/video_detail',
      arguments: video.id,
    );
  },
  child: VideoPlayerWidget(...),
)
```

### 3. 使用 Navigator.push 直接跳转

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => VideoDetailPage(
      videoId: videoId,
    ),
  ),
);
```

## VideoDetailPage 主要功能

### 1. 自动调用 videoDetail API
```dart
// 在 initState 中自动调用 API
@override
void initState() {
  super.initState();
  _futureVideoDetail = VideoApiService.videoDetail(widget.videoId);
}
```

### 2. 视频播放器
- 使用 Chewie 提供完善的播放控制
- 支持暂停、播放、快进、全屏等功能
- 自动处理加载状态和错误状态

### 3. 页面布局
- 上部分：视频播放器（Expanded flex: 3）
- 下部分：视频信息区域（Expanded flex: 2）
  - 视频描述
  - 查看次数
  - 标签（自动换行）
  - 点赞收藏行

### 4. 交互功能
- 点赞：点击心形图标，数量会实时更新
- 收藏：点击书签图标，状态会切换
- 分享：点击分享图标（可扩展功能）

## 错误处理

页面包含完善的错误处理：
- 网络错误：显示错误信息和重试按钮
- 视频加载失败：显示占位符和错误信息
- API 调用失败：显示友好的错误提示

## 注意事项

1. 确保传入的视频 ID 有效
2. VideoDetailData 目前没有 category 字段，标签使用固定值
3. 点赞和收藏功能目前是本地状态，实际项目中需要调用 API
4. 视频播放器支持自动播放，但受平台限制可能需要用户交互

## 扩展建议

1. 可以添加评论功能
2. 可以添加相关视频推荐
3. 可以添加下载功能
4. 可以添加播放列表功能