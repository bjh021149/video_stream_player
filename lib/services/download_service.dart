// services/download_service.dart
import 'dart:io';
//import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'dart:async';
import 'dart:convert';
//import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

enum DownloadStatus {
  notStarted,
  downloading,
  paused,
  completed,
  failed,
}

class DownloadTask {
  final String videoId;
  final String videoTitle;
  final String url;
  final String serverId;
  final String serverName;
  DownloadStatus status;
  double progress;
  String? localPath;
  int totalBytes;
  int downloadedBytes;
  CancelToken? cancelToken;
  StreamController<DownloadProgress>? progressController;
  
  DownloadTask({
    required this.videoId,
    required this.videoTitle,
    required this.url,
    required this.serverId,
    required this.serverName,
    this.status = DownloadStatus.notStarted,
    this.progress = 0.0,
    this.localPath,
    this.totalBytes = 0,
    this.downloadedBytes = 0,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'videoId': videoId,
      'videoTitle': videoTitle,
      'url': url,
      'serverId': serverId,
      'serverName': serverName,
      'status': status.index,
      'progress': progress,
      'localPath': localPath,
      'totalBytes': totalBytes,
      'downloadedBytes': downloadedBytes,
    };
  }
  
  factory DownloadTask.fromJson(Map<String, dynamic> json) {
    return DownloadTask(
      videoId: json['videoId'],
      videoTitle: json['videoTitle'],
      url: json['url'],
      serverId: json['serverId'],
      serverName: json['serverName'],
      status: DownloadStatus.values[json['status']],
      progress: json['progress']?.toDouble() ?? 0.0,
      localPath: json['localPath'],
      totalBytes: json['totalBytes'] ?? 0,
      downloadedBytes: json['downloadedBytes'] ?? 0,
    );
  }
}

class DownloadProgress {
  final String videoId;
  final double progress;
  final int downloadedBytes;
  final int totalBytes;
  final DownloadStatus status;
  
  DownloadProgress({
    required this.videoId,
    required this.progress,
    required this.downloadedBytes,
    required this.totalBytes,
    required this.status,
  });
}

class CancelToken {
  bool isCancelled = false;
  
  void cancel() {
    isCancelled = true;
  }
}

class DownloadService {
  static final DownloadService _instance = DownloadService._internal();
  factory DownloadService() => _instance;
  DownloadService._internal();
  
  final Map<String, DownloadTask> _downloadTasks = {};
  final _downloadProgressController = StreamController<DownloadProgress>.broadcast();
  
  Stream<DownloadProgress> get downloadProgress => _downloadProgressController.stream;
  
  List<DownloadTask> get allTasks => _downloadTasks.values.toList();
  
