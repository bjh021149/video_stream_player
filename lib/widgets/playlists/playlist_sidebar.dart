// lib/widgets/playlists/playlist_sidebar.dart
import 'package:flutter/material.dart';
import 'package:video_stream_player/models/playlist_entity.dart';
import 'playlist_tile.dart';
import 'playlist_provider.dart';

class PlaylistSidebar extends StatelessWidget {
  final PlaylistProvider provider;
  final VoidCallback onCreatePlaylist;
  final Function(PlaylistEntity) onEditPlaylist;
  final Function(PlaylistEntity) onDeletePlaylist;
  final Function(PlaylistEntity) onSelectPlaylist;

  const PlaylistSidebar({
    super.key,
    required this.provider,
    required this.onCreatePlaylist,
    required this.onEditPlaylist,
    required this.onDeletePlaylist,
    required this.onSelectPlaylist,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: .3),
        border: Border(
          right: BorderSide(
            color: Colors.white.withValues(alpha: .1),
          ),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    '我的列表',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add, size: 20),
                  onPressed: onCreatePlaylist,
                  tooltip: '创建播放列表',
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: provider.playlists.length,
              itemBuilder: (context, index) {
                final playlist = provider.playlists[index];
                final isSelected = provider.selectedPlaylist?.playlistId == playlist.playlistId;
                
                return PlaylistTile(
                  playlist: playlist,
                  isSelected: isSelected,
                  index: index,
                  onTap: () => onSelectPlaylist(playlist),
                  onEdit: () => onEditPlaylist(playlist),
                  onDelete: () => onDeletePlaylist(playlist),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}