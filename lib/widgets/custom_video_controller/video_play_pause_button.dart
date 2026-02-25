// lib/widgets/custom_video_controller/video_play_pause_button.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'video_utils.dart';

class VideoPlayPauseButton extends StatefulWidget {
  final bool isPlaying;
  final VoidCallback onPressed;
  final double size;
  
  const VideoPlayPauseButton({
    super.key,
    required this.isPlaying,
    required this.onPressed,
    this.size = 40.0,
  });

  @override
  State<VideoPlayPauseButton> createState() => _VideoPlayPauseButtonState();
}

class _VideoPlayPauseButtonState extends State<VideoPlayPauseButton> with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  bool _isPressed = false;
  late AnimationController _pulseController;
  
  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
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
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: VideoUtils.primaryColor.withValues(alpha: _isHovered ? 0.5 : 0.3),
                  blurRadius: _isHovered ? 20 : 10,
                  spreadRadius: _isHovered ? 2 : 0,
                ),
                if (!widget.isPlaying)
                  BoxShadow(
                    color: VideoUtils.primaryColor.withValues(alpha: 0.2),
                    blurRadius: 15,
                    spreadRadius: 0,
                  ),
              ],
              gradient: RadialGradient(
                colors: [
                  VideoUtils.primaryColor.withValues(alpha: _isHovered ? 0.3 : 0.2),
                  Colors.transparent,
                ],
                stops: const [0.5, 1.0],
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: VideoUtils.buttonBackground,
              ),
              child: AnimatedSwitcher(
                duration: 300.ms,
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return ScaleTransition(
                    scale: animation,
                    child: RotationTransition(
                      turns: animation,
                      child: child,
                    ),
                  );
                },
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // 脉冲效果（仅在暂停时显示）
                    if (!widget.isPlaying)
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          return Container(
                            width: widget.size * 1.5,
                            height: widget.size * 1.5,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: VideoUtils.primaryColor.withValues(
                                  alpha: 0.3 * (1 - _pulseController.value),
                                ),
                                width: 2,
                              ),
                            ),
                          );
                        },
                      ),
                    
                    // 图标
                    Icon(
                      widget.isPlaying ? Icons.pause : Icons.play_arrow,
                      key: ValueKey<bool>(widget.isPlaying),
                      color: _isHovered ? VideoUtils.primaryColor : Colors.white,
                      size: widget.size,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}