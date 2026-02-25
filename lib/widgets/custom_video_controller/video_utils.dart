// lib/widgets/custom_video_controller/video_utils.dart
import 'package:flutter/material.dart';

/// 视频工具类 - 包含共用函数和常量
class VideoUtils {
  static const double controlButtonSize = 32.0;
  static const double largeControlButtonSize = 40.0;
  static const Duration seekStep = Duration(seconds: 10);
  static const Duration hideControlsDelay = Duration(seconds: 5);
  static const Duration volumeStep = Duration(milliseconds: 50);
  static const double volumeChangeStep = 0.01;
  
  // 颜色常量（使用 withValues）
  static Color get primaryColor => Colors.deepPurple;
  static Color get accentColor => Colors.amber;
  static Color get successColor => Colors.green;
  static Color get errorColor => Colors.red;
  
  static Color get backgroundDark => const Color(0xFF121212);
  static Color get surfaceDark => const Color(0xFF1E1E1E);
  
  // 带透明度的颜色
  static Color get overlayBackground => Colors.black.withValues(alpha: 0.85);
  static Color get controlBarBackground => Colors.black.withValues(alpha: 0.4);
  static Color get buttonBackground => Colors.white.withValues(alpha: 0.1);
  static Color get buttonHoverBackground => Colors.white.withValues(alpha: 0.2);
  static Color get buttonSplashColor => Colors.deepPurple.withValues(alpha: 0.3);
  static Color get progressBarBackground => Colors.grey.shade800.withValues(alpha: 0.5);
  static Color get dividerColor => Colors.white.withValues(alpha: 0.1);
  static Color get textSecondary => Colors.white.withValues(alpha: 0.7);
  static Color get textTertiary => Colors.white.withValues(alpha: 0.5);
  static Color get textDisabled => Colors.white.withValues(alpha: 0.3);
  
  /// 格式化时长
  static String formatDuration(Duration duration) {
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
  
  /// 格式化比特率
  static String formatBitrate(int bitrate) {
    if (bitrate <= 0) return '';
    if (bitrate < 1000) return '$bitrate Kbps';
    if (bitrate < 1000000) return '${(bitrate / 1000).toStringAsFixed(1)} Mbps';
    return '${(bitrate / 1000000).toStringAsFixed(1)} Gbps';
  }
  
// lib/widgets/custom_video_controller/video_utils.dart

/// 获取音量图标
static IconData getVolumeIcon(double volume) {
  if (volume == 0) return Icons.volume_off;
  if (volume < 0.3) return Icons.volume_mute;
  if (volume < 0.7) return Icons.volume_down;
  return Icons.volume_up;
}

/// 获取音量颜色
static Color getVolumeColor(double volume) {
  if (volume == 1.0) return successColor;
  if (volume == 0) return errorColor; // 静音时显示红色
  if (volume < 0.3) return Colors.orange; // 低音量显示橙色
  return Colors.white;
}
}