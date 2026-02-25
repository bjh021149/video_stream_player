// services/thumbnail_service.dart
import 'dart:io';
import 'package:video_stream_player/models/video_entity.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:video_player/video_player.dart';
import 'dart:async';
import 'package:video_thumbnail/video_thumbnail.dart';

class ThumbnailService {
  static final ThumbnailService _instance = ThumbnailService._internal();
  factory ThumbnailService() => _instance;
  ThumbnailService._internal();
  
  final Map<String, String> _thumbnailCache = {};
  final Map<String, VideoPlayerController> _controllerCache = {};

  /// 生成视频缩略图
  Future<String?> generateThumbnail(String videoUrl, String videoId) async {
    try {
      final thumbnailPath = await VideoThumbnail.thumbnailFile(
        video: videoUrl,
        thumbnailPath: (await getTemporaryDirectory()).path,
        imageFormat: ImageFormat.JPEG,
        quality: 75,
        maxWidth: 300, // 限制宽度，减小文件大小
        maxHeight: 300, // 限制高度，减小文件大小
      );
      
      if (thumbnailPath != null) {
        // 将生成的缩略图移动到持久化目录
        final localPath = await _saveThumbnailToPermanent(thumbnailPath, videoId);
        _thumbnailCache[videoId] = localPath;
        return localPath;
      }
    } catch (e) {
      print('生成缩略图失败: $e');
    }
    return null;
  }
  
  /// 将临时缩略图保存到持久化目录
  Future<String> _saveThumbnailToPermanent(String tempPath, String videoId) async {
    final permanentPath = await _getLocalThumbnailPath(videoId);
    final tempFile = File(tempPath);
    final permanentFile = File(permanentPath);
    
    if (await tempFile.exists()) {
      // 确保目录存在
      await permanentFile.parent.create(recursive: true);
      // 复制文件到持久化目录
      await tempFile.copy(permanentPath);
      // 删除临时文件
      await tempFile.delete();
    }
    
    return permanentPath;
  }
  
  /// 获取视频缩略图（如果不存在则生成）
  Future<String?> getThumbnail(String videoUrl, String videoId) async {
    // 检查缓存
    if (_thumbnailCache.containsKey(videoId)) {
      return _thumbnailCache[videoId];
    }
    
    // 检查本地是否已有生成的缩略图
    final localPath = await _getLocalThumbnailPath(videoId);
    if (await File(localPath).exists()) {
      _thumbnailCache[videoId] = localPath;
      return localPath;
    }
    
    // 如果没有本地文件，生成新的缩略图
    return await generateThumbnail(videoUrl, videoId);
  }
  
  /// 获取本地缩略图路径
  Future<String> _getLocalThumbnailPath(String videoId) async {
    final dir = await getApplicationDocumentsDirectory();
    final thumbDir = Directory(path.join(dir.path, 'thumbnails'));
    if (!await thumbDir.exists()) {
      await thumbDir.create(recursive: true);
    }
    return path.join(thumbDir.path, '$videoId.jpg');
  }
  
  /// 批量获取缩略图信息
  Future<void> preloadThumbnails(List<VideoEntity> videos) async {
    for (var video in videos) {
      if (video.getPosterUrl() != null) continue;
      
      final source = video.getPreferredSource();
      if (source != null) {
        // 在后台生成缩略图，不等待完成
        getThumbnail(source.url, video.videoId).then((_) {
          print('缩略图预加载完成: ${video.title}');
        });
      }
    }
  }
  
  /// 清理缩略图缓存
  void clearCache() {
    _thumbnailCache.clear();
  }
  
  /// 删除缩略图文件
  Future<void> deleteThumbnail(String videoId) async {
    final path = await _getLocalThumbnailPath(videoId);
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
    _thumbnailCache.remove(videoId);
  }
  
  /// 释放所有控制器
  void dispose() {
    for (var controller in _controllerCache.values) {
      controller.dispose();
    }
    _controllerCache.clear();
    _thumbnailCache.clear();
  }
}