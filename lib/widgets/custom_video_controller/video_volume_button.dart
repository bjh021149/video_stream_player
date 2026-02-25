// lib/widgets/custom_video_controller/video_volume_button.dart
import 'package:flutter/material.dart';
import 'video_utils.dart';

class VideoVolumeButton extends StatefulWidget {
  final double volume;
  final Function(double) onVolumeChanged;
  final VoidCallback? onMuteToggle;
  
  const VideoVolumeButton({
    super.key,
    required this.volume,
    required this.onVolumeChanged,
    this.onMuteToggle,
  });

  @override
  State<VideoVolumeButton> createState() => _VideoVolumeButtonState();
}

class _VideoVolumeButtonState extends State<VideoVolumeButton> with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  bool _isPressed = false;
  bool _showSlider = false;
  
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  
  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    _fadeAnimation = CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOut,
    );
  }
  
  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }
  
  void _handleMuteToggle() {
    if (widget.onMuteToggle != null) {
      widget.onMuteToggle!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() {
          _isHovered = true;
          _showSlider = true;
        });
        _slideController.forward();
      },
      onExit: (_) {
        setState(() {
          _isHovered = false;
        });
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted && !_isHovered) {
            setState(() {
              _showSlider = false;
            });
            _slideController.reverse();
          }
        });
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 音量按钮
          GestureDetector(
            onTapDown: (_) => setState(() => _isPressed = true),
            onTapUp: (_) => setState(() => _isPressed = false),
            onTapCancel: () => setState(() => _isPressed = false),
            onTap: _handleMuteToggle,
            child: AnimatedScale(
              scale: _isPressed ? 0.9 : (_isHovered ? 1.1 : 1.0),
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOutBack,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isHovered 
                      ? VideoUtils.buttonHoverBackground 
                      : VideoUtils.buttonBackground,
                  boxShadow: [
                    if (_isHovered)
                      BoxShadow(
                        color: VideoUtils.getVolumeColor(widget.volume).withValues(alpha: 0.4),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                  ],
                ),
                child: Icon(
                  VideoUtils.getVolumeIcon(widget.volume),
                  color: VideoUtils.getVolumeColor(widget.volume),
                  size: 24,
                ),
              ),
            ),
          ),
          
          // 音量滑块
          if (_showSlider)
            Positioned(
              bottom: 50,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Container(
                    width: 180,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: VideoUtils.overlayBackground,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: VideoUtils.dividerColor,
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            // 音量图标
                            GestureDetector(
                              onTap: _handleMuteToggle,
                              child: Icon(
                                widget.volume == 0 ? Icons.volume_off : Icons.volume_up,
                                color: VideoUtils.getVolumeColor(widget.volume),
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 8),
                            
                            // 音量滑块
                            Expanded(
                              child: SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  trackHeight: 4,
                                  thumbShape: const RoundSliderThumbShape(
                                    enabledThumbRadius: 8,
                                    elevation: 2,
                                  ),
                                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                                  activeTrackColor: VideoUtils.primaryColor,
                                  inactiveTrackColor: VideoUtils.progressBarBackground,
                                  thumbColor: Colors.white,
                                ),
                                child: Slider(
                                  value: widget.volume,
                                  onChanged: (value) {
                                    widget.onVolumeChanged(value);
                                  },
                                  min: 0,
                                  max: 1,
                                ),
                              ),
                            ),
                            
                            const SizedBox(width: 4),
                            
                            // 音量百分比
                            Text(
                              '${(widget.volume * 100).toInt()}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                        
                        // 静音提示
                        if (widget.volume == 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 4,
                                  height: 4,
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Text(
                                  '静音',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 8,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                        // 最大音量提示
                        if (widget.volume == 1.0)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 4,
                                  height: 4,
                                  decoration: const BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Text(
                                  '最大音量',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontSize: 8,
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
        ],
      ),
    );
  }
}