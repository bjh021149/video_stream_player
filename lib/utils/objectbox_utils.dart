// utils/objectbox_utils.dart
import 'package:flutter/foundation.dart';
import 'package:video_stream_player/services/object_service.dart';

class ObjectBoxUtils {
  static late ObjectBoxService objectBox;
  
  static Future<void> init() async {
    try {
      objectBox = await ObjectBoxService.getInstance();
      await objectBox.initSampleData();
      if (kDebugMode) {
        print('ObjectBox 初始化成功');
        print('视频数量: ${objectBox.getAllVideos().length}');
        print('播放列表数量: ${objectBox.getAllPlaylists().length}');
      }
    } catch (e) {
      print('ObjectBox 初始化失败: $e');
      rethrow;
    }
  }
  
  static void dispose() {
    objectBox.store.close();
  }
}