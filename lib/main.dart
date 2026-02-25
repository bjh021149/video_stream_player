// main.dart
import 'package:flutter/material.dart';
import 'package:video_stream_player/pages/home_page.dart';
import 'package:fvp/fvp.dart' as fvp;
import 'package:flutter/foundation.dart';
import 'utils/objectbox_utils.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:window_manager/window_manager.dart'; // 添加窗口管理
import 'package:bitsdojo_window/bitsdojo_window.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化窗口管理器（仅桌面端）
  if (!kIsWeb) {
    await windowManager.ensureInitialized();
    WindowOptions windowOptions = const WindowOptions(
      size: Size(1280, 720),
      minimumSize: Size(800, 600),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden,
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }
  
  // 初始化 Animate 全局配置
  Animate.restartOnHotReload = true;
  
  // 初始化 ObjectBox
  try {
    await ObjectBoxUtils.init();
    debugPrint('ObjectBox 初始化成功');
  } catch (e) {
    debugPrint('ObjectBox 初始化失败: $e');
  }
  
  // 只在非Web平台注册fvp
  if (!kIsWeb) {
    try {
      fvp.registerWith(options: {
        'video.decoders': ['NVDEC', 'FFmpeg'],
        'lowLatency': 1,
        'bufferSize': 1024 * 1024 * 30,
        'maxCachedFiles': 5,
      });
      debugPrint('FVP注册成功');
    } catch (e) {
      debugPrint('FVP注册失败: $e');
    }
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seedColor = Colors.deepPurple;
    
    return MaterialApp(
      title: '网络串流视频播放器',
      debugShowCheckedModeBanner: false,
      
      // 响应式框架配置 - 针对桌面端优化
      builder: (context, child) => ResponsiveBreakpoints.builder(
        child: child!,
        breakpoints: [
          const Breakpoint(start: 0, end: 450, name: MOBILE),
          const Breakpoint(start: 451, end: 1024, name: TABLET),
          const Breakpoint(start: 1025, end: 1920, name: DESKTOP),
          const Breakpoint(start: 1921, end: double.infinity, name: '4K'),
        ],
      ),
      
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        
        // 桌面端优化的字体大小
        typography: Typography.material2021(
          platform: TargetPlatform.linux,
        ),
        
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          clipBehavior: Clip.antiAlias,
          color: Colors.grey.shade900.withValues(alpha: 0.8),
        ),
        
        appBarTheme: const AppBarThemeData(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
          scrolledUnderElevation: 4,
          titleTextStyle: TextStyle(
            fontSize: 18, // 桌面端可以稍微小一点
            fontWeight: FontWeight.w600,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
        
        // 桌面端优化的对话框
        dialogTheme: DialogThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: Colors.grey.shade900.withValues(alpha: 0.95),
          elevation: 8,
        ),
        
        dividerTheme: DividerThemeData(
          color: Colors.white.withValues(alpha: 0.1),
          thickness: 1,
          space: 1,
        ),
        
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 2,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            backgroundColor: seedColor,
            foregroundColor: Colors.white,
          ),
        ),
        
        iconTheme: IconThemeData(
          color: Colors.white.withValues(alpha: 0.9),
          size: 20,
        ),
        
        listTileTheme: ListTileThemeData(
          textColor: Colors.white,
          iconColor: Colors.white.withValues(alpha: 0.7),
          dense: true, // 桌面端可以使用更紧凑的列表
        ),
        
        popupMenuTheme: PopupMenuThemeData(
          color: Colors.grey.shade900,
          textStyle: const TextStyle(color: Colors.white, fontSize: 13),
        ),
        
        // 桌面端优化的工具提示
        tooltipTheme: TooltipThemeData(
          decoration: BoxDecoration(
            color: Colors.grey.shade800,
            borderRadius: BorderRadius.circular(4),
          ),
          textStyle: const TextStyle(color: Colors.white, fontSize: 12),
          waitDuration: const Duration(milliseconds: 500),
        ),
      ),
      
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          clipBehavior: Clip.antiAlias,
          color: Colors.grey.shade900.withValues(alpha: 0.8),
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
        ),
        dialogTheme: DialogThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: Colors.grey.shade900.withValues(alpha: 0.95),
        ),
      ),
      themeMode: ThemeMode.dark,
      
      home: const HomePage(),
    );
  }
}