// lib/widgets/custom_video_controller/video_seek_buttons.dart
import 'package:flutter/material.dart';
import 'video_utils.dart';
import 'dart:math';

class VideoSeekButtons extends StatefulWidget {
  final VoidCallback onRewind;
  final VoidCallback onForward;
  final double size;
  
  const VideoSeekButtons({
    super.key,
    required this.onRewind,
    required this.onForward,
    this.size = 32.0,
  });

  @override
  State<VideoSeekButtons> createState() => _VideoSeekButtonsState();
}

class _VideoSeekButtonsState extends State<VideoSeekButtons> {
  bool _isRewindHovered = false;
  bool _isForwardHovered = false;
  bool _isRewindPressed = false;
  bool _isForwardPressed = false;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildSeekButton(
          icon: Icons.replay_10,
          label: '-10s',
          isHovered: _isRewindHovered,
          isPressed: _isRewindPressed,
          onHover: (value) => setState(() => _isRewindHovered = value),
          onTapDown: () => setState(() => _isRewindPressed = true),
          onTapUp: () => setState(() => _isRewindPressed = false),
          onTapCancel: () => setState(() => _isRewindPressed = false),
          onPressed: widget.onRewind,
        ),
        const SizedBox(width: 8),
        _buildSeekButton(
          icon: Icons.forward_10,
          label: '+10s',
          isHovered: _isForwardHovered,
          isPressed: _isForwardPressed,
          onHover: (value) => setState(() => _isForwardHovered = value),
          onTapDown: () => setState(() => _isForwardPressed = true),
          onTapUp: () => setState(() => _isForwardPressed = false),
          onTapCancel: () => setState(() => _isForwardPressed = false),
          onPressed: widget.onForward,
        ),
      ],
    );
  }

  Widget _buildSeekButton({
    required IconData icon,
    required String label,
    required bool isHovered,
    required bool isPressed,
    required ValueChanged<bool> onHover,
    required VoidCallback onTapDown,
    required VoidCallback onTapUp,
    required VoidCallback onTapCancel,
    required VoidCallback onPressed,
  }) {
    return MouseRegion(
      onEnter: (_) => onHover(true),
      onExit: (_) {
        onHover(false);
        onTapCancel();
      },
      child: GestureDetector(
        onTapDown: (_) => onTapDown(),
        onTapUp: (_) => onTapUp(),
        onTapCancel: onTapCancel,
        onTap: onPressed,
        child: Tooltip(
          message: label,
          preferBelow: false,
          decoration: BoxDecoration(
            color: VideoUtils.overlayBackground,
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(color: Colors.white),
          child: AnimatedScale(
            scale: isPressed ? 0.9 : (isHovered ? 1.1 : 1.0),
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOutBack,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isHovered 
                    ? VideoUtils.buttonHoverBackground 
                    : VideoUtils.buttonBackground,
                boxShadow: [
                  if (isHovered)
                    BoxShadow(
                      color: VideoUtils.primaryColor.withValues(alpha: 0.3),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // 旋转的环形指示器（悬停时显示）
                  if (isHovered)
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: const Duration(seconds: 2),
                      curve: Curves.linear,
                      builder: (context, value, child) {
                        return CustomPaint(
                          size: Size(widget.size + 8, widget.size + 8),
                          painter: _RingPainter(
                            progress: value,
                            color: VideoUtils.primaryColor,
                          ),
                        );
                      },
                    ),
                  
                  // 图标
                  Icon(
                    icon,
                    color: isHovered ? VideoUtils.primaryColor : Colors.white,
                    size: widget.size,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// 环形绘制器
class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;

  _RingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}