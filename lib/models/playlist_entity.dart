// models/playlist_entity.dart
import 'package:objectbox/objectbox.dart';
import 'video_entity.dart';

@Entity()
class PlaylistEntity {
  @Id()
  int id = 0;
  
  @Index()
  String playlistId;
  
  String name;
  String? description;
  
  @Property(type: PropertyType.date)
  DateTime createdAt;
  
  @Property(type: PropertyType.date)
  DateTime updatedAt;
  
  // 播放列表中的视频（有序）
  final videos = ToMany<VideoEntity>();
  
  // 当前播放索引
  int currentIndex = 0;
  
  // 播放模式
  bool isShuffled = false;
  bool isRepeating = false;
  
  PlaylistEntity({
    required this.playlistId,
    required this.name,
    this.description,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : 
    createdAt = createdAt ?? DateTime.now(),
    updatedAt = updatedAt ?? DateTime.now();
}