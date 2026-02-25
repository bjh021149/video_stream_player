// lib/widgets/custom_video_controller/video_overlay_indicators.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'video_utils.dart';

class VolumeOverlay extends StatefulWidget {
  final double volume;
  
  const VolumeOverlay({
    super.key,
    required this.volume,
  });

  @override
  State<VolumeOverlay> createState() => _VolumeOverlayState();
}

class _VolumeOverlayState extends State<VolumeOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  
  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeOutBack,
    );
    _scaleController.forward();
  }

  @override
  void didUpdateWidget(VolumeOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 当音量变化时，触发一个轻微的脉冲动画
    if (oldWidget.volume != widget.volume) {
      _scaleController.reset();
      _scaleController.forward();
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: MediaQuery.of(context).size.height * 0.15,
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: 0.8 + (0.2 * _scaleAnimation.value),
                child: child,
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 图标和百分比
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        transitionBuilder: (Widget child, Animation<double> animation) {
                          return RotationTransition(
                            turns: animation,
                            child: ScaleTransition(
                              scale: animation,
                              child: child,
                            ),
                          );
                        },
                        child: Icon(
                          VideoUtils.getVolumeIcon(widget.volume),
                          key: ValueKey<double>(widget.volume),
                          color: VideoUtils.getVolumeColor(widget.volume),
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 8),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 150),
                        child: Text(
                          '${(widget.volume * 100).toInt()}%',
                          key: ValueKey<int>((widget.volume * 100).toInt()),
                          style: TextStyle(
                            color: VideoUtils.getVolumeColor(widget.volume),
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // 音量条
                  Container(
                    width: 200,
                    height: 8,
                    decoration: BoxDecoration(
                      color: VideoUtils.progressBarBackground,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Stack(
                      children: [
                        // 背景
                        Container(),
                        
                        // 进度
                        FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: widget.volume,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  VideoUtils.primaryColor,
                                  widget.volume == 1.0 ? VideoUtils.successColor : VideoUtils.primaryColor,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                        
                        // 音量刻度
                        ...List.generate(10, (index) {
                          return Positioned(
                            left: index * 20.0,
                            top: 0,
                            bottom: 0,
                            child: Container(
                              width: 1,
                              height: 8,
                              color: Colors.white.withValues(
                                alpha: index < widget.volume * 10 ? 0.3 : 0.1,
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  
                  // 提示文字
                  if (widget.volume == 1.0)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        '最大音量',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )
                  else if (widget.volume == 0.0)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        '静音',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 200.ms);
  }
}

class SpeedOverlay extends StatelessWidget {
  final bool isForward;
  final double speed;
  
  const SpeedOverlay({
    super.key,
    required this.isForward,
    required this.speed,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      top: MediaQuery.of(context).size.height * 0.15,
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 旋转的图标
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(seconds: 2),
                  curve: Curves.linear,
                  builder: (context, value, child) {
                    return Transform.rotate(
                      angle: value * 2 * 3.14159,
                      child: Icon(
                        isForward ? Icons.fast_forward : Icons.fast_rewind,
                        color: Colors.amber,
                        size: 32,
                      ),
                    );
                  },
                ),
                
                const SizedBox(width: 12),
                
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isForward ? '快进中' : '快退中',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.amber.withValues(alpha: 0.5),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '${speed.toInt()}x',
                        style: const TextStyle(
                          color: Colors.amber,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().scale(
      begin: const Offset(0.8, 0.8),
      end: const Offset(1, 1),
      duration: 200.ms,
      curve: Curves.easeOutBack,
    ).fadeIn();
  }
}