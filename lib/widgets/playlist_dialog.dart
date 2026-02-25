// widgets/playlist_dialog.dart
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:video_stream_player/services/object_service.dart';
import 'package:video_stream_player/models/video_entity.dart';
import 'package:video_stream_player/models/playlist_entity.dart';
import 'package:video_stream_player/pages/new_player_page.dart';
import 'package:video_stream_player/services/download_service.dart';
import 'package:video_stream_player/widgets/thumbnail_widget.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:animations/animations.dart';
import 'dart:ui';

enum PlaylistViewMode {
  playlist,
  all,
}

class PlaylistDialog extends StatefulWidget {
  final String? currentVideoUrl;

  const PlaylistDialog({
    super.key,
    this.currentVideoUrl,
  });

  @override
  State<PlaylistDialog> createState() => _PlaylistDialogState();

  static Future<void> show({
    required BuildContext context,
    String? currentVideoUrl,
  }) {
    return showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(20),
        backgroundColor: Colors.transparent,
        child: PlaylistDialog(currentVideoUrl: currentVideoUrl),
      ),
    );
  }
}

class _PlaylistDialogState extends State<PlaylistDialog> with SingleTickerProviderStateMixin {
  late ObjectBoxService _objectBox;
  late DownloadService _downloadService;
  List<PlaylistEntity> _playlists = [];
  PlaylistEntity? _selectedPlaylist;
  bool _isLoading = true;
  final TextEditingController _playlistNameController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _animation;
  
  VideoEntity? _currentVideo;
  
  StreamSubscription<DownloadProgress>? _downloadSubscription;
  final Map<String, DownloadProgress> _downloadProgressMap = {};

  PlaylistViewMode _viewMode = PlaylistViewMode.playlist;
  List<VideoEntity> _allVideos = [];
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _animationController.forward();
    
    _downloadService = DownloadService();
    _initializePlaylists();
    
    _downloadSubscription = _downloadService.downloadProgress.listen((progress) {
      if (mounted) {
        setState(() {
          _downloadProgressMap[progress.videoId] = progress;
        });
      }
    });
    
    _downloadService.loadDownloadRecords();
  }
  
  Future<void> _initializePlaylists() async {
    _objectBox = await ObjectBoxService.getInstance();
    
    // 添加监听器，当数据变化时自动刷新
    _objectBox.addListener(_onDataChanged);
    
    if (widget.currentVideoUrl != null) {
      _currentVideo = _objectBox.getVideoByVideoId(widget.currentVideoUrl!);
    }
    
    _loadPlaylists();
  }
  
  /// 数据变化时的回调函数
  void _onDataChanged() {
    if (mounted) {
      _loadPlaylists();
    }
  }
  
