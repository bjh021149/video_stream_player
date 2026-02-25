// lib/widgets/custom_video_controller/video_control_bar.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'video_play_pause_button.dart';
import 'video_seek_buttons.dart';
import 'video_speed_button.dart';
import 'video_volume_button.dart';
import 'video_full_button.dart';
import 'video_playlist_button.dart';
import 'video_progress_bar.dart';
import 'video_utils.dart';
import 'dart:ui';

class VideoControlBar extends StatelessWidget {
  final bool isPlaying;
  final double currentSpeed;
  final double volume;
  final bool isFullscreen;
  final Duration currentPosition;
  final Duration totalDuration;
  final Duration bufferedPosition;
  
  final VoidCallback onPlayPause;
  final VoidCallback onRewind;
  final VoidCallback onForward;
  final VoidCallback onSpeedPressed;
  final Function(double) onVolumeChanged;
  final VoidCallback onFullscreen;
  final Function(Duration) onSeek;
  final VoidCallback onPlaylistPressed;
  final VoidCallback onMuteToggle; // 新增静音回调参数
  
  const VideoControlBar({
    super.key,
    required this.isPlaying,
    required this.currentSpeed,
    required this.volume,
    required this.isFullscreen,
    required this.currentPosition,
    required this.totalDuration,
    required this.bufferedPosition,
    required this.onPlayPause,
    required this.onRewind,
    required this.onForward,
    required this.onSpeedPressed,
    required this.onVolumeChanged,
    required this.onFullscreen,
    required this.onSeek,
    required this.onPlaylistPressed,
    required this.onMuteToggle, // 新增
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                VideoUtils.controlBarBackground,
                VideoUtils.controlBarBackground.withValues(alpha: 0.9),
              ],
            ),
            border: Border(
              top: BorderSide(
                color: VideoUtils.dividerColor,
                width: 0.5,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 进度条
              VideoProgressBar(
                currentPosition: currentPosition,
                totalDuration: totalDuration,
                bufferedPosition: bufferedPosition,
                onSeek: onSeek,
              ),
              
              // 控制按钮行
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    // 播放/暂停
                    VideoPlayPauseButton(
                      isPlaying: isPlaying,
                      onPressed: onPlayPause,
                    ),
                    const SizedBox(width: 8),
                    
                    // 前进/后退
                    VideoSeekButtons(
                      onRewind: onRewind,
                      onForward: onForward,
                    ),
                    
                    const Spacer(),
                    
                    // 播放列表按钮
                    VideoPlaylistButton(
                      onPressed: onPlaylistPressed,
                    ),
                    const SizedBox(width: 8),
                    
                    // 速度控制
                    VideoSpeedButton(
                      currentSpeed: currentSpeed,
                      onPressed: onSpeedPressed,
                    ),
                    const SizedBox(width: 8),
                    
                    // 音量控制 - 传递静音回调
                    VideoVolumeButton(
                      volume: volume,
                      onVolumeChanged: onVolumeChanged,
                      onMuteToggle: onMuteToggle, // 传递静音回调
                    ),
                    const SizedBox(width: 8),
                    
                    // 全屏控制
                    VideoFullButton(
                      isFullscreen: isFullscreen,
                      onPressed: onFullscreen,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().slideY(
      begin: 0.5,
      end: 0,
      duration: 300.ms,
      curve: Curves.easeOutCubic,
    ).fadeIn();
  }
}