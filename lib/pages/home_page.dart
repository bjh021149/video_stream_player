// pages/home_page.dart
import 'package:flutter/material.dart';
import 'package:video_stream_player/pages/new_player_page.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:video_stream_player/widgets/shortcut_hint.dart';

/// 主页面
/// 包含视频URL输入和播放按钮
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  final TextEditingController _urlController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _videoUrl;
  
  late AnimationController _bgAnimationController;
  
  // 拖放状态
  bool _isDragging = false;

  // 示例视频URL列表
  final List<Map<String, String>> _sampleVideos = [
    {
      'name': 'Big Buck Bunny (MP4)',
      'url': 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
      'poster': 'https://peach.blender.org/wp-content/uploads/bbb-splash.png',
    },
    {
      'name': 'Elephant Dream (MP4)',
      'url': 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
      'poster': 'https://download.blender.org/ED/ed_splash.png',
    },
    {
      'name': 'Sintel (MP4)',
      'url': 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/Sintel.mp4',
      'poster': 'https://sintel.org/wp-content/uploads/2011/07/sintel-poster.jpg',
    },
  ];

  @override
  void initState() {
    super.initState();
    _bgAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _urlController.dispose();
    _bgAnimationController.dispose();
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
    _playVideo();
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          '键盘快捷键',
          style: TextStyle(color: Colors.white),
        ),
        content:const SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children:  [
              ShortcutHint(keyName: '空格', description: '播放/暂停'),
              ShortcutHint(keyName: '← →', description: '快退/快进（按住3倍速）'),
              ShortcutHint(keyName: '↑ ↓', description: '音量增减'),
              ShortcutHint(keyName: 'ESC', description: '退出全屏/返回'),
              ShortcutHint(keyName: 'F11', description: '全屏切换'),
              SizedBox(height: 8),
              Divider(color: Colors.white24),
              SizedBox(height: 8),
              Text(
                '提示：也可以拖放视频文件到窗口直接播放',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveBreakpoints.of(context).largerThan(TABLET);
    final isMobile = ResponsiveBreakpoints.of(context).isMobile;
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          '网络串流视频播放器',
          style: TextStyle(
            fontSize: isDesktop ? 24 : 20,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
            foreground: Paint()
              ..shader = const LinearGradient(
                colors: [Colors.deepPurple, Colors.amber],
              ).createShader(const Rect.fromLTWH(0, 0, 200, 70)),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: isDesktop,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showHelpDialog,
            tooltip: '快捷键帮助',
          ),
        ],
      ),
      body: DropTarget(
        onDragDone: (details) {
          setState(() => _isDragging = false);
          for (final file in details.files) {
            final path = file.path;
            if (path.endsWith('.mp4') || 
                path.endsWith('.mkv') || 
                path.endsWith('.avi') ||
                path.endsWith('.mov') ||
                path.endsWith('.flv') ||
                path.endsWith('.wmv')) {
              _urlController.text = path;
              _playVideo();
              break;
            }
          }
        },
        onDragEntered: (details) {
          setState(() => _isDragging = true);
        },
        onDragExited: (details) {
          setState(() => _isDragging = false);
        },
        child: Stack(
          children: [
            // 底层：动态背景
            _buildAnimatedBackground(),
            
            // 中层：主体内容
            SafeArea(
              child: Padding(
                padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
                child: isDesktop
                    ? _buildDesktopLayout()
                    : _buildMobileLayout(),
              ),
            ),
            
            // 最上层：拖放覆盖层（当拖拽时显示）
            if (_isDragging)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.7),
                  child: Center(
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.8, end: 1.0),
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.elasticOut,
                      builder: (context, scale, child) {
                        return Transform.scale(
                          scale: scale,
                          child: Container(
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade900.withValues(alpha: 0.95),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: Colors.deepPurple,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.deepPurple.withValues(alpha: 0.3),
                                  blurRadius: 30,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // 动画图标
                                TweenAnimationBuilder<double>(
                                  tween: Tween(begin: 0.0, end: 1.0),
                                  duration: const Duration(milliseconds: 500),
                                  curve: Curves.elasticOut,
                                  builder: (context, value, child) {
                                    return Transform.scale(
                                      scale: value,
                                      child: Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Colors.deepPurple.withValues(alpha: 0.2),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.cloud_upload,
                                          size: 48,
                                          color: Colors.deepPurple[300],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 24),
                                const Text(
                                  '释放鼠标播放视频',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.deepPurple.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text(
                                    'MP4, MKV, AVI, MOV, FLV, WMV',
                                    style: TextStyle(
                                      color: Colors.deepPurple,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.keyboard_arrow_down,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '拖放文件到此处',
                                      style: TextStyle(
                                        color: Colors.grey[400],
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _bgAnimationController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.deepPurple.shade900.withValues(alpha: 0.3),
                Colors.black,
                Colors.deepPurple.shade800.withValues(alpha: 0.2),
                Colors.black,
              ],
              stops: [
                0.0,
                0.3,
                0.6 + (_bgAnimationController.value * 0.2),
                1.0,
              ],
            ),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: 20 * _bgAnimationController.value,
              sigmaY: 20 * _bgAnimationController.value,
            ),
            child: Container(
              color: Colors.black.withValues(alpha: 0.2),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 左侧输入区
        Expanded(
          flex: 2,
          child: _buildInputCard().animate().fadeIn(
            duration: 600.ms,
            curve: Curves.easeOutQuad,
          ).slideX(
            begin: -0.1,
            end: 0,
            curve: Curves.easeOutQuad,
          ),
        ),
        const SizedBox(width: 24),
        // 右侧示例视频区
        Expanded(
          flex: 3,
          child: _buildSampleList().animate().fadeIn(
            duration: 800.ms,
            delay: 200.ms,
          ).slideX(
            begin: 0.1,
            end: 0,
            curve: Curves.easeOutQuad,
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildInputCard().animate().fadeIn(
            duration: 500.ms,
          ).slideY(
            begin: -0.1,
            end: 0,
            curve: Curves.easeOutQuad,
          ),
          const SizedBox(height: 24),
          _buildSampleList().animate().fadeIn(
            duration: 700.ms,
            delay: 200.ms,
          ),
        ],
      ),
    );
  }

  Widget _buildInputCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade900.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.deepPurple.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.link,
                          color: Colors.deepPurple,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        '输入视频URL',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  TextFormField(
                    controller: _urlController,
                    style: const TextStyle(fontSize: 16),
                    decoration: InputDecoration(
                      labelText: '视频URL',
                      hintText: 'https://example.com/video.mp4 或 本地文件路径',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.05),
                      prefixIcon: const Icon(Icons.link),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.paste),
                        onPressed: () async {
                          // 可以添加粘贴功能
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '请输入视频URL';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // 拖放提示
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.cloud_upload,
                          size: 16,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '或拖放视频文件到窗口',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  ElevatedButton(
                    onPressed: _playVideo,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                    ),
                    child:const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.play_arrow),
                         SizedBox(width: 8),
                        Text(
                          '播放视频',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSampleList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 16),
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
              const Text(
                '示例视频',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        ..._sampleVideos.asMap().entries.map((entry) {
          final index = entry.key;
          final video = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildSampleVideoCard(video, index),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildSampleVideoCard(Map<String, String> video, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (index * 100)),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: child,
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _selectSampleVideo(video['url']!),
                borderRadius: BorderRadius.circular(16),
                splashColor: Colors.deepPurple.withValues(alpha: 0.3),
                highlightColor: Colors.transparent,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // 视频缩略图区域
                      Container(
                        width: 100,
                        height: 60,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          gradient: LinearGradient(
                            colors: [
                              Colors.deepPurple.shade700,
                              Colors.purple.shade900,
                            ],
                          ),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            if (video['poster'] != null)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  video['poster']!,
                                  fit: BoxFit.cover,
                                  width: 100,
                                  height: 60,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(
                                      Icons.movie,
                                      color: Colors.white,
                                      size: 30,
                                    );
                                  },
                                ),
                              )
                            else
                              const Icon(
                                Icons.movie,
                                color: Colors.white,
                                size: 30,
                              ),
                            
                            // 播放图标叠加
                            Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.5),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.play_arrow,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // 视频信息
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              video['name']!,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              video['url']!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.5),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      // 箭头指示
                      Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white.withValues(alpha: 0.3),
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}