// widgets/playlist_dialog.dart

  void _loadPlaylists() {
  // 保存当前选中的播放列表ID
  final selectedId = _selectedPlaylist?.playlistId;
  
  setState(() {
    _playlists = _objectBox.getAllPlaylists();
    _allVideos = _objectBox.getAllVideos();
    
    // 尝试恢复选中的播放列表
    if (selectedId != null) {
      try {
        _selectedPlaylist = _playlists.firstWhere(
          (p) => p.playlistId == selectedId,
        );
      } catch (e) {
        // 如果找不到原来的播放列表，选中第一个（如果有）
        _selectedPlaylist = _playlists.isNotEmpty ? _playlists.first : null;
      }
    } else if (_playlists.isNotEmpty && _selectedPlaylist == null) {
      _selectedPlaylist = _playlists.first;
    }
    
    _isLoading = false;
  });
}
  
  void _selectPlaylist(PlaylistEntity playlist) {
    setState(() {
      _selectedPlaylist = playlist;
    });
  }
  
  void _createNewPlaylist() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900.withValues(alpha:  0.95),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: const Text(
          '创建新播放列表',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: _playlistNameController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: '输入播放列表名称',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha:  0.3)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.white.withValues(alpha:  0.05),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _playlistNameController.clear();
            },
            child: Text(
              '取消',
              style: TextStyle(color: Colors.white.withValues(alpha:  0.7)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (_playlistNameController.text.isNotEmpty) {
                final newPlaylist = _objectBox.createPlaylist(
                  _playlistNameController.text,
                );
                _playlistNameController.clear();
                Navigator.pop(context);
                
                // 直接选中新创建的播放列表（不需要手动刷新，监听器会自动刷新）
                _selectedPlaylist = newPlaylist;
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('播放列表 "${newPlaylist.name}" 已创建'),
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: Colors.deepPurple,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: const Text('创建'),
          ),
        ],
      ),
    );
  }
  
  void _deletePlaylist(PlaylistEntity playlist) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900.withValues(alpha: .95),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: const Text(
          '删除播放列表',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          '确定要删除播放列表 "${playlist.name}" 吗？',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              '取消',
              style: TextStyle(color: Colors.white.withValues(alpha: .7)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            onPressed: () {
              _objectBox.deletePlaylist(playlist.playlistId);
              Navigator.pop(context);
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('播放列表 "${playlist.name}" 已删除'),
                  duration: const Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
  
  void _addCurrentToPlaylist(PlaylistEntity playlist) {
    if (_currentVideo != null) {
      bool exists = playlist.videos.any((v) => v.videoId == _currentVideo!.videoId);
      
      if (!exists) {
        _objectBox.addVideoToPlaylist(playlist.playlistId, _currentVideo!);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('已添加到 "${playlist.name}"'),
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('视频已在 "${playlist.name}" 中'),
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.orange,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请先播放一个视频'),
          duration: Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
  
  void _playVideo(VideoEntity video) {
    Navigator.pop(context);
    final source = video.getPreferredSource();
    if (source != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PlayerPage(videoUrl: source.url),
        ),
      );
    }
  }
  
  void _playAll() {
    if (_selectedPlaylist != null && _selectedPlaylist!.videos.isNotEmpty) {
      Navigator.pop(context);
      final firstVideo = _selectedPlaylist!.videos.first;
      final source = firstVideo.getPreferredSource();
      if (source != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlayerPage(videoUrl: source.url),
          ),
        );
      }
    }
  }
  
  void _editPlaylistName(PlaylistEntity playlist) {
    _playlistNameController.text = playlist.name;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900.withValues(alpha: .95),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: const Text(
          '修改播放列表名称',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: _playlistNameController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: '输入新名称',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: .3)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.white.withValues(alpha: .05),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _playlistNameController.clear();
            },
            child: Text(
              '取消',
              style: TextStyle(color: Colors.white.withValues(alpha: .7)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (_playlistNameController.text.isNotEmpty) {
                playlist.name = _playlistNameController.text;
                _objectBox.updatePlaylist(playlist);
                _playlistNameController.clear();
                Navigator.pop(context);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('播放列表名称已更新'),
                    duration: Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDownloadButton(VideoEntity video) {
    final status = _downloadService.getDownloadStatus(video.videoId);
    final progress = _downloadService.getDownloadProgress(video.videoId);
    final localPath = _downloadService.getLocalPath(video.videoId);
    
    if (localPath != null) {
      return IconButton(
        icon: const Icon(Icons.check_circle, color: Colors.green, size: 18),
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: Colors.grey.shade900.withValues(alpha: .95),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: const Text(
                '已缓存',
                style: TextStyle(color: Colors.white),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '视频已缓存到本地',
                    style: TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '路径: $localPath',
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    '关闭',
                    style: TextStyle(color: Colors.white.withValues(alpha: .7)),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    _downloadService.cancelDownload(video.videoId);
                    setState(() {});
                    Navigator.pop(context);
                  },
                  child: const Text('删除缓存', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          );
        },
        tooltip: '已缓存',
      );
    }
    
    switch (status) {
      case DownloadStatus.downloading:
        return IconButton(
          icon: Stack(
            alignment: Alignment.center,
            children: [
              const Icon(Icons.pause_circle, color: Colors.orange, size: 18),
              Text(
                '${(progress * 100).toInt()}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          onPressed: () {
            _downloadService.pauseDownload(video.videoId);
            setState(() {});
          },
          tooltip: '暂停下载',
        );
        
      case DownloadStatus.paused:
        return IconButton(
          icon: const Icon(Icons.play_circle, color: Colors.orange, size: 18),
          onPressed: () {
            final source = video.getPreferredSource();
            if (source != null) {
              _downloadService.resumeDownload(video.videoId);
            }
          },
          tooltip: '继续下载',
        );
        
      case DownloadStatus.failed:
        return IconButton(
          icon: const Icon(Icons.error, color: Colors.red, size: 18),
          onPressed: () {
            final source = video.getPreferredSource();
            if (source != null) {
              _downloadService.startDownload(
                videoId: video.videoId,
                videoTitle: video.title,
                url: source.url,
                serverId: source.serverId,
                serverName: source.serverName,
              );
            }
          },
          tooltip: '下载失败，点击重试',
        );
        
      case DownloadStatus.notStarted:
      default:
        return IconButton(
          icon: const Icon(Icons.download, color: Colors.white, size: 18),
          onPressed: () {
            _showSourceSelectionDialog(video);
          },
          tooltip: '缓存视频',
        );
    }
  }
  
  void _showSourceSelectionDialog(VideoEntity video) {
    final sources = video.getAvailableSources();
    
    if (sources.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('没有可用的视频源'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    
    if (sources.length == 1) {
      final source = sources.first;
      _downloadService.startDownload(
        videoId: video.videoId,
        videoTitle: video.title,
        url: source.url,
        serverId: source.serverId,
        serverName: source.serverName,
      );
      setState(() {});
      return;
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900.withValues(alpha: .95),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: const Text(
          '选择缓存源',
          style: TextStyle(color: Colors.white),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: sources.length,
            itemBuilder: (context, index) {
              final source = sources[index];
              return ListTile(
                title: Text(
                  source.serverName,
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  '${source.quality ?? '自动'} · ${_formatBitrate(source.bitrate)}',
                  style: TextStyle(color: Colors.white.withValues(alpha: .5)),
                ),
                trailing: source.quality != null
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.deepPurple.withValues(alpha: .2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          source.quality!,
                          style: const TextStyle(color: Colors.deepPurple),
                        ),
                      )
                    : null,
                onTap: () {
                  Navigator.pop(context);
                  _downloadService.startDownload(
                    videoId: video.videoId,
                    videoTitle: video.title,
                    url: source.url,
                    serverId: source.serverId,
                    serverName: source.serverName,
                  );
                  setState(() {});
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              '取消',
              style: TextStyle(color: Colors.white.withValues(alpha: .7)),
            ),
          ),
        ],
      ),
    );
  }
  
  String _formatBitrate(int bitrate) {
    if (bitrate <= 0) return '';
    if (bitrate < 1000) return '$bitrate Kbps';
    if (bitrate < 1000000) return '${(bitrate / 1000).toStringAsFixed(1)} Mbps';
    return '${(bitrate / 1000000).toStringAsFixed(1)} Gbps';
  }
  
  @override
  void dispose() {
    // 移除监听器
    _objectBox.removeListener(_onDataChanged);
    
    _animationController.dispose();
    _playlistNameController.dispose();
    _downloadSubscription?.cancel();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveBreakpoints.of(context).largerThan(TABLET);
    final isMobile = ResponsiveBreakpoints.of(context).isMobile;
    
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: isDesktop 
                  ? MediaQuery.of(context).size.width * 0.8
                  : MediaQuery.of(context).size.width * 0.95,
              height: isDesktop
                  ? MediaQuery.of(context).size.height * 0.85
                  : MediaQuery.of(context).size.height * 0.9,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .5),
                    blurRadius: 30,
                    spreadRadius: 5,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade900.withValues(alpha: .8),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: .1),
                      ),
                    ),
                    child: _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Colors.deepPurple,
                            ),
                          )
                        : Column(
                            children: [
                              _buildHeader(),
                              Expanded(
                                child: _playlists.isEmpty
                                    ? _buildEmptyState()
                                    : Row(
                                        children: [
                                          if (!isMobile) _buildPlaylistSidebar(),
                                          Expanded(
                                            child: _buildPlaylistContent(),
                                          ),
                                        ],
                                      ),
                              ),
                              if (_currentVideo != null) _buildBottomBar(),
                            ],
                          ),
                  ),
                ),
              ),
            ).animate().scale(
              begin: const Offset(0.9, 0.9),
              end: const Offset(1, 1),
              duration: 400.ms,
              curve: Curves.easeOutCubic,
            ).fadeIn(
              duration: 300.ms,
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildHeader() {
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
          Container(
            width: 4,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.deepPurple,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              '播放列表',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              _viewMode == PlaylistViewMode.playlist 
                  ? Icons.playlist_play 
                  : Icons.video_library,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _viewMode = _viewMode == PlaylistViewMode.playlist 
                    ? PlaylistViewMode.all 
                    : PlaylistViewMode.playlist;
              });
            },
            tooltip: _viewMode == PlaylistViewMode.playlist 
                ? '显示所有视频' 
                : '显示播放列表',
          ),
          if (_currentVideo != null)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: Colors.deepPurple.withValues(alpha: .2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.play_circle,
                    color: Colors.deepPurple,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '当前视频',
                    style: TextStyle(
                      color: Colors.deepPurple[300],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.deepPurple.withValues(alpha: .1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.playlist_play,
              size: 60,
              color: Colors.deepPurple,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '暂无播放列表',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '点击下方按钮创建第一个播放列表',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: .5),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _createNewPlaylist,
            icon: const Icon(Icons.add),
            label: const Text('创建播放列表'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPlaylistSidebar() {
    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: .3),
        border: Border(
          right: BorderSide(
            color: Colors.white.withValues(alpha: .1),
          ),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    '我的列表',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add, size: 20),
                  onPressed: _createNewPlaylist,
                  tooltip: '创建播放列表',
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _playlists.length,
              itemBuilder: (context, index) {
                final playlist = _playlists[index];
                final isSelected = _selectedPlaylist?.playlistId == playlist.playlistId;
                
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.deepPurple.withValues(alpha: .3) : null,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    dense: true,
                    leading: Stack(
                      children: [
                        if (playlist.videos.isNotEmpty)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: ThumbnailWidget(
                              posterUrl: playlist.videos.first.getPosterUrl(),
                              videoUrl: playlist.videos.first.getPreferredSource()?.url ?? '',
                              videoId: playlist.videos.first.videoId,
                              width: 32,
                              height: 32,
                              fit: BoxFit.cover,
                              placeholder: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade800,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.playlist_play,
                                  size: 16,
                                  color: isSelected ? Colors.deepPurple : Colors.grey,
                                ),
                              ),
                            ),
                          )
                        else
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade800,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.playlist_play,
                              size: 16,
                              color: isSelected ? Colors.deepPurple : Colors.grey,
                            ),
                          ),
                        if (isSelected)
                          const Positioned(
                            bottom: 0,
                            right: 0,
                            child: Icon(
                              Icons.check_circle,
                              color: Colors.deepPurple,
                              size: 12,
                            ),
                          ),
                      ],
                    ),
                    title: Text(
                      playlist.name,
                      style: TextStyle(
                        color: isSelected ? Colors.deepPurple : Colors.white,
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      '${playlist.videos.length}个视频',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 11,
                      ),
                    ),
                    trailing: PopupMenuButton(
                      icon: Icon(
                        Icons.more_vert,
                        size: 16,
                        color: isSelected ? Colors.deepPurple : Colors.grey,
                      ),
                      color: Colors.grey.shade900,
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          height: 32,
                          onTap: () => _editPlaylistName(playlist),
                          child: const Row(
                            children: [
                               Icon(Icons.edit, size: 16, color: Colors.white),
                               SizedBox(width: 8),
                              Text('重命名', style: TextStyle(color: Colors.white)),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          height: 32,
                          onTap: () => _deletePlaylist(playlist),
                          child: const Row(
                            children: [
                               Icon(Icons.delete, size: 16, color: Colors.red),
                               SizedBox(width: 8),
                               Text('删除', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    onTap: () => _selectPlaylist(playlist),
                  ),
                ).animate().fadeIn(
                  duration: 300.ms,
                  delay: (index * 50).ms,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPlaylistContent() {
    if (_selectedPlaylist == null && _viewMode == PlaylistViewMode.playlist) {
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
    
    List<VideoEntity> displayVideos;
    String title;
    String subtitle;
    
    if (_viewMode == PlaylistViewMode.playlist) {
      displayVideos = _selectedPlaylist!.videos.toList();
      title = _selectedPlaylist!.name;
      subtitle = '${displayVideos.length}个视频 · 总时长 ${_formatTotalDuration(_selectedPlaylist!)}';
    } else {
      displayVideos = _allVideos;
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
        Container(
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
              if (displayVideos.isNotEmpty && _viewMode == PlaylistViewMode.playlist)
                IconButton(
                  icon: const Icon(Icons.play_arrow, color: Colors.deepPurple),
                  onPressed: _playAll,
                  tooltip: '播放全部',
                ),
            ],
          ),
        ),
        Expanded(
          child: displayVideos.isEmpty
              ? Center(
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
                        _viewMode == PlaylistViewMode.playlist
                            ? '播放列表为空'
                            : '暂无视频',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 14,
                        ),
                      ),
                      if (_viewMode == PlaylistViewMode.playlist)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: TextButton.icon(
                            onPressed: () {
                              setState(() {
                                _viewMode = PlaylistViewMode.all;
                              });
                            },
                            icon: const Icon(Icons.video_library),
                            label: const Text('查看所有视频'),
                          ),
                        ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: displayVideos.length,
                  itemBuilder: (context, index) {
                    final video = displayVideos[index];
                    final sources = video.getAvailableSources();
                    final isCurrent = widget.currentVideoUrl != null && 
                                      video.videoId == widget.currentVideoUrl;
                    final isInCurrentPlaylist = _selectedPlaylist != null && 
                        _selectedPlaylist!.videos.any((v) => v.videoId == video.videoId);
                    
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
                      child: _buildVideoTile(
                        video, 
                        sources, 
                        isCurrent, 
                        isInCurrentPlaylist,
                        index,
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
  
  Widget _buildVideoTile(
    VideoEntity video,
    List<VideoSource> sources,
    bool isCurrent,
    bool isInCurrentPlaylist,
    int index,
  ) {
    final downloadStatus = _downloadService.getDownloadStatus(video.videoId);
    final downloadProgress = _downloadService.getDownloadProgress(video.videoId);
    final localPath = _downloadService.getLocalPath(video.videoId);
    
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
                      Container(
                        margin: const EdgeInsets.only(right: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: .2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          '已缓存',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 9,
                          ),
                        ),
                      ),
                    Text(
                      _formatDuration(video.duration),
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.withValues(alpha: .2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${sources.length}个源',
                        style: const TextStyle(
                          color: Colors.deepPurple,
                          fontSize: 9,
                        ),
                      ),
                    ),
                    if (_viewMode == PlaylistViewMode.all && !isInCurrentPlaylist && _selectedPlaylist != null)
                      Container(
                        margin: const EdgeInsets.only(left: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: .2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          '未添加',
                          style: TextStyle(
                            color: Colors.blue,
                            fontSize: 9,
                          ),
                        ),
                      ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (video.getCurrentSource()?.quality != null)
                      Container(
                        margin: const EdgeInsets.only(right: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade800,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          video.getCurrentSource()!.quality!,
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 9,
                          ),
                        ),
                      ),
                    _buildDownloadButton(video),
                    IconButton(
                      icon: const Icon(Icons.play_arrow, size: 20),
                      color: Colors.deepPurple,
                      onPressed: () => _playVideo(video),
                    ),
                    if (_viewMode == PlaylistViewMode.playlist)
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 16),
                        color: Colors.red.withValues(alpha: .7),
                        onPressed: () {
                          _objectBox.removeVideoFromPlaylist(
                            _selectedPlaylist!.playlistId,
                            video.videoId,
                          );
                          
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('已从播放列表移除'),
                              duration: Duration(seconds: 1),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      )
                    else if (_viewMode == PlaylistViewMode.all && _selectedPlaylist != null)
                      IconButton(
                        icon: Icon(
                          isInCurrentPlaylist 
                              ? Icons.check_circle 
                              : Icons.playlist_add,
                          size: 16,
                          color: isInCurrentPlaylist ? Colors.green : Colors.blue,
                        ),
                        onPressed: isInCurrentPlaylist ? null : () {
                          _objectBox.addVideoToPlaylist(
                            _selectedPlaylist!.playlistId,
                            video,
                          );
                          
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('已添加到 "${_selectedPlaylist!.name}"'),
                              duration: Duration(seconds: 1),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
              if (downloadStatus == DownloadStatus.downloading)
                Padding(
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
                ),
            ],
          ),
        );
      },
      openBuilder: (context, action) {
        return PlayerPage(videoUrl: video.getPreferredSource()?.url ?? '');
      },
    );
  }
  
  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: .1),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '当前: ${_currentVideo!.title}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          PopupMenuButton<PlaylistEntity>(
            icon: const Icon(Icons.playlist_add, color: Colors.deepPurple),
            tooltip: '添加到播放列表',
            color: Colors.grey.shade900,
            onSelected: (playlist) {
              _addCurrentToPlaylist(playlist);
            },
            itemBuilder: (context) {
              return _playlists.map((playlist) {
                return PopupMenuItem(
                  value: playlist,
                  child: Text(
                    playlist.name,
                    style: const TextStyle(color: Colors.white),
                  ),
                );
              }).toList();
            },
          ),
        ],
      ),
    );
  }
  
  String _formatDuration(int seconds) {
    final duration = Duration(seconds: seconds);
    final minutes = duration.inMinutes;
    final remainingSeconds = duration.inSeconds.remainder(60);
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }
  
  String _formatTotalDuration(PlaylistEntity playlist) {
    final totalSeconds = playlist.videos.fold<int>(
      0,
      (sum, video) => sum + video.duration,
    );
    
    final hours = Duration(seconds: totalSeconds).inHours;
    final minutes = Duration(seconds: totalSeconds).inMinutes.remainder(60);
    
    if (hours > 0) {
      return '$hours小时$minutes分钟';
    } else {
      return '$minutes分钟';
    }
  }
}