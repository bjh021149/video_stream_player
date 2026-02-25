// utils/platform_utils.dart
import 'package:flutter/foundation.dart';

/// 平台工具类
class PlatformUtils {
  static bool get isWeb => kIsWeb;
  
  static bool get isMobile => isAndroid || isIOS;
  
  static bool get isDesktop => isWindows || isLinux || isMacOS;
  
  static bool get isWindows {
    if (isWeb) return false;
    try {
      return const String.fromEnvironment('PLATFORM') == 'windows' ||
             const bool.hasEnvironment('IS_WINDOWS');
    } catch (_) {
      return false;
    }
  }
  
  static bool get isLinux {
    if (isWeb) return false;
    try {
      return const String.fromEnvironment('PLATFORM') == 'linux' ||
             const bool.hasEnvironment('IS_LINUX');
    } catch (_) {
      return false;
    }
  }
  
  static bool get isMacOS {
    if (isWeb) return false;
    try {
      return const String.fromEnvironment('PLATFORM') == 'macos' ||
             const bool.hasEnvironment('IS_MACOS');
    } catch (_) {
      return false;
    }
  }
  
  static bool get isAndroid {
    if (isWeb) return false;
    try {
      return const String.fromEnvironment('PLATFORM') == 'android' ||
             const bool.hasEnvironment('IS_ANDROID');
    } catch (_) {
      return false;
    }
  }
  
  static bool get isIOS {
    if (isWeb) return false;
    try {
      return const String.fromEnvironment('PLATFORM') == 'ios' ||
             const bool.hasEnvironment('IS_IOS');
    } catch (_) {
      return false;
    }
  }
  
  static String get platformName {
    if (isWeb) return 'Web';
    if (isWindows) return 'Windows';
    if (isLinux) return 'Linux';
    if (isMacOS) return 'macOS';
    if (isAndroid) return 'Android';
    if (isIOS) return 'iOS';
    return 'Unknown';
  }
  
  /// 获取Linux发行版信息
  static Future<String?> getLinuxDistribution() async {
    if (!isLinux) return null;
    
    try {
      // 这里可以添加读取 /etc/os-release 的逻辑
      // 但在Flutter中可能需要通过平台通道实现
      return 'Unknown Linux';
    } catch (e) {
      return null;
    }
  }
}