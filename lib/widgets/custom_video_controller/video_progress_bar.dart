// lib/widgets/custom_video_controller/video_progress_bar.dart
import 'package:flutter/material.dart';
import 'video_utils.dart';
import 'package:flutter/gestures.dart';
class VideoProgressBar extends StatefulWidget {
  final Duration currentPosition;
  final Duration totalDuration;
  final Duration bufferedPosition;
  final Function(Duration) onSeek;
  
  const VideoProgressBar({
    super.key,
    required this.currentPosition,
    required this.totalDuration,
    required this.bufferedPosition,
    required this.onSeek,
  });

  @override
  State<VideoProgressBar> createState() => _VideoProgressBarState();
}

class _VideoProgressBarState extends State<VideoProgressBar> {
  bool _isHovered = false;
  bool _isDragging = false;
  double _dragValue = 0;
  double _hoverValue = 0;
  bool _showPreview = false;

  @override
  Widget build(BuildContext context) {
    final progress = widget.totalDuration.inMilliseconds > 0
        ? widget.currentPosition.inMilliseconds / widget.totalDuration.inMilliseconds
        : 0.0;
    
    final buffered = widget.totalDuration.inMilliseconds > 0
        ? widget.bufferedPosition.inMilliseconds / widget.totalDuration.inMilliseconds
        : 0.0;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() {
        _isHovered = false;
        _isDragging = false;
        _showPreview = false;
      }),
      child: GestureDetector(
        onTapDown: (details) {
          _isDragging = true;
          _updateDragPosition(details);
        },
        onHorizontalDragStart: (_) => setState(() => _isDragging = true),
        onHorizontalDragUpdate: (details) {
          _updateDragPosition(details);
        },
        onHorizontalDragEnd: (_) {
          if (_isDragging) {
            final seekValue = _dragValue;
            widget.onSeek(Duration(
              milliseconds: (seekValue * widget.totalDuration.inMilliseconds).toInt(),
            ));
          }
          setState(() => _isDragging = false);
        },
        child: Container(
          height: 50,
          color: VideoUtils.controlBarBackground,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              // 当前时间
              _buildTimeDisplay(
                VideoUtils.formatDuration(widget.currentPosition),
                isCurrent: true,
              ),
              
              // 进度条区域
              Expanded(
                child: MouseRegion(
                  onHover: (event) {
                    if (!_isDragging) {
                      _updateHoverPosition(event);
                    }
                  },
                  child: Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      // 背景条
                      Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: VideoUtils.progressBarBackground,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      
                      // 缓冲进度
                      FractionallySizedBox(
                        widthFactor: buffered,
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      
                      // 播放进度
                      FractionallySizedBox(
                        widthFactor: _isDragging ? _dragValue : progress,
                        child: Container(
                          height: _isHovered ? 6 : 4,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF6B4EFF), // 深紫色
                                Color(0xFF9D7AFF), // 浅紫色
                              ],
                            ),
                            borderRadius: BorderRadius.circular(2),
                            boxShadow: [
                              if (_isHovered)
                                BoxShadow(
                                  color: VideoUtils.primaryColor.withValues(alpha: 0.5),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                            ],
                          ),
                        ),
                      ),
                      
                      // 预览指示器
                      if (_isHovered && !_isDragging)
                        Positioned(
                          left: _getHoverPosition(),
                          child: Container(
                            width: 2,
                            height: 12,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      
                      // 拖拽指示器
                      if (_isHovered || _isDragging)
                        Positioned(
                          left: _getThumbPosition(),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: _isDragging ? 16 : 12,
                            height: _isDragging ? 16 : 12,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              border: Border.all(
                                color: VideoUtils.primaryColor,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 4,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                        ),
                      
                      // 预览时间提示
                      if (_showPreview && _isHovered && !_isDragging)
                        Positioned(
                          left: _getHoverPosition() - 30,
                          bottom: 20,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Text(
                              _getPreviewTime(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              
              // 总时长
              _buildTimeDisplay(
                VideoUtils.formatDuration(widget.totalDuration),
                isCurrent: false,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeDisplay(String time, {required bool isCurrent}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: EdgeInsets.symmetric(
        horizontal: 8,
        vertical: (_isHovered || _isDragging) ? 6 : 4,
      ),
      decoration: BoxDecoration(
        color: (_isHovered || _isDragging) && isCurrent
            ? VideoUtils.primaryColor.withValues(alpha: 0.2)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        time,
        style: TextStyle(
          color: (_isHovered || _isDragging) && isCurrent
              ? VideoUtils.primaryColor
              : isCurrent
                  ? Colors.white
                  : VideoUtils.textSecondary,
          fontSize: 12,
          fontWeight: (_isHovered || _isDragging) && isCurrent
              ? FontWeight.bold
              : FontWeight.normal,
        ),
      ),
    );
  }

  void _updateDragPosition(dynamic details) {
    final renderBox = context.findRenderObject() as RenderBox;
    final localPosition = _getLocalPosition(details);
    final width = renderBox.size.width - 200; // 减去两侧时间显示宽度
    
    setState(() {
      _dragValue = (localPosition / width).clamp(0.0, 1.0);
      _showPreview = true;
    });
  }

  void _updateHoverPosition(PointerHoverEvent event) {
    final renderBox = context.findRenderObject() as RenderBox;
    final localPosition = event.localPosition.dx - 50; // 减去左侧时间显示宽度
    final width = renderBox.size.width - 200;
    
    setState(() {
      _hoverValue = (localPosition / width).clamp(0.0, 1.0);
      _showPreview = true;
    });
  }

  double _getLocalPosition(dynamic details) {
    if (details is TapDownDetails) {
      return details.localPosition.dx - 50;
    } else if (details is DragUpdateDetails) {
      return details.localPosition.dx - 50;
    }
    return 0;
  }

  double _getThumbPosition() {
    final renderBox = context.findRenderObject() as RenderBox;
    final width = renderBox.size.width - 200;
    final value = _isDragging ? _dragValue : 
                  (_isHovered ? _hoverValue : 
                  (widget.totalDuration.inMilliseconds > 0
                      ? widget.currentPosition.inMilliseconds / widget.totalDuration.inMilliseconds
                      : 0));
    return value * width - (_isDragging ? 8 : 6);
  }

  double _getHoverPosition() {
    final renderBox = context.findRenderObject() as RenderBox;
    final width = renderBox.size.width - 200;
    return _hoverValue * width - 1;
  }

  String _getPreviewTime() {
    final milliseconds = (_hoverValue * widget.totalDuration.inMilliseconds).toInt();
    return VideoUtils.formatDuration(Duration(milliseconds: milliseconds));
  }
}