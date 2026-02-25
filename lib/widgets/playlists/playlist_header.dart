// lib/widgets/playlists/playlist_header.dart
import 'package:flutter/material.dart';
import 'playlist_provider.dart';

class PlaylistHeader extends StatelessWidget {
  final PlaylistProvider provider;
  final VoidCallback onClose;

  const PlaylistHeader({
    super.key,
    required this.provider,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: .1),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.deepPurple,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              '播放列表',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              provider.viewMode == PlaylistViewMode.playlist 
                  ? Icons.playlist_play 
                  : Icons.video_library,
              color: Colors.white,
            ),
            onPressed: provider.toggleViewMode,
            tooltip: provider.viewMode == PlaylistViewMode.playlist 
                ? '显示所有视频' 
                : '显示播放列表',
          ),
          if (provider.currentVideo != null)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: Colors.deepPurple.withValues(alpha: .2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.play_circle,
                    color: Colors.deepPurple,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '当前视频',
                    style: TextStyle(
                      color: Colors.deepPurple[300],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}