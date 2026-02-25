// lib/widgets/playlists/playlist_dialog.dart
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:video_stream_player/pages/new_player_page.dart';
import 'package:video_stream_player/models/video_entity.dart';
import 'package:video_stream_player/models/playlist_entity.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui';
import 'playlist_provider.dart';
import 'playlist_header.dart';
import 'playlist_empty_state.dart';
import 'playlist_sidebar.dart';
import 'playlist_content.dart';
import 'playlist_bottom_bar.dart';

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

class _PlaylistDialogState extends State<PlaylistDialog> with SingleTickerProviderStateMixin{
  late PlaylistProvider _provider;
  final TextEditingController _playlistNameController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _animation;

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
    
    _provider = PlaylistProvider();
    _provider.loadData(currentVideoUrl: widget.currentVideoUrl);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _playlistNameController.dispose();
    _provider.dispose();
    super.dispose();
  }

  void _showCreatePlaylistDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900.withValues(alpha: 0.95),
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
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
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
              style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_playlistNameController.text.isNotEmpty) {
                final newPlaylist = await _provider.createPlaylist(
                  _playlistNameController.text,
                );
                _playlistNameController.clear();
                Navigator.pop(context);
                
                // 选中新创建的播放列表
                _provider.selectPlaylist(newPlaylist);
                
                _showSnackBar('播放列表 "${newPlaylist.name}" 已创建', Colors.deepPurple);
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

  void _showEditPlaylistDialog(PlaylistEntity playlist) {
    _playlistNameController.text = playlist.name;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900.withValues(alpha: 0.95),
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
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
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
              style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (_playlistNameController.text.isNotEmpty) {
                _provider.updatePlaylistName(playlist, _playlistNameController.text);
                _playlistNameController.clear();
                Navigator.pop(context);
                _showSnackBar('播放列表名称已更新', Colors.deepPurple);
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

  void _showDeletePlaylistDialog(PlaylistEntity playlist) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900.withValues(alpha: 0.95),
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
              style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
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
              _provider.deletePlaylist(playlist.playlistId);
              Navigator.pop(context);
              _showSnackBar('播放列表 "${playlist.name}" 已删除', Colors.red);
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  void _showSourceSelectionDialog(VideoEntity video) {
    final sources = video.getAvailableSources();
    
    if (sources.isEmpty) {
      _showSnackBar('没有可用的视频源', Colors.orange);
      return;
    }
    
    if (sources.length == 1) {
      final source = sources.first;
      _provider.downloadService.startDownload(
        videoId: video.videoId,
        videoTitle: video.title,
        url: source.url,
        serverId: source.serverId,
        serverName: source.serverName,
      );
      return;
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900.withValues(alpha: 0.95),
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
                  '${source.quality ?? '自动'} · ${_provider.formatBitrate(source.bitrate)}',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                ),
                trailing: source.quality != null
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.deepPurple.withValues(alpha: 0.2),
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
                  _provider.downloadService.startDownload(
                    videoId: video.videoId,
                    videoTitle: video.title,
                    url: source.url,
                    serverId: source.serverId,
                    serverName: source.serverName,
                  );
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
              style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
            ),
          ),
        ],
      ),
    );
  }

  void _playVideo(VideoEntity video) {
    Navigator.pop(context);
    final source = _provider.getPreferredSource(video);
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
    if (_provider.selectedPlaylist != null && _provider.selectedPlaylist!.videos.isNotEmpty) {
      Navigator.pop(context);
      final firstVideo = _provider.selectedPlaylist!.videos.first;
      final source = _provider.getPreferredSource(firstVideo);
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

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        backgroundColor: color,
      ),
    );
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
                    child: ListenableBuilder(
                      listenable: _provider,
                      builder: (context, child) {
                        if (_provider.isLoading) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: Colors.deepPurple,
                            ),
                          );
                        }
                        
                        return Column(
                          children: [
                            PlaylistHeader(
                              provider: _provider,
                              onClose: () => Navigator.pop(context),
                            ),
                            Expanded(
                              child: _provider.playlists.isEmpty
                                  ? PlaylistEmptyState(
                                      onCreatePlaylist: _showCreatePlaylistDialog,
                                    )
                                  : Row(
                                      children: [
                                        if (!isMobile)
                                          PlaylistSidebar(
                                            provider: _provider,
                                            onCreatePlaylist: _showCreatePlaylistDialog,
                                            onEditPlaylist: _showEditPlaylistDialog,
                                            onDeletePlaylist: _showDeletePlaylistDialog,
                                            onSelectPlaylist: _provider.selectPlaylist,
                                          ),
                                        Expanded(
                                          child: PlaylistContent(
                                            provider: _provider,
                                            currentVideoUrl: widget.currentVideoUrl,
                                            onPlayAll: _playAll,
                                            onPlayVideo: _playVideo,
                                            onShowSourceDialog: _showSourceSelectionDialog,
                                            onAddToPlaylist: (video) {
                                              if (_provider.selectedPlaylist != null) {
                                                _provider.addVideoToPlaylist(
                                                  _provider.selectedPlaylist!.playlistId,
                                                  video,
                                                );
                                                _showSnackBar(
                                                  '已添加到 "${_provider.selectedPlaylist!.name}"',
                                                  Colors.green,
                                                );
                                              }
                                            },
                                            onRemoveFromPlaylist: (videoId) {
                                              if (_provider.selectedPlaylist != null) {
                                                _provider.removeVideoFromPlaylist(
                                                  _provider.selectedPlaylist!.playlistId,
                                                  videoId,
                                                );
                                                _showSnackBar(
                                                  '已从播放列表移除',
                                                  Colors.orange,
                                                );
                                              }
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                            PlaylistBottomBar(
                              provider: _provider,
                              onAddToPlaylist: (playlist) {
                                _provider.addCurrentToPlaylist(playlist);
                                _showSnackBar(
                                  '已添加到 "${playlist.name}"',
                                  Colors.green,
                                );
                              },
                            ),
                          ],
                        );
                      },
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
}