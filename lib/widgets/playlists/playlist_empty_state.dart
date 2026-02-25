// lib/widgets/playlists/playlist_empty_state.dart
import 'package:flutter/material.dart';

class PlaylistEmptyState extends StatelessWidget {
  final VoidCallback onCreatePlaylist;

  const PlaylistEmptyState({
    super.key,
    required this.onCreatePlaylist,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.deepPurple.withValues(alpha: .1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.playlist_play,
              size: 60,
              color: Colors.deepPurple,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '暂无播放列表',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '点击下方按钮创建第一个播放列表',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: .5),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onCreatePlaylist,
            icon: const Icon(Icons.add),
            label: const Text('创建播放列表'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ],
      ),
    );
  }
}