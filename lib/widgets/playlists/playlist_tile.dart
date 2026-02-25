// lib/widgets/playlists/playlist_tile.dart
import 'package:flutter/material.dart';
import 'package:video_stream_player/models/playlist_entity.dart';
import 'package:video_stream_player/widgets/thumbnail_widget.dart';
import 'package:flutter_animate/flutter_animate.dart';

class PlaylistTile extends StatelessWidget {
  final PlaylistEntity playlist;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final int index;

  const PlaylistTile({
    super.key,
    required this.playlist,
    required this.isSelected,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? Colors.deepPurple.withValues(alpha: .3) : null,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        dense: true,
        leading: Stack(
          children: [
            if (playlist.videos.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: ThumbnailWidget(
                  posterUrl: playlist.videos.first.getPosterUrl(),
                  videoUrl: playlist.videos.first.getPreferredSource()?.url ?? '',
                  videoId: playlist.videos.first.videoId,
                  width: 32,
                  height: 32,
                  fit: BoxFit.cover,
                  placeholder: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade800,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.playlist_play,
                      size: 16,
                      color: isSelected ? Colors.deepPurple : Colors.grey,
                    ),
                  ),
                ),
              )
            else
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.grey.shade800,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.playlist_play,
                  size: 16,
                  color: isSelected ? Colors.deepPurple : Colors.grey,
                ),
              ),
            if (isSelected)
              const Positioned(
                bottom: 0,
                right: 0,
                child: Icon(
                  Icons.check_circle,
                  color: Colors.deepPurple,
                  size: 12,
                ),
              ),
          ],
        ),
        title: Text(
          playlist.name,
          style: TextStyle(
            color: isSelected ? Colors.deepPurple : Colors.white,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${playlist.videos.length}个视频',
          style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 11,
          ),
        ),
        trailing: PopupMenuButton(
          icon: Icon(
            Icons.more_vert,
            size: 16,
            color: isSelected ? Colors.deepPurple : Colors.grey,
          ),
          color: Colors.grey.shade900,
          itemBuilder: (context) => [
            PopupMenuItem(
              height: 32,
              onTap: onEdit,
              child: const Row(
                children: [
                  Icon(Icons.edit, size: 16, color: Colors.white),
                  SizedBox(width: 8),
                  Text('重命名', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
            PopupMenuItem(
              height: 32,
              onTap: onDelete,
              child: const Row(
                children: [
                  Icon(Icons.delete, size: 16, color: Colors.red),
                  SizedBox(width: 8),
                  Text('删除', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
        onTap: onTap,
      ),
    ).animate().fadeIn(
      duration: 300.ms,
      delay: (index * 50).ms,
    );
  }
}