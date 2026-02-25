// pages/player_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:chewie/chewie.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/video_service.dart';
import '../widgets/playlist_dialog.dart';
import '../services/object_service.dart';
import '../models/video_entity.dart';

class PlayerPage extends StatefulWidget {
  final String videoUrl;
  
  const PlayerPage({
    super.key,
    required this.videoUrl,
  });
  
  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> with WidgetsBindingObserver {
  late VideoService _videoService;
  ChewieController? _chewieController;
  bool _isInitialized = false;
  bool _isLoading = true;
  String? _errorMessage;
  
  // 音量控制相关
  double _currentVolume = 1.0;
  Timer? _volumeTimer;
  bool _isVolumeIncreasing = true;
  static const double _volumeStep = 0.01;
  static const Duration _volumeInterval = Duration(milliseconds: 50);
  
  // 播放速度控制相关
  double _normalPlaybackSpeed = 1.0;
  double _fastPlaybackSpeed = 3.0;
  Timer? _speedTimer;
  bool _isSpeedKeyPressed = false;
  bool _isForwardPressed = true; // true: 向前, false: 向后
  
  // 键盘事件监听 - 使用 HardwareKeyboard
  final Map<LogicalKeyboardKey, bool> _pressedKeys = {};
  
  // 音量指示器
  OverlayEntry? _volumeOverlay;
  bool _isOverlayVisible = false;
  
  // 速度指示器
  OverlayEntry? _speedOverlay;
  bool _isSpeedOverlayVisible = false;
  
  // 是否已显示成功通知
  bool _hasShownSuccessNotification = false;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    print('PlayerPage initState, URL: ${widget.videoUrl}');
    _videoService = VideoService();
    _initializePlayer();
    
    // 注册全局键盘监听
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _videoService.pause();
      _stopVolumeTimer();
      _stopSpeedTimer();
      _hideVolumeIndicator();
      _hideSpeedIndicator();
      _pressedKeys.clear();
      // 恢复正常速度
      _resetPlaybackSpeed();
    } else if (state == AppLifecycleState.resumed) {
      HardwareKeyboard.instance.addHandler(_handleKeyEvent);
    }
  }
  
  bool _handleKeyEvent(KeyEvent event) {
    if (!mounted) return false;
    
    // 处理音量控制键（上下键）
    if (event.logicalKey == LogicalKeyboardKey.arrowUp || 
        event.logicalKey == LogicalKeyboardKey.arrowDown) {
      
      print('音量控制事件: ${event.runtimeType}, 按键: ${event.logicalKey}');
      
      if (event is KeyDownEvent) {
        _pressedKeys[event.logicalKey] = true;
        
        if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
          _showVolumeIndicator();
          _startVolumeTimer(true);
        } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
          _showVolumeIndicator();
          _startVolumeTimer(false);
        }
        
        return true;
        
      } else if (event is KeyUpEvent) {
        _pressedKeys.remove(event.logicalKey);
        
        bool anyArrowKeyPressed = _pressedKeys.containsKey(LogicalKeyboardKey.arrowUp) ||
                                   _pressedKeys.containsKey(LogicalKeyboardKey.arrowDown);
        
        if (!anyArrowKeyPressed) {
          _stopVolumeTimer();
          _hideVolumeIndicator();
        }
        
        return true;
      }
    }
    
    // 处理播放速度控制键（左右键）
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft || 
        event.logicalKey == LogicalKeyboardKey.arrowRight) {
      
      print('速度控制事件: ${event.runtimeType}, 按键: ${event.logicalKey}');
      
      if (event is KeyDownEvent) {
        _pressedKeys[event.logicalKey] = true;
        
        if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
          print('向前键按下 - 启动3倍速');
          _isForwardPressed = true;
          _showSpeedIndicator(true);
          _setFastSpeed();
        } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
          print('向后键按下 - 启动3倍速');
          _isForwardPressed = false;
          _showSpeedIndicator(false);
          _setFastSpeed();
        }
        
        return true;
        
      } else if (event is KeyUpEvent) {
        _pressedKeys.remove(event.logicalKey);
        
        bool anySpeedKeyPressed = _pressedKeys.containsKey(LogicalKeyboardKey.arrowLeft) ||
                                   _pressedKeys.containsKey(LogicalKeyboardKey.arrowRight);
        
        if (!anySpeedKeyPressed) {
          print('所有速度控制键松开 - 恢复正常速度');
          _hideSpeedIndicator();
          _resetPlaybackSpeed();
        }
        
        return true;
      }
    }
    
    return false;
  }
  
  // 音量控制方法
  void _startVolumeTimer(bool isIncrease) {
    _stopVolumeTimer();
    _isVolumeIncreasing = isIncrease;
    
    // 立即执行一次音量调整
    _adjustVolume(isIncrease);
    
    // 启动定时器持续调整
    _volumeTimer = Timer.periodic(_volumeInterval, (timer) {
      if (!mounted) {
        _stopVolumeTimer();
        return;
      }
      _adjustVolume(_isVolumeIncreasing);
    });
  }
  
  void _stopVolumeTimer() {
    _volumeTimer?.cancel();
    _volumeTimer = null;
  }
  
  void _adjustVolume(bool isIncrease) {
    if (!_videoService.isInitialized) return;
    
    double newVolume = _currentVolume;
    
    if (isIncrease) {
      newVolume = _currentVolume + _volumeStep;
      if (newVolume > 1.0) newVolume = 1.0;
    } else {
      newVolume = _currentVolume - _volumeStep;
      if (newVolume < 0.0) newVolume = 0.0;
    }
    
    if (newVolume != _currentVolume) {
      print('设置音量: ${newVolume.toStringAsFixed(2)}');
      setState(() {
        _currentVolume = newVolume;
      });
      
      _videoService.setVolume(_currentVolume);
      
      if (_isOverlayVisible) {
        _showVolumeIndicator();
      }
    }
  }
  
  // 播放速度控制方法
  void _setFastSpeed() {
    if (!_videoService.isInitialized) return;
    
    String direction = _isForwardPressed ? '向前' : '向后';
    print('设置${direction}3倍速播放');
    
    // 直接通过 VideoService 设置速度
    _videoService.setPlaybackSpeed(_fastPlaybackSpeed);
  }
  
  void _resetPlaybackSpeed() {
    if (!_videoService.isInitialized) return;
    
    print('恢复正常速度: ${_normalPlaybackSpeed}x');
    
    // 直接通过 VideoService 设置速度
    _videoService.setPlaybackSpeed(_normalPlaybackSpeed);
  }
  
  void _stopSpeedTimer() {
    _speedTimer?.cancel();
    _speedTimer = null;
    _isSpeedKeyPressed = false;
  }
  
  // 音量指示器
  void _showVolumeIndicator() {
    if (_volumeOverlay != null) {
      try {
        _volumeOverlay!.remove();
      } catch (e) {
        print('移除旧的音量指示器时出错: $e');
      }
      _volumeOverlay = null;
    }
    
    _volumeOverlay = OverlayEntry(
      builder: (context) => Positioned(
        left: 0,
        right: 0,
        bottom: MediaQuery.of(context).size.height * 0.15,
        child: Center(
          child: Material(
            color: Colors.transparent,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _currentVolume == 0 ? Icons.volume_off : 
                    _currentVolume < 0.3 ? Icons.volume_mute :
                    _currentVolume < 0.7 ? Icons.volume_down : Icons.volume_up,
                    color: Colors.white,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${(_currentVolume * 100).toInt()}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: 200,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: _currentVolume,
                      child: Container(
                        decoration: BoxDecoration(
                          color: _currentVolume == 1.0 ? Colors.green : Colors.deepPurple,
                          borderRadius: BorderRadius.circular(4),
                          gradient: _currentVolume == 1.0 ? null : LinearGradient(
                            colors: [
                              Colors.deepPurple,
                              Colors.deepPurpleAccent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (_currentVolume == 1.0)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '最大音量',
                        style: TextStyle(
                          color: Colors.green[300],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  if (_currentVolume == 0.0)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '静音',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    
    Overlay.of(context).insert(_volumeOverlay!);
    _isOverlayVisible = true;
  }
  
  void _hideVolumeIndicator() {
    if (_volumeOverlay != null) {
      try {
        _volumeOverlay!.remove();
      } catch (e) {
        print('移除音量指示器时出错: $e');
      }
      _volumeOverlay = null;
    }
    _isOverlayVisible = false;
  }
  
  // 速度指示器
  void _showSpeedIndicator(bool isForward) {
    if (_speedOverlay != null) {
      try {
        _speedOverlay!.remove();
      } catch (e) {
        print('移除旧的速度指示器时出错: $e');
      }
      _speedOverlay = null;
    }
    
    _speedOverlay = OverlayEntry(
      builder: (context) => Positioned(
        left: 0,
        right: 0,
        top: MediaQuery.of(context).size.height * 0.15,
        child: Center(
          child: Material(
            color: Colors.transparent,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isForward ? Icons.fast_forward : Icons.fast_rewind,
                    color: Colors.amber,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isForward ? '快进中' : '快退中',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_fastPlaybackSpeed.toInt()}x',
                          style: const TextStyle(
                            color: Colors.amber,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    
    Overlay.of(context).insert(_speedOverlay!);
    _isSpeedOverlayVisible = true;
  }
  
  void _hideSpeedIndicator() {
    if (_speedOverlay != null) {
      try {
        _speedOverlay!.remove();
      } catch (e) {
        print('移除速度指示器时出错: $e');
      }
      _speedOverlay = null;
    }
    _isSpeedOverlayVisible = false;
  }
  
  void _showNotification(String message, {bool isError = false}) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.deepPurple,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  
// pages/player_page.dart
Future<void> _initializePlayer() async {
  try {
    print('开始初始化播放器');
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    await _videoService.initializeNetworkPlayer(widget.videoUrl);
    
    if (mounted) {
      print('视频服务初始化成功');
      
      // 自动保存视频到数据库
      await _autoSaveVideo();
      
      setState(() {
        _isInitialized = true;
        _isLoading = false;
      });
      
      if (kDebugMode && !_hasShownSuccessNotification) {
        _showNotification('视频加载成功');
        _hasShownSuccessNotification = true;
      }
      
      _setupChewieController();
    }
  } catch (e) {
    print('视频初始化失败: $e');
    if (mounted) {
      setState(() {
        _errorMessage = '视频加载失败: $e';
        _isLoading = false;
      });
      
      _showNotification('视频加载失败', isError: true);
    }
  }
}

/// 自动保存视频到数据库
Future<void> _autoSaveVideo() async {
  try {
    final objectBox = await ObjectBoxService.getInstance();
    
    // 检查视频是否已存在
    final existingVideo = objectBox.getVideoByVideoId(widget.videoUrl);
    
    if (existingVideo == null) {
      // 从URL中提取文件名作为标题
      String title = _extractTitleFromUrl(widget.videoUrl);
      
      // 创建新的视频实体
      final newVideo = VideoEntity(
        videoId: widget.videoUrl,
        title: title,
        sources: [
          VideoSource(
            serverId: 'default',
            serverName: '默认服务器',
            url: widget.videoUrl,
            quality: '自动',
            poster: _extractPosterFromUrl(widget.videoUrl), // 如果有海报URL的话
          ),
        ],
        duration: _videoService.videoDuration.inSeconds,
        currentServerId: 'default',
      );
      
      await objectBox.putVideo(newVideo);
      print('视频已自动保存到数据库: $title');
      
      // 可选：自动添加到默认播放列表
      final playlists = objectBox.getAllPlaylists();
      if (playlists.isNotEmpty) {
        final defaultPlaylist = playlists.first;
        objectBox.addVideoToPlaylist(defaultPlaylist.playlistId, newVideo);
        print('已自动添加到默认播放列表: ${defaultPlaylist.name}');
      }
    } else {
      print('视频已存在于数据库中');
    }
  } catch (e) {
    print('自动保存视频失败: $e');
  }
}

/// 从URL中提取标题
String _extractTitleFromUrl(String url) {
  try {
    // 尝试从URL中提取文件名
    final uri = Uri.parse(url);
    final path = uri.path;
    
    // 获取最后一个路径段
    final segments = path.split('/');
    if (segments.isNotEmpty) {
      final lastSegment = segments.last;
      
      // 移除扩展名
      if (lastSegment.contains('.')) {
        return lastSegment.split('.').first;
      }
      return lastSegment;
    }
    
    // 如果是从Emby这样的服务来的，尝试提取ID
    if (url.contains('/videos/')) {
      final idMatch = RegExp(r'/videos/(\d+)').firstMatch(url);
      if (idMatch != null) {
        return 'Emby视频 ${idMatch.group(1)}';
      }
    }
  } catch (e) {
    print('提取标题失败: $e');
  }
  
  // 默认标题
  return '视频 ${DateTime.now().millisecondsSinceEpoch}';
}

/// 从URL中提取海报（如果有）
String? _extractPosterFromUrl(String url) {
  // 对于Emby，可以尝试构造海报URL
  if (url.contains('/videos/')) {
    final idMatch = RegExp(r'/videos/(\d+)').firstMatch(url);
    if (idMatch != null) {
      final videoId = idMatch.group(1);
      // 构造Emby海报URL（根据你的Emby设置调整）
      return url.replaceFirst(
        RegExp(r'/videos/\d+/.*'),
        '/Items/$videoId/Images/Primary'
      );
    }
  }
  return null;
}
  
  void _setupChewieController() {
    if (!_videoService.isInitialized) {
      print('视频服务未初始化，无法创建ChewieController');
      return;
    }
    
    print('创建ChewieController');
    try {
      _chewieController = ChewieController(
        videoPlayerController: _videoService.controller,
        autoPlay: true,
        looping: false,
        aspectRatio: 16 / 9,
        allowFullScreen: true,
        allowMuting: true,
        
        showControls: true,
        showControlsOnInitialize: true,
        allowedScreenSleep: false,
        
        deviceOrientationsAfterFullScreen: [
          DeviceOrientation.portraitUp,
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ],
        
        materialProgressColors: ChewieProgressColors(
          playedColor: Colors.deepPurple,
          bufferedColor: Colors.grey,
          handleColor: Colors.deepPurple,
          backgroundColor: Colors.grey.shade300,
        ),
        
        placeholder: Container(
          color: Colors.black,
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
        
        errorBuilder: (context, errorMessage) {
          print('Chewie错误: $errorMessage');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                Text(
                  '播放错误: $errorMessage',
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    _initializePlayer();
                  },
                  child: const Text('重试'),
                ),
              ],
            ),
          );
        },
      );
      
      print('ChewieController创建成功');
      
      _videoService.setVolume(_currentVolume);
      _videoService.play();
      
      if (kDebugMode && !_hasShownSuccessNotification) {
        _showNotification('播放器准备就绪');
      }
    } catch (e) {
      print('创建ChewieController失败: $e');
      setState(() {
        _errorMessage = '播放器初始化失败: $e';
      });
      _showNotification('播放器初始化失败', isError: true);
    }
  }
  
  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    WidgetsBinding.instance.removeObserver(this);
    _stopVolumeTimer();
    _stopSpeedTimer();
    _hideVolumeIndicator();
    _hideSpeedIndicator();
    _pressedKeys.clear();
    print('PlayerPage dispose');
    _chewieController?.dispose();
    _videoService.dispose();
    super.dispose();
  }
  
@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('视频播放'),
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        // 播放列表按钮
        IconButton(
          icon: const Icon(Icons.playlist_play),
          onPressed: () {
            PlaylistDialog.show(
              context: context,
              currentVideoUrl: widget.videoUrl,
            );
          },
          tooltip: '播放列表',
        ),
      ],
    ),
    body: _buildBody(),
  );
}
  
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('正在加载视频...'),
          ],
        ),
      );
    }
    
    if (_errorMessage != null) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _errorMessage = null;
                  });
                  _initializePlayer();
                },
                child: const Text('重试'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('返回'),
              ),
            ],
          ),
        ),
      );
    }
    
    if (_chewieController != null) {
      return Chewie(
        controller: _chewieController!,
      );
    }
    
    return const Center(
      child: Text('无法初始化播放器'),
    );
  }
}