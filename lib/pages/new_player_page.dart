// pages/new_player_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/video_service.dart';
import '../widgets/playlists/playlist_dialog.dart';
import '../services/object_service.dart';
import '../models/video_entity.dart';
import '../widgets/custom_video_controller/custom_video_controller.dart';
import 'package:video_player/video_player.dart';
import 'package:window_manager/window_manager.dart';
import 'package:shared_preferences/shared_preferences.dart'; // 添加这个导入

class PlayerPage extends StatefulWidget {
  final String videoUrl;
  
  const PlayerPage({
    super.key,
    required this.videoUrl,
  });
  
  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  late VideoService _videoService;
  bool _isInitialized = false;
  bool _isLoading = true;
  String? _errorMessage;
  
  // 播放状态
  bool _isPlaying = false;
  double _currentSpeed = 1.0;
  bool _isFullscreen = false;
  
  // 音量控制相关 - 所有操作都基于 _currentVolume
  double _currentVolume = 1.0; // 默认值，会在 _loadSavedVolume 中被覆盖
  double _previousVolume = 1.0; // 用于静音恢复
  
  // SharedPreferences 键名
  static const String _volumePrefKey = 'last_volume';
  
  // 时间相关
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  Duration _bufferedPosition = Duration.zero;
  
  // 控制条显示
  bool _isControlsVisible = true;
  
  // 鼠标活动检测
  Timer? _mouseActivityTimer;
  static const Duration _mouseIdleDuration = Duration(seconds: 3);
  
  // 音量控制相关
  Timer? _volumeTimer;
  bool _isVolumeKeyPressed = false;
  bool _isVolumeIncreasing = true;
  static const double _volumeStep = 0.01;
  static const Duration _volumeInterval = Duration(milliseconds: 80);
  
  // 音量指示器显示状态
  bool _isVolumeOverlayVisible = false;
  Timer? _volumeOverlayTimer;
  
  // 速度控制相关
  Timer? _speedTimer;
  bool _isSpeedKeyPressed = false;
  bool _isSpeedForward = true;
  
  // 速度指示器显示状态
  bool _isSpeedOverlayVisible = false;
  
  // 键盘事件焦点
  final FocusNode _focusNode = FocusNode();
  
  // 是否已显示成功通知
  bool _hasShownSuccessNotification = false;
  
  // 返回按钮动画控制器
  late AnimationController _backButtonController;
  late Animation<double> _backButtonAnimation;
  
  // 保存窗口原始状态
  bool _wasWindowMaximized = false;
  Size? _windowSizeBeforeFullscreen;
  Offset? _windowPositionBeforeFullscreen;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // 初始化返回按钮动画
    _backButtonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _backButtonAnimation = CurvedAnimation(
      parent: _backButtonController,
      curve: Curves.easeOutCubic,
    );
    
    debugPrint('PlayerPage initState, URL: ${widget.videoUrl}');
    _videoService = VideoService();
    
    // 先加载保存的音量设置，再初始化播放器
    _loadSavedVolume().then((_) {
      _initializePlayer();
    });
    
    // 页面加载后请求焦点
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }
  
  /// 加载保存的音量设置
  Future<void> _loadSavedVolume() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedVolume = prefs.getDouble(_volumePrefKey) ?? 1.0;
      
      // 确保音量值在有效范围内
      _currentVolume = savedVolume.clamp(0.0, 1.0);
      _previousVolume = _currentVolume > 0 ? _currentVolume : 1.0;
      
      debugPrint('加载保存的音量: $_currentVolume');
    } catch (e) {
      debugPrint('加载音量设置失败: $e');
      // 使用默认值
      _currentVolume = 1.0;
      _previousVolume = 1.0;
    }
  }
  
  /// 保存音量设置
  Future<void> _saveVolume(double volume) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_volumePrefKey, volume);
      debugPrint('保存音量设置: $volume');
    } catch (e) {
      debugPrint('保存音量设置失败: $e');
    }
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _videoService.pause();
      _stopVolumeAdjustment();
      _stopSpeedAdjustment();
      _hideVolumeOverlay();
      _hideSpeedOverlay();
      _resetPlaybackSpeed();
      _cancelMouseTimer();
      
      // 应用暂停时保存音量
      _saveVolume(_currentVolume);
    } else if (state == AppLifecycleState.resumed) {
      _focusNode.requestFocus();
    }
  }
  
  // ========== 音量控制 ==========

  /// 设置音量（所有音量修改都通过这个方法）

