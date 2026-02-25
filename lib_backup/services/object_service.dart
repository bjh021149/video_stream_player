// services/objectbox_service.dart


import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../models/video_entity.dart';
import '../models/playlist_entity.dart';
import '../objectbox.g.dart'; // 自动生成的代码

class ObjectBoxService {
  late final Store store;
  late final Box<VideoEntity> videoBox;
  late final Box<PlaylistEntity> playlistBox;
  
  static ObjectBoxService? _instance;
  
  static Future<ObjectBoxService> getInstance() async {
    if (_instance == null) {
      _instance = await _create();
    }
    return _instance!;
  }
  
  static Future<ObjectBoxService> _create() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final store = await openStore(directory: path.join(docsDir.path, 'video-player'));
    return ObjectBoxService._(store);
  }
  
  ObjectBoxService._(this.store) {
    videoBox = store.box<VideoEntity>();
    playlistBox = store.box<PlaylistEntity>();
  }
  
  // ========== 视频管理 ==========
  
  /// 添加或更新视频
  VideoEntity putVideo(VideoEntity video) {
    final id = videoBox.put(video);
    return videoBox.get(id)!;
  }
  
  /// 批量添加视频
  void putVideos(List<VideoEntity> videos) {
    videoBox.putMany(videos);
  }
  
  /// 根据videoId获取视频
  VideoEntity? getVideoByVideoId(String videoId) {
    final query = videoBox.query(VideoEntity_.videoId.equals(videoId)).build();
    final result = query.findFirst();
    query.close();
    return result;
  }
  
  /// 获取所有视频
  List<VideoEntity> getAllVideos() {
    return videoBox.getAll();
  }
  
  /// 更新视频的当前服务器
  void updateCurrentServer(String videoId, String serverId) {
    final video = getVideoByVideoId(videoId);
    if (video != null) {
      video.currentServerId = serverId;
      videoBox.put(video);
    }
  }
  
  /// 添加视频源到视频
  void addVideoSource(String videoId, VideoSource source) {
    final video = getVideoByVideoId(videoId);
    if (video != null) {
      video.addSource(source);
      videoBox.put(video);
    }
  }
  
  /// 移除视频源
  void removeVideoSource(String videoId, String serverId) {
    final video = getVideoByVideoId(videoId);
    if (video != null) {
      video.removeSource(serverId);
      videoBox.put(video);
    }
  }
  
  // ========== 播放列表管理 ==========
  
  /// 创建播放列表
  PlaylistEntity createPlaylist(String name, {String? description}) {
    final playlist = PlaylistEntity(
      playlistId: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      description: description,
    );
    final id = playlistBox.put(playlist);
    return playlistBox.get(id)!;
  }
  
  /// 获取所有播放列表
  List<PlaylistEntity> getAllPlaylists() {
    return playlistBox.getAll();
  }
  
  /// 获取播放列表
  PlaylistEntity? getPlaylist(String playlistId) {
    final query = playlistBox.query(PlaylistEntity_.playlistId.equals(playlistId)).build();
    final result = query.findFirst();
    query.close();
    return result;
  }
  
  /// 更新播放列表
  void updatePlaylist(PlaylistEntity playlist) {
    playlist.updatedAt = DateTime.now();
    playlistBox.put(playlist);
  }
  
  /// 向播放列表添加视频
  void addVideoToPlaylist(String playlistId, VideoEntity video) {
    final playlist = getPlaylist(playlistId);
    
    if (playlist != null) {
      // 检查是否已存在
      bool exists = playlist.videos.any((v) => v.videoId == video.videoId);
      if (!exists) {
        playlist.videos.add(video);
        playlist.updatedAt = DateTime.now();
        playlistBox.put(playlist);
      }
    }
  }
  
  /// 从播放列表移除视频
  void removeVideoFromPlaylist(String playlistId, String videoId) {
    final playlist = getPlaylist(playlistId);
    
    if (playlist != null) {
      playlist.videos.removeWhere((v) => v.videoId == videoId);
      playlist.updatedAt = DateTime.now();
      playlistBox.put(playlist);
    }
  }
  
  /// 更新播放列表顺序
  void reorderPlaylist(String playlistId, int oldIndex, int newIndex) {
    final playlist = getPlaylist(playlistId);
    if (playlist != null) {
      final videos = playlist.videos.toList();
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final item = videos.removeAt(oldIndex);
      videos.insert(newIndex, item);
      
      playlist.videos.clear();
      playlist.videos.addAll(videos);
      playlist.updatedAt = DateTime.now();
      playlistBox.put(playlist);
    }
  }
  
  /// 更新当前播放索引
  void updateCurrentIndex(String playlistId, int index) {
    final playlist = getPlaylist(playlistId);
    if (playlist != null) {
      playlist.currentIndex = index;
      playlist.updatedAt = DateTime.now();
      playlistBox.put(playlist);
    }
  }
  
  /// 切换随机播放模式
  void toggleShuffle(String playlistId) {
    final playlist = getPlaylist(playlistId);
    if (playlist != null) {
      playlist.isShuffled = !playlist.isShuffled;
      playlist.updatedAt = DateTime.now();
      playlistBox.put(playlist);
    }
  }
  
  /// 切换循环模式
  void toggleRepeat(String playlistId) {
    final playlist = getPlaylist(playlistId);
    if (playlist != null) {
      playlist.isRepeating = !playlist.isRepeating;
      playlist.updatedAt = DateTime.now();
      playlistBox.put(playlist);
    }
  }
  
  /// 删除播放列表
  void deletePlaylist(String playlistId) {
    final playlist = getPlaylist(playlistId);
    if (playlist != null) {
      playlistBox.remove(playlist.id);
    }
  }
  
  // ========== 获取下一个/上一个视频 ==========
  
  /// 获取下一个视频
  VideoEntity? getNextVideo(String playlistId) {
    final playlist = getPlaylist(playlistId);
    if (playlist == null || playlist.videos.isEmpty) return null;
    
    if (playlist.isShuffled) {
      // 随机选择
      final random = DateTime.now().millisecondsSinceEpoch;
      final index = random % playlist.videos.length;
      playlist.currentIndex = index;
      playlistBox.put(playlist);
      return playlist.videos[index];
    } else {
      // 顺序播放
      int nextIndex = playlist.currentIndex + 1;
      if (nextIndex >= playlist.videos.length) {
        if (playlist.isRepeating) {
          nextIndex = 0; // 列表循环
        } else {
          return null; // 没有下一首
        }
      }
      playlist.currentIndex = nextIndex;
      playlistBox.put(playlist);
      return playlist.videos[nextIndex];
    }
  }
  
  /// 获取上一个视频
  VideoEntity? getPreviousVideo(String playlistId) {
    final playlist = getPlaylist(playlistId);
    if (playlist == null || playlist.videos.isEmpty) return null;
    
    if (playlist.isShuffled) {
      // 随机选择
      final random = DateTime.now().millisecondsSinceEpoch;
      final index = random % playlist.videos.length;
      playlist.currentIndex = index;
      playlistBox.put(playlist);
      return playlist.videos[index];
    } else {
      // 顺序播放
      int prevIndex = playlist.currentIndex - 1;
      if (prevIndex < 0) {
        if (playlist.isRepeating) {
          prevIndex = playlist.videos.length - 1; // 列表循环
        } else {
          return null; // 没有上一首
        }
      }
      playlist.currentIndex = prevIndex;
      playlistBox.put(playlist);
      return playlist.videos[prevIndex];
    }
  }
  
  // 在 ObjectBoxService 类中添加
