// lib/widgets/drop_target_area.dart
import 'package:flutter/material.dart';
import 'package:desktop_drop/desktop_drop.dart';
//import 'dart:io';

class DropTargetArea extends StatelessWidget {
  final Widget child;
  final Function(String path) onFileDropped;
  
  const DropTargetArea({
    super.key,
    required this.child,
    required this.onFileDropped,
  });

  @override
  Widget build(BuildContext context) {
    return DropTarget(
      onDragDone: (details) {
        for (final file in details.files) {
          if (file.path.endsWith('.mp4') || 
              file.path.endsWith('.mkv') || 
              file.path.endsWith('.avi') ||
              file.path.endsWith('.mov') ||
              file.path.endsWith('.flv')) {
            onFileDropped(file.path);
            break;
          }
        }
      },
      onDragEntered: (details) {
        // 可以添加拖拽进入时的视觉反馈
      },
      onDragExited: (details) {
        // 拖拽离开时的视觉反馈
      },
      child: child,
    );
  }
}