// widgets/playlist_dialog.dart
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:video_stream_player/services/object_service.dart';  // 修正导入路径
import 'package:video_stream_player/models/video_entity.dart';
import 'package:video_stream_player/models/playlist_entity.dart';
import 'package:video_stream_player/pages/player_page.dart';
import 'package:video_stream_player/services/download_service.dart';
import 'package:video_stream_player/widgets/thumbnail_widget.dart';

// 枚举定义在类外部是正确的
enum PlaylistViewMode {
  playlist,  // 显示当前选中播放列表中的视频
  all,       // 显示所有视频
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
  
  // 当前视频信息
  VideoEntity? _currentVideo;
  
  // 下载相关
  StreamSubscription<DownloadProgress>? _downloadSubscription;
  Map<String, DownloadProgress> _downloadProgressMap = {};

  // 视图模式 - 移到类内部
  PlaylistViewMode _viewMode = PlaylistViewMode.playlist;
  List<VideoEntity> _allVideos = [];
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
    
    _downloadService = DownloadService();
    _initializePlaylists();
    
    // 监听下载进度
    _downloadSubscription = _downloadService.downloadProgress.listen((progress) {
      if (mounted) {
        setState(() {
          _downloadProgressMap[progress.videoId] = progress;
        });
      }
    });
    
