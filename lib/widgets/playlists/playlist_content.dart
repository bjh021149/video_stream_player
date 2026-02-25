// lib/widgets/playlists/playlist_content.dart
import 'package:flutter/material.dart';
import 'package:video_stream_player/models/video_entity.dart';

import 'package:video_stream_player/services/download_service.dart';
import 'video_tile.dart';
import 'playlist_provider.dart';

class PlaylistContent extends StatelessWidget {
  final PlaylistProvider provider;
  final String? currentVideoUrl;
  final VoidCallback onPlayAll;
  final Function(VideoEntity) onPlayVideo;
  final Function(VideoEntity) onShowSourceDialog;
  final Function(VideoEntity) onAddToPlaylist;
  final Function(String) onRemoveFromPlaylist;

  const PlaylistContent({
    super.key,
    required this.provider,
    this.currentVideoUrl,
    required this.onPlayAll,
    required this.onPlayVideo,
    required this.onShowSourceDialog,
    required this.onAddToPlaylist,
    required this.onRemoveFromPlaylist,
  });

  @override
  Widget build(BuildContext context) {
    if (provider.selectedPlaylist == null && provider.viewMode == PlaylistViewMode.playlist) {
      return _buildEmptySelection();
    }
    
    List<VideoEntity> displayVideos;
    String title;
    String subtitle;
    
    if (provider.viewMode == PlaylistViewMode.playlist) {
      displayVideos = provider.selectedPlaylist!.videos.toList();
      title = provider.selectedPlaylist!.name;
      subtitle = '${displayVideos.length}个视频 · 总时长 ${provider.formatTotalDuration(provider.selectedPlaylist!)}';
    } else {
      displayVideos = provider.allVideos;
      title = '所有视频';
      final totalSeconds = displayVideos.fold<int>(
        0,
        (sum, video) => sum + video.duration,
      );
      final hours = Duration(seconds: totalSeconds).inHours;
      final minutes = Duration(seconds: totalSeconds).inMinutes.remainder(60);
      final totalDuration = hours > 0 ? '$hours小时$minutes分钟' : '$minutes分钟';
      subtitle = '${displayVideos.length}个视频 · 总时长 $totalDuration';
    }
    
    return Column(
      children: [
        _buildHeader(title, subtitle, displayVideos.isNotEmpty && provider.viewMode == PlaylistViewMode.playlist),
        Expanded(
          child: displayVideos.isEmpty
              ? _buildEmptyVideos()
              : _buildVideoList(displayVideos),
        ),
      ],
    );
  }

  Widget _buildHeader(String title, String subtitle, bool showPlayAll) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: .1),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          ),
          if (showPlayAll)
            IconButton(
              icon: const Icon(Icons.play_arrow, color: Colors.deepPurple),
              onPressed: onPlayAll,
              tooltip: '播放全部',
            ),
        ],
      ),
    );
  }

  Widget _buildEmptySelection() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.playlist_play,
            size: 48,
            color: Colors.grey.shade700,
          ),
          const SizedBox(height: 16),
          Text(
            '请选择一个播放列表',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyVideos() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.video_library,
            size: 48,
            color: Colors.grey.shade700,
          ),
          const SizedBox(height: 8),
          Text(
            provider.viewMode == PlaylistViewMode.playlist
                ? '播放列表为空'
                : '暂无视频',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 14,
            ),
          ),
          if (provider.viewMode == PlaylistViewMode.playlist)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: TextButton.icon(
                onPressed: provider.toggleViewMode,
                icon: const Icon(Icons.video_library),
                label: const Text('查看所有视频'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVideoList(List<VideoEntity> videos) {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: videos.length,
      itemBuilder: (context, index) {
        final video = videos[index];
        final sources = video.getAvailableSources();
        final isCurrent = currentVideoUrl != null && 
                          video.videoId == currentVideoUrl;
        final isInCurrentPlaylist = provider.selectedPlaylist != null && 
            provider.selectedPlaylist!.videos.any((v) => v.videoId == video.videoId);
        
        final downloadStatus = provider.downloadService.getDownloadStatus(video.videoId);
        final downloadProgress = provider.downloadService.getDownloadProgress(video.videoId);
        final localPath = provider.downloadService.getLocalPath(video.videoId);
        
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 300 + (index * 50)),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: child,
              ),
            );
          },
          child: VideoTile(
            video: video,
            sources: sources,
            isCurrent: isCurrent,
            isInCurrentPlaylist: isInCurrentPlaylist,
            index: index,
            viewMode: provider.viewMode,
            selectedPlaylistId: provider.selectedPlaylist?.playlistId,
            downloadStatus: downloadStatus,
            downloadProgress: downloadProgress,
            localPath: localPath,
            onPlay: () => onPlayVideo(video),
            onDownload: () => _handleDownloadAction(video, downloadStatus),
            onAddToPlaylist: () => onAddToPlaylist(video),
            onRemoveFromPlaylist: () => onRemoveFromPlaylist(video.videoId),
            onShowSourceDialog: onShowSourceDialog,
          ),
        );
      },
    );
  }

  void _handleDownloadAction(VideoEntity video, DownloadStatus status) {
    switch (status) {
      case DownloadStatus.downloading:
        provider.downloadService.pauseDownload(video.videoId);
        break;
      case DownloadStatus.paused:
        provider.downloadService.resumeDownload(video.videoId);
        break;
      case DownloadStatus.failed:
      case DownloadStatus.notStarted:
        onShowSourceDialog(video);
        break;
      default:
        break;
    }
  }
}