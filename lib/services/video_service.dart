// services/video_service.dart
import 'package:video_player/video_player.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// 视频播放服务类
/// 负责管理视频播放器的生命周期和状态
class VideoService {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _isPlaying = false;
  String? _currentUrl;
  String? _lastError;
  bool _isNetworkVideo = false;

  /// 获取视频控制器实例
  VideoPlayerController get controller => _controller;

  /// 检查是否已初始化
  bool get isInitialized => _isInitialized;

  /// 检查是否正在播放
  bool get isPlaying => _isPlaying;

  /// 获取当前播放的URL
  String? get currentUrl => _currentUrl;
  
  /// 获取最后错误信息
  String? get lastError => _lastError;
  
  /// 是否为网络视频
  bool get isNetworkVideo => _isNetworkVideo;

  /// 初始化视频播放器（自动识别网络或本地）
  /// [videoUrl] - 网络视频流URL 或 本地文件路径
  Future<void> initializePlayer(String videoUrl) async {
    _lastError = null;
    
    try {
      debugPrint('开始初始化视频: $videoUrl');
      
      // 判断是网络URL还是本地文件
      final uri = Uri.tryParse(videoUrl);
      if (uri != null && (uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https'))) {
        // 网络视频
        _isNetworkVideo = true;
        await _initializeNetworkPlayer(uri);
      } else {
        // 本地文件
        _isNetworkVideo = false;
        await _initializeLocalPlayer(videoUrl);
      }
      
      debugPrint('视频初始化成功');
      _isInitialized = true;
      _currentUrl = videoUrl;
      
      // 监听播放状态
      _controller.addListener(_onVideoControllerListener);
    } catch (e) {
      debugPrint('视频初始化失败: $e');
      _isInitialized = false;
      _lastError = e.toString();
      throw Exception('视频初始化失败: $e');
    }
  }

  /// 初始化网络视频播放器
  Future<void> _initializeNetworkPlayer(Uri uri) async {
    debugPrint('初始化网络视频: $uri');
    
    // 如果已有控制器，先释放
    if (_isInitialized) {
      debugPrint('释放旧的视频控制器');
      await _controller.dispose();
    }

    debugPrint('创建新的网络视频控制器');
    // 创建新的视频控制器
    _controller = VideoPlayerController.networkUrl(uri);
    
    // 添加错误监听
    _controller.addListener(() {
      if (_controller.value.hasError) {
        debugPrint('视频控制器错误: ${_controller.value.errorDescription}');
        _lastError = _controller.value.errorDescription;
      }
    });
    
    // 初始化控制器
    debugPrint('等待视频初始化...');
    await _controller.initialize();
  }

  /// 初始化本地视频播放器
  Future<void> _initializeLocalPlayer(String filePath) async {
    debugPrint('初始化本地视频: $filePath');
    
    // 检查文件是否存在
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('文件不存在: $filePath');
    }
    
    // 如果已有控制器，先释放
    if (_isInitialized) {
      debugPrint('释放旧的视频控制器');
      await _controller.dispose();
    }

    debugPrint('创建新的本地视频控制器');
    // 创建本地文件视频控制器
    _controller = VideoPlayerController.file(file);
    
    // 添加错误监听
    _controller.addListener(() {
      if (_controller.value.hasError) {
        debugPrint('视频控制器错误: ${_controller.value.errorDescription}');
        _lastError = _controller.value.errorDescription;
      }
    });
    
    // 初始化控制器
    debugPrint('等待视频初始化...');
    await _controller.initialize();
  }

  /// 视频控制器状态监听
  void _onVideoControllerListener() {
    if (_controller.value.isPlaying != _isPlaying) {
      _isPlaying = _controller.value.isPlaying;
    }
  }

  /// 播放视频
  Future<void> play() async {
    if (!_isInitialized) return;
    debugPrint('播放视频');
    await _controller.play();
  }

  /// 暂停视频
  Future<void> pause() async {
    if (!_isInitialized) return;
    debugPrint('暂停视频');
    await _controller.pause();
  }

  /// 停止视频（暂停并跳转到开始）
  Future<void> stop() async {
    if (!_isInitialized) return;
    debugPrint('停止视频');
    await _controller.pause();
    await _controller.seekTo(Duration.zero);
  }

  /// 跳转到指定位置
  Future<void> seekTo(Duration position) async {
    if (!_isInitialized) return;
    debugPrint('跳转到: $position');
    await _controller.seekTo(position);
  }

  /// 设置播放速度
  void setPlaybackSpeed(double speed) {
    if (!_isInitialized) return;
    debugPrint('设置播放速度: $speed');
    _controller.setPlaybackSpeed(speed);
  }

  /// 设置音量 (0.0 - 1.0)
  Future<void> setVolume(double volume) async {
    if (!_isInitialized) return;
    debugPrint('设置音量: $volume');
    await _controller.setVolume(volume);
  }

  /// 获取视频时长
  Duration get videoDuration {
    if (!_isInitialized) return Duration.zero;
    return _controller.value.duration;
  }

  /// 获取当前位置
  Duration get currentPosition {
    if (!_isInitialized) return Duration.zero;
    return _controller.value.position;
  }

  /// 获取缓冲进度
  Duration get bufferedPosition {
    if (!_isInitialized) return Duration.zero;
    final buffered = _controller.value.buffered;
    if (buffered.isNotEmpty) {
      return buffered.last.end;
    }
    return Duration.zero;
  }

  /// 释放资源
  void dispose() {
    debugPrint('释放VideoService资源');
    if (_isInitialized) {
      _controller.removeListener(_onVideoControllerListener);
      _controller.dispose();
    }
    _isInitialized = false;
    _isPlaying = false;
    _currentUrl = null;
    _lastError = null;
  }
}