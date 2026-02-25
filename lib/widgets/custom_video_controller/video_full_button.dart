// lib/widgets/custom_video_controller/video_fullscreen_button.dart
import 'package:flutter/material.dart';

class VideoFullButton extends StatelessWidget {
  final bool isFullscreen;
  final VoidCallback onPressed;
  
  const VideoFullButton({
    super.key,
    required this.isFullscreen,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          splashColor: Colors.white.withValues(alpha: 0.2),
          highlightColor: Colors.transparent,
          child: Padding(
            padding:const EdgeInsetsGeometry.all(8.0),
            child: Icon(
              isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}