void _setVolume(double newVolume) {
  if (!_videoService.isInitialized) return;
  
  // 确保音量在有效范围内
  newVolume = newVolume.clamp(0.0, 1.0);
  // 保留两位小数
  newVolume = (newVolume * 100).roundToDouble() / 100;
  
  if (newVolume != _currentVolume) {
    // 只有在非静音状态下才更新 _previousVolume
    // 注意：当从静音恢复到非静音时，不应该更新 _previousVolume
    if (newVolume > 0 && _currentVolume == 0) {
      // 从静音恢复到非静音，保持 _previousVolume 不变
      debugPrint('从静音恢复，保持 _previousVolume = $_previousVolume');
    } else if (newVolume > 0) {
      // 正常调整音量时更新 _previousVolume
      _previousVolume = newVolume;
      debugPrint('更新 _previousVolume 为: $_previousVolume');
    }
    
    setState(() {
      _currentVolume = newVolume;
    });
    
    _videoService.setVolume(newVolume);
    
    // 音量变化时保存
    _saveVolume(newVolume);
    
    debugPrint('音量设置为: $_currentVolume, 保存的静音前音量: $_previousVolume');
  }
}
  /// 调整音量（相对调整，用于键盘连续调节）
void _adjustVolume(double delta) {
  if (!_videoService.isInitialized) return;
  
  double newVolume = _currentVolume + delta;
  
  // 确保音量在有效范围内
  newVolume = newVolume.clamp(0.0, 1.0);
  // 保留两位小数
  newVolume = (newVolume * 100).roundToDouble() / 100;
  
  if (newVolume != _currentVolume) {
    // 键盘调节时，如果从静音状态调高音量，应该更新 _previousVolume
    if (_currentVolume == 0 && newVolume > 0) {
      _previousVolume = newVolume;
      debugPrint('键盘从静音调高音量，更新 _previousVolume 为: $_previousVolume');
    } else if (newVolume > 0) {
      // 正常调节音量时更新 _previousVolume
      _previousVolume = newVolume;
    }
    
    setState(() {
      _currentVolume = newVolume;
    });
    
    _videoService.setVolume(newVolume);
    _saveVolume(newVolume);
    
    debugPrint('键盘调节音量: $_currentVolume, 保存的静音前音量: $_previousVolume');
  }
}

  /// 静音切换
