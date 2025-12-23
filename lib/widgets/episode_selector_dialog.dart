/// 集数选择弹窗组件
library;

import 'package:flutter/material.dart';
import 'package:shunle/widgets/video_data.dart';

/// 集数选择弹窗
class EpisodeSelectorDialog extends StatelessWidget {
  /// 集数列表
  final List<EpisodeInfo> episodes;

  /// 当前集数
  final int currentEpisode;

  /// 集数选择回调
  final Function(EpisodeInfo) onEpisodeSelected;

  const EpisodeSelectorDialog({
    super.key,
    required this.episodes,
    required this.currentEpisode,
    required this.onEpisodeSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            // 标题栏
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.tv,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '选择集数',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            // 集数列表
            Expanded(
              child: episodes.isEmpty
                  ? const Center(
                      child: Text(
                        '暂无集数数据',
                        style: TextStyle(color: Colors.white70),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: episodes.length,
                      itemBuilder: (context, index) {
                        final episode = episodes[index];
                        return _buildEpisodeItem(episode, index);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建集数项
  Widget _buildEpisodeItem(EpisodeInfo episode, int index) {
    final isCurrent = episode.episodeNumber == currentEpisode;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
              onEpisodeSelected(episode);
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isCurrent
                  ? Colors.red.withOpacity(0.2)
                  : Colors.grey[800],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isCurrent ? Colors.red : Colors.transparent,
                width: 2,
              ),
            ),
            child: Row(
              children: [
                // 集数编号
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isCurrent ? Colors.red : Colors.grey[700],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      '${episode.episodeNumber}',
                      style: TextStyle(
                        color: isCurrent ? Colors.white : Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // 集数信息
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        episode.title.isNotEmpty ? episode.title : '第${episode.episodeNumber}集',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      if (episode.description != null &&
                          episode.description!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            episode.description!,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 显示付费提示
  void _showPayDialog() {
    // TODO: 实现付费逻辑
    // 这里可以显示付费提示弹窗
    print('Show pay dialog');
  }

  /// 格式化时长显示
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}