    // 加载已下载记录
    _downloadService.loadDownloadRecords();
  }
  
  Future<void> _initializePlaylists() async {
    _objectBox = await ObjectBoxService.getInstance();
    
    // 如果有当前视频URL，获取视频信息
    if (widget.currentVideoUrl != null) {
      _currentVideo = _objectBox.getVideoByVideoId(widget.currentVideoUrl!);
    }
    
    _loadPlaylists();
  }
  
  void _loadPlaylists() {
    setState(() {
      _playlists = _objectBox.getAllPlaylists();
      _allVideos = _objectBox.getAllVideos();
      if (_playlists.isNotEmpty && _selectedPlaylist == null) {
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
        title: const Text('创建新播放列表'),
        content: TextField(
          controller: _playlistNameController,
          decoration: const InputDecoration(
            hintText: '输入播放列表名称',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _playlistNameController.clear();
            },
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_playlistNameController.text.isNotEmpty) {
                final newPlaylist = _objectBox.createPlaylist(
                  _playlistNameController.text,
                );
                _loadPlaylists();
                _selectPlaylist(newPlaylist);
                _playlistNameController.clear();
                Navigator.pop(context);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('播放列表 "${newPlaylist.name}" 已创建'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
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
        title: const Text('删除播放列表'),
        content: Text('确定要删除播放列表 "${playlist.name}" 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () {
              _objectBox.deletePlaylist(playlist.playlistId);
              _loadPlaylists();
              Navigator.pop(context);
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('播放列表 "${playlist.name}" 已删除'),
                  duration: const Duration(seconds: 2),
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
      // 检查视频是否已在播放列表中
      bool exists = playlist.videos.any((v) => v.videoId == _currentVideo!.videoId);
      
      if (!exists) {
        _objectBox.addVideoToPlaylist(playlist.playlistId, _currentVideo!);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('已添加到 "${playlist.name}"'),
            duration: const Duration(seconds: 1),
          ),
        );
        
        // 刷新播放列表
        _loadPlaylists();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('视频已在 "${playlist.name}" 中'),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } else {
      // 如果没有当前视频，提示先播放视频
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请先播放一个视频'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }
  
  void _playVideo(VideoEntity video) {
    Navigator.pop(context); // 关闭弹窗
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
      Navigator.pop(context); // 关闭弹窗
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
        title: const Text('修改播放列表名称'),
        content: TextField(
          controller: _playlistNameController,
          decoration: const InputDecoration(
            hintText: '输入新名称',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _playlistNameController.clear();
            },
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_playlistNameController.text.isNotEmpty) {
                playlist.name = _playlistNameController.text;
                _objectBox.updatePlaylist(playlist);
                _loadPlaylists();
                _playlistNameController.clear();
                Navigator.pop(context);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('播放列表名称已更新'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }
  
  // 下载按钮构建方法
  Widget _buildDownloadButton(VideoEntity video) {
    final status = _downloadService.getDownloadStatus(video.videoId);
    final progress = _downloadService.getDownloadProgress(video.videoId);
    final localPath = _downloadService.getLocalPath(video.videoId);
    
    // 如果已下载完成，显示已缓存图标
    if (localPath != null) {
      return IconButton(
        icon: const Icon(Icons.check_circle, color: Colors.green, size: 18),
        onPressed: () {
          // 显示已下载信息
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('已缓存'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('视频已缓存到本地'),
                  const SizedBox(height: 8),
                  Text(
                    '路径: $localPath',
                    style: const TextStyle(fontSize: 10),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('关闭'),
                ),
                TextButton(
                  onPressed: () {
                    // 删除缓存
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
    
    // 根据下载状态显示不同按钮
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
            // 获取首选源进行下载
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
            // 重试下载
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
            // 显示源选择对话框
            _showSourceSelectionDialog(video);
          },
          tooltip: '缓存视频',
        );
    }
  }
  
  // 显示源选择对话框
  void _showSourceSelectionDialog(VideoEntity video) {
    final sources = video.getAvailableSources();
    
    if (sources.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('没有可用的视频源')),
      );
      return;
    }
    
    if (sources.length == 1) {
      // 只有一个源，直接下载
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
    
    // 多个源，显示选择对话框
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择缓存源'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: sources.length,
            itemBuilder: (context, index) {
              final source = sources[index];
              return ListTile(
                title: Text(source.serverName),
                subtitle: Text('${source.quality ?? '自动'} · ${_formatBitrate(source.bitrate)}'),
                trailing: source.quality != null
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.deepPurple.withOpacity(0.2),
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
            child: const Text('取消'),
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
    _animationController.dispose();
    _playlistNameController.dispose();
    _downloadSubscription?.cancel();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(16),
          ),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    // 标题栏
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
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
                          // 视图切换按钮
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
                          // 当前视频指示器
                          if (_currentVideo != null)
                            Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.deepPurple.withOpacity(0.2),
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
                    ),
                    
                    // 主要内容区
                    Expanded(
                      child: _playlists.isEmpty
                          ? _buildEmptyState()
                          : Row(
                              children: [
                                // 左侧播放列表导航
                                _buildPlaylistSidebar(),
                                
                                // 右侧播放列表内容
                                Expanded(
                                  child: _buildPlaylistContent(),
                                ),
                              ],
                            ),
                    ),
                    
                    // 底部快捷操作栏
                    if (_currentVideo != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: Colors.white.withOpacity(0.1),
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
                              icon: const Icon(Icons.playlist_add),
                              tooltip: '添加到播放列表',
                              onSelected: (playlist) {
                                _addCurrentToPlaylist(playlist);
                              },
                              itemBuilder: (context) {
                                return _playlists.map((playlist) {
                                  return PopupMenuItem(
                                    value: playlist,
                                    child: Text(playlist.name),
                                  );
                                }).toList();
                              },
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
        );
      },
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.playlist_play,
            size: 80,
            color: Colors.grey[600],
          ),
          const SizedBox(height: 16),
          Text(
            '暂无播放列表',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '点击右上角按钮创建第一个播放列表',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _createNewPlaylist,
            icon: const Icon(Icons.add),
            label: const Text('创建播放列表'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPlaylistSidebar() {
    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: Colors.grey[850],
        border: Border(
          right: BorderSide(
            color: Colors.white.withOpacity(0.1),
          ),
        ),
      ),
      child: Column(
        children: [
          // 播放列表标题和创建按钮
          Container(
            padding: const EdgeInsets.all(12),
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
          
          // 播放列表列表
          Expanded(
            child: ListView.builder(
              itemCount: _playlists.length,
              itemBuilder: (context, index) {
                final playlist = _playlists[index];
                final isSelected = _selectedPlaylist?.playlistId == playlist.playlistId;
                
                return Container(
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.deepPurple.withOpacity(0.3) : null,
                  ),
                  child: ListTile(
                    dense: true,
                    leading: Stack(
                      children: [
                        // 播放列表封面（如果有视频）
                        if (playlist.videos.isNotEmpty)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: ThumbnailWidget(
                              posterUrl: playlist.videos.first.getPosterUrl(),
                              videoUrl: playlist.videos.first.getPreferredSource()?.url ?? '',
                              videoId: playlist.videos.first.videoId,
                              width: 24,
                              height: 24,
                              fit: BoxFit.cover,
                              placeholder: Container(
                                width: 24,
                                height: 24,
                                color: Colors.grey[800],
                                child: Icon(
                                  Icons.playlist_play,
                                  size: 14,
                                  color: isSelected ? Colors.deepPurple : Colors.grey,
                                ),
                              ),
                            ),
                          )
                        else
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: Colors.grey[800],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Icon(
                              Icons.playlist_play,
                              size: 14,
                              color: isSelected ? Colors.deepPurple : Colors.grey,
                            ),
                          ),
                        
                        // 选中状态指示
                        if (isSelected)
                          const Positioned(
                            bottom: 0,
                            right: 0,
                            child: Icon(
                              Icons.check_circle,
                              color: Colors.deepPurple,
                              size: 8,
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
                        color: Colors.grey[500],
                        fontSize: 11,
                      ),
                    ),
                    trailing: PopupMenuButton(
                      icon: Icon(
                        Icons.more_vert,
                        size: 16,
                        color: isSelected ? Colors.deepPurple : Colors.grey,
                      ),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          height: 32,
                          onTap: () => _editPlaylistName(playlist),
                          child: const Row(
                            children: [
                              Icon(Icons.edit, size: 16),
                              SizedBox(width: 8),
                              Text('重命名', style: TextStyle(fontSize: 13)),
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
                              Text('删除', style: TextStyle(fontSize: 13, color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    onTap: () => _selectPlaylist(playlist),
                  ),
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
      return const Center(child: Text('请选择一个播放列表'));
    }
    
    // 根据视图模式决定显示的视频列表
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
        // 头部
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Colors.white.withOpacity(0.1),
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
                        color: Colors.grey[400],
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
        
        // 视频列表
        Expanded(
          child: displayVideos.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.video_library,
                        size: 48,
                        color: Colors.grey[700],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _viewMode == PlaylistViewMode.playlist
                            ? '播放列表为空'
                            : '暂无视频',
                        style: TextStyle(
                          color: Colors.grey[500],
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
                    
                    // 获取下载状态
                    final downloadStatus = _downloadService.getDownloadStatus(video.videoId);
                    final downloadProgress = _downloadService.getDownloadProgress(video.videoId);
                    final localPath = _downloadService.getLocalPath(video.videoId);
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: isCurrent ? Colors.deepPurple.withOpacity(0.2) : Colors.grey[850],
                        borderRadius: BorderRadius.circular(8),
                        border: isCurrent
                            ? Border.all(color: Colors.deepPurple, width: 1)
                            : null,
                      ),
                      child: Column(
                        children: [
                          ListTile(
                            dense: true,
                            leading: ThumbnailWidget(
                              posterUrl: video.getPosterUrl(),
                              videoUrl: video.getPreferredSource()?.url ?? '',
                              videoId: video.videoId,
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                              placeholder: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[800],
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  if (localPath != null)
                                    const Icon(Icons.offline_bolt, color: Colors.green, size: 20)
                                  else if (isCurrent)
                                    const Icon(Icons.play_arrow, color: Colors.deepPurple, size: 20)
                                  else
                                    const Icon(Icons.video_library, color: Colors.grey, size: 20),
                                  if (downloadStatus == DownloadStatus.downloading)
                                    CircularProgressIndicator(
                                      value: downloadProgress,
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
                                    ),
                                ],
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
                                      color: Colors.green.withOpacity(0.2),
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
                                    color: Colors.grey[500],
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
                                    color: Colors.deepPurple.withOpacity(0.2),
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
                                      color: Colors.blue.withOpacity(0.2),
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
                                // 画质标签
                                if (video.getCurrentSource()?.quality != null)
                                  Container(
                                    margin: const EdgeInsets.only(right: 4),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[800],
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      video.getCurrentSource()!.quality!,
                                      style: TextStyle(
                                        color: Colors.grey[400],
                                        fontSize: 9,
                                      ),
                                    ),
                                  ),
                                
                                // 下载按钮
                                _buildDownloadButton(video),
                                
                                // 播放按钮
                                IconButton(
                                  icon: const Icon(Icons.play_arrow, size: 18),
                                  color: Colors.white,
                                  onPressed: () => _playVideo(video),
                                ),
                                
                                // 根据视图模式显示不同按钮
                                if (_viewMode == PlaylistViewMode.playlist)
                                  // 在播放列表中显示删除按钮
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 16),
                                    color: Colors.red,
                                    onPressed: () {
                                      _objectBox.removeVideoFromPlaylist(
                                        _selectedPlaylist!.playlistId,
                                        video.videoId,
                                      );
                                      _loadPlaylists();
                                      
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('已从播放列表移除'),
                                          duration: Duration(seconds: 1),
                                        ),
                                      );
                                    },
                                  )
                                else if (_viewMode == PlaylistViewMode.all && _selectedPlaylist != null)
                                  // 在所有视频中显示添加到播放列表按钮
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
                                      _loadPlaylists();
                                      
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('已添加到 "${_selectedPlaylist!.name}"'),
                                          duration: Duration(seconds: 1),
                                        ),
                                      );
                                    },
                                  ),
                              ],
                            ),
                          ),
                          
                          // 下载进度条
                          if (downloadStatus == DownloadStatus.downloading)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              child: Column(
                                children: [
                                  LinearProgressIndicator(
                                    value: downloadProgress,
                                    backgroundColor: Colors.grey[800],
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Text(
                                        '${(downloadProgress * 100).toInt()}%',
                                        style: TextStyle(
                                          color: Colors.grey[400],
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
                ),
        ),
      ],
    );
  }
  
  String _formatDuration(int seconds) {
    final duration = Duration(seconds: seconds);
    final minutes = duration.inMinutes;
    final remainingSeconds = duration.inSeconds.remainder(60);
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }
  
  String _formatTotalDuration([PlaylistEntity? playlist]) {
    if (playlist != null) {
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
    return '0分钟';
  }
}