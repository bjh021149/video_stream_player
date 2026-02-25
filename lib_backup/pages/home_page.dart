import 'package:flutter/material.dart';
import 'player_page.dart';

/// 主页面
/// 包含视频URL输入和播放按钮
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _urlController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _videoUrl;

  // 示例视频URL列表
  final List<Map<String, String>> _sampleVideos = [
    {
      'name': 'Big Buck Bunny (MP4)',
      'url': 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
    },
    {
      'name': 'Elephant Dream (MP4)',
      'url': 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
    },
    {
      'name': 'Sintel (MP4)',
      'url': 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/Sintel.mp4',
    },
  ];

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  void _playVideo() {
    if (_formKey.currentState?.validate() ?? false) {
      final url = _urlController.text.trim();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PlayerPage(videoUrl: url),
        ),
      );
    }
  }

  void _selectSampleVideo(String url) {
    _urlController.text = url;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('网络串流视频播放器'),
        centerTitle: true,
        elevation: 2,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 视频URL输入表单
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        '输入视频URL',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _urlController,
                        decoration: const InputDecoration(
                          labelText: '视频URL',
                          hintText: 'https://example.com/video.mp4',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.link),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '请输入视频URL';
                          }
                          if (!value.startsWith('http://') && 
                              !value.startsWith('https://')) {
                            return '请输入有效的URL (以http://或https://开头)';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _playVideo,
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('播放视频'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // 示例视频列表
            const Text(
              '示例视频',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: _sampleVideos.length,
                itemBuilder: (context, index) {
                  final video = _sampleVideos[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const Icon(Icons.video_library),
                      title: Text(video['name']!),
                      subtitle: Text(
                        video['url']!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: const Icon(Icons.play_circle_fill),
                      onTap: () {
                        _selectSampleVideo(video['url']!);
                        _playVideo();
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
