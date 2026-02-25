// lib/widgets/playlists/playlist_provider.dart
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:video_stream_player/services/object_service.dart';
import 'package:video_stream_player/models/video_entity.dart';
import 'package:video_stream_player/models/playlist_entity.dart';
import 'package:video_stream_player/services/download_service.dart';

enum PlaylistViewMode {
  playlist,
  all,
}

class PlaylistProvider extends ChangeNotifier {
  late ObjectBoxService _objectBox;
  late DownloadService _downloadService;
  
  List<PlaylistEntity> _playlists = [];
  PlaylistEntity? _selectedPlaylist;
  bool _isLoading = true;
  VideoEntity? _currentVideo;
  PlaylistViewMode _viewMode = PlaylistViewMode.playlist;
  List<VideoEntity> _allVideos = [];
  
  StreamSubscription<DownloadProgress>? _downloadSubscription;
  final Map<String, DownloadProgress> _downloadProgressMap = {};
  
  // Getters
  List<PlaylistEntity> get playlists => _playlists;
  PlaylistEntity? get selectedPlaylist => _selectedPlaylist;
  bool get isLoading => _isLoading;
  VideoEntity? get currentVideo => _currentVideo;
  PlaylistViewMode get viewMode => _viewMode;
  List<VideoEntity> get allVideos => _allVideos;
  Map<String, DownloadProgress> get downloadProgressMap => _downloadProgressMap;
  
  // 下载服务 getter
  DownloadService get downloadService => _downloadService;
  
  PlaylistProvider() {
    _downloadService = DownloadService();
    _initialize();
    
    _downloadSubscription = _downloadService.downloadProgress.listen((progress) {
      _downloadProgressMap[progress.videoId] = progress;
      notifyListeners();
    });
    
    _downloadService.loadDownloadRecords();
  }
  
  Future<void> _initialize() async {
    _objectBox = await ObjectBoxService.getInstance();
    _objectBox.addListener(_onDataChanged);
    await loadData();
  }
  
  void _onDataChanged() {
    loadData();
  }
  
  Future<void> loadData({String? currentVideoUrl}) async {
    if (currentVideoUrl != null) {
      _currentVideo = _objectBox.getVideoByVideoId(currentVideoUrl);
    }
    
    // 保存当前选中的播放列表ID
    final selectedId = _selectedPlaylist?.playlistId;
    
    _playlists = _objectBox.getAllPlaylists();
    _allVideos = _objectBox.getAllVideos();
    
    // 尝试恢复选中的播放列表
    if (selectedId != null) {
      final matchingPlaylists = _playlists.where((p) => p.playlistId == selectedId).toList();
      if (matchingPlaylists.isNotEmpty) {
        _selectedPlaylist = matchingPlaylists.first;
      } else {
        _selectedPlaylist = _playlists.isNotEmpty ? _playlists.first : null;
      }
    } else if (_playlists.isNotEmpty && _selectedPlaylist == null) {
      _selectedPlaylist = _playlists.first;
    }
    
    _isLoading = false;
    notifyListeners();
  }
  
  void setCurrentVideo(String? videoUrl) {
    if (videoUrl != null) {
      _currentVideo = _objectBox.getVideoByVideoId(videoUrl);
      notifyListeners();
    }
  }
  
  void selectPlaylist(PlaylistEntity playlist) {
    _selectedPlaylist = playlist;
    notifyListeners();
  }
  
  void toggleViewMode() {
    _viewMode = _viewMode == PlaylistViewMode.playlist 
        ? PlaylistViewMode.all 
        : PlaylistViewMode.playlist;
    notifyListeners();
  }
  
  Future<PlaylistEntity> createPlaylist(String name) async {
    final newPlaylist = _objectBox.createPlaylist(name);
    // 不需要手动刷新，监听器会处理
    return newPlaylist;
  }
  
  void deletePlaylist(String playlistId) {
    _objectBox.deletePlaylist(playlistId);
  }
  
  void updatePlaylistName(PlaylistEntity playlist, String newName) {
    playlist.name = newName;
    _objectBox.updatePlaylist(playlist);
  }
  
  void addCurrentToPlaylist(PlaylistEntity playlist) {
    if (_currentVideo != null) {
      _objectBox.addVideoToPlaylist(playlist.playlistId, _currentVideo!);
    }
  }
  
  void addVideoToPlaylist(String playlistId, VideoEntity video) {
    _objectBox.addVideoToPlaylist(playlistId, video);
  }
  
  void removeVideoFromPlaylist(String playlistId, String videoId) {
    _objectBox.removeVideoFromPlaylist(playlistId, videoId);
  }
  
  bool isVideoInPlaylist(String playlistId, String videoId) {
    final playlist = _objectBox.getPlaylist(playlistId);
    return playlist?.videos.any((v) => v.videoId == videoId) ?? false;
  }
  
  VideoSource? getPreferredSource(VideoEntity video) {
    return video.getPreferredSource();
  }
  
  String formatDuration(int seconds) {
    final duration = Duration(seconds: seconds);
    final minutes = duration.inMinutes;
    final remainingSeconds = duration.inSeconds.remainder(60);
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }
  
  String formatTotalDuration(PlaylistEntity playlist) {
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
  
  String formatBitrate(int bitrate) {
    if (bitrate <= 0) return '';
    if (bitrate < 1000) return '$bitrate Kbps';
    if (bitrate < 1000000) return '${(bitrate / 1000).toStringAsFixed(1)} Mbps';
    return '${(bitrate / 1000000).toStringAsFixed(1)} Gbps';
  }
  
  @override
  void dispose() {
    _objectBox.removeListener(_onDataChanged);
    _downloadSubscription?.cancel();
    super.dispose();
  }
}