void _toggleMute() {
  if (_currentVolume > 0) {
    // 当前有声音，静音
    _previousVolume = _currentVolume; // 保存当前音量
    _setVolume(0.0); // 设为0
    debugPrint('静音，保存音量: $_previousVolume');
  } else {
    // 当前静音，恢复到之前的音量
    
    debugPrint('解除静音，目标音量: $_previousVolume');
    
    // 直接设置目标音量，不经过 _setVolume 的 _previousVolume 更新逻辑
    //if (!_videoService.isInitialized) return;
    

    
    if (_previousVolume > 0) {
      setState(() {
        _currentVolume = _previousVolume;
      });
      
      _videoService.setVolume(_previousVolume);
      _saveVolume(_previousVolume);
      
      debugPrint('音量设置为: $_currentVolume, 保存的静音前音量: $_previousVolume');
    }
  }
  
  // 显示音量指示器
  _showVolumeOverlay();
  
  // 设置定时器自动隐藏
  _volumeOverlayTimer?.cancel();
  _volumeOverlayTimer = Timer(const Duration(milliseconds: 1500), () {
    if (mounted && !_isVolumeKeyPressed) {
      _hideVolumeOverlay();
    }
  });
}
  /// 开始持续调整音量（键盘按下时）
  void _startVolumeAdjustment(bool isIncrease) {
    if (_isVolumeKeyPressed) return;
    
    _isVolumeKeyPressed = true;
    _isVolumeIncreasing = isIncrease;
    
    // 显示音量指示器，并取消自动隐藏
    _volumeOverlayTimer?.cancel();
    _showVolumeOverlay();
    
    // 立即执行一次
    _adjustVolume(isIncrease ? _volumeStep : -_volumeStep);
    
    // 启动定时器持续调整
    _volumeTimer = Timer.periodic(_volumeInterval, (timer) {
      if (!_isVolumeKeyPressed || !mounted) {
        _stopVolumeAdjustment();
        return;
      }
      _adjustVolume(isIncrease ? _volumeStep : -_volumeStep);
    });
  }

  /// 停止调整音量（键盘松开时）
  void _stopVolumeAdjustment() {
    _isVolumeKeyPressed = false;
    _volumeTimer?.cancel();
    _volumeTimer = null;
    
    // 延迟隐藏音量指示器
    _volumeOverlayTimer?.cancel();
    _volumeOverlayTimer = Timer(const Duration(milliseconds: 800), () {
      if (mounted && !_isVolumeKeyPressed) {
        _hideVolumeOverlay();
      }
    });
  }

  /// 显示音量指示器
  void _showVolumeOverlay() {
    setState(() {
      _isVolumeOverlayVisible = true;
    });
  }

  /// 隐藏音量指示器
  void _hideVolumeOverlay() {
    setState(() {
      _isVolumeOverlayVisible = false;
    });
  }
  
  // 鼠标活动时调用
  void _onUserActivity() {
    if (!_isControlsVisible) {
      setState(() {
        _isControlsVisible = true;
      });
      _backButtonController.forward();
    }
    _resetMouseTimer();
  }
  
  // 重置鼠标计时器
  void _resetMouseTimer() {
    _cancelMouseTimer();
    if (_isPlaying) {
      _mouseActivityTimer = Timer(_mouseIdleDuration, () {
        if (mounted && _isPlaying) {
          setState(() {
            _isControlsVisible = false;
          });
          _backButtonController.reverse();
        }
      });
    }
  }
  
  // 取消鼠标计时器
  void _cancelMouseTimer() {
    _mouseActivityTimer?.cancel();
    _mouseActivityTimer = null;
  }
  
  // 控制条显示/隐藏
  void _showControls() {
    if (!_isControlsVisible) {
      setState(() {
        _isControlsVisible = true;
      });
      _backButtonController.forward();
    }
    _resetMouseTimer();
  }
  
  void _toggleControls() {
    setState(() {
      _isControlsVisible = !_isControlsVisible;
      if (_isControlsVisible) {
        _backButtonController.forward();
        _resetMouseTimer();
      } else {
        _backButtonController.reverse();
        _cancelMouseTimer();
      }
    });
  }
  
  // 播放/暂停
  void _togglePlayPause() {
    if (_isPlaying) {
      _videoService.pause();
    } else {
      _videoService.play();
    }
    setState(() {
      _isPlaying = !_isPlaying;
    });
    _onUserActivity();
  }
  
  // 前进/后退
  void _rewind() {
    final newPosition = _currentPosition - const Duration(seconds: 10);
    _videoService.seekTo(newPosition);
    _onUserActivity();
  }
  
  void _forward() {
    final newPosition = _currentPosition + const Duration(seconds: 10);
    _videoService.seekTo(newPosition);
    _onUserActivity();
  }
  
  // 跳转
  void _seekTo(Duration position) {
    _videoService.seekTo(position);
    _onUserActivity();
  }
  
  // ========== 速度控制 ==========

  void _setFastSpeed() {
    if (!_videoService.isInitialized) return;
    _videoService.setPlaybackSpeed(3.0);
  }
  
  void _resetPlaybackSpeed() {
    if (!_videoService.isInitialized) return;
    _videoService.setPlaybackSpeed(_currentSpeed);
  }
  
  void _startSpeedAdjustment(bool isForward) {
    if (_isSpeedKeyPressed) return;
    
    _isSpeedKeyPressed = true;
    _isSpeedForward = isForward;
    
    _showSpeedOverlay(isForward);
    _setFastSpeed();
  }
  
  void _stopSpeedAdjustment() {
    _isSpeedKeyPressed = false;
    _speedTimer?.cancel();
    _speedTimer = null;
    _hideSpeedOverlay();
    _resetPlaybackSpeed();
  }
  
  void _showSpeedOverlay(bool isForward) {
    setState(() {
      _isSpeedOverlayVisible = true;
      _isSpeedForward = isForward;
    });
  }
  
  void _hideSpeedOverlay() {
    setState(() {
      _isSpeedOverlayVisible = false;
    });
  }
  
  void _showSpeedMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey.shade900,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  '播放速度',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ..._buildSpeedMenuItems(),
            ],
          ),
        );
      },
    );
  }
  
  List<Widget> _buildSpeedMenuItems() {
    final speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];
    return speeds.map((speed) {
      return ListTile(
        title: Text(
          speed == 1.0 ? '${speed}x (正常)' : '${speed}x',
          style: const TextStyle(color: Colors.white),
        ),
        trailing: _currentSpeed == speed
            ? const Icon(Icons.check, color: Colors.deepPurple)
            : null,
        onTap: () {
          setState(() {
            _currentSpeed = speed;
          });
          _videoService.setPlaybackSpeed(speed);
          Navigator.pop(context);
          _onUserActivity();
        },
      );
    }).toList();
  }
  
  // ========== 全屏控制 ==========
  
  Future<void> _enterFullscreen() async {
    try {
      _wasWindowMaximized = await windowManager.isMaximized();
      if (!_wasWindowMaximized) {
        _windowSizeBeforeFullscreen = await windowManager.getSize();
        _windowPositionBeforeFullscreen = await windowManager.getPosition();
      }
      
      await windowManager.setFullScreen(true);
      
      if (!kIsWeb) {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive, overlays: []);
      }
      
      if (mounted) {
        setState(() {
          _isFullscreen = true;
        });
      }
      
      debugPrint('进入全屏模式');
    } catch (e) {
      debugPrint('进入全屏失败: $e');
    }
  }
  
  Future<void> _exitFullscreen() async {
    try {
      await windowManager.setFullScreen(false);
      
      if (!kIsWeb) {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge, overlays: SystemUiOverlay.values);
      }
      
      if (!_wasWindowMaximized && 
          _windowSizeBeforeFullscreen != null && 
          _windowPositionBeforeFullscreen != null) {
        await windowManager.setSize(_windowSizeBeforeFullscreen!);
        await windowManager.setPosition(_windowPositionBeforeFullscreen!);
      }
      
      if (mounted) {
        setState(() {
          _isFullscreen = false;
        });
      }
      
      debugPrint('退出全屏模式');
    } catch (e) {
      debugPrint('退出全屏失败: $e');
    }
  }
  
  void _toggleFullscreen() {
    if (_isFullscreen) {
      _exitFullscreen();
    } else {
      _enterFullscreen();
    }
    _onUserActivity();
  }
  
  // ========== 其他功能 ==========
  
  void _showPlaylist() {
    PlaylistDialog.show(
      context: context,
      currentVideoUrl: widget.videoUrl,
    );
  }
  
  void _handleBackPress() {
    if (_isFullscreen) {
      _exitFullscreen();
    } else {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      } else {
        _showBackNotification();
      }
    }
  }
  
  void _showBackNotification() {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('按 ESC 再次退出应用'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.deepPurple,
      ),
    );
  }
  
  // ========== 初始化播放器 ==========
  
  Future<void> _initializePlayer() async {
    try {
      debugPrint('开始初始化播放器');
      
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      
      await _videoService.initializePlayer(widget.videoUrl);
      
      if (mounted) {
        debugPrint('视频服务初始化成功');
        
        // 设置加载的音量
        _videoService.setVolume(_currentVolume);
        
        if (_videoService.isNetworkVideo) {
          await _autoSaveVideo();
        } else {
          debugPrint('本地视频，不保存到数据库');
        }
        
        setState(() {
          _isInitialized = true;
          _isLoading = false;
          _totalDuration = _videoService.videoDuration;
        });
        
        _startProgressUpdates();
        
        _videoService.play();
        setState(() {
          _isPlaying = true;
        });
        
        if (kDebugMode && !_hasShownSuccessNotification) {
          _showNotification('视频加载成功');
          _hasShownSuccessNotification = true;
        }
        
        _backButtonController.forward();
        _resetMouseTimer();
        _focusNode.requestFocus();
      }
    } catch (e) {
      debugPrint('视频初始化失败: $e');
      if (mounted) {
        setState(() {
          _errorMessage = '视频加载失败: $e';
          _isLoading = false;
        });
        
        _showNotification('视频加载失败', isError: true);
      }
    }
  }
  
  void _startProgressUpdates() {
    Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (!mounted || !_videoService.isInitialized) {
        timer.cancel();
        return;
      }
      
      setState(() {
        _currentPosition = _videoService.currentPosition;
        _bufferedPosition = _videoService.bufferedPosition;
      });
    });
  }
  
  Future<void> _autoSaveVideo() async {
    try {
      final objectBox = await ObjectBoxService.getInstance();
      
      final existingVideo = objectBox.getVideoByVideoId(widget.videoUrl);
      
      if (existingVideo == null) {
        String title = _extractTitleFromUrl(widget.videoUrl);
        
        final newVideo = VideoEntity(
          videoId: widget.videoUrl,
          title: title,
          sources: [
            VideoSource(
              serverId: 'default',
              serverName: '默认服务器',
              url: widget.videoUrl,
              quality: '自动',
              poster: _extractPosterFromUrl(widget.videoUrl),
            ),
          ],
          duration: _videoService.videoDuration.inSeconds,
          currentServerId: 'default',
        );
        
        await objectBox.putVideo(newVideo);
        debugPrint('视频已自动保存到数据库: $title');
        
        final playlists = objectBox.getAllPlaylists();
        if (playlists.isNotEmpty) {
          final defaultPlaylist = playlists.first;
          objectBox.addVideoToPlaylist(defaultPlaylist.playlistId, newVideo);
          debugPrint('已自动添加到默认播放列表: ${defaultPlaylist.name}');
        }
      } else {
        debugPrint('视频已存在于数据库中');
      }
    } catch (e) {
      debugPrint('自动保存视频失败: $e');
    }
  }
  
  String _extractTitleFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final path = uri.path;
      
      final segments = path.split('/');
      if (segments.isNotEmpty) {
        final lastSegment = segments.last;
        
        if (lastSegment.contains('.')) {
          return lastSegment.split('.').first;
        }
        return lastSegment;
      }
      
      if (url.contains('/videos/')) {
        final idMatch = RegExp(r'/videos/(\d+)').firstMatch(url);
        if (idMatch != null) {
          return 'Emby视频 ${idMatch.group(1)}';
        }
      }
    } catch (e) {
      debugPrint('提取标题失败: $e');
    }
    
    return '视频 ${DateTime.now().millisecondsSinceEpoch}';
  }
  
  String? _extractPosterFromUrl(String url) {
    if (url.contains('/videos/')) {
      final idMatch = RegExp(r'/videos/(\d+)').firstMatch(url);
      if (idMatch != null) {
        final videoId = idMatch.group(1);
        return url.replaceFirst(
          RegExp(r'/videos/\d+/.*'),
          '/Items/$videoId/Images/Primary'
        );
      }
    }
    return null;
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
  
  @override
  void dispose() {
    _focusNode.dispose();
    WidgetsBinding.instance.removeObserver(this);
    _cancelMouseTimer();
    _stopVolumeAdjustment();
    _stopSpeedAdjustment();
    _volumeOverlayTimer?.cancel();
    _backButtonController.dispose();
    
    // 在页面销毁时保存音量
    _saveVolume(_currentVolume);
    
    if (_isFullscreen) {
      windowManager.setFullScreen(false);
    }
    
    if (!kIsWeb) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge, overlays: SystemUiOverlay.values);
    }
    
    debugPrint('PlayerPage dispose');
    _videoService.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: KeyboardListener(
        focusNode: _focusNode,
        onKeyEvent: (KeyEvent event) {
          if (event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
              _startVolumeAdjustment(true);
            } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
              _startVolumeAdjustment(false);
            } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
              _startSpeedAdjustment(true);
            } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
              _startSpeedAdjustment(false);
            } else if (event.logicalKey == LogicalKeyboardKey.space) {
              _togglePlayPause();
            } else if (event.logicalKey == LogicalKeyboardKey.escape) {
              _handleBackPress();
            } else if (event.logicalKey == LogicalKeyboardKey.f11) {
              _toggleFullscreen();
            }
          } else if (event is KeyUpEvent) {
            if (event.logicalKey == LogicalKeyboardKey.arrowUp ||
                event.logicalKey == LogicalKeyboardKey.arrowDown) {
              _stopVolumeAdjustment();
            } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft ||
                       event.logicalKey == LogicalKeyboardKey.arrowRight) {
              _stopSpeedAdjustment();
            }
          }
        },
        child: MouseRegion(
          onHover: (_) => _onUserActivity(),
          child: _buildBody(),
        ),
      ),
    );
  }
  
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.deepPurple),
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
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
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
                onPressed: () {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  }
                },
                child: const Text('返回'),
              ),
            ],
          ),
        ),
      );
    }
    
    if (!_isInitialized) {
      return const Center(child: Text('无法初始化播放器'));
    }
    
    return GestureDetector(
      onTap: _toggleControls,
      onPanDown: (_) => _onUserActivity(),
      child: Stack(
        children: [
          // 视频播放器
          Center(
            child: AspectRatio(
              aspectRatio: _videoService.controller.value.aspectRatio,
              child: VideoPlayer(_videoService.controller),
            ),
          ),
          
          // 返回按钮
          if (_isControlsVisible)
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              left: 16,
              child: FadeTransition(
                opacity: _backButtonAnimation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(-1, 0),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: _backButtonController,
                    curve: Curves.easeOutCubic,
                  )),
                  child: Material(
                    color: Colors.transparent,
                    child: MouseRegion(
                      onHover: (_) => _onUserActivity(),
                      child: InkWell(
                        onTap: _handleBackPress,
                        customBorder: const CircleBorder(),
                        splashColor: Colors.white.withValues(alpha: 0.2),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1),
                          ),
                          child: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          
          // 音量指示器
          if (_isVolumeOverlayVisible)
            Positioned(
              top: MediaQuery.of(context).size.height * 0.3,
              left: MediaQuery.of(context).size.width * 0.5 - 60,
              child: Material(
                color: Colors.transparent,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutBack,
                  builder: (context, scale, child) {
                    return Transform.scale(
                      scale: 0.8 + (0.2 * scale),
                      child: Container(
                        width: 120,
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _currentVolume == 0 ? Colors.red : Colors.deepPurple.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _currentVolume == 0 
                                ? Icons.volume_off 
                                : _currentVolume < 0.3 
                                  ? Icons.volume_mute 
                                  : _currentVolume < 0.7 
                                    ? Icons.volume_down 
                                    : Icons.volume_up,
                              color: _currentVolume == 0 ? Colors.red : Colors.deepPurple,
                              size: 32,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${(_currentVolume * 100).toInt()}%',
                              style: TextStyle(
                                color: _currentVolume == 0 ? Colors.red : Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: LinearProgressIndicator(
                                value: _currentVolume,
                                backgroundColor: Colors.grey[800],
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  _currentVolume == 0 ? Colors.red : Colors.deepPurple,
                                ),
                                minHeight: 4,
                              ),
                            ),
                            if (_currentVolume == 1.0)
                              const Padding(
                                padding: EdgeInsets.only(top: 4),
                                child: Text(
                                  '最大音量',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontSize: 8,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          
          // 速度指示器
          if (_isSpeedOverlayVisible)
            Positioned(
              top: MediaQuery.of(context).size.height * 0.2,
              left: MediaQuery.of(context).size.width * 0.5 - 80,
              child: Material(
                color: Colors.transparent,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutBack,
                  builder: (context, scale, child) {
                    return Transform.scale(
                      scale: scale,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: Colors.amber.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _isSpeedForward ? Icons.fast_forward : Icons.fast_rewind,
                              color: Colors.amber,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              '3.0x',
                              style: TextStyle(
                                color: Colors.amber,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          
          // 控制条
          if (_isControlsVisible)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: MouseRegion(
                onHover: (_) => _onUserActivity(),
                child: VideoControlBar(
                  isPlaying: _isPlaying,
                  currentSpeed: _currentSpeed,
                  volume: _currentVolume,
                  isFullscreen: _isFullscreen,
                  currentPosition: _currentPosition,
                  totalDuration: _totalDuration,
                  bufferedPosition: _bufferedPosition,
                  onPlayPause: _togglePlayPause,
                  onRewind: _rewind,
                  onForward: _forward,
                  onSpeedPressed: _showSpeedMenu,
                  onVolumeChanged: (volume) {
                    // 滑块调节音量
                    _setVolume(volume);
                    _showVolumeOverlay();
                    
                    // 设置定时器自动隐藏
                    _volumeOverlayTimer?.cancel();
                    _volumeOverlayTimer = Timer(const Duration(milliseconds: 1500), () {
                      if (mounted && !_isVolumeKeyPressed) {
                        _hideVolumeOverlay();
                      }
                    });
                  },
                  onFullscreen: _toggleFullscreen,
                  onSeek: _seekTo,
                  onPlaylistPressed: _showPlaylist,
                  onMuteToggle: _toggleMute,
                ),
              ),
            ),
          

        ],
      ),
    );
  }
}