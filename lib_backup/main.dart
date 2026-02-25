// main.dart
import 'package:flutter/material.dart';
import 'package:video_stream_player/pages/home_page.dart';
import 'package:fvp/fvp.dart' as fvp;
import 'package:flutter/foundation.dart';
import 'utils/objectbox_utils.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
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
    return MaterialApp(
      title: '网络串流视频播放器',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
      ),
      themeMode: ThemeMode.dark,
      home: const HomePage(),
    );
  }
}