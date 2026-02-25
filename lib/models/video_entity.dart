// models/video_entity.dart
import 'package:objectbox/objectbox.dart';
import 'dart:convert';

/// 视频源信息
class VideoSource {
  final String serverId;      // 服务器标识
  final String serverName;    // 服务器显示名称
  final String url;           // 视频流URL
  final int bitrate;          // 码率
  final String? quality;      // 画质标签
  final bool isAvailable;     // 是否可用
  final String? poster;       // 海报图片URL（每个源可能有不同的海报）
  
  VideoSource({
    required this.serverId,
    required this.serverName,
    required this.url,
    this.bitrate = 0,
    this.quality,
    this.isAvailable = true,
    this.poster,
  });
  
  Map<String, dynamic> toMap() {
    return {
      'serverId': serverId,
      'serverName': serverName,
      'url': url,
      'bitrate': bitrate,
      'quality': quality,
      'isAvailable': isAvailable,
      'poster': poster,
    };
  }
  
  factory VideoSource.fromMap(Map<String, dynamic> map) {
    return VideoSource(
      serverId: map['serverId'],
      serverName: map['serverName'],
      url: map['url'],
      bitrate: map['bitrate'] ?? 0,
      quality: map['quality'],
      isAvailable: map['isAvailable'] ?? true,
      poster: map['poster'],
    );
  }
}

@Entity()
class VideoEntity {
  @Id()
  int id = 0;
  
  @Index()
  String videoId; // 唯一标识
  
  String title;
  String? poster;  // 海报图片URL（如果所有源共享同一海报）
  int duration; // 秒为单位
  String? subtitle;
  
  // 存储多个视频源（JSON格式）
  String sourcesJson = '[]';
  
  // 当前选中的服务器ID
  String? currentServerId;
  
  // 缩略图缓存路径
  String? thumbnailPath;
  
  @Property(type: PropertyType.date)
  DateTime createdAt;
  
  VideoEntity({
    required this.videoId,
    required this.title,
    List<VideoSource>? sources,
    this.poster,
    this.thumbnailPath,
    this.duration = 0,
    this.subtitle,
    this.currentServerId,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now() {
    if (sources != null) {
      setSources(sources);
    }
  }
  
  /// 获取所有视频源
  List<VideoSource> getSources() {
    try {
      if (sourcesJson.isEmpty) return [];
      final List<dynamic> list = List.from(jsonDecode(sourcesJson));
      return list.map((item) => VideoSource.fromMap(item)).toList();
    } catch (e) {
      print('解析视频源失败: $e');
      return [];
    }
  }
  
  /// 设置视频源
  void setSources(List<VideoSource> sources) {
    final list = sources.map((s) => s.toMap()).toList();
    sourcesJson = jsonEncode(list);
  }
  
  /// 添加视频源
  void addSource(VideoSource source) {
    final sources = getSources();
    sources.add(source);
    setSources(sources);
  }
  
  /// 移除视频源
  void removeSource(String serverId) {
    final sources = getSources();
    sources.removeWhere((s) => s.serverId == serverId);
    setSources(sources);
  }
  
  /// 获取当前选中的视频源
  VideoSource? getCurrentSource() {
    if (currentServerId == null) return null;
    
    final sources = getSources();
    try {
      return sources.firstWhere((s) => s.serverId == currentServerId);
    } catch (e) {
      return null;
    }
  }
  
  /// 获取可用的视频源
  List<VideoSource> getAvailableSources() {
    return getSources().where((s) => s.isAvailable).toList();
  }
  
  /// 获取首选视频源（第一个可用的）
  VideoSource? getPreferredSource() {
    final available = getAvailableSources();
    if (available.isEmpty) return null;
    
    // 如果有当前选中的且可用，返回当前选中的
    final current = getCurrentSource();
    if (current != null && current.isAvailable) {
      return current;
    }
    
    // 否则返回第一个可用的
    return available.first;
  }
  
  /// 获取要显示的海报URL
  String? getPosterUrl() {
    // 优先使用视频自己的海报
    if (poster != null) return poster;
    
    // 其次使用当前选中源的海报
    final current = getCurrentSource();
    if (current?.poster != null) return current!.poster;
    
    // 最后使用第一个可用源的海报
    final firstSource = getAvailableSources().firstOrNull;
    return firstSource?.poster;
  }
}