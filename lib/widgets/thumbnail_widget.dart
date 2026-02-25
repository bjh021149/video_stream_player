// widgets/thumbnail_widget.dart
import 'package:flutter/material.dart';
import 'package:video_stream_player/services/thumbnail_service.dart';
import 'dart:io';

class ThumbnailWidget extends StatefulWidget {
  final String? posterUrl;      // 海报URL
  final String videoUrl;        // 视频URL
  final String videoId;         // 视频ID
  final double width;           // 宽度
  final double height;          // 高度
  final BoxFit fit;             // 适应方式
  final Widget? placeholder;    // 占位图
  final bool useCache;          // 是否使用缓存
  final bool generateIfMissing; // 如果没有缩略图是否生成
  
  const ThumbnailWidget({
    super.key,
    this.posterUrl,
    required this.videoUrl,
    required this.videoId,
    this.width = double.infinity,
    this.height = 120,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.useCache = true,
    this.generateIfMissing = true, // 默认生成缩略图
  });

  @override
  State<ThumbnailWidget> createState() => _ThumbnailWidgetState();
}

class _ThumbnailWidgetState extends State<ThumbnailWidget> {
  final ThumbnailService _thumbnailService = ThumbnailService();
  String? _thumbnailPath;
  bool _isLoading = false;
  bool _hasError = false;
  
  @override
  void initState() {
    super.initState();
    _loadThumbnail();
  }
  
  Future<void> _loadThumbnail() async {
    // 如果有海报URL，直接使用海报
    if (widget.posterUrl != null && widget.posterUrl!.isNotEmpty) {
      setState(() {
        _thumbnailPath = widget.posterUrl;
      });
      return;
    }
    
    // 如果没有视频URL，直接返回
    if (widget.videoUrl.isEmpty) {
      setState(() {
        _hasError = true;
      });
      return;
    }
    
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    
    try {
      // 获取缩略图（如果不存在且generateIfMissing为true，会自动生成）
      String? path;
      if (widget.generateIfMissing) {
        path = await _thumbnailService.getThumbnail(
          widget.videoUrl,
          widget.videoId,
        );
      } else {
        path = await _thumbnailService.getThumbnail(
          widget.videoUrl,
          widget.videoId,
        );
      }
      
      if (mounted) {
        setState(() {
          _thumbnailPath = path;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('加载缩略图失败: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: _buildContent(),
    );
  }
  
  Widget _buildContent() {
    // 显示加载中
    if (_isLoading) {
      return widget.placeholder ??
          Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
              ),
            ),
          );
    }
    
    // 显示错误状态或没有缩略图
    if (_hasError || _thumbnailPath == null) {
      return widget.placeholder ??
          Container(
            color: Colors.grey[850],
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.video_library,
                  size: 32,
                  color: Colors.grey[700],
                ),
                const SizedBox(height: 4),
                Text(
                  '无预览',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          );
    }
    
    // 判断是网络图片还是本地文件
    if (_thumbnailPath!.startsWith('http')) {
      // 网络图片（海报）
      return Image.network(
        _thumbnailPath!,
        fit: widget.fit,
        errorBuilder: (context, error, stackTrace) {
          return widget.placeholder ??
              Container(
                color: Colors.grey[850],
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.broken_image,
                      size: 32,
                      color: Colors.grey[700],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '加载失败',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return widget.placeholder ??
              Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded / 
                          loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                ),
              );
        },
      );
    } else if (_thumbnailPath!.isNotEmpty) {
      // 本地缩略图文件
      return Image.file(
        File(_thumbnailPath!),
        fit: widget.fit,
        errorBuilder: (context, error, stackTrace) {
          return widget.placeholder ??
              Container(
                color: Colors.grey[850],
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.broken_image,
                      size: 32,
                      color: Colors.grey[700],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '加载失败',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              );
        },
      );
    }
    
    // 默认情况
    return widget.placeholder ??
        Container(
          color: Colors.grey[850],
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.video_library,
                size: 32,
                color: Colors.grey[700],
              ),
              const SizedBox(height: 4),
              Text(
                '无预览',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 10,
                ),
              ),
            ],
          ),
        );
  }
  
  @override
  void didUpdateWidget(ThumbnailWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoId != widget.videoId ||
        oldWidget.posterUrl != widget.posterUrl ||
        oldWidget.videoUrl != widget.videoUrl) {
      _thumbnailPath = null;
      _loadThumbnail();
    }
  }
}