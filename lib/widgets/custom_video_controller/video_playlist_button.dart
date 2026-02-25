// lib/widgets/custom_video_controller/video_playlist_button.dart
import 'package:flutter/material.dart';
import 'video_utils.dart';

class VideoPlaylistButton extends StatefulWidget {
  final VoidCallback onPressed;
  
  const VideoPlaylistButton({
    super.key,
    required this.onPressed,
  });

  @override
  State<VideoPlaylistButton> createState() => _VideoPlaylistButtonState();
}

class _VideoPlaylistButtonState extends State<VideoPlaylistButton> with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  bool _isPressed = false;
  late AnimationController _pulseController;
  
  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }
  
  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() {
        _isHovered = false;
        _isPressed = false;
      }),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onPressed,
        child: AnimatedScale(
          scale: _isPressed ? 0.9 : (_isHovered ? 1.1 : 1.0),
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutBack,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 背景光晕
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isHovered 
                          ? VideoUtils.primaryColor.withValues(alpha: 0.3)
                          : VideoUtils.primaryColor.withValues(alpha: 0.1 * _pulseController.value),
                    ),
                  );
                },
              ),
              
              // 按钮
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isHovered 
                      ? VideoUtils.buttonHoverBackground 
                      : VideoUtils.buttonBackground,
                  boxShadow: [
                    if (_isHovered)
                      BoxShadow(
                        color: VideoUtils.primaryColor.withValues(alpha: 0.4),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                  ],
                ),
                child: const Icon(
                  Icons.playlist_play,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}