/// 获取所有视频

  // ========== 初始化示例数据 ==========
  
// 在 objectbox_service.dart 的 initSampleData 方法中

Future<void> initSampleData() async {
  if (videoBox.isEmpty()) {
    // 创建示例视频（包含多个源和海报）
    final sampleVideos = [
      VideoEntity(
        videoId: '1',
        title: 'Big Buck Bunny',
        poster: 'https://peach.blender.org/wp-content/uploads/bbb-splash.png',
        sources: [
          VideoSource(
            serverId: 'main',
            serverName: '主服务器',
            url: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
            quality: '1080p',
            bitrate: 5000,
            poster: 'https://peach.blender.org/wp-content/uploads/bbb-splash.png',
          ),
          VideoSource(
            serverId: 'backup',
            serverName: '备用服务器',
            url: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
            quality: '720p',
            bitrate: 2500,
          ),
        ],
        duration: 596,
        subtitle: '开源动画电影',
        currentServerId: 'main',
      ),
      VideoEntity(
        videoId: '2',
        title: 'Elephant Dream',
        poster: 'https://download.blender.org/ED/ed_splash.png',
        sources: [
          VideoSource(
            serverId: 'main',
            serverName: '主服务器',
            url: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
            quality: '1080p',
            bitrate: 4800,
            poster: 'https://download.blender.org/ED/ed_splash.png',
          ),
        ],
        duration: 653,
        subtitle: '第一部开源电影',
        currentServerId: 'main',
      ),
      VideoEntity(
        videoId: '3',
        title: 'Sintel',
        poster: 'https://sintel.org/wp-content/uploads/2011/07/sintel-poster.jpg',
        sources: [
          VideoSource(
            serverId: 'main',
            serverName: '主服务器',
            url: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/Sintel.mp4',
            quality: '4K',
            bitrate: 15000,
            poster: 'https://sintel.org/wp-content/uploads/2011/07/sintel-poster.jpg',
          ),
          VideoSource(
            serverId: 'backup',
            serverName: '备用服务器',
            url: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/Sintel.mp4',
            quality: '1080p',
            bitrate: 6000,
          ),
        ],
        duration: 888,
        subtitle: 'Blender基金会出品',
        currentServerId: 'main',
      ),
    ];
    
    putVideos(sampleVideos);
    
    // 创建默认播放列表
    final defaultPlaylist = createPlaylist('默认播放列表');
    for (var video in sampleVideos) {
      addVideoToPlaylist(defaultPlaylist.playlistId, video);
    }
  }
}
}