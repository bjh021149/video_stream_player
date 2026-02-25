// lib/widgets/playlists/playlist_bottom_bar.dart
import 'package:flutter/material.dart';
import 'package:video_stream_player/models/playlist_entity.dart';
import 'playlist_provider.dart';

class PlaylistBottomBar extends StatelessWidget {
  final PlaylistProvider provider;
  final Function(PlaylistEntity) onAddToPlaylist;

  const PlaylistBottomBar({
    super.key,
    required this.provider,
    required this.onAddToPlaylist,
  });

  @override
  Widget build(BuildContext context) {
    if (provider.currentVideo == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: .1),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '当前: ${provider.currentVideo!.title}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          PopupMenuButton<PlaylistEntity>(
            icon: const Icon(Icons.playlist_add, color: Colors.deepPurple),
            tooltip: '添加到播放列表',
            color: Colors.grey.shade900,
            onSelected: onAddToPlaylist,
            itemBuilder: (context) {
              return provider.playlists.map((playlist) {
                return PopupMenuItem(
                  value: playlist,
                  child: Text(
                    playlist.name,
                    style: const TextStyle(color: Colors.white),
                  ),
                );
              }).toList();
            },
          ),
        ],
      ),
    );
  }
}