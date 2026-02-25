// lib/widgets/custom_video_controller/video_speed_button.dart
import 'package:flutter/material.dart';
import 'video_utils.dart';

class VideoSpeedButton extends StatefulWidget {
  final double currentSpeed;
  final VoidCallback onPressed;
  final List<double> availableSpeeds;
  
  const VideoSpeedButton({
    super.key,
    required this.currentSpeed,
    required this.onPressed,
    this.availableSpeeds = const [0.5, 1.0, 1.5, 2.0],
  });

  @override
  State<VideoSpeedButton> createState() => _VideoSpeedButtonState();
}

class _VideoSpeedButtonState extends State<VideoSpeedButton> with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  bool _isPressed = false;
  late AnimationController _glowController;
  
  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }
  
  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isFastSpeed = widget.currentSpeed > 1.0;
    final speedColor = isFastSpeed ? Colors.amber : VideoUtils.primaryColor;
    
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
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isHovered 
                  ? VideoUtils.buttonHoverBackground 
                  : VideoUtils.buttonBackground,
              boxShadow: [
                if (_isHovered)
                  BoxShadow(
                    color: speedColor.withValues(alpha: 0.4),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
              ],
            ),
            child: AnimatedBuilder(
              animation: _glowController,
              builder: (context, child) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: speedColor.withValues(
                      alpha: _isHovered ? 0.3 : 0.2 + (0.1 * _glowController.value),
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${widget.currentSpeed.toStringAsFixed(1)}x',
                    style: TextStyle(
                      color: _isHovered ? speedColor : Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}