  Future<String> _getDownloadDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    final downloadDir = Directory(path.join(directory.path, 'downloads'));
    if (!await downloadDir.exists()) {
      await downloadDir.create(recursive: true);
    }
    return downloadDir.path;
  }
  
  String _getSafeFileName(String title, String url) {
    // 从URL获取扩展名
    final extension = path.extension(url.split('?')[0]);
    final safeExtension = extension.isNotEmpty ? extension : '.mp4';
    
    // 清理标题中的非法字符
    String safeTitle = title.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
    return '$safeTitle$safeExtension';
  }
  
  Future<void> startDownload({
    required String videoId,
    required String videoTitle,
    required String url,
    required String serverId,
    required String serverName,
  }) async {
    // 检查是否已在下载
    if (_downloadTasks.containsKey(videoId)) {
      final task = _downloadTasks[videoId]!;
      if (task.status == DownloadStatus.downloading) {
        print('视频已在下载中');
        return;
      } else if (task.status == DownloadStatus.completed) {
        print('视频已下载完成');
        return;
      }
    }
    
    // 创建下载任务
    final task = DownloadTask(
      videoId: videoId,
      videoTitle: videoTitle,
      url: url,
      serverId: serverId,
      serverName: serverName,
      status: DownloadStatus.downloading,
    );
    
    task.cancelToken = CancelToken();
    task.progressController = StreamController<DownloadProgress>();
    
    _downloadTasks[videoId] = task;
    
    try {
      final downloadDir = await _getDownloadDirectory();
      final fileName = _getSafeFileName(videoTitle, url);
      final filePath = path.join(downloadDir, fileName);
      
      // 发起HTTP请求
      final request = http.Request('GET', Uri.parse(url));
      final response = await request.send();
      
      task.totalBytes = response.contentLength ?? 0;
      
      // 创建文件
      final file = File(filePath);
      final sink = file.openWrite();
      
      // 下载数据
      await response.stream.listen(
        (chunk) {
          if (task.cancelToken?.isCancelled ?? false) {
            sink.close();
            return;
          }
          
          sink.add(chunk);
          task.downloadedBytes += chunk.length;
          
          if (task.totalBytes > 0) {
            task.progress = task.downloadedBytes / task.totalBytes;
          }
          
          _downloadProgressController.add(DownloadProgress(
            videoId: videoId,
            progress: task.progress,
            downloadedBytes: task.downloadedBytes,
            totalBytes: task.totalBytes,
            status: task.status,
          ));
          
          task.progressController?.add(DownloadProgress(
            videoId: videoId,
            progress: task.progress,
            downloadedBytes: task.downloadedBytes,
            totalBytes: task.totalBytes,
            status: task.status,
          ));
        },
        onDone: () async {
          await sink.close();
          
          if (task.cancelToken?.isCancelled ?? false) {
            task.status = DownloadStatus.paused;
            // 删除未完成的文件
            if (await file.exists()) {
              await file.delete();
            }
          } else {
            task.status = DownloadStatus.completed;
            task.localPath = filePath;
            
            // 保存下载记录
            await _saveDownloadRecord(task);
          }
          
          _downloadProgressController.add(DownloadProgress(
            videoId: videoId,
            progress: task.progress,
            downloadedBytes: task.downloadedBytes,
            totalBytes: task.totalBytes,
            status: task.status,
          ));
          
          task.progressController?.close();
        },
        onError: (error) {
          task.status = DownloadStatus.failed;
          _downloadProgressController.add(DownloadProgress(
            videoId: videoId,
            progress: task.progress,
            downloadedBytes: task.downloadedBytes,
            totalBytes: task.totalBytes,
            status: task.status,
          ));
        },
        cancelOnError: true,
      ).asFuture();
      
    } catch (e) {
      print('下载失败: $e');
      task.status = DownloadStatus.failed;
      _downloadProgressController.add(DownloadProgress(
        videoId: videoId,
        progress: task.progress,
        downloadedBytes: task.downloadedBytes,
        totalBytes: task.totalBytes,
        status: task.status,
      ));
    }
  }
  
  void pauseDownload(String videoId) {
    final task = _downloadTasks[videoId];
    if (task != null && task.status == DownloadStatus.downloading) {
      task.cancelToken?.cancel();
      task.status = DownloadStatus.paused;
    }
  }
  
  void resumeDownload(String videoId) {
    final task = _downloadTasks[videoId];
    if (task != null && task.status == DownloadStatus.paused) {
      startDownload(
        videoId: task.videoId,
        videoTitle: task.videoTitle,
        url: task.url,
        serverId: task.serverId,
        serverName: task.serverName,
      );
    }
  }
  
  void cancelDownload(String videoId) {
  final task = _downloadTasks[videoId];
  if (task != null) {
    task.cancelToken?.cancel();
    task.status = DownloadStatus.notStarted;
    task.progress = 0;
    task.downloadedBytes = 0;
    
    // 删除临时文件
    if (task.localPath != null) {
      try {
        File(task.localPath!).deleteSync(); // 使用同步删除
        debugPrint('文件删除成功: ${task.localPath}');
      } catch (e) {
        debugPrint('删除文件失败: $e');
      }
    }
  }
}
  
  DownloadStatus getDownloadStatus(String videoId) {
    return _downloadTasks[videoId]?.status ?? DownloadStatus.notStarted;
  }
  
  double getDownloadProgress(String videoId) {
    return _downloadTasks[videoId]?.progress ?? 0.0;
  }
  
  String? getLocalPath(String videoId) {
    return _downloadTasks[videoId]?.localPath;
  }
  
  Future<void> _saveDownloadRecord(DownloadTask task) async {
    try {
      final prefsDir = await getApplicationDocumentsDirectory();
      final recordFile = File(path.join(prefsDir.path, 'download_records.json'));
      
      List<Map<String, dynamic>> records = [];
      if (await recordFile.exists()) {
        final content = await recordFile.readAsString();
        records = List<Map<String, dynamic>>.from(jsonDecode(content));
      }
      
      // 移除旧的记录
      records.removeWhere((r) => r['videoId'] == task.videoId);
      
      // 添加新记录
      records.add(task.toJson());
      
      await recordFile.writeAsString(jsonEncode(records));
    } catch (e) {
      debugPrint('保存下载记录失败: $e');
    }
  }
  
  Future<void> loadDownloadRecords() async {
    try {
      final prefsDir = await getApplicationDocumentsDirectory();
      final recordFile = File(path.join(prefsDir.path, 'download_records.json'));
      
      if (await recordFile.exists()) {
        final content = await recordFile.readAsString();
        final records = List<Map<String, dynamic>>.from(jsonDecode(content));
        
        for (var record in records) {
          final task = DownloadTask.fromJson(record);
          _downloadTasks[task.videoId] = task;
        }
      }
    } catch (e) {
      print('加载下载记录失败: $e');
    }
  }
  
  void dispose() {
    _downloadProgressController.close();
    for (var task in _downloadTasks.values) {
      task.progressController?.close();
    }
  }
}