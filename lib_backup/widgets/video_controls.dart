// widgets/video_controls.dart
import 'package:flutter/material.dart';
//import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';
import '../services/video_service.dart';

/// 自定义视频控制组件
class VideoControls extends StatefulWidget {
  final VideoService videoService;
  final AnimationController fadeController;
  
  const VideoControls({
    super.key,
    required this.videoService,
    required this.fadeController,
  });
  
  @override
  State<VideoControls> createState() => _VideoControlsState();
}

class _VideoControlsState extends State<VideoControls> {
  bool _isVisible = true;
  late Animation<double> _fadeAnimation;
  double _currentSpeed = 1.0;
  
  @override
  void initState() {
    super.initState();
    _fadeAnimation = CurvedAnimation(
      parent: widget.fadeController,
      curve: Curves.easeIn,
    );
    
    _startHideTimer();
  }
  
  void _startHideTimer() {
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && widget.videoService.isPlaying) {
        setState(() {
          _isVisible = false;
          widget.fadeController.reverse();
        });
      }
    });
  }
  
  void _toggleControls() {
    setState(() {
      _isVisible = !_isVisible;
      if (_isVisible) {
        widget.fadeController.forward();
        _startHideTimer();
      } else {
        widget.fadeController.reverse();
      }
    });
  }
  
  void _showSpeedMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black87,  // 设置背景色为黑色
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('0.5x', style: TextStyle(color: Colors.white)),
                onTap: () {
                  setState(() {
                    _currentSpeed = 0.5;
                    widget.videoService.setPlaybackSpeed(0.5);
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('1.0x (正常)', style: TextStyle(color: Colors.white)),
                onTap: () {
                  setState(() {
                    _currentSpeed = 1.0;
                    widget.videoService.setPlaybackSpeed(1.0);
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('1.5x', style: TextStyle(color: Colors.white)),
                onTap: () {
                  setState(() {
                    _currentSpeed = 1.5;
                    widget.videoService.setPlaybackSpeed(1.5);
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('2.0x', style: TextStyle(color: Colors.white)),
                onTap: () {
                  setState(() {
                    _currentSpeed = 2.0;
                    widget.videoService.setPlaybackSpeed(2.0);
                  });
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleControls,
      behavior: HitTestBehavior.opaque,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          color: Colors.transparent,  // 控制条容器透明
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _buildProgressBar(),
              _buildControlBar(),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildProgressBar() {
    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: widget.videoService.controller!,
      builder: (context, VideoPlayerValue value, child) {
        return Container(
          color: Colors.black26,  // 进度条背景半透明
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              Text(
                _formatDuration(value.position),
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 2,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                    activeTrackColor: Colors.blue,
                    inactiveTrackColor: Colors.grey,
                  ),
                  child: Slider(
                    value: value.duration.inMilliseconds > 0
                        ? value.position.inMilliseconds / value.duration.inMilliseconds
                        : 0,
                    onChanged: (newValue) {
                      final newPosition = Duration(
                        milliseconds: (newValue * value.duration.inMilliseconds).toInt(),
                      );
                      widget.videoService.seekTo(newPosition);
                    },
                  ),
                ),
              ),
              Text(
                _formatDuration(value.duration),
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildControlBar() {
    return Container(
      color: Colors.black26,  // 控制条背景半透明
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: const Icon(Icons.replay_10, color: Colors.white),
            onPressed: () {
              final newPosition = widget.videoService.currentPosition - const Duration(seconds: 10);
              widget.videoService.seekTo(newPosition);
            },
          ),
          IconButton(
            icon: Icon(
              widget.videoService.isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
              size: 32,
            ),
            onPressed: () {
              if (widget.videoService.isPlaying) {
                widget.videoService.pause();
              } else {
                widget.videoService.play();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.forward_10, color: Colors.white),
            onPressed: () {
              final newPosition = widget.videoService.currentPosition + const Duration(seconds: 10);
              widget.videoService.seekTo(newPosition);
            },
          ),
          // 添加速度控制按钮
          IconButton(
            icon: Text(
              '${_currentSpeed}x',
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
            ),
            onPressed: _showSpeedMenu,
          ),
        ],
      ),
    );
  }
  
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '$hours:${twoDigits(minutes)}:${twoDigits(seconds)}';
    } else {
      return '${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
  }
}