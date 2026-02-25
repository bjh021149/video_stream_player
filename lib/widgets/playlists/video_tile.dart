// lib/widgets/playlists/video_tile.dart
import 'package:flutter/material.dart';
import 'package:video_stream_player/models/video_entity.dart';
import 'package:video_stream_player/widgets/thumbnail_widget.dart';
import 'package:video_stream_player/services/download_service.dart';
import 'package:animations/animations.dart';
import 'package:video_stream_player/widgets/playlists/playlist_provider.dart';
class VideoTile extends StatelessWidget {
  final VideoEntity video;
  final List<VideoSource> sources;
  final bool isCurrent;
  final bool isInCurrentPlaylist;
  final int index;
  final PlaylistViewMode viewMode;
  final String? selectedPlaylistId;
  final DownloadStatus downloadStatus;
  final double downloadProgress;
  final String? localPath;
  
  final VoidCallback onPlay;
  final VoidCallback? onDownload;
  final VoidCallback? onAddToPlaylist;
  final VoidCallback? onRemoveFromPlaylist;
  final Function(VideoEntity) onShowSourceDialog;

  const VideoTile({
    super.key,
    required this.video,
    required this.sources,
    required this.isCurrent,
    required this.isInCurrentPlaylist,
    required this.index,
    required this.viewMode,
    this.selectedPlaylistId,
    required this.downloadStatus,
    required this.downloadProgress,
    this.localPath,
    required this.onPlay,
    this.onDownload,
    this.onAddToPlaylist,
    this.onRemoveFromPlaylist,
    required this.onShowSourceDialog,
  });

  @override
  Widget build(BuildContext context) {
    return OpenContainer(
      closedColor: Colors.transparent,
      closedElevation: 0,
      openElevation: 8,
      transitionType: ContainerTransitionType.fadeThrough,
      transitionDuration: const Duration(milliseconds: 500),
      closedBuilder: (context, action) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: isCurrent 
                ? Colors.deepPurple.withValues(alpha: .15)
                : Colors.white.withValues(alpha: .03),
            borderRadius: BorderRadius.circular(16),
            border: isCurrent
                ? Border.all(color: Colors.deepPurple, width: 1)
                : Border.all(color: Colors.transparent),
          ),
          child: Column(
            children: [
              ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: ThumbnailWidget(
                    posterUrl: video.getPosterUrl(),
                    videoUrl: video.getPreferredSource()?.url ?? '',
                    videoId: video.videoId,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    placeholder: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade800,
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        if (localPath != null)
                          const Icon(Icons.offline_bolt, color: Colors.green, size: 24)
                        else if (isCurrent)
                          const Icon(Icons.play_arrow, color: Colors.deepPurple, size: 24)
                        else
                          const Icon(Icons.video_library, color: Colors.grey, size: 24),
                        if (downloadStatus == DownloadStatus.downloading)
                          CircularProgressIndicator(
                            value: downloadProgress,
                            strokeWidth: 2,
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.deepPurple),
                          ),
                      ],
                    ),
                  ),
                ),
                title: Text(
                  video.title,
                  style: TextStyle(
                    color: isCurrent ? Colors.deepPurple : Colors.white,
                    fontSize: 14,
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Row(
                  children: [
                    if (localPath != null)
                      _buildTag('已缓存', Colors.green),
                    _buildDuration(video.duration),
                    const SizedBox(width: 8),
                    _buildSourceCount(sources.length),
                    if (viewMode == PlaylistViewMode.all && !isInCurrentPlaylist && selectedPlaylistId != null)
                      _buildTag('未添加', Colors.blue),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (video.getCurrentSource()?.quality != null)
                      _buildQualityTag(video.getCurrentSource()!.quality!),
                    _buildDownloadButton(),
                    _buildPlayButton(),
                    _buildActionButton(),
                  ],
                ),
              ),
              if (downloadStatus == DownloadStatus.downloading)
                _buildProgressIndicator(),
            ],
          ),
        );
      },
      openBuilder: (context, action) {
        return onPlay as Widget; // 这里需要根据实际情况调整
      },
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 9,
        ),
      ),
    );
  }

  Widget _buildDuration(int seconds) {
    final duration = Duration(seconds: seconds);
    final minutes = duration.inMinutes;
    final remainingSeconds = duration.inSeconds.remainder(60);
    
    return Text(
      '$minutes:${remainingSeconds.toString().padLeft(2, '0')}',
      style: TextStyle(
        color: Colors.grey.shade500,
        fontSize: 11,
      ),
    );
  }

  Widget _buildSourceCount(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.deepPurple.withValues(alpha: .2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$count个源',
        style: const TextStyle(
          color: Colors.deepPurple,
          fontSize: 9,
        ),
      ),
    );
  }

  Widget _buildQualityTag(String quality) {
    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        quality,
        style: TextStyle(
          color: Colors.grey.shade400,
          fontSize: 9,
        ),
      ),
    );
  }

  Widget _buildDownloadButton() {
    if (localPath != null) {
      return IconButton(
        icon: const Icon(Icons.check_circle, color: Colors.green, size: 18),
        onPressed: onDownload,
        tooltip: '已缓存',
      );
    }

    switch (downloadStatus) {
      case DownloadStatus.downloading:
        return IconButton(
          icon: Stack(
            alignment: Alignment.center,
            children: [
              const Icon(Icons.pause_circle, color: Colors.orange, size: 18),
              Text(
                '${(downloadProgress * 100).toInt()}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          onPressed: onDownload,
          tooltip: '暂停下载',
        );
        
      case DownloadStatus.paused:
        return IconButton(
          icon: const Icon(Icons.play_circle, color: Colors.orange, size: 18),
          onPressed: onDownload,
          tooltip: '继续下载',
        );
        
      case DownloadStatus.failed:
        return IconButton(
          icon: const Icon(Icons.error, color: Colors.red, size: 18),
          onPressed: onDownload,
          tooltip: '下载失败，点击重试',
        );
        
      case DownloadStatus.notStarted:
      default:
        return IconButton(
          icon: const Icon(Icons.download, color: Colors.white, size: 18),
          onPressed: () => onShowSourceDialog(video),
          tooltip: '缓存视频',
        );
    }
  }

  Widget _buildPlayButton() {
    return IconButton(
      icon: const Icon(Icons.play_arrow, size: 20),
      color: Colors.deepPurple,
      onPressed: onPlay,
    );
  }

  Widget _buildActionButton() {
    if (viewMode == PlaylistViewMode.playlist) {
      return IconButton(
        icon: const Icon(Icons.delete_outline, size: 16),
        color: Colors.red.withValues(alpha: .7),
        onPressed: onRemoveFromPlaylist,
      );
    } else if (viewMode == PlaylistViewMode.all && selectedPlaylistId != null) {
      return IconButton(
        icon: Icon(
          isInCurrentPlaylist ? Icons.check_circle : Icons.playlist_add,
          size: 16,
          color: isInCurrentPlaylist ? Colors.green : Colors.blue,
        ),
        onPressed: isInCurrentPlaylist ? null : onAddToPlaylist,
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildProgressIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        children: [
          LinearProgressIndicator(
            value: downloadProgress,
            backgroundColor: Colors.grey.shade800,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.deepPurple),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                '${(downloadProgress * 100).toInt()}